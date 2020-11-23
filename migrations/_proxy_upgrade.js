// migrations/MM_upgrade_box_contract.js
const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const Box = artifacts.require('Box');
const BoxV2 = artifacts.require('BoxV2');

module.exports = async function (deployer) {
  const existing = await Box.deployed();
  console.log('existing address:',existing);
  
  const instance = await upgradeProxy(existing.address, BoxV2, { deployer });
  console.log("Upgraded", instance.address);
};