const CapitalConverter = artifacts.require("CapitalConverter");

contract('CapitalConverter Test', async accounts => {
    it('should convert ', async ()=>{

        let contract = await CapitalConverter.deployed()
        await contract.convert(1e18)
    });

    it('should get smartBalance',async () => {

        let contract = await CapitalConverter.deployed()
      let balance =  await contract.smartBalance()
      console.log('balance:',balance);
      
    })
    
  });