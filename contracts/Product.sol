
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

contract Product {
    using SafeMath for uint;

    struct Product {
        string productName;
        uint status;
        uint totalSale;
        uint available;
        
    }
    address[] public productIndex;
    mapping (address => Product) private _products;

    function getLength() public view returns (uint) {
        return productIndex.length;
    }

  

    function getProduct(address _productAddr) public view returns (Product memory) {
        return _products[_productAddr];
    }

    function addProduct(address _productAddr, string memory _productName, uint _status) public  {
        _products[_productAddr]    =  Product(_productName, _status, 0);
        productIndex.push(_productAddr) ;
    }

    function updateProduct(address _productAddr, string memory  _productName, uint _status) public  {
        _products[_productAddr] = Product(_productName, _status, 0);
    }

    function deleteProduct(address _productAddr) public  {
        delete _products[_productAddr];
        for(uint i=0;i<productIndex.length;i++){
            if(productIndex[i] == _productAddr){
                productIndex[i] = productIndex[productIndex.length-1];
                productIndex.pop();
                break;
            }
        }
    }

    function updateStatus(address _productAddr,uint _status) public {
        _products[_productAddr].status = _status;
    }
    
    function addTotalSale(address _productAddr,uint _amount) public {
        _products[_productAddr].totalSale = _products[_productAddr].totalSale.add(_amount);
    }

    function subAvailable(address _productAddr,uint _amount) public {
        _products[_productAddr].available = _products[_productAddr].available.sub(_amount);
    }

}