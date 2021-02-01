
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "./interfaces/INsure.sol";

pragma solidity ^0.6.0;

contract LockFunds is Ownable {
    
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    
    address public signer = 0x666747ffD8417a735dFf70264FDf4e29076c775a; 
    string constant public name = "Stake";
    string public version = "1";
    
    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    INsure public Nsure;
    uint256 private _totalSupply;
    uint256 public claimDuration = 1 minutes;

    mapping(address => uint256) private _balances;
    mapping(address => uint256) public claimAt;

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

    constructor(address _nsure)public {
        Nsure = INsure(_nsure);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function setClaimDuration(uint256 _duration)external onlyOwner {
        require(claimDuration != _duration, "the same duration");
        claimDuration = _duration;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }
 
    function deposit(uint amount) external {
        require(amount > 0, "Cannot stake 0");

        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);

        Nsure.transferFrom(msg.sender, address(this), amount);

        emit Deposit(msg.sender, amount);
    }

      function withdraw(uint256 _amount,uint deadline,uint8 v, bytes32 r, bytes32 s) external {
        require(_balances[msg.sender] >= _amount,"insufficient");

        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)),keccak256(bytes(version)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(WITHDRAW_TYPEHASH,address(msg.sender), _amount,nonces[msg.sender]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "invalid signature");
        require(signatory == signer, "unauthorized");
        require(block.timestamp <= deadline, "signature expired");

        _balances[msg.sender] = _balances[msg.sender].sub(_amount);
        Nsure.transfer(msg.sender,_amount);

        emit Withdraw(msg.sender,_amount);
    }

    // burn 1/2 for claiming 
    function burnOuts(address [] _burnUsers, uint256[] _amounts) external onlyOwner {
        // for循环执行下述命令

        // 0. require检查

        // 1. 销毁该合约对应金额

        // 2. 减少该用户的amount

        // 3. 触发事件
    }

    function claim(uint _amount,uint ,uint deadline,uint8 v, bytes32 r, bytes32 s) external {
        require(block.timestamp > claimAt[msg.sender].add(claimDuration),"wait" );

        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)),keccak256(bytes(version)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(CLAIM_TYPEHASH,address(msg.sender),currency, _amount,nonces[msg.sender]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);

        require(signatory != address(0), "invalid signature");
        require(signatory == signer, "unauthorized");
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

    function burnNsure(uint256 _amount)external onlyOwner {
        Nsure.burn(_amount);
    }
    

    receive() external payable {}
   
}