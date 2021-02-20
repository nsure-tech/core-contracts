/**
 * @author  Nsure.Network <contact@nsure.network>
 *
 * @dev     A contract for claiming purchase cover rewards.
 */


import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/INsure.sol";

pragma solidity ^0.6.0;


contract ClaimPurchaseMint is Ownable, ReentrancyGuard{
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    address public signer = 0x666747ffD8417a735dFf70264FDf4e29076c775a; 
    string constant public name = "Claim";
    string public constant version = "1";

    uint256 public nsurePerBlock    = 2 * 1e17;
    
    uint256 public deadlineDuration = 30 minutes;
    
    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;
    

    INsure public Nsure;
    uint256 private _totalSupply;
    uint256 public claimDuration = 60 minutes;
    uint256 lastRewardBlock;

    mapping(address => uint256) private _balances;
    mapping(address => uint256) public claimAt;

   
    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
 
    /// @notice The EIP-712 typehash for the permit struct used by the contract
    bytes32 public constant CLAIM_TYPEHASH = keccak256("Claim(address account,uint256 amount,uint256 nonce,uint256 deadline)");


    constructor(address _nsure, uint256 startBlock) public {
        Nsure = INsure(_nsure);

        lastRewardBlock = block.number > startBlock ? block.number : startBlock;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
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

    function setDeadlineDuration(uint256 _duration) external onlyOwner {
        deadlineDuration = _duration;
        emit SetDeadlineDuration(_duration);
    }

    function updateBlockReward(uint256 _newReward) external onlyOwner {
        nsurePerBlock   = _newReward;
        emit UpdateBlockReward(_newReward);
    }

    function mintPurchaseNsure() internal  {
        if (block.number <= lastRewardBlock) {
            return ;
        }

        uint256 nsureReward = nsurePerBlock.mul(block.number.sub(lastRewardBlock));
        Nsure.mint(address(this), nsureReward);

        lastRewardBlock = block.number;

    }

    // claim rewards of purchase rewards
    function claim(uint _amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external nonReentrant {
        require(block.timestamp > claimAt[msg.sender].add(claimDuration), "wait" );
        require(block.timestamp.add(deadlineDuration) > deadline, "expired");

        require(block.timestamp <= deadline, "signature expired");
        // mint nsure to address(this) first.
        mintPurchaseNsure();

        bytes32 domainSeparator =   keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)),
                                        keccak256(bytes(version)), getChainId(), address(this)));
        bytes32 structHash =        keccak256(abi.encode(CLAIM_TYPEHASH,address(msg.sender), 
                                        _amount,nonces[msg.sender]++, deadline));

        bytes32 digest      = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory   = ecrecover(digest, v, r, s);

        require(signatory != address(0), "invalid signature");
        require(signatory == signer, "unauthorized");
        

        claimAt[msg.sender] = block.timestamp;
      
        Nsure.transfer(msg.sender, _amount);

        emit Claim(msg.sender, _amount);
      

        
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
    
    
     event Claim(address indexed user,uint256 amount);
    event SetClaimDuration(uint256 duration);
    event SetSigner(address indexed signer);
    event SetDeadlineDuration(uint256 duration);
    event UpdateBlockReward(uint256 reward);
 

}
