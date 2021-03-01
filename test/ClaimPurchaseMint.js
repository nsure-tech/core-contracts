const ClaimPurchaseMint = artifacts.require("ClaimPurchaseMint");

contract('ClaimPurchaseMint Test', async accounts => {
    it(' get totalSupply ', async ()=>{
        
        let contract = await ClaimPurchaseMint.deployed()
        let total =await contract.totalSupply()
        console.log('total:',total.toNumber());
        
        
    });
    
    it('set signer',async () => {

        let signer = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE'
        let contract = await ClaimPurchaseMint.deployed()
        let total =await contract.setSigner(signer)
    })
  });