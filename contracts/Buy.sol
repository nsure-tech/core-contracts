import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/ICover.sol";
import "./interfaces/IWETH.sol";


pragma solidity >=0.6.0;

contract Buy is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    address public WETH;
    address public signer = 0x666747ffD8417a735dFf70264FDf4e29076c775a;
    string public constant name = "Buy";
    string public constant version = "1";

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

    struct ProductStatus {
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
        require(_addr != address(0),"_addr is zero");
        stakingPool = _addr;
        emit SetStakeAddr(_addr);
    }

    function setSurplusAddr(address _addr) external onlyOwner{
        require(_addr != address(0),"_addr is zero");
        surplus = _addr;
        emit SetSurplusAddr(_addr);
    }

    function setTreasury (address _addr) external onlyOwner {
        require(_addr != address(0),"_addr is zero");
        treasury = _addr;
        emit SetTreasury(_addr);
    }
    
    function setSurplusRate(uint _rate) external onlyOwner{
        surplueRate = _rate;
        emit SetSurplusRate(_rate);
    }

    function setStakeRate(uint _rate) external  onlyOwner{
        stakeRate = _rate;
        emit SetStakeRate(_rate);
    }

    function setSigner(address _signer) external onlyOwner {
        require(_signer != address(0),"_signer is zero");
        signer = _signer;
        emit SetSigner(_signer);
    }


    function addDivCurrency(address currency) external onlyOwner {
        require(currency != address(0),"currency is zero");
        divCurrencies.push(currency);
        emit AddDivCurrency(currency);
    }

    function delDivCurrency(address currency) external onlyOwner {
        require(currency != address(0),"currency is zero");
        for(uint256 i=0;i<divCurrencies.length;i++){
            if(divCurrencies[i]== currency){
                delete divCurrencies[i];
                emit DeleteDivCurrency(currency);
                break;
            }
        }
    }
    

    function getDivCurrencyLength() external view returns (uint256) {
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
        require(_product.getStatus(_productId) == 1, "this insurance is not currently available for purchase");
        require(divCurrencies[currency] != address(0) && currency < divCurrencies.length, "this asset type is not supported");
        require(block.timestamp <= deadline, "signature expired");
      
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

    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
    
    
    event NewOrder(Order);
    event SetStakeAddr(address indexed stake);
    event SetSurplusAddr(address indexed surplus);
    event SetTreasury(address indexed treasury);
    event SetSurplusRate(uint256 rate);
    event SetStakeRate(uint256 rate);
    event SetSigner(address indexed signer);
    event AddDivCurrency(address indexed currency);
    event DeleteDivCurrency(address indexed currency);
    
}
