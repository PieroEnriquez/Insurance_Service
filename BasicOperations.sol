//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./SafeMath.sol";
import "./AggregatorV3Interface.sol";

abstract contract BasicOperations{

    using SafeMath for uint256;

    //Adding the necessary interface for the price feed
    AggregatorV3Interface internal priceFeed;

    //Constructing the contract as abstract plus the data feed from the USDT contract
    constructor(){
        priceFeed = AggregatorV3Interface(0x3E7d1eAB13ad0104d2750B8863b489D65364e32D);
    }

    //In this case, i'm going to use Ethereum contract of the USDT token for the price
    function getThePrice() public view returns (uint) {
        (
            /*uint80 roundID*/,
            uint price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
       return price;
   }

    //Function to calculate the token price based on a stablecoin by the relation of 1 token per 5 USDTs
    function calcTokenPrice(uint _numTokens) internal view returns(uint){
        return _numTokens.mul(5*(getThePrice()));
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