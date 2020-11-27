pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract Product {
        using SafeMath for uint;

    struct Product {
        string productName;
        uint status;
        uint totalSale;
        uint available;
        
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

    function updateStatus(address _productAddr,uint _status) public {
        _products[_productAddr].status = _status;
    }
    
    function addTotalSale(address _productAddr,uint _amount) public {
        _products[_productAddr].totalSale = _products[_productAddr].totalSale.add(_amount);
    }


}