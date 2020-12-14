import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";
import "./interfaces/IMerkleDistributor.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
pragma solidity >=0.6.0;

contract Buy is Ownable {
    address public signAdmin = 0x666747ffD8417a735dFf70264FDf4e29076c775a; 
    string constant public name = "Buy";
    string public version = "1";

    address public stakingPool = 0x666747ffD8417a735dFf70264FDf4e29076c775a;
    address public surplus = 0x666747ffD8417a735dFf70264FDf4e29076c775a;
    address public override  token = 0x666747ffD8417a735dFf70264FDf4e29076c775a;
    bytes32 public merkleRoot;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

        /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    // IProduct public _product;
    uint public orderIndex          = 1000;
    uint public rate                = 500;
    mapping (uint => Order) public insuranceOrders;

event NewOrder(address indexed buyer,uint currency,address indexed product,uint amount,uint cost,uint period,uint createAt);
    struct Order {
        address payable buyer;

        uint premium;
        uint amount;
        uint period;
        uint createAt;
        uint8 state;

    }

      /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

 
    /// @notice The EIP-712 typehash for the permit struct used by the contract
    bytes32 public constant BUY_INSURANCE_TYPEHASH = keccak256("BuyInsurance(address product,address account,uint256 amount,uint256 cost,uint256 currencyType,uint256 period,uint256 nonce,uint256 deadline)");



      function buyInsuranceWithETH(address _productAddr, uint _amount,uint _cost,uint period, uint8 v, bytes32 r, bytes32 s,uint deadline) 
            external payable 
    {
   
        // Product memory _productInfo = _products.getProduct(_productAddr);
        // require(_productInfo.status == 1, "this product is disabled!");

        // Initialize order data

        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)),keccak256(bytes(version)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(BUY_INSURANCE_TYPEHASH, address(_productAddr),address(msg.sender), _amount, _cost,1,period, nonces[msg.sender]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "invalid signature");
        require(signatory == signAdmin, "unauthorized");
        require(block.timestamp <= deadline, "signature expired");

        Order storage _order = insuranceOrders[orderIndex];
        orderIndex++;
        // require(_order.buyer == address(0), "order id is not empty?!");

        // _order.buyer    = _msgSender();
        _order.premium  = _cost;
        _order.amount    = _amount;
        _order.createAt = block.timestamp;
        _order.period = period;
        _order.state    = 0;

        //update product 
        // _product.sub(_productAddr,amount)
        
        //transfer eth to staking Pool and Surplus
        stakingPool.transfer(msg.value.mul(40).div(100));
        surplus.transfer(msg.value.mul(10).div(100));
        
        emit NewOrder(msg.sender,1,_productAddr,_amount,_cost,period,block.timestamp);
    }


      function buyInsuranceWithStable(address _productAddr,address account,uint _amount,uint _cost,uint period, uint8 v, bytes32 r, bytes32 s,uint deadline) 
            external payable   
    {
   
        // Product memory _productInfo = _products.getProduct(_productAddr);
        // require(_productInfo.status == 1, "this product is disabled!");

        // Initialize order data

        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)),keccak256(bytes(version)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(BUY_INSURANCE_TYPEHASH, _productAddr,account, _amount, _cost,2, nonces[msg.sender]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "invalid signature");
        require(signatory == signAdmin, "unauthorized");
        require(block.timestamp <= deadline, "signature expired");
        require(account == msg.sender,"not yout tx");

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


    
    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
    }

    function isClaimed(uint256 index) public view override returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external override {
        require(!isClaimed(index), 'MerkleDistributor: Drop already claimed.');

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MerkleDistributor: Invalid proof.');

        // Mark it claimed and send the token.
        _setClaimed(index);
        require(IERC20(token).transfer(account, amount), 'MerkleDistributor: Transfer failed.');

        emit Claimed(index, account, amount);
    }


    function getChainId() public pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
   

    
}
