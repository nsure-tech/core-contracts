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

module.exports = async function (deployer) {
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
  
  let operater = '0x666747ffD8417a735dFf70264FDf4e29076c775a'

  // let nsure =await Nsure.at(nsureAddr)
  // let usdt = await USDT.at(usdtAddr)
  // let surplus = await Surplus.at(surplusAddr)
  // let treasury = await Treasury.at(treasuryAddr)
  // let capitalConvertEth = await CapitalConvert.at(capitalConvertEthAddr)
  // let capitalConvertUsdt = await CapitalConvert.at(capitalConvertUsdtAddr)
  // let product = await Product.at(productAddr)
  let capitalStake = await CapitalStake.at(capitalStakeAddr)
  let underwritng = await Underwriting.at(underwritingAddr)
  let buy = await Buy.at(buyAddr)


  //
 
  //product
  // let operatorRet = await product.operator()
  // console.log('operator ret:',operatorRet);
  
//   if(operatorRet !== operater){
//     console.log('set operator');
    
    // await product.setOperator(operater)
//   }
// let lenProduct = await product.getLength()
// console.log('product len:',lenProduct.toNumber());

  // for(let i=1;i<=10;i++){
  //   await product.addProduct(i,1)
  //   console.log('product add:',i);
    
  // }

  //capitalStake
  // await capitalStake.add(100,capitalConvertEthAddr ,true)
  // console.log('capital stake eth add ok');
  
  // await capitalStake.add(100,capitalConvertUsdtAddr,true)
  // console.log('capital stake usdt add ok');
  

  //underwriting
  // await underwritng.setOperator(operater)
  // await underwritng.addDivCurrency(wethAddr,'100000000000000000000')
  // console.log('lockfund add weth');
  
  // await underwritng.addDivCurrency(usdtAddr,'100000000000000000000')
  // console.log('lockfund add usdt');
  

  //buy
  await buy.addDivCurrency(wethAddr) 
  console.log('buy add weth');
  
  // await buy.addDivCurrency(usdtAddr) 
  // console.log('buy add usdt');
  

  //nsure add minter
  // await nsure.addMinter(capitalConvertEthAddr)
  // await nsure.addMinter(capitalConvertUsdtAddr)
  // await nsure.addMinter(lockfundsAddr)
  // await nsure.addMinter(capitalStakeAddr)
  // await nsure.addMinter(claimPurchaseMint)
  // console.log('nsure add minter ok');
  

};