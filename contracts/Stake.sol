
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
     address public signAdmin = 0x666747ffD8417a735dFf70264FDf4e29076c775a; 
   string constant public name = "Stake";
    string public version = "1";
      /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    ERC20 public Nsure;
    ERC20 public USDT;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user,  uint256 amount);
    event Unstake(address indexed user,uint256 amount);
    event Claim(address indexed user,uint256 currency,uint256 amount);
    

      /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

 
    /// @notice The EIP-712 typehash for the permit struct used by the contract
    bytes32 public constant CLAIM_TYPEHASH = keccak256("Claim(address account,uint256 currency,uint256 amount,uint256 nonce,uint256 deadline)");


    /// @notice The EIP-712 typehash for the permit struct used by the contract
    bytes32 public constant WITHDRAW_TYPEHASH = keccak256("Withdraw(address account,uint256 amount,uint256 nonce,uint256 deadline)");

    constructor(address _nsure,address _usdt)public {
        Nsure = ERC20(_nsure);
        USDT = ERC20(_usdt); //not available
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

 
    function deposit(uint amount) external {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        Nsure.safeTransferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, amount);
    }

      function withdraw(uint256 _amount,uint deadline,uint8 v, bytes32 r, bytes32 s) external {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)),keccak256(bytes(version)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(WITHDRAW_TYPEHASH,address(msg.sender), _amount,nonces[msg.sender]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "invalid signature");
        require(signatory == signAdmin, "unauthorized");
        require(block.timestamp <= deadline, "signature expired");
        Nsure.safeTransfer(msg.sender,_amount);
        emit Withdraw(msg.sender,_amount);
    }



    function claim(uint _amount,uint currency,uint deadline,uint8 v, bytes32 r, bytes32 s) external {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)),keccak256(bytes(version)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(CLAIM_TYPEHASH,address(msg.sender),currency, _amount,nonces[msg.sender]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "invalid signature");
        require(signatory == signAdmin, "unauthorized");
        require(block.timestamp <= deadline, "signature expired");
        if(currency ==1){
            msg.sender.transfer(_amount);
        }else{
            // USDT.safeTransfer(msg.sender,_amount);
        }
        emit Claim(msg.sender,currency,_amount);
        
    }


    function getChainId() public pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
   
}