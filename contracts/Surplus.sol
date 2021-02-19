
/**
 * @dev Surplus Pool which just does receive/payout things.
 *
 * @dev A ratio(commonly would be 40%) of the cover cost would be sent to surplus pool for claiming.
 */


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

pragma solidity >= 0.6.0;


contract Surplus is Ownable {
    using SafeERC20 for IERC20;
 
    address public constant ETHEREUM = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
  
    address public operator;

    // return my token balance
    function myBalanceOf(address tokenAddress) external view returns(uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    // payout for claiming
    function payouts(address payable _to, uint256 _amount,address token) external onlyOperator {
        require(_to != address(0),"_to is zero");
        if (token != ETHEREUM) {
            IERC20(token).safeTransfer(_to, _amount);
        } else {
            _to.transfer(_amount);
        }

        emit ePayouts(_to, _amount);
    }

    receive() external payable {}
    

    function setOperator(address _operator) external onlyOwner {   
        require(_operator != address(0),"_operator is zero");
        operator = _operator;
        emit eSetOperator(_operator);
    }

    modifier onlyOperator() {
        require(msg.sender == operator,"not operator");
        _;
    }

    /////////// events /////////////
    event ePayouts(address indexed to, uint256 amount);
    event eSetOperator(address indexed operator);
 
}
