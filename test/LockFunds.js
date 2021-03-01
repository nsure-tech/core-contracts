const LockFunds = artifacts.require("LockFunds");

contract('LockFunds Test', async accounts => {
    it(' get totalSupply ', async ()=>{

        let contract = await LockFunds.deployed()
        let total =await contract.totalSupply()
        console.log('total:',total);
    });
    
    it('set duration',async () => {

        let duration = 86400
        let contract = await LockFunds.deployed()
        await contract.setDeadlineDuration(duration)
    })
  });