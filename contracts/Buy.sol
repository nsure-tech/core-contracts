import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/ICover.sol";

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

contract Buy is Ownable {
    using SafeMath for uint256;
    address public signAdmin = 0x666747ffD8417a735dFf70264FDf4e29076c775a;
    string public constant name = "Buy";
    string public version = "1";

    address public stakingPool;
    address public surplus;
    address public token;
    ICover public _product ;
    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    // IProduct public _product;
    uint256 public orderIndex = 1000;
    uint256 public rate = 500;
    mapping(uint256 => Order) public insuranceOrders;

    event NewOrder(
        // address indexed buyer,
        // uint256 currency
        // // address indexed product,
        // // uint256 amount,
        // // uint256 cost,
        // // uint256 period
        // // uint256 createAt
        Order
    );
    struct Order {
        address payable buyer;
        address product;
        uint256 currency;
        uint256 premium;
        uint256 amount;
        uint256 period;
        uint256 createAt;
        uint8 state;
    }

constructor(address _stake,address _surplus,address _cover)public {
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
            "BuyInsurance(address product,address account,uint256 amount,uint256 cost,uint256 currencyType,uint256 period,uint256 nonce,uint256 deadline)"
        );

    function setStakeAddr(address _addr) external {
        stakingPool = _addr;
    }

    function setSurplusAddr(address _addr) external {
        surplus = _addr;
    }

    function buyInsuranceWithETH(
        address _productAddr,
        uint256 _amount,
        uint256 _cost,
        uint256 period,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 deadline
    ) external payable {
        ICover.Product memory _productInfo = _product.getProduct(_productAddr);
        require(_productInfo.status == 1, "this product is disabled!");
        require(_product.getAvailale() >= _amount,"not enough");

        // Initialize order data

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
                    address(_productAddr),
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
        require(signatory == signAdmin, "unauthorized");
        require(block.timestamp <= deadline, "signature expired");

        Order storage _order = insuranceOrders[orderIndex];
        orderIndex++;
        // require(_order.buyer == address(0), "order id is not empty?!");

        _order.buyer    = _msgSender();
        _order.currency =1;
        _order.product = _productAddr;
        _order.premium = _cost;
        _order.amount = _amount;
        _order.createAt = block.timestamp;
        _order.period = period;
        _order.state = 0;

        //update product
        _product.subAvailable(_amount);

        //transfer eth to staking Pool and Surplus
        payable(stakingPool).transfer(msg.value.mul(40).div(100));
        payable(surplus).transfer(msg.value.mul(10).div(100));

        emit NewOrder(
            _order
            // msg.sender,
            // 1
            // _productAddr,
            // _amount,
            // _cost,
            // period
            // block.timestamp
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
        // Product memory _productInfo = _products.getProduct(_productAddr);
        // require(_productInfo.status == 1, "this product is disabled!");

        // Initialize order data

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
        require(signatory == signAdmin, "unauthorized");
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
