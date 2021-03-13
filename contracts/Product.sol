/**
 * @dev a contract for defining product basic information.
 *   
 * @notice  more info need to be defined in the backend system.
 */

 
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

contract Product is Ownable {
    using SafeMath for uint;

    struct ProductStatus {
        uint status;
    }

    uint256[] public productId;
    mapping (uint => ProductStatus) private _products;

    address public operator;

    modifier onlyOperator() {
        require(msg.sender == operator,"not operator");
        _;
    }

    function getLength() external view returns (uint) {
        return productId.length;
    }


    function getProduct(uint _productId) external view returns (ProductStatus memory) {
        return _products[_productId];
    }

    function getStatus(uint _productId) external view returns (uint) {
        return _products[_productId].status;
    }

    function addProduct(uint _productId, uint _status) external onlyOperator {
        for(uint256 i=0;i<productId.length;i++){
            if(productId[i] == _productId){
                return;
            }
        }
        _products[_productId] =  ProductStatus(_status);
        productId.push(_productId) ;

        emit AddProduct(_productId,_status);
    }

    function deleteProduct(uint _productId) external onlyOperator {
        delete _products[_productId];
        
        for(uint i=0;i<productId.length;i++){
            if(productId[i] == _productId){
                productId[i] = productId[productId.length-1];
                productId.pop();

                emit DeleteProduct(_productId);
                break;
            }
        }

    }

       function updateStatus(uint _productId,uint _status) public onlyOperator {
         for(uint256 i=0;i<productId.length;i++){
            if(productId[i] == _productId){
                require(_products[_productId].status != _status, "same status");
                 _products[_productId].status = _status;
                 emit UpdateStatus(_productId,_status);
                 
                return;
            }
        }

    }


    function setOperator(address _operator) external onlyOwner {  
        require(_operator != address(0),"_operator is zero"); 
        operator = _operator;
        emit SetOperator(_operator);
    }


    event UpdateStatus(uint  product,uint256 status);
    event DeleteProduct(uint  product);
    event AddProduct(uint  product,uint256 status);
    event SetOperator(address indexed operator);
}
