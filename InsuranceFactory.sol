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
        token = new ERC20Basic(100);
        insurance = address(this);
        company = payable(msg.sender);
    }

    //Creating structs for the insured client, the service and the laboratory that offers it
    struct insured{
        address clientAddress;
        bool authorization;
        address contractAdress;
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

}
