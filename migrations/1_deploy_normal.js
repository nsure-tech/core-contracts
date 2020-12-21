const Migrations = artifacts.require("Buy");

module.exports = function (deployer) {
  deployer.deploy(Migrations);
};
