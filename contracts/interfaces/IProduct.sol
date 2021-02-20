pragma solidity ^0.6.0;
interface IProduct {
    function getStatus(uint256 _productId) external view returns (uint256);
}