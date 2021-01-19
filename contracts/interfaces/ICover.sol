pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
interface ICover {

    struct Product {
        uint status;
        
    }
    function getStatus(uint _productId) external view returns (uint);
      function getProduct(uint _productId) external view returns (Product memory) ;
}