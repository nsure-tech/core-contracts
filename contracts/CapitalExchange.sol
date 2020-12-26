
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/GSN/Context.sol";


contract CapitalExchange is ERC20("nETH","nETH"), Ownable {
    using SafeMath  for uint;
    receive() external payable  {
        convert();
    }
    
    function ratio(uint _value) internal view returns (uint) {
        if(totalSupply() == 0){
          return 1;
        }
        return  totalSupply().div(address(this).balance.sub(_value));
    }
    

    function convert() public payable    { 
        require(msg.value > 0, "Cannot stake 0");
        uint value = msg.value.mul(ratio(msg.value));
        _mint(msg.sender,value);
        emit Mint(msg.sender, value);
    }

function exit(uint _value) external {
   require(balanceOf(msg.sender) >= _value && _value > 0, "not good");
   uint value = _value.mul(address(this).balance).div(totalSupply());
   _burn(msg.sender,_value);
    msg.sender.transfer(value);
   emit Burn(msg.sender, _value);
}


    event Mint(address indexed sender, uint amount);
    event Burn(address indexed sender, uint amount);
   
}