import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/ICover.sol";
import "./interfaces/IWETH.sol";


pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

contract Buy is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    address public WETH;
    address public signer = 0x666747ffD8417a735dFf70264FDf4e29076c775a;
    string public constant name = "Buy";
    string public version = "1";

    address public stakingPool;
    address public surplus;
    address public treasury;
    ICover public _product ;

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    uint256 public orderIndex = 1000;
    uint256 public surplueRate = 40;
    uint256 public stakeRate = 50;
    uint256 public treasuryRate = 10;
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

    address[]  public  divCurrencies;


    constructor(address _stake,address _surplus,address _cover,address _weth,address _treasury) public {
        stakingPool = _stake;
        surplus = _surplus;
        WETH = _weth;
        treasury = _treasury;
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

    function setTreasury (address _addr) external onlyOwner {
        treasury = _addr;
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


    function addDivCurrency(address currency) public onlyOwner {
        divCurrencies.push(currency);
    }

    function delDivCurrency(address currency) public onlyOwner {
        for(uint256 i=0;i<divCurrencies.length;i++){
            if(divCurrencies[i]== currency){
                delete divCurrencies[i];
                break;
            }
        }
    }
    

    function getDivCurrencyLength() public view returns (uint256) {
        return divCurrencies.length;
    }


    function buyInsurance(
            uint _productId,
            uint256 _amount,
            uint256 _cost,
            uint256 period,
            uint8 v,
            bytes32 r,
            bytes32 s,
            uint256 deadline,
            uint256 currency
        ) external payable nonReentrant
    {
        require(_product.getStatus(_productId) == 0, "disable");
        require(divCurrencies[currency] != address(0) && currency < divCurrencies.length, "no currency");

        if(divCurrencies[currency] == WETH) {
            //eth =>weth
            require(msg.value == _cost,"not equal");
            IWETH(WETH).deposit{value: msg.value}();
        } else {
            IERC20(divCurrencies[currency]).safeTransferFrom(msg.sender,address(this), _cost);
        }
        
        IERC20(divCurrencies[currency]).safeTransfer(address(stakingPool), _cost.mul(stakeRate).div(100));
        IERC20(divCurrencies[currency]).safeTransfer(address(surplus), _cost.mul(surplueRate).div(100));
        IERC20(divCurrencies[currency]).safeTransfer(address(treasury), _cost.mul(treasuryRate).div(100));
        
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
                    currency,
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
        _order.currency = currency;
        _order.productId= _productId;
        _order.premium  = _cost;
        _order.amount   = _amount;
        _order.createAt = block.timestamp;
        _order.period   = period;
        _order.state    = 0;

        emit NewOrder(
            _order
        );
    }

    function getChainId() public pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}