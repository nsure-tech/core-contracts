const Buy = artifacts.require("Buy");

contract('Buy Test', async accounts => {
    it('should getDivCurrencyLength ', async ()=>{

        let contract = await Buy.deployed()
        let len =await contract.getDivCurrencyLength()
        console.log('len:',len);
        
    });

    it('addDivCurrency',async ()=>{

        let divAddress = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE'
        let contract = await Buy.deployed()
        await contract.addDivCurrency(divAddress)
    })
    
  });