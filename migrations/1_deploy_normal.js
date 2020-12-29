const Converter = artifacts.require("CapitalConverter");


module.exports = function (deployer) {
  deployer.deploy(Converter,'0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE',18);
};

