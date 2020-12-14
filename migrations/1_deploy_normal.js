const Migrations = artifacts.require("Nsure");

module.exports = function (deployer) {
  deployer.deploy(Migrations);
};
