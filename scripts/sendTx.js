async function main() {
    require('dotenv').config();
    const { API_URL, PRIVATE_KEY, PUBLIC_KEY, METAMASK_HOT } = process.env;
    const { createAlchemyWeb3 } = require("@alch/alchemy-web3");
    const web3 = createAlchemyWeb3(API_URL);
    const nonce = await web3.eth.getTransactionCount(PUBLIC_KEY, 'latest'); // nonce starts counting from 0

    const transaction = {
     'to': METAMASK_HOT,
     'value': 100,
     'gas': 30000,
     'maxFeePerGas': 2500000000,
     'nonce': nonce,
     // optional data field to send message or execute smart contract
    };
   
    const signedTx = await web3.eth.accounts.signTransaction(transaction, PRIVATE_KEY);
    
    web3.eth.sendSignedTransaction(signedTx.rawTransaction, function(error, hash) {
    if (!error) {
      console.log("🎉 The hash of your transaction is: ", hash, "\n Check Alchemy's Mempool to view the status of your transaction!");
    } else {
      console.log("❗Something went wrong while submitting your transaction:", error)
    }
   });
}

main();