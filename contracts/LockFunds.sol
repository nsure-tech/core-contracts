/**
 * @dev     a contract for locking Nsure Token to be an underwriter.
 *   
 * @notice  the underwriter program would be calculated and recorded by central ways
            which is too complicated for contracts(gas used etc.)
 */


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
    using SafeERC20 for IERC20;
    
    address public signer = 0x666747ffD8417a735dFf70264FDf4e29076c775a; 
    string constant public name = "Stake";
    string public version = "1";
    
    uint256 public depositMax = 1000000e18;
    uint256 public deadlineDuration = 30 minutes;
    
    address public operator;
    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;
    
    struct DivCurrencie {
        address divCurrencie;
        uint256 limit;
    }
    DivCurrencie[] public divCurrencies;
    

    INsure public Nsure;
    uint256 private _totalSupply;
    uint256 public claimDuration = 1 minutes;

    mapping(address => uint256) private _balances;
    mapping(address => uint256) public claimAt;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user,  uint256 amount);
    event Unstake(address indexed user,uint256 amount);
    event Claim(address indexed user,uint256 currency,uint256 amount);
    event Burn(address indexed user,uint256 amount);
    
    modifier onlyOperator() {
        require(msg.sender == operator,"not operator");
        _;
    }

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
 
    function setOperator(address _operator) external onlyOwner {   
        operator = _operator;
    }

    function setDeadlineDuration(uint256 _duration) external onlyOwner {
        deadlineDuration = _duration;
    }
 
    function getDivCurrencyLength() public view returns (uint256) {
        return divCurrencies.length;
    }

    
    function addDivCurrency(address _currency,uint256 _limit) public onlyOwner {
        divCurrencies.push(DivCurrencie({divCurrencie:_currency,limit:_limit}));
    }

    function setDepositMax(uint256 _max) external onlyOwner {
        depositMax = _max;
    }

    function deposit(uint amount) external {
        require(amount > 0, "Cannot stake 0");
        require(amount <= depositMax,"too much");

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
    function burnOuts(address[] memory _burnUsers, uint256[] memory _amounts) 
        external onlyOperator 
    {
        require(_burnUsers.length == _amounts.length, "not equal");

        for(uint256 i = 0; i<_burnUsers.length; i++) {
            require(_balances[_burnUsers[i]] >= _amounts[i], "insufficient");

            Nsure.burn(_amounts[i]);
            _balances[_burnUsers[i]] = _balances[_burnUsers[i]].sub(_amounts[i]);

            emit Burn(_burnUsers[i],_amounts[i]);
        }
    }

    function claim(uint _amount, uint currency, uint deadline, uint8 v, bytes32 r, bytes32 s)
        external
    {
        require(block.timestamp > claimAt[msg.sender].add(claimDuration), "wait" );
        require(block.timestamp.add(deadlineDuration) > deadline, "expired");
        require(_amount <= divCurrencies[currency].limit, "too much");

        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)),keccak256(bytes(version)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(CLAIM_TYPEHASH,address(msg.sender), currency, _amount,nonces[msg.sender]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);

        require(signatory != address(0), "invalid signature");
        require(signatory == signer, "unauthorized");
        require(block.timestamp <= deadline, "signature expired");

        claimAt[msg.sender] = block.timestamp;
        IERC20(divCurrencies[currency].divCurrencie).safeTransfer(msg.sender,_amount);

        emit Claim(msg.sender,currency,_amount);
    }

    function getChainId() public pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }


    receive() external payable {}
   
}