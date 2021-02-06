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
import "./interfaces/INsure.sol";


contract CapitalStake is Ownable, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 reward;

        uint256 pendingWithdrawal;  // payments available for withdrawal by an investor
        uint256 pendingAt;
    }

    // Info of each pool.
    struct PoolInfo {
        uint256 amount;             //Total Deposit of Lp token
        IERC20 lpToken;             // Address of LP token contract.
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accNsurePerShare;
    }
 
    INsure public nsure;
    uint256 public nsurePerBlock    = 18 * 1e17;

    uint256 public pendingDuration  = 14 days;


    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    uint256 public startBlock;

    constructor(address _nsure, uint256 _startBlock) public {
        nsure       = INsure(_nsure);
        startBlock  = _startBlock;
    }
    
   
    function updateBlockReward(uint256 _newReward) external onlyOwner {
        nsurePerBlock   = _newReward;
    }

    function updateWithdrawPending(uint256 _seconds) external onlyOwner {
        pendingDuration = _seconds;
    }

    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) onlyOwner public {
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
            accNsurePerShare: 0
        }));
    }

    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }

        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
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


    function deposit(uint256 _pid, uint256 _amount) public whenNotPaused {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);

        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accNsurePerShare).div(1e12).sub(user.rewardDebt);
            safeNsureTransfer(msg.sender,pending);
        }

        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accNsurePerShare).div(1e12);
        
        pool.amount = pool.amount.add(_amount);

        emit Deposit(msg.sender, _pid, _amount);
    }


    // unstake, need pending sometime
    function unstake(uint256 _pid,uint256 _amount) public whenNotPaused {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.amount >= _amount, "unstake: not good");

        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accNsurePerShare).div(1e12).sub(user.rewardDebt);
        safeNsureTransfer(msg.sender, pending);

        user.amount     = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accNsurePerShare).div(1e12);

        user.pendingAt  = block.timestamp;
        user.pendingWithdrawal = user.pendingWithdrawal.add(_amount);

        emit Unstake(msg.sender,_pid,_amount);
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
    function withdraw(uint256 _pid) public whenNotPaused {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(block.timestamp >= user.pendingAt.add(pendingDuration), "still pending");

        uint256 amount          = user.pendingWithdrawal;
        pool.amount             = pool.amount.sub(amount);
        pool.lpToken.safeTransfer(address(msg.sender), amount);

        user.pendingWithdrawal  = 0;
        
        emit Withdraw(msg.sender, _pid, amount);
    }

    //claim reward
    function claim(uint256 _pid) external whenNotPaused {
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
        uint256 nsureBal = nsure.balanceOf(address(this));
        if (_amount > nsureBal) {
            nsure.transfer(_to, nsureBal);
        } else {
            nsure.transfer(_to, _amount);
        }
    }
    

    ////////////  event definitions  ////////////
    event Claim(address indexed user,uint256 pid,uint256 amount);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Unstake(address indexed user,uint256 pid, uint256 amount);

    // event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
}
