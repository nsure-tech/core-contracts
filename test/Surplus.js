const { assert } = require("chai");

const Surplus = artifacts.require("Surplus");

contract('Surplus Test', async accounts => {
    it('should set operator correctly ', async ()=>{

        let contract = await Surplus.deployed()
        await contract.setOperator(accounts[0])
        
    });

    it('should be the account[0]',async ()=>{

        let contract = await Surplus.deployed()
        let operator = await contract.operator()
        assert.equal(accounts[0],operator)
    })
    
  });