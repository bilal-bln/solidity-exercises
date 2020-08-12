/*
    reference:
    https://www.youtube.com/watch?v=BY4o0Qqlh-4
*/

pragma solidity ^0.6.6;

contract GasEfficientContract {
    uint8 value = 1; // saves bytes compared to uint256
    
    // does NOT consume gas
    function hello() public pure returns(string memory) {
        return "Hello Solidity";
    }
    
    // does consume gas
    function incrementAndGetValue() public returns(uint8) {
        value++;
        return value;
    }
}