//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./SafeMath.sol";
import "./AggregatorV3Interface.sol";

abstract contract BasicOperations{

    using SafeMath for uint256;

    //Adding the necessary interface for the price feed
    AggregatorV3Interface internal priceFeed;

    //Constructing the contract as abstract
    constructor(){
        priceFeed = AggregatorV3Interface(0x3E7d1eAB13ad0104d2750B8863b489D65364e32D);
    }

    //In this case, i'm going to use Ethereum contract of the USDT token for the price


    //Function to calculate the token price based on a stablecoin
    function calcTokenPrice(uint _numTokens) internal pure returns(uint){
        return _numTokens = 0;
    }

    //Function to get the balance of required tokens in the contract
    function getBalance() public view returns(uint ethers){
        return payable(address(this)).balance;
    }

    //Function to transform a uint to a string
    function uint2str(uint _i) internal pure returns(string memory _uintAsString){
        if (_i == 0){
            return "0";
        }
        uint j = _i;
        uint len;
        while(j != 0){
            len++;
            j /=10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while(_i != 0){
            k = k+1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }


}