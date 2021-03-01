const CapitalStake = artifacts.require("CapitalStake");

contract('CapitalStake Test', async accounts => {
    it('should deposit ', async ()=>{

        let contract = await CapitalStake.deployed()
        await contract.deposit(0,1e18)
        
    });

    it('get pool length',async () => {

        let contract = await CapitalStake.deployed()
       let len = await contract.poolLength()
       console.log('len:',len);
       
    })
    
  });