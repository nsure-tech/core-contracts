
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./library/Roles.sol";
import "./interfaces/ICover.sol";

interface Nsure is IERC20 {
   function mint(address _to, uint256 _amount) external  returns (bool);
}

contract CapitalStake {
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

    ICover public cover;
 
    Nsure public nsure;
    uint256 public nsurePerBlock;

    uint256 public mcr = 300; //percent 
    uint256 public pendingDuration = 10 minutes;
    //total weigth of each pool
    mapping(uint => uint) public totalWeight;
    //user's weight of each pool
    mapping(uint => mapping(address => uint)) public userWeight;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    uint256 public startBlock;

    address public devaddr = 0x666747ffD8417a735dFf70264FDf4e29076c775a;
   

    constructor(address _nsure,address _cover) public {
        nsure =Nsure(_nsure);
        nsurePerBlock = 10;
        startBlock = block.number;
        cover = ICover(_cover);
    }
    
    //add or sub weight
    function setWeight(uint _pid,address _account,uint256 _weight , bool _add )    external {
        if(_add){
            totalWeight[_pid] = totalWeight[_pid].add(_weight);
            userWeight[_pid][_account] =  userWeight[_pid][_account].add(_weight);
        }else {
            require(userWeight[_pid][_account] >= _weight , "insufficient");
            totalWeight[_pid] = totalWeight[_pid].sub(_weight);
            userWeight[_pid][_account] =  userWeight[_pid][_account].sub(_weight);
        }
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public {
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

    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public  {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }



    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        // if (_to <= bonusEndBlock) {
        //     return _to.sub(_from).mul(BONUS_MULTIPLIER);
        // } else if (_from >= bonusEndBlock) {
        //     return _to.sub(_from);
        // } else {
        //     return bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
        //         _to.sub(bonusEndBlock)
        //     );
        // }
        return _to.sub(_from);
    }

    function pendingNsure(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accNsurePerShare = pool.accNsurePerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this)).add(totalWeight[_pid]);
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 nsureReward = multiplier.mul(nsurePerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accNsurePerShare = accNsurePerShare.add(nsureReward.mul(1e12).div(lpSupply));
        }
        uint weight = userWeight[_pid][_user];
        return user.amount.add(weight).mul(accNsurePerShare).div(1e12).sub(user.rewardDebt).add(user.reward);
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
        uint256 lpSupply = pool.lpToken.balanceOf(address(this)).add(totalWeight[_pid]);
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 nsureReward = multiplier.mul(nsurePerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        nsure.mint(devaddr, nsureReward.div(10));
        nsure.mint(address(this), nsureReward);
        pool.accNsurePerShare = pool.accNsurePerShare.add(nsureReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount.add(userWeight[_pid][msg.sender]) > 0) {
            user.reward = user.amount.add(userWeight[_pid][msg.sender]).mul(pool.accNsurePerShare).div(1e12).sub(user.rewardDebt).add(user.reward);
        }
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.add(userWeight[_pid][msg.sender]).mul(pool.accNsurePerShare).div(1e12);
        pool.amount = pool.amount.add(_amount);

        cover.addAvailable(_amount.mul(mcr).div(100));
        emit Deposit(msg.sender, _pid, _amount);
    }

    //pending
    function unstake(uint256 _pid,uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount.sub(user.pendingWithdrawal) >= _amount, "withdraw: not good");
        user.pendingWithdrawal = user.pendingWithdrawal.add(_amount);
        user.pendingAt = block.timestamp;
        emit Unstake(msg.sender,_pid,_amount);
    }
    
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.pendingWithdrawal >= _amount, "withdraw: not good");
        require(block.timestamp >= user.pendingAt.add(pendingDuration) ,"pending");
        updatePool(_pid);
        user.reward = user.amount.add(userWeight[_pid][msg.sender]).mul(pool.accNsurePerShare).div(1e12).sub(user.rewardDebt).add(user.reward);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.add(userWeight[_pid][msg.sender]).mul(pool.accNsurePerShare).div(1e12);
        user.pendingWithdrawal = user.pendingWithdrawal.sub(_amount);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        pool.amount = pool.amount.sub(_amount);
        cover.subAvailable(_amount.mul(mcr).div(100));
        emit Withdraw(msg.sender, _pid, _amount);
    }

    //claim reward
    function claim(uint256 _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        uint reward =  user.amount.add(userWeight[_pid][msg.sender]).mul(pool.accNsurePerShare).div(1e12).sub(user.rewardDebt).add(user.reward);
        user.rewardDebt = user.amount.add(userWeight[_pid][msg.sender]).mul(pool.accNsurePerShare).div(1e12);
        user.reward = 0;
        safeNsureTransfer(msg.sender, reward); 
        emit Claim(msg.sender,_pid,reward);
    }

    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        user.reward = 0;
        if(userWeight[_pid][msg.sender] >0){
            totalWeight[_pid] = totalWeight[_pid].sub(userWeight[_pid][msg.sender]);
            userWeight[_pid][msg.sender] = 0;
        }
    }

    function safeNsureTransfer(address _to, uint256 _amount) internal {
        uint256 nsureBal = nsure.balanceOf(address(this));
        if (_amount > nsureBal) {
            nsure.transfer(_to, nsureBal);
        } else {
            nsure.transfer(_to, _amount);
        }
    }
    
    event Claim(address indexed user,uint256 pid,uint256 amount);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Unstake(address indexed user,uint256 pid, uint256 amount);
 
}
