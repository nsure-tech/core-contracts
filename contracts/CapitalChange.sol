
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/GSN/Context.sol";


contract CapitalChange is ERC20("token","tok"), Ownable {
    using SafeMath  for uint;
 
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));


    receive() external payable  {
        stake();
    }
    
    function calc(uint _value) internal view returns (uint) {
        if(totalSupply() == 0){
          return _value;
        }
        return totalSupply().mul(_value).div(address(this).balance);
    }
    
    function stake() public payable    { 
        require(msg.value > 0, "Cannot stake 0");
        uint value = calc(msg.value);
       _mint(msg.sender,value);
        emit Mint(msg.sender, value);
    }

function withdraw(uint _value) external {
   require(balanceOf(msg.sender) >= _value && _value > 0, "not good");
   uint value = address(this).balance.mul(_value).div(totalSupply());
   _burn(msg.sender,value);
    msg.sender.transfer(value);
   emit Burn(msg.sender, _value);
}


function claim(uint _value) external onlyOwner {
    require(address(this).balance > _value, "");
    msg.sender.transfer(_value);
}
 

    event Mint(address indexed sender, uint amount);
    event Burn(address indexed sender, uint amount);
   
}