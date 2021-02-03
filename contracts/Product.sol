
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

contract Product is Ownable {
    using SafeMath for uint;

    struct Product {
        // 0:enable 1:disable
        uint status;
    }

    uint256[] public productId;
    mapping (uint => Product) private _products;
    // mapping (uint=>bool) private exist;

    function getLength() public view returns (uint) {
        return productId.length;
    }


    function getProduct(uint _productId) public view returns (Product memory) {
        return _products[_productId];
    }

function getStatus(uint _productId) external view returns (uint) {
    return _products[_productId].status;
}
    function addProduct(uint _productId, uint _status) public onlyOwner  {
        // require(exist[_productId] == false,"exist");
        for(uint256 i=0;i<productId.length;i++){
            if(productId[i] == _productId){
                return;
            }
        }
        _products[_productId] =  Product(_status);
        productId.push(_productId) ;
        // exist[_productId] = true;

        emit AddProduct(_productId,_status);
    }

    function deleteProduct(uint _productId) public onlyOwner {
        delete _products[_productId];
        
        for(uint i=0;i<productId.length;i++){
            if(productId[i] == _productId){
                productId[i] = productId[productId.length-1];
                productId.pop();
                break;
            }
        }
        // exist[_productId] = false;

        emit DeleteProduct(_productId);
    }

    function updateStatus(uint _productId,uint _status) public onlyOwner {
        _products[_productId].status = _status;
        
        emit UpdateStatus(_productId,_status);
    }
    



    event UpdateStatus(uint  product,uint256 status);
    event DeleteProduct(uint  product);
    event AddProduct(uint  product,uint256 status);
}