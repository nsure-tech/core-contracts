

/**
 * @dev Treasury which just does receive/payout things. 
 *      About 10% of the cover cost would be sent here for voting things etc.
 */


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

pragma solidity >= 0.6.0;


contract Treasury is Ownable {
    using SafeERC20 for IERC20;

    address public ETHEREUM = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    address public operator;


    receive() external payable {}
  

    // payout for claiming
    function payouts(address payable _to, uint256 _amount, address token) external onlyOperator {
        if (token != ETHEREUM) {
            IERC20(token).safeTransfer(_to, _amount);
        } else {
            _to.transfer(_amount);
        }

        emit ePayouts(_to, _amount);
    }

    function setOperator(address _operator) external onlyOwner {   
        operator = _operator;
    }

    // return my token balance
    function myBalanceOf(address tokenAddress) public view returns(uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }
    

    modifier onlyOperator() {
        require(msg.sender == operator,"not operator");
        _;
    }

    
    /////////// events /////////////
    event ePayouts(address indexed to, uint256 amount);
 
}
