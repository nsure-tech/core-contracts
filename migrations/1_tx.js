const Buy = artifacts.require("Buy"); //7
const LockFunds = artifacts.require("LockFunds"); //6
const CapitalStake = artifacts.require("CapitalStake"); //5
const CapitalConvert = artifacts.require("CapitalConverter"); //4
const Nsure = artifacts.require("Nsure"); //3
const USDT = artifacts.require('USDT')
const Surplus = artifacts.require("Surplus"); //2
const Treasury = artifacts.require('Treasury')
const Product = artifacts.require("Product"); //1
const ClaimPurchaseMint = artifacts.require('ClaimPurchaseMint'); //0

module.exports = async function (deployer) {
  let nsureAddr = '0xEf729dA236Fa560319b9AcEf939c081fEc41c12C'
  let usdtAddr = '0x328f0Cb880d68ffB00ad2991f05C69C875d776d2'
  let surplusAddr= '0xbc76A570BD1f6E5E8b58951384d9823803495A6a'
  let productAddr = '0x0786a7a36515306B9F58f63e935bc4dfD9eEDB1c'
  let ETH = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE'
  let wethAddr = '0x19eA6711FBB2BD8302C2ae612eA6718abdada893'
  let treasuryAddr = '0x07EB6Dfd628375F757CeD7f68Ed8D6AA27B16568'
  let capitalConvertEthAddr = '0x7dd34494dBC14c3Cb383dAA97b7146E138B1CD6B'
  let capitalConvertUsdtAddr = '0x99e6f45d01BcdD92E031a2D5B9D691EE200D11a7'
  let capitalStakeAddr = '0xd2150f45b8cd01A1b0bAcA765228C700F7861487'
  let lockfundsAddr = '0xaA138c9e8769A687C3Bd4E476899A64C1dCe0d72'
  let buyAddr = '0x6923880701Bb2B4Ae89d747d2C3ca3fA3c75Ae34'
  let claimPurchaseMint = '0x449dB430715F6193e8DE990F93313619D3411AbE'

  let nsure =await Nsure.at(nsureAddr)
  // let usdt = await USDT.at(usdtAddr)
  // let surplus = await Surplus.at(surplusAddr)
  // let treasury = await Treasury.at(treasuryAddr)
  // let capitalConvertEth = await CapitalConvert.at(capitalConvertEthAddr)
  // let capitalConvertUsdt = await CapitalConvert.at(capitalConvertUsdtAddr)

  console.log("let's begin");
  
  // let product = await Product.at(productAddr)
  let capitalStake = await CapitalStake.at(capitalStakeAddr)
  // let lockfund = await LockFunds.at(lockfundsAddr)
  // let buy = await Buy.at(buyAddr)


  //
  let operater = '0x666747ffD8417a735dFf70264FDf4e29076c775a'
  //product
//   let operatorRet = await product.operator()
//   console.log('operator ret:',operatorRet);
  
//   if(operatorRet !== operater){
//     console.log('set operator');
    
//     await product.setOperator(operater)
//   }
// let lenProduct = await product.getLength()
// console.log('product len:',lenProduct.toNumber());

//   for(let i=1+lenProduct.toNumber();i<=10;i++){
//     await product.addProduct(i,1)
//     console.log('product add:',i);
    
//   }

  //capitalStake
  // await capitalStake.add(100,capitalConvertEthAddr ,true)
  // console.log('capital stake eth add ok');
  
  // await capitalStake.add(100,capitalConvertUsdtAddr,true)
  // console.log('capital stake usdt add ok');
  

  //lockfunds
  // await lockfund.setOperator(operater)
  // await lockfund.addDivCurrency(wethAddr,'100000000000000000000')
  // console.log('lockfund add weth');
  
  // await lockfund.addDivCurrency(usdtAddr,'100000000000000000000')
  // console.log('lockfund add usdt');
  

  //buy
  // await buy.addDivCurrency(wethAddr) 
  // console.log('buy add weth');
  
  // await buy.addDivCurrency(usdtAddr) 
  // console.log('buy add usdt');
  

  //nsure add minter
  // await nsure.addMinter(capitalConvertEthAddr)
  // await nsure.addMinter(capitalConvertUsdtAddr)
  // await nsure.addMinter(lockfundsAddr)
  await nsure.addMinter(capitalStakeAddr)
  // await nsure.addMinter(claimPurchaseMint)
  // console.log('nsure add minter ok');
  

};