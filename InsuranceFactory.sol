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

    //Function to shut down an insured that unsubscribed
    function insuredOff(address _insured) public onlyInsurance(msg.sender){
        mappingInsured[_insured].authorization = false;
        InsuranceHealthRecord(mappingInsured[_insured].contractAddress).unsubscribe;
    }

    //Function to set a new service
    function newService(string memory _name, uint _price) public onlyInsurance(msg.sender){
        mappingService[_name] = service(_name, _price, true);
        nameServices.push(_name);
        emit NewService(_name, _price);
    }

    //Function for the insurance to shut down a service
    function serviceDown(string memory _name) public onlyInsurance(msg.sender){
        require(serviceState(_name) == true, "The service is already down");
        mappingService[_name].serviceState = false;
        emit ServiceOff(_name);
    }

    //Function to see the availability of a service
    function serviceState(string memory _name) public view returns(bool){
        return mappingService[_name].serviceState;
    }

    //
    function servicePrice(string memory _name) public view returns(uint256){
        require(serviceState(_name) == true, "This service is nos available right now");
        return mappingService[_name].servicePrice;
    }



    //Function to buy tokens that will help later for the insured's own contract
    function buyTokens(address _insured, uint _numTokens) public payable onlyClient(msg.sender){
        _insured;
        uint256 balance = balanceOf();
        require(_numTokens <= balance, "Try buying less tokens");
        require(_numTokens > 0, "Try buying a number of tokens higher than 0");
        token.transfer(msg.sender, _numTokens);
        emit BuyedTokens(_numTokens);
    }

    //Function to get the balance of tokens from the insurance
    function balanceOf() public view returns(uint256){
        return(token.balanceOf(insurance));
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

    //Modifier for only the insured to run a function
    modifier only(address _insurance){
        require(_insurance == owner.ownerAddress, "You are not the insured");
        _;
    }

    //Function to see the insured's record of lab's services
    function LabInsuredRecord() public view returns(labAskedServices[]memory){
        return labInsuredRecord;
    }

    //Function to see the last time the insured took a service
    function InsuredRecord(string memory _service) public view returns(string memory, uint){
        return (insuredRecord[_service].serviceName, insuredRecord[_service].servicePrice);
    }

    //Function to see the state of a service the insured has taken
    function InsuredServiceState(string memory _service) public view returns(bool){
        return insuredRecord[_service].serviceState;
    }

    //Function for the insured to unsubscribe from the insurance and, therefore, to destruct the insured's contract
    function unsubscribe() public only(msg.sender){
        emit SelfDestruct(msg.sender);
        selfdestruct(payable(msg.sender));
    }

    //Function to buy tokens from the contract of the insured
    function buyTokens(uint _numTokens) public payable only(msg.sender){
        require(_numTokens > 0, "You must put a number bigger than 0");
        uint cost = calcTokenPrice(_numTokens);
        require(msg.value <= cost, "You don't have enough money");
        uint returnValue = msg.value - cost;
        payable(msg.sender).transfer(returnValue);
        InsuranceFactory(owner.insurance).buyTokens(owner.ownerAddress, _numTokens);
    }

    //Function to get the balance of the address
    function balanceOf() public view only(msg.sender) returns(uint256){
        return(owner.tokens.balanceOf(address(this)));
    }

    function tokensBack(uint _numTokens) public payable only(msg.sender){
        require(_numTokens > 0, "You must input an amount of tokens higher than 0");
        require(_numTokens >= balanceOf(), "You must have the amount of tokens you want to give back");
        owner.tokens.transfer(owner.insurance, _numTokens);
        payable(msg.sender).transfer(calcTokenPrice(_numTokens));
        emit TokensBack(msg.sender, _numTokens);
    }

    function askForService(string memory _service) public only(msg.sender){
        require(InsuranceFactory(owner.insurance).serviceState(_service) == true, "This service is not available right now");
        uint256 tokenPay = InsuranceFactory(owner.insurance).servicePrice(_service);
        require(tokenPay >= balanceOf(), "You need to buy more tokens");
        owner.tokens.transfer(owner.insurance, tokenPay);
        insuredRecord[_service] = askedServices(_service, tokenPay, true);
        emit PayedService(msg.sender, _service, tokenPay);
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
