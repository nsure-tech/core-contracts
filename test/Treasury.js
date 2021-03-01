const Treasury = artifacts.require("Treasury");

contract('Treasury Test', async accounts => {
    it('set operator ', async ()=>{

        let contract = await Treasury.deployed()
        await contract.setOperator(accounts[0])
        
    });

    it('get myBalance',async () => {

        let tokenAddress = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE'
        let contract = await Treasury.deployed()
        let balance =await contract.myBalanceOf(accounts[0])

    })
    
  });