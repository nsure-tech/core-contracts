pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
interface ICover {

    struct Product {
        uint status;
        uint totalSale;
        uint available;
        
    }
      function getProduct(address _productAddr) external view returns (Product memory) ;
       function addAvailable(uint _amount) external ;
       function addTotalSale(address _productAddr,uint _amount) external;
      function subAvailable(uint _amount) external;
      function getAvailale()external view returns (uint);
}