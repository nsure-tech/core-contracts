const Product = artifacts.require("Product");

contract('Product Test', async accounts => {
    it('set operator ', async ()=>{

        let contract = await Product.deployed()
        await contract.setOperator(accounts[0])
        await contract.addProduct(1,1)
        
    });
    
  });