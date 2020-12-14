
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/Math.sol";


pragma solidity ^0.6.0;

contract Stake {
    
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    ERC20 public Nsure = ERC20(0x20945cA1df56D237fD40036d47E866C7DcCD2114);

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    event Depost(address indexed user, uint256 amount);

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

 
    function depost(uint amount) external {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        Nsure.safeTransferFrom(msg.sender, address(this), amount);
        emit Depost(msg.sender, amount);
    }
    
}