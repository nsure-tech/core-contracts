pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

contract Product {
    
       struct Product {
        string productName;
        uint status;

        uint totalSale;
        
    }

    mapping (address => Product) private _products;


    function getProduct(address _productAddr) public view returns (Product memory) {
        return _products[_productAddr];
    }

    function addProduct(address _productAddr, string memory _productName, uint _status) public  {
        _products[_productAddr]    =  Product(_productName, _status, 0);
    }

    function updateProduct(address _productAddr, string memory  _productName, uint _status) public  {
        _products[_productAddr] = Product(_productName, _status, 0);
    }

    function deleteProduct(address _productAddr) public  {
        delete _products[_productAddr];
    }



}