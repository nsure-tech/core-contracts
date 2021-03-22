const Buy = artifacts.require("Buy"); //7
const Underwriting = artifacts.require("Underwriting"); //6
const CapitalStake = artifacts.require("CapitalStake"); //5
const CapitalConvert = artifacts.require("CapitalConverter"); //4
const Nsure = artifacts.require("Nsure"); //3
const USDT = artifacts.require('USDT')
const Surplus = artifacts.require("Surplus"); //2
const Treasury = artifacts.require('Treasury')
const Product = artifacts.require("Product"); //1
const ClaimPurchaseMint = artifacts.require('ClaimPurchaseMint'); //0



//weth 0x19eA6711FBB2BD8302C2ae612eA6718abdada893


//new begin

module.exports = async function (deployer,network,accounts){ //nsure
let nsureAddr = '0xEf729dA236Fa560319b9AcEf939c081fEc41c12C'
let usdtAddr = '0x328f0Cb880d68ffB00ad2991f05C69C875d776d2'
let surplus= '0xbc76A570BD1f6E5E8b58951384d9823803495A6a'
let product = '0x0786a7a36515306B9F58f63e935bc4dfD9eEDB1c'
let ETH = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE'
let weth = '0x19eA6711FBB2BD8302C2ae612eA6718abdada893'
let treasury = '0x07EB6Dfd628375F757CeD7f68Ed8D6AA27B16568'
let capitalConvertEth = '0x7dd34494dBC14c3Cb383dAA97b7146E138B1CD6B'
let capitalConvertUsdt = '0x99e6f45d01BcdD92E031a2D5B9D691EE200D11a7'
// let capitalStake = '0xd2150f45b8cd01A1b0bAcA765228C700F7861487'
let underwriting = '0xaA138c9e8769A687C3Bd4E476899A64C1dCe0d72'
let buy = '0x6923880701Bb2B4Ae89d747d2C3ca3fA3c75Ae34'
let claimPurchaseMint='0x449dB430715F6193e8DE990F93313619D3411AbE'

// await deployer.deploy(ClaimPurchaseMint,'0xEf729dA236Fa560319b9AcEf939c081fEc41c12C',10000000)
// console.log(ClaimPurchaseMint.address);

// await deployer.deploy(Product);
// console.log(Product.address);
// await  deployer.deploy(Surplus);
// console.log(Surplus.address);

// await deployer.deploy(USDT)

// await deployer.deploy(Nsure);
// console.log(Nsure.address);

// await deployer.deploy(Treasury)
// console.log(Treasury.address)

//address _token, uint256 _tokenDecimal,string memory name,string memory symbol
// await deployer.deploy(CapitalConvert,ETH,18,'nETH','nETH');
// console.log('capitalConvert neth:',CapitalConvert.address);

//address _token, uint256 _tokenDecimal,string memory name,string memory symbol
// await deployer.deploy(CapitalConvert,usdtAddr,18,'nUSDT','nUSDT');
// console.log('capitalConvert nUSDT:',CapitalConvert.address);

//nsure,stakeBlock
 await deployer.deploy(CapitalStake,nsureAddr,23897742);


//nsure
// await  deployer.deploy(Underwriting,nsureAddr);

//address _underwriting,address _surplus,address _product,address _weth,address _treasury
// await deployer.deploy(Buy,underwriting,surplus,product,weth,treasury);


}

