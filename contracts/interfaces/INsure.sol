pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
interface INsure {

    function  burn(uint256 amount)  external ;
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external  returns (bool);
}