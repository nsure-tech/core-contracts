pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
interface INsure {

    function burn(uint256 amount)  external ;
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external  returns (bool);
    function mint(address _to, uint256 _amount) external  returns (bool);
    function balanceOf(address account) external view returns (uint256);
}