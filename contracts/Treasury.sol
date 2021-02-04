
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

pragma solidity >= 0.6.0;


contract Treasury is Ownable {
    using SafeERC20 for IERC20;


    address public ETHEREUM = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
  
    // return my token balance
    function myBalanceOf(address tokenAddress) public view returns(uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    // payout for claiming
    function payouts(address payable _to, uint256 _amount,address token) external onlyOwner {
        if (token != ETHEREUM) {
            IERC20(token).safeTransfer(_to, _amount);
        } else {
            _to.transfer(_amount);
        }

        emit ePayouts(_to, _amount);
    }

    receive() external payable {}
    
    /////////// events /////////////
    event ePayouts(address indexed to, uint256 amount);
 
}
