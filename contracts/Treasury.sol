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
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/INsure.sol";

pragma solidity ^0.6.0;



contract Underwriting is Ownable, ReentrancyGuard{
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    

    address public constant ETHEREUM = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);


    address public signer; 
    string constant public name = "Treasury";
    string public constant version = "1";
    
    uint256 public depositMax = 1 * 1e6 * 1e18;
    uint256 public deadlineDuration = 30 minutes;
    
    address public operator;
    
    /// @notice A record of states for signing / validating signatures
    mapping (address => uint256) public nonces;
    
    struct DivCurrency {
        address divCurrency;
        uint256 limit;
    }
    
    DivCurrency[] public divCurrencies;
    

    INsure public Nsure;
    uint256 private _totalSupply;
    uint256 public claimDuration = 30 minutes;

    mapping(address => uint256) private _balances;
    mapping(address => uint256) public claimAt;

   

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

    constructor(address _signer, address _nsure)public {
        Nsure = INsure(_nsure);
        signer = _signer;
    }

    receive() external payable {}
  
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }


  // payout for claiming
    function payouts(address payable _to, uint256 _amount, address token) external onlyOperator {
         require(_to != address(0),"_to is zero");
        if (token != ETHEREUM) {
            IERC20(token).safeTransfer(_to, _amount);
        } else {
            _to.transfer(_amount);
        }

        emit ePayouts(_to, _amount);
    }


    // return my token balance
    function myBalanceOf(address tokenAddress) external view returns(uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }
    
    function setClaimDuration(uint256 _duration)external onlyOwner {
        require(claimDuration != _duration, "the same duration");
        claimDuration = _duration;
        emit SetClaimDuration(_duration);
    }

    function setSigner(address _signer) external onlyOwner {
        require(_signer != address(0),"_signer is zero");
        signer = _signer;
        emit SetSigner(_signer);
    }
 
    function setOperator(address _operator) external onlyOwner {  
        require(_operator != address(0),"_operator is zero"); 
        operator = _operator;
        emit SetOperator(_operator);
    }

    function setDeadlineDuration(uint256 _duration) external onlyOwner {
        deadlineDuration = _duration;
        emit SetDeadlineDuration(_duration);
    }
 
    function getDivCurrencyLength() external view returns (uint256) {
        return divCurrencies.length;
    }

    function addDivCurrency(address _currency,uint256 _limit) external onlyOwner {
        require(_currency != address(0),"_currency is zero");
        divCurrencies.push(DivCurrency({divCurrency:_currency, limit:_limit}));
    }

    function setDepositMax(uint256 _max) external onlyOwner {
        depositMax = _max;
        emit SetDepositMax(_max);
    }

    function deposit(uint256 amount) external nonReentrant{
        require(amount > 0, "Cannot stake 0");
        require(amount <= depositMax,"exceeding the maximum limit");

        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);

        // Nsure.transferFrom(msg.sender, address(this), amount);
        Nsure.transferFrom(msg.sender,address(this),amount);
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 _amount,uint256 deadline,uint8 v, bytes32 r, bytes32 s) 
        external nonReentrant
    {
        require(_balances[msg.sender] >= _amount,"insufficient");

        bytes32 domainSeparator =   keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)),
                                        keccak256(bytes(version)), getChainId(), address(this)));
        bytes32 structHash  = keccak256(abi.encode(WITHDRAW_TYPEHASH, address(msg.sender), 
                                _amount,nonces[msg.sender]++, deadline));
        bytes32 digest      = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        address signatory = ecrecover(digest, v, r, s);

        require(signatory != address(0), "invalid signature");
        require(signatory == signer, "unauthorized");
        require(block.timestamp <= deadline, "signature expired");

        _balances[msg.sender] = _balances[msg.sender].sub(_amount);
        Nsure.transfer(msg.sender,_amount);
        emit Withdraw(msg.sender,_amount,nonces[msg.sender]-1);
    }

    // burn 1/2 for claiming 
    function burnOuts(address[] calldata _burnUsers, uint256[] calldata _amounts) 
        external onlyOperator 
    {
        require(_burnUsers.length == _amounts.length, "not equal");

        for(uint256 i = 0; i<_burnUsers.length; i++) {
            require(_balances[_burnUsers[i]] >= _amounts[i], "insufficient");

            _balances[_burnUsers[i]] = _balances[_burnUsers[i]].sub(_amounts[i]);
            Nsure.burn(_amounts[i]);

            emit Burn(_burnUsers[i],_amounts[i]);
        }
    }

    function claim(uint256 _amount, uint256 currency, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external nonReentrant
    {
        require(block.timestamp > claimAt[msg.sender].add(claimDuration), "wait" );
        require(block.timestamp.add(deadlineDuration) > deadline, "expired");
        require(_amount <= divCurrencies[currency].limit, "exceeding the maximum limit");
        require(block.timestamp <= deadline, "signature expired");

        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)),keccak256(bytes(version)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(CLAIM_TYPEHASH,address(msg.sender), currency, _amount,nonces[msg.sender]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);

        require(signatory != address(0), "invalid signature");
        require(signatory == signer, "unauthorized");
        

        claimAt[msg.sender] = block.timestamp;
        IERC20(divCurrencies[currency].divCurrency).safeTransfer(msg.sender,_amount);

        emit Claim(msg.sender,currency,_amount,nonces[msg.sender] -1);
    }

    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }


   


    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user,  uint256 amount,uint256 nonce);
    event Claim(address indexed user,uint256 currency,uint256 amount,uint256 nonce);
    event Burn(address indexed user,uint256 amount);
    event SetOperator(address indexed operator);
    event SetClaimDuration(uint256 duration);
    event SetSigner(address indexed signer);
    event SetDeadlineDuration(uint256 deadlineDuration);
    event SetDepositMax(uint256 depositMax);
        /////////// events /////////////
    event ePayouts(address indexed to, uint256 amount);
    event eSetOperator(address indexed operator);
}
