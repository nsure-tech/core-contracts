import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/ICover.sol";

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

contract Buy is Ownable {
    using SafeMath for uint256;
    address public signer = 0x666747ffD8417a735dFf70264FDf4e29076c775a;
    string public constant name = "Buy";
    string public version = "1";

    address public stakingPool;
    address public surplus;
    ICover public _product ;

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    // IProduct public _product;
    uint256 public orderIndex = 1000;
    uint256 public surplueRate = 10;
    uint256 public stakeRate = 40;
    mapping(uint256 => Order) public insuranceOrders;

    event NewOrder(Order);

    struct Order {
        address payable buyer;
        uint productId;
        uint256 currency;
        uint256 premium;
        uint256 amount;
        uint256 period;
        uint256 createAt;
        uint8 state;
    }

    struct Product {
        uint status;
    }


    constructor(address _stake,address _surplus,address _cover) public {
        stakingPool = _stake;
        surplus = _surplus;
        
        _product = ICover(_cover);
    }

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    /// @notice The EIP-712 typehash for the permit struct used by the contract
    bytes32 public constant BUY_INSURANCE_TYPEHASH =
        keccak256(
            "BuyInsurance(uint256 product,address account,uint256 amount,uint256 cost,uint256 currencyType,uint256 period,uint256 nonce,uint256 deadline)"
    );


    ////////////////// admin ///////////////
    function setStakeAddr(address _addr) external onlyOwner{
        stakingPool = _addr;
    }

    function setSurplusAddr(address _addr) external onlyOwner{
        surplus = _addr;
    }

    function setSurplusRate(uint _rate) external onlyOwner{
        surplueRate = _rate;
    }

    function setStakeRate(uint _rate) external  onlyOwner{
        stakeRate = _rate;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }


    function buyInsuranceWithETH(
        uint _productId,
        uint256 _amount,
        uint256 _cost,
        uint256 period,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 deadline
    ) external payable {
        require(msg.value == _cost,"not eq");
        require(_product.getStatus(_productId) == 0,"disable");

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
                    BUY_INSURANCE_TYPEHASH,
                    _productId,
                    address(msg.sender),
                    _amount,
                    _cost,
                    1,
                    period,
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
        require(block.timestamp <= deadline, "signature expired");

        Order storage _order = insuranceOrders[orderIndex];
        orderIndex++;

        _order.buyer    = _msgSender();
        _order.currency =1;
        _order.productId = _productId;
        _order.premium = _cost;
        _order.amount = _amount;
        _order.createAt = block.timestamp;
        _order.period = period;
        _order.state = 0;


        // //transfer eth to staking Pool and Surplus
        payable(stakingPool).transfer(msg.value.mul(stakeRate).div(100));
        payable(surplus).transfer(msg.value.mul(surplueRate).div(100));

        emit NewOrder(
            _order
        );
    }

    function buyInsuranceWithStable(
        address _productAddr,
        address account,
        uint256 _amount,
        uint256 _cost,
        uint256 period,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 deadline
    ) external {

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
                    BUY_INSURANCE_TYPEHASH,
                    _productAddr,
                    account,
                    _amount,
                    _cost,
                    2,
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
        require(block.timestamp <= deadline, "signature expired");
        require(account == msg.sender, "not yout tx");

        Order storage _order = insuranceOrders[orderIndex];
        orderIndex++;
        // require(_order.buyer == address(0), "order id is not empty?!");

        // _order.buyer    = _msgSender();
        // _order.premium  = premium;
        // _order.price    = _amount;
        // _order.state    = 0;
        // _order.settleBlockNumber = _blocks.add(block.number);

        //update product
        // _product.sub(_productAddr,_amount);

        //staking pool

        // IERC20(_token).safeTransferFrom(msg.sender,address(this),_amount);
        // stake(_amount);
        // emit NewOrder(_orderId, _order.buyer, _productAddr, _order.premium, _order.price, _order.settleBlockNumber);
    }

    function getChainId() public pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}
