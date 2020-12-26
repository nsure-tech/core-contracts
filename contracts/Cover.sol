
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

contract Cover {
    using SafeMath for uint;

    struct Product {
        uint status;
        uint totalSale;
        // uint available;
        
    }
    uint public available;
    address[] public productIndex;
    mapping (address => Product) private _products;

    function getLength() public view returns (uint) {
        return productIndex.length;
    }

  function getAvailale()public view returns (uint){
      return available;
  }

    function getProduct(address _productAddr) public view returns (Product memory) {
        return _products[_productAddr];
    }

    function addProduct(address _productAddr, uint _status) public  {
        _products[_productAddr]    =  Product( _status, 0);
        productIndex.push(_productAddr) ;
        emit AddProduct(_productAddr,_status);
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
        emit DeleteProduct(_productAddr);
    }

    function updateStatus(address _productAddr,uint _status) public {
        _products[_productAddr].status = _status;
        emit UpdateStatus(_productAddr,_status);
    }
    
    function addTotalSale(address _productAddr,uint _amount) public {
        _products[_productAddr].totalSale = _products[_productAddr].totalSale.add(_amount);
       emit AddTotalSale(_productAddr,_amount);
    }

    function subAvailable(uint _amount) public {
        // _products[_productAddr].available = _products[_productAddr].available.sub(_amount);
        available = available.sub(_amount);
        emit SubAvailable(_amount);
    }

    function addAvailable(uint _amount) public {
        // _products[_productAddr].available = _products[_productAddr].available.add(_amount);
        available = available.add(_amount);
        emit AddAvailable(_amount);
    }

    event AddAvailable(uint256 amount);
    event SubAvailable(uint256 amount);
    event AddTotalSale(address indexed product,uint256 amount);
    event UpdateStatus(address indexed product,uint256 status);
    event DeleteProduct(address indexed product);
    event AddProduct(address indexed product,uint256 status);
}