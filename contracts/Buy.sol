pragma solidity > 0.6.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IProduct.sol";




pragma solidity ^0.6.0;

contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
    }

    function withdraw(uint256 amount) public {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
    }
}

contract PoolReward is LPTokenWrapper, IRewardDistributionRecipient {
    IERC20 public nsure = IERC20(0x41854abd86ab4b76ec440eb7f4eeeba79e6d499417);
    uint256 public constant DURATION = 7 days;

    uint256 public initreward = 3500*1e18;
    uint256 public starttime = 1598284800; //08/24/2020 @ 4:00pm (UTC)
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 amount) public updateReward(msg.sender)  checkStart{ 
        require(amount > 0, "Cannot stake 0");
        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public updateReward(msg.sender)  checkStart{
        require(amount > 0, "Cannot withdraw 0");
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender)  checkStart{
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            jfi.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }


    modifier checkStart(){
        require(block.timestamp > starttime,"not start");
        _;
    }

    function notifyRewardAmount(uint256 reward)
        external
        onlyRewardDistribution
        updateReward(address(0))
    {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(DURATION);
        }
        jfi.mint(address(this),reward);
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(reward);
    }
}


contract Buy is PoolReward {
    
    IProduct public _product;
      uint public orderIndex          = 1000;
      uint public rate = 500;
      mapping (uint => Order) public insuranceOrders;

    struct Order {
        address payable buyer;

        uint premium;
        uint price;
        uint settleBlockNumber; //

        uint8 totalProviders;
        uint8 state;

    }


      function buyInsuranceWithETH(address _productAddr, uint _amount, uint _blocks) 
            external payable whenNotPaused
    {
   
        Product memory _productInfo = _products.getProduct(_productAddr);
        require(_productInfo.status == 1, "this product is disabled!");

        // Initialize order data

        uint premium    = _calculatePremium(_amount, _blocks, _productInfo.feeRate); //计算保费 ，中心化 
        require(premium == msg.value, "premium and msg.value is not the same");

        Order storage _order = insuranceOrders[orderIndex];
        orderIndex++;
        // require(_order.buyer == address(0), "order id is not empty?!");

        _order.buyer    = _msgSender();
        _order.premium  = premium;
        _order.price    = _amount;
        _order.state    = 0;
        _order.settleBlockNumber = _blocks.add(block.number);

        //update product 
        //todo
        
        //staking pool 
        stake(msg.value.mul(rate));
        

        emit NewOrder(_orderId, _order.buyer, _productAddr, _order.premium, _order.price, _order.settleBlockNumber);
    }


      function buyInsuranceWithStable(address _productAddr, uint _amount, uint _blocks,address _token) 
            external payable whenNotPaused  
    {
   
        Product memory _productInfo = _products.getProduct(_productAddr);
        require(_productInfo.status == 1, "this product is disabled!");

        // Initialize order data

        uint premium    = _calculatePremium(_amount, _blocks, _productInfo.feeRate); //计算保费 ，中心化 
        require(premium == msg.value, "premium and msg.value is not the same");

        Order storage _order = insuranceOrders[orderIndex];
        orderIndex++;
        // require(_order.buyer == address(0), "order id is not empty?!");

        _order.buyer    = _msgSender();
        _order.premium  = premium;
        _order.price    = _amount;
        _order.state    = 0;
        _order.settleBlockNumber = _blocks.add(block.number);

        //update product 
        //todo
        
        //staking pool 
       
        IERC20(_token).safeTransferFrom(msg.sender,address(this),_amount);
        stake(_amount);
        emit NewOrder(_orderId, _order.buyer, _productAddr, _order.premium, _order.price, _order.settleBlockNumber);
    }

   

    
}
