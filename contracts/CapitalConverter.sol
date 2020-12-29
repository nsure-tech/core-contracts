
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Pauseable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/GSN/Context.sol";


contract CapitalConverter is ERC20, Ownable, Pauseable, ReentrancyGuard {
    using SafeMath for uint256;

    address public ETHEREUM = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    address public token;
    uint256 public tokenDecimal;

    constructor(address _token, uint256 _tokenDecimal) 
        public  ERC20("name","symbol")
    {
        token           = _token;
        tokenDecimal    = _tokenDecimal;
    }

    receive() external payable {
        revert();
    }
    

    function smartBalance(address _token) public view returns (uint256) {
        if (_token == ETHEREUM) {
            return address(this).balance;
        }
        return IERC20(_token).balanceOf(address(this));
    }

    function calculateMintAmount(uint256 _depositAmount) internal view returns (uint256) {    
        uint256 initialBalance = smartBalance(address(this)).sub(tokenDecimal);

        if (totalSupply() == 0) {
            uint256 value = _depositAmount.mul(uint256(1e18)).div(10**dollarDecimal);
            return value;
        }

        return _depositAmount.mul(totalSupply()).div(initialBalance);
    }
    
    // convert ETH or USDx to nETH/nUSDx
    function convert(uint256 _amount) public payable nonReentrant whenNotPaused { 
        require(_amount > 0, "CapitalConverter: Cannot stake 0.");

        if (_token != ETHEREUM) {
            require(msg.value == 0, "CapitalConverter: Should not allow ETH deposits during ERC20 token deposits.");
            IERC20(_token).safeTransferFrom(_msgSender(), address(this), _amount);
        } else {
            require(_amount == msg.value, "CapitalConverter: Incorrect eth amount.");
        }

        uint256 value = calculateMintAmount(_amount);
        _mint(_msgSender(), value);
        
        // emit event
        emit Mint(_msgSender(), value);
    }

    // withdraw the ETH or USDx
    function exit(uint256 _value) external nonReentrant whenNotPaused {
        require(balanceOf(_msgSender()) >= _value && _value > 0, "CapitalConverter: _value is not good");

        uint256 value = _value.mul(smartBalance(address(this))).div(totalSupply());
        _burn(_msgSender(),_value);
        
        if (token != ETHEREUM) {
            IERC20(token).transfer(_msgSender(), value);
        } else {
            _msgSender().transfer(value);
        }

        // emit event
        emit Burn(_msgSender(), _value);
    }


    event Mint(address indexed sender, uint256 amount);
    event Burn(address indexed sender, uint256 amount);
   
}