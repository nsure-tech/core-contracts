/**
 * @dev a contract for convert eth to nETH or token to nToken.
 *   
 * @notice  there would be a ratio between Token and nToken when emit a claim event.
 */


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract CapitalConverter is ERC20, Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public ETHEREUM = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    uint256 public maxConvert = 1000e18;
    address public token;
    uint256 public tokenDecimal;

    address public operator;

    constructor(address _token, uint256 _tokenDecimal,string memory name,string memory symbol) public  ERC20(name,symbol)
    {
        token           = _token;
        tokenDecimal    = _tokenDecimal;
    }

    receive() external payable {
        revert();
    }


    function smartBalance() public view returns (uint256) {
        if (token == ETHEREUM) {
            return address(this).balance;
        }

        return IERC20(token).balanceOf(address(this));
    }

    function calculateMintAmount(uint256 _depositAmount) internal view returns (uint256) {
        if (totalSupply() == 0) {
            uint256 value = _depositAmount.mul(uint256(1e18)).div(10**tokenDecimal);
            return value;
        }

        uint256 initialBalance = smartBalance().sub(_depositAmount);
        return _depositAmount.mul(totalSupply()).div(initialBalance);
    }
    
    // convert ETH or USDx to nETH/nUSDx
    function convert(uint256 _amount) public payable nonReentrant whenNotPaused {
        require(_amount > 0, "CapitalConverter: Cannot stake 0.");
        require(_amount <= maxConvert, "too much");

        if (token != ETHEREUM) {
            require(msg.value == 0, "CapitalConverter: Should not allow ETH deposits.");
            IERC20(token).safeTransferFrom(_msgSender(), address(this), _amount);
        } else {
            require(_amount == msg.value, "CapitalConverter: Incorrect eth amount.");
        }

        uint256 value = calculateMintAmount(_amount);
        _mint(_msgSender(), value);
        
        // emit event
        emit eMint(_msgSender(), _amount, value);
    }

    // withdraw the ETH or USDx
    function exit(uint256 _value) external nonReentrant whenNotPaused {
        require(balanceOf(_msgSender()) >= _value && _value > 0, "CapitalConverter: _value is not good");

        uint256 value = _value.mul(smartBalance()).div(totalSupply());
        if (token != ETHEREUM) {
            IERC20(token).safeTransfer(_msgSender(), value);
        } else {
            _msgSender().transfer(value);
        }

        _burn(_msgSender(), _value);
        
        // emit event
        emit eBurn(_msgSender(), _value, value);
    }

    function payouts(address payable _to, uint256 _amount) external onlyOperator {
        if (token != ETHEREUM) {
            IERC20(token).safeTransfer(_to, _amount);
        } else {
            _to.transfer(_amount);
        }

        emit ePayouts(_to, _amount);
    }

    modifier onlyOperator(){
        require(msg.sender == operator, "not operator");
        _;
    }

    function setOperator(address _operator) external onlyOwner {
        operator = _operator;
    }

    function setMaxConvert(uint256 _max) external onlyOwner {
        maxConvert = _max;
    }


    event eMint(address indexed sender, uint256 input, uint256 amount);
    event eBurn(address indexed sender, uint256 amount, uint256 output);
    event ePayouts(address indexed to, uint256 amount);
}
