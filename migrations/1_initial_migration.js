const Migrations = artifacts.require("Migrations");
const M1 = artifacts.require('M1')
module.exports = function (deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(M1)
};
