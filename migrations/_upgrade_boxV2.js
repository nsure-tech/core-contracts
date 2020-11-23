const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const Box = artifacts.require('Box');
// const BoxV2 = artifacts.require('BoxV2');

module.exports = async function (deployer) {
  let existing = await Box.deployed();
  console.log('addr existing:',existing.address);
  
  const instance = await upgradeProxy(existing.address, Box, { deployer });
  console.log("Upgraded", instance.address);
};