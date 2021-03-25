/**
 * @dev Capital mining contract. Need stake here to earn rewards after converting to nTokens.
 */

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/INsure.sol";




contract CapitalStake is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public signer;
    string public constant name = "CapitalStake";
    string public constant version = "1";
    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many  tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 reward;

        uint256 pendingWithdrawal;  // payments available for withdrawal by an investor
        uint256 pendingAt;
    }

    // Info of each pool.
    struct PoolInfo {
        uint256 amount;             //Total Deposit of token
        IERC20 lpToken;             // Address of token contract.
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accNsurePerShare;
        uint256 pending;
    }
 
    INsure public nsure;
    uint256 public nsurePerBlock    = 18 * 1e17;

    uint256 public pendingDuration  = 14 days;

    bool public canDeposit = true;
    address public operator;

    // the max capacity for one user's deposit.
    mapping(uint256 => uint256) public userCapacityMax;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    uint256 public startBlock;


     /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    /// @notice The EIP-712 typehash for the permit struct used by the contract
    bytes32 public constant Capital_Unstake_TYPEHASH =
        keccak256(
            "CapitalUnstake(uint256 pid,address account,uint256 amount,uint256 nonce,uint256 deadline)"
    );

    bytes32 public constant Capital_Deposit_TYPEHASH =
        keccak256(
            "Deposit(uint256 pid,address account,uint256 amount,uint256 nonce,uint256 deadline)"
    );



    constructor(address _signer, address _nsure, uint256 _startBlock) public {
        nsure       = INsure(_nsure);
        startBlock  = _startBlock;
        userCapacityMax[0] = 10e18;
        signer = _signer;
    }
    
      function setOperator(address _operator) external onlyOwner {   
        require(_operator != address(0),"_operator is zero");
        operator = _operator;
        emit eSetOperator(_operator);
    }

    modifier onlyOperator() {
        require(msg.sender == operator,"not operator");
        _;
    }

    function switchDeposit() external onlyOperator {
        canDeposit = !canDeposit;
        emit SwitchDeposit(canDeposit);
    }

    function setUserCapacityMax(uint256 _pid,uint256 _max) external onlyOperator {
        userCapacityMax[_pid] = _max;
        emit SetUserCapacityMax(_pid,_max);
    }
   
   
    function updateBlockReward(uint256 _newReward) external onlyOwner {
        nsurePerBlock   = _newReward;
        emit UpdateBlockReward(_newReward);
    }

    function updateWithdrawPending(uint256 _seconds) external onlyOwner {
        pendingDuration = _seconds;
        emit UpdateWithdrawPending(_seconds);
    }

    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) onlyOwner external {
        require(address(_lpToken) != address(0),"_lpToken is zero");
        for(uint256 i=0; i<poolLength(); i++) {
            require(address(_lpToken) != address(poolInfo[i].lpToken), "Duplicate Token!");
        }

        if (_withUpdate) {
            massUpdatePools();
        }

        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            amount:0,
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accNsurePerShare: 0,
            pending: 0
        }));

        emit Add(_allocPoint,_lpToken,_withUpdate);
    }

    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate)  onlyOwner external {
        require(_pid < poolInfo.length , "invalid _pid");
        if (_withUpdate) {
            massUpdatePools();
        }

        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        emit Set(_pid,_allocPoint,_withUpdate);
    }

    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from);
    }

    function pendingNsure(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        uint256 accNsurePerShare = pool.accNsurePerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 nsureReward = multiplier.mul(nsurePerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accNsurePerShare = accNsurePerShare.add(nsureReward.mul(1e12).div(lpSupply));
        }

        return user.amount.mul(accNsurePerShare).div(1e12).sub(user.rewardDebt);
    }


    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public {
        require(_pid < poolInfo.length, "invalid _pid");
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 nsureReward = multiplier.mul(nsurePerBlock).mul(pool.allocPoint).div(totalAllocPoint);

        bool mintRet = nsure.mint(address(this), nsureReward);
        if(mintRet) {
            pool.accNsurePerShare = pool.accNsurePerShare.add(nsureReward.mul(1e12).div(lpSupply));
            pool.lastRewardBlock = block.number;
        }
    }


    function deposit(uint256 _pid, uint256 _amount) external whenNotPaused {
        require(canDeposit, "can not");
        require(_pid < poolInfo.length, "invalid _pid");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount.add(_amount) <= userCapacityMax[_pid],"exceed the limit");
        updatePool(_pid);

      
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);

        uint256 pending = user.amount.mul(pool.accNsurePerShare).div(1e12).sub(user.rewardDebt);
        
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accNsurePerShare).div(1e12);
        
        pool.amount = pool.amount.add(_amount);

        if(pending > 0){
            safeNsureTransfer(msg.sender,pending);
        }

        emit Deposit(msg.sender, _pid, _amount);
    }


    // unstake, need pending sometime
    function unstake(
            uint256 _pid,
            uint256 _amount,
            uint8 v,
            bytes32 r,
            bytes32 s,
            uint256 deadline) external nonReentrant whenNotPaused {

   
        bytes32 domainSeparator =
            keccak256(
                abi.encode(
                    DOMAIN_TYPEHASH,
                    keccak256(bytes(name)),
                    keccak256(bytes(version)),
                    getChainId(),
                    address(this)
                )
            );
        bytes32 structHash =
            keccak256(
                abi.encode(
                    Capital_Unstake_TYPEHASH,
                    _pid,
                    address(msg.sender),
                    _amount,
                    nonces[msg.sender]++,
                    deadline
                )
            );
        bytes32 digest =
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, structHash)
            );
            
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "invalid signature");
        require(signatory == signer, "unauthorized");
        

        require(_pid < poolInfo.length , "invalid _pid");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.amount >= _amount, "unstake: insufficient assets");

        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accNsurePerShare).div(1e12).sub(user.rewardDebt);
       
        user.amount     = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accNsurePerShare).div(1e12);

        user.pendingAt  = block.timestamp;
        user.pendingWithdrawal = user.pendingWithdrawal.add(_amount);

        pool.pending = pool.pending.add(_amount);

        safeNsureTransfer(msg.sender, pending);

        emit Unstake(msg.sender,_pid,_amount,nonces[msg.sender]-1);
    }


      // unstake, need pending sometime
      // won't use this function, for we don't use it now.
    function deposit(
            uint256 _pid,
            uint256 _amount,
            uint8 v,
            bytes32 r,
            bytes32 s,
            uint256 deadline) external nonReentrant whenNotPaused {

   
        bytes32 domainSeparator =
            keccak256(
                abi.encode(
                    DOMAIN_TYPEHASH,
                    keccak256(bytes(name)),
                    keccak256(bytes(version)),
                    getChainId(),
                    address(this)
                )
            );
        bytes32 structHash =
            keccak256(
                abi.encode(
                    Capital_Deposit_TYPEHASH,
                    _pid,
                    address(msg.sender),
                    _amount,
                    nonces[msg.sender]++,
                    deadline
                )
            );
        bytes32 digest =
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, structHash)
            );
            
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "invalid signature");
        require(signatory == signer, "unauthorized");
        

        require(_pid < poolInfo.length , "invalid _pid");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount.add(_amount) <= userCapacityMax[_pid],"exceed the limit");

           updatePool(_pid);

      
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);

        uint256 pending = user.amount.mul(pool.accNsurePerShare).div(1e12).sub(user.rewardDebt);
        
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accNsurePerShare).div(1e12);
        
        pool.amount = pool.amount.add(_amount);

        if(pending > 0){
            safeNsureTransfer(msg.sender,pending);
        }

        emit DepositSign(msg.sender, _pid, _amount,nonces[msg.sender] - 1);
    }




    function isPending(uint256 _pid) external view returns (bool,uint256) {
        UserInfo storage user = userInfo[_pid][msg.sender];
        if(block.timestamp >= user.pendingAt.add(pendingDuration)) {
            return (false,0);
        }

        return (true,user.pendingAt.add(pendingDuration).sub(block.timestamp));
    }
    
    // when it's pending while a claim occurs, the value of the withdrawal will decrease as usual
    // so we keep the claim function by this tool.
    function withdraw(uint256 _pid) external nonReentrant whenNotPaused {
        require(_pid < poolInfo.length , "invalid _pid");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(block.timestamp >= user.pendingAt.add(pendingDuration), "still pending");

        uint256 amount          = user.pendingWithdrawal;
        pool.amount             = pool.amount.sub(amount);
        pool.pending            = pool.pending.sub(amount);

        user.pendingWithdrawal  = 0;

        pool.lpToken.safeTransfer(address(msg.sender), amount);

     
        
        emit Withdraw(msg.sender, _pid, amount);
    }

    //claim reward
    function claim(uint256 _pid) external nonReentrant whenNotPaused {
        require(_pid < poolInfo.length , "invalid _pid");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        updatePool(_pid);

        uint256 pending = user.amount.mul(pool.accNsurePerShare).div(1e12).sub(user.rewardDebt);
        safeNsureTransfer(msg.sender, pending);

        user.rewardDebt = user.amount.mul(pool.accNsurePerShare).div(1e12);

        emit Claim(msg.sender, _pid, pending);
    }

    // we don't support this function due to the claim process..
    // or guys will step over the claim events via this function. 
    // function emergencyWithdraw(uint256 _pid) public {
    //     PoolInfo storage pool = poolInfo[_pid];
    //     UserInfo storage user = userInfo[_pid][msg.sender];
    //     pool.lpToken.safeTransfer(address(msg.sender), user.amount);

    //     emit EmergencyWithdraw(msg.sender, _pid, user.amount);

    //     user.amount = 0;
    //     user.rewardDebt = 0;
    // }

    function safeNsureTransfer(address _to, uint256 _amount) internal {
        require(_to != address(0),"_to is zero");
        uint256 nsureBal = nsure.balanceOf(address(this));
        if (_amount > nsureBal) {
            // nsure.transfer(_to, nsureBal);
            nsure.transfer(_to,nsureBal);
        } else {
            // nsure.transfer(_to, _amount);
            nsure.transfer(_to,_amount);
        }
    }
    
     function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
    

    ////////////  event definitions  ////////////
    event Claim(address indexed user,uint256 pid,uint256 amount);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event DepositSign(address indexed user, uint256 indexed pid, uint256 amount, uint256 nonce);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Unstake(address indexed user,uint256 pid, uint256 amount,uint256 nonce);
    event UpdateBlockReward(uint256 reward);
    event UpdateWithdrawPending(uint256 duration);
    event Add(uint256 point, IERC20 token, bool update);
    event Set(uint256 pid, uint256 point, bool update);
    event SwitchDeposit(bool swi);
    event SetUserCapacityMax(uint256 pid,uint256 max);
    event eSetOperator(address indexed operator);
    // event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
}
