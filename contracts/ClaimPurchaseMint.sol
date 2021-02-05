
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


contract ClaimPurchaseMint is Ownable {
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    address public signer = 0x666747ffD8417a735dFf70264FDf4e29076c775a; 
    string constant public name = "Claim";
    string public version = "1";
    
    uint256 public deadlineDuration = 30 minutes;
    
    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;
    

    INsure public Nsure;
    uint256 private _totalSupply;
    uint256 public claimDuration = 1 minutes;

    mapping(address => uint256) private _balances;
    mapping(address => uint256) public claimAt;


    event Claim(address indexed user,uint256 amount);
   
 

      /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

 
    /// @notice The EIP-712 typehash for the permit struct used by the contract
    bytes32 public constant CLAIM_TYPEHASH = keccak256("Claim(address account,uint256 amount,uint256 nonce,uint256 deadline)");



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

 function setDeadlineDuration(uint256 _duration) external onlyOwner {
     deadlineDuration = _duration;
 }

  



    function claim(uint _amount,uint deadline,uint8 v, bytes32 r, bytes32 s) external {
        require(block.timestamp > claimAt[msg.sender].add(claimDuration),"wait" );
        require(block.timestamp.add(deadlineDuration) > deadline,"expired");
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)),keccak256(bytes(version)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(CLAIM_TYPEHASH,address(msg.sender), _amount,nonces[msg.sender]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);

        require(signatory != address(0), "invalid signature");
        require(signatory == signer, "unauthorized");
        require(block.timestamp <= deadline, "signature expired");

        claimAt[msg.sender] = block.timestamp;
        Nsure.transfer(msg.sender,_amount);

        emit Claim(msg.sender,_amount);
    }



    function getChainId() public pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

 

   
}
