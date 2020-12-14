pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
interface IProduct {

    struct Product {
        string productName;
        uint status;
        uint totalSale;
    }

      function getProduct(address _productAddr) external view returns (Product memory) ;
}