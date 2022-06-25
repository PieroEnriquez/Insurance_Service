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
    */
    mapping(address => insured) public mappingInsured;
    mapping(string => service)  public mappingService;
    mapping(address => lab) public mappingLabs;

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


}
