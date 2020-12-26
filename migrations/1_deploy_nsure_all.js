const Buy = artifacts.require("Buy"); //7
// const Stake = artifacts.require("Stake"); //6
// const CapitalStake = artifacts.require("CapitalStake"); //5
// const CapitalExchange = artifacts.require("CapitalExchange"); //4
// const Nsure = artifacts.require("Nsure"); //3
// const Surplus = artifacts.require("Surplus"); //2
// const Cover = artifacts.require("Cover"); //1


//0x8A86528c077785a73f978c52f72F4917A2dBd9EE
// module.exports = function (deployer) {
//   deployer.deploy(Cover);
// };

// //0xA837C739e70294D080800C8DA6AB46266aB03737
// module.exports = function (deployer) {
//   deployer.deploy(Surplus);
// };

// // //0x4eC851036118b265612Fc6aFaaf250Cf81E28D70
// module.exports = function (deployer) {
//   deployer.deploy(Nsure);
// };


// //0x1356A9ef2aA3a01c7e9B6b77dAEA5601b69e59d3
// module.exports = function (deployer) {
//   deployer.deploy(CapitalExchange);
// };

// //0xfe98a238fa2A51fef569F36ed708Fd26F1FeEc59
// module.exports = function (deployer) {
//   deployer.deploy(CapitalStake,'0x4eC851036118b265612Fc6aFaaf250Cf81E28D70');
// };


//0x7D712dA9c4C17D90344CBD0213FE90f13aBE25D4
// module.exports = function (deployer) {
//   deployer.deploy(Stake,'0x4eC851036118b265612Fc6aFaaf250Cf81E28D70','0x4eC851036118b265612Fc6aFaaf250Cf81E28D70');
// };

// //0xF71aB5C39d535Cc88bDa09d21198a2C473F02710
module.exports = function (deployer) { //address _stake,address _surplus,address _cover
  deployer.deploy(Buy,'0x7D712dA9c4C17D90344CBD0213FE90f13aBE25D4',
  '0xA837C739e70294D080800C8DA6AB46266aB03737',
  '0x8A86528c077785a73f978c52f72F4917A2dBd9EE');
};
