// migrations/3_transfer_ownership.js
const { admin } = require('@openzeppelin/truffle-upgrades');
 
module.exports = async function (deployer, network) {
  // Use address of your Gnosis Safe
  const gnosisSafe = '0x60670bF8898A4fD24902987C8EB331AD8aEA6bdd';
 
  // Don't change ProxyAdmin ownership for our test network
  if (network !== 'test') {
    // The owner of the ProxyAdmin can upgrade our contracts
    console.log("it's not test network:",network);
    await admin.transferProxyAdminOwnership(gnosisSafe);
  }
};