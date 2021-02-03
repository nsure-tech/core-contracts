const Buy = artifacts.require("Buy"); //7
// const Stake = artifacts.require("LockFunds"); //6
// const CapitalStake = artifacts.require("CapitalStake"); //5
// const CapitalExchange = artifacts.require("CapitalExchange"); //4
// const Nsure = artifacts.require("Nsure"); //3
// const Surplus = artifacts.require("Surplus"); //2
// const Cover = artifacts.require("Product"); //1


//0xa5a489D44db79E9E59E1A454EC3857cFe45B1F34
// module.exports = function (deployer) {
//   deployer.deploy(Cover);
// };

// //0xA837C739e70294D080800C8DA6AB46266aB03737
// module.exports = function (deployer) {
//   deployer.deploy(Surplus);
// };

// // //0x6cf83f10234ac1db01baed7e45c52a59c9c66a3b
// module.exports = function (deployer) {
//   deployer.deploy(Nsure);
// };


// //0x1356A9ef2aA3a01c7e9B6b77dAEA5601b69e59d3
// module.exports = function (deployer) {
//   deployer.deploy(CapitalExchange);
// };

// // //0x411a23Db417ABE388Eac940Dd2C78c4227E81c0D
// module.exports = function (deployer) { //nsure,cover
//   deployer.deploy(CapitalStake,'0x6cf83f10234ac1db01baed7e45c52a59c9c66a3b','0x8A86528c077785a73f978c52f72F4917A2dBd9EE');
// };


// 0xcC8f135Bb303e633b01C3a3e3762a4B085B089d6
// module.exports = function (deployer) { //nsure,usdt(not avaiable)
//   deployer.deploy(Stake,'0x6cf83f10234ac1db01baed7e45c52a59c9c66a3b','0x6cf83f10234ac1db01baed7e45c52a59c9c66a3b');
// };

// //0xfB2AeeEac92e9Af00ab0993472672bb16c65ffAE
module.exports = function (deployer) { //address _stake,address _surplus,address _cover
  deployer.deploy(Buy,'0xcC8f135Bb303e633b01C3a3e3762a4B085B089d6',
  '0xA837C739e70294D080800C8DA6AB46266aB03737',
  '0xa5a489D44db79E9E59E1A454EC3857cFe45B1F34');
};
