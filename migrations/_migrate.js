const Migrations = artifacts.require("ChickenChef");

module.exports = function (deployer) {


  deployer.deploy(
      Migrations,
      '0x15c257333FD5eE70B8A468F0848C6f6BEd6FB38f',
      '0xa25A449539F88F9a63712Aa1bF79A718062549F7',
      2,
      21782202,
      22782202
      );
};