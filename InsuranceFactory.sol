//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./BasicOperations.sol";
import "./ERC20.sol";

contract InsuranceFactory is BasicOperations{

    //Declaring addresses and the instance of token contract
    ERC20Basic private token;
    address insurance;
    address payable public company;
    
    constructor(){
        token = new ERC20Basic(1000);
        insurance = address(this);
        company = payable(msg.sender);
    }

    //Creating structs for the insured client, the service and the laboratory that offers it
    struct insured{
        address clientAddress;
        bool authorization;
        address contractAddress;
    }

    struct service{
        string serviceName;
        uint servicePrice;
        bool serviceState;
    }

    struct lab{
        address contractAddress;
        bool validation;
    }

    /*
    Mappings to find each struct according to:
    - insured's address (address => insured)
    - service's name (string => service)
    - lab's addres (address => lab)
    and arrays to save the insured's address, the name of the services and the addresses of the labs
    */
    mapping(address => insured) public mappingInsured;
    mapping(string => service)  public mappingService;
    mapping(address => lab) public mappingLabs;

    address[] insuredAddresses;
    string[] private nameServices;
    address[] labsAddresses;

    //Function for an insured to know if he/she has authorization
    function functionOnlyInsured(address _address) public view{
        require(mappingInsured[_address].authorization == true, "This address is not authorized");
    }

    //The previous function helps for a modifier for clients only to run a function
    modifier onlyClient(address _address){
        functionOnlyInsured(_address);
        _;
    }

    modifier onlyInsurance(address _address){
        require(_address == company, "You are not allowed to run this function");
        _;
    }

    modifier InsuranceOrInsured(address _insuredAddress, address _requestingAddress){
        require((mappingInsured[_requestingAddress].authorization == true && _insuredAddress == _requestingAddress)
        || company == _requestingAddress);
        _;
    }

    event BuyedTokens(uint256);
    event NewLab(address, address);
    event NewInsured(address, address);
    event NewService(string, uint256);
    event InsuredOff(address);
    event ServiceOff(string);

    //Function to create a new contract for a certified lab
    function newLab() public{
        labsAddresses.push(msg.sender);
        address labAddress = address(new Laboratory(msg.sender, insurance));
        mappingLabs[msg.sender] = lab(labAddress, true);
        emit NewLab(msg.sender, labAddress);
    }

    //Creates a new contract for an insured
    function newInsuredContract() public{
        insuredAddresses.push(msg.sender);
        address insuredAddress = address(new InsuranceHealthRecord(msg.sender, token, insurance, company));
        mappingInsured[msg.sender] = insured(msg.sender, true, insuredAddress);
        emit NewInsured(msg.sender, insuredAddress);
    }

    //Function to see the available labs
    function availableLabs() public view onlyInsurance(msg.sender) returns(address[]memory){
        return labsAddresses;
    }

    //Function to see the mapping that collects the insureds' addresses
    function Insureds() public view onlyInsurance(msg.sender) returns(address[]memory){
        return insuredAddresses;
    }

    //Function to see insureds' record of services received
    function insuredHistoricalRecord(address _insuredAddress, address _consultingAddress) public view InsuranceOrInsured(_insuredAddress, _consultingAddress) returns(string memory){
        string memory record = "";
        address insuredContract = mappingInsured[_insuredAddress].contractAddress;

        for(uint i=0; i<nameServices.length; i++){
            if(mappingService[nameServices[i]].serviceState && InsuranceHealthRecord(insuredContract).InsuredServiceState(nameServices[i]) == true){
                (string memory _nameService, uint _priceService) = InsuranceHealthRecord(insuredContract).InsuredRecord(nameServices[i]);
                record = string(abi.encodePacked(record, "(", _nameService, ",", uint2str(_priceService), ") - "));
            }
        }
        return record;
    }

    function insuredOff(address _insured) public onlyInsurance(msg.sender){
        mappingInsured[_insured].authorization = false;
        InsuranceHealthRecord(mappingInsured[_insured].contractAddress).unsubscribe;
    }


}

contract InsuranceHealthRecord is BasicOperations{

    enum State{Up, Down}

    struct Owner{
        address ownerAddress;
        uint ownerCash;
        State state;
        IERC20 tokens;
        address insurance;
        address payable company;
    }

    //Declaring the addresses
    Owner owner;

    constructor(address _owner, IERC20 _token, address _insurance, address payable _company){
        owner.ownerAddress = _owner;
        owner.ownerCash = 0;
        owner.state = State.Up;
        owner.tokens = _token;
        owner.insurance = _insurance;
        owner.company = _company;
    }

    //Struct for asked services by the client on and off the labs
    struct askedServices{
        string serviceName;
        uint256 servicePrice;
        bool serviceState;
    }

    struct labAskedServices{
        string serviceName;
        uint256 servicePrice;
        address labAddress;
    }

    mapping(string => askedServices) insuredRecord;
    labAskedServices [] labInsuredRecord;

    event SelfDestruct(address);
    event TokensBack(address, uint256);
    event PayedService(address, string, uint256);
    event RequestLabService(address, address, string);
        
    modifier only(address _insurance){
        require(_insurance == owner.ownerAddress, "You are not the insured");
        _;
    }

    function LabInsuredRecord() public view returns(labAskedServices[]memory){
        return labInsuredRecord;
    }

    function InsuredRecord(string memory) public view returns(string memory, uint){

    }

    function InsuredServiceState(string memory _service) public view returns(bool){

    }

    function unsubscribe() public only(msg.sender){
        
    }

}

contract Laboratory is BasicOperations{

    //Declaring the addresses
    address public labAddress;
    address insuranceContract;

    constructor(address _account, address _insuranceContract){
        labAddress = _account;
        insuranceContract = _insuranceContract;
    }


}
