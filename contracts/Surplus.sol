
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/GSN/Context.sol";

pragma solidity >= 0.6.0;

contract Surplus is Ownable {

    function claimEth(uint _amount) external onlyOwner {
        require(address(this).balance >= _amount,"not good");
        msg.sender.transfer(_amount);
    }

    function claimToken(address _token, uint _amount) external onlyOwner {
        require(IERC20(_token).balanceOf(address(this)) >= _amount,"not good");
        IERC20(_token).transfer(msg.sender,_amount);
    }
 
    receive() external payable {

    }


}