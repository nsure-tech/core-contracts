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

// // //0x411a23Db417ABE388Eac940Dd2C78c4227E81c0D
// module.exports = function (deployer) { //nsure,cover
//   deployer.deploy(CapitalStake,'0x4eC851036118b265612Fc6aFaaf250Cf81E28D70','0x8A86528c077785a73f978c52f72F4917A2dBd9EE');
// };


// 0x7124eC0CEB84bFdb668a5C2C8c6d487600f1d66d
// module.exports = function (deployer) { //nsure,usdt(not avaiable)
//   deployer.deploy(Stake,'0x4eC851036118b265612Fc6aFaaf250Cf81E28D70','0x4eC851036118b265612Fc6aFaaf250Cf81E28D70');
// };

//0x3D433536eeF9A9B9D2d5356f2F608dF743A3DE96
module.exports = function (deployer) { //address _stake,address _surplus,address _cover
  deployer.deploy(Buy,'0x7124eC0CEB84bFdb668a5C2C8c6d487600f1d66d',
  '0xA837C739e70294D080800C8DA6AB46266aB03737',
  '0x8A86528c077785a73f978c52f72F4917A2dBd9EE');
};
