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



module.exports = async function (deployer,network,accounts){ //nsure
let ETH = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE'
let nsureAddr = '0x6CF83F10234ac1DB01Baed7E45c52A59C9c66A3b'   //'0x6CF83F10234ac1DB01Baed7E45c52A59C9c66A3b' offical nusre
let claimPurchaseMintAddr='0xac27a005ac0fA7e46b0ccfE62eE4265Fc37d00FD'
let productAddr = '0x7379d11C66A5D43b79692D83005D1e4f43EAc223'
let treasuryAddr = '0x943A434E32C6aB499e3E7B15451E7acC90930a6b'
let surplusAddr= '0x815776F301Ee527c3BAA1b3b712aD9f8a207bab0'
let usdtAddr = '0x328f0Cb880d68ffB00ad2991f05C69C875d776d2'
let wethAddr = '0x19eA6711FBB2BD8302C2ae612eA6718abdada893'
let capitalConvertEthAddr = '0x75425606a336Ef15abEcdb18fa4E8465fA097655'
let capitalStakeAddr = '0x55696e6b3fDf74bc56F0935c6eC8e199bF047519'
let underwritingAddr = '0xfE01adB1bA0D3C120Ff92868d59aACa877134779'
let buyAddr = '0xc603b1200b1Da337CA11c357af8F6193fb40bA7E'

// let capitalConvertUsdt = '0x99e6f45d01BcdD92E031a2D5B9D691EE200D11a7'







//nsure startBlock
// await deployer.deploy(ClaimPurchaseMint,nsureTestOffical,10000000)
// console.log('ClaimPurchaseMint:',ClaimPurchaseMint.address);

// await deployer.deploy(Product);
// console.log('product:',Product.address);


//nsure
// await deployer.deploy(Treasury,nsureAddr)
// console.log('treasury addr:',Treasury.address)


// await  deployer.deploy(Surplus);
// console.log('surplus:',Surplus.address);

// await deployer.deploy(USDT)

// await deployer.deploy(Nsure);
// console.log(Nsure.address);


/////address _token, uint256 _tokenDecimal,string memory name,string memory symbol
// await deployer.deploy(CapitalConvert,ETH,18,'nETH','nETH');
// console.log('capitalConvert neth:',CapitalConvert.address);

//address _token, uint256 _tokenDecimal,string memory name,string memory symbol
// await deployer.deploy(CapitalConvert,usdtAddr,18,'nUSDT','nUSDT');
// console.log('capitalConvert nUSDT:',CapitalConvert.address);

////nsure,stakeBlock
//  await deployer.deploy(CapitalStake,nsureAddr,23897742);


//nsure
// await  deployer.deploy(Underwriting,nsureAddr);

//////address _underwriting,address _surplus,address _product,address _weth,address _treasury
await deployer.deploy(Buy,underwriting,surplus,product,weth,treasury);


}

