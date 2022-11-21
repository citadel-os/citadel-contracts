const API_URL = process.env.API_URL;
const API_KEY = process.env.API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const PUBLIC_KEY = process.env.PUBLIC_KEY;
const PILOT_NFT = process.env.PILOT_NFT;

const { createAlchemyWeb3 } = require("@alch/alchemy-web3");
const web3 = createAlchemyWeb3(API_URL);

const contract = require("../artifacts/contracts/PilotNFT.sol/PilotNFT.json");
const nftContract = new web3.eth.Contract(contract.abi, PILOT_NFT);


async function main() {
  const PilotNFT = await ethers.getContractFactory("PilotNFT");
  const pilotNFT = await PilotNFT.attach(PILOT_NFT);

  const nonce = await web3.eth.getTransactionCount(PUBLIC_KEY, 'latest'); //get latest nonce

  //the transaction
  const tx = {
    'from': PUBLIC_KEY,
    'to': PILOT_NFT,
    'nonce': nonce,
    'value': 180000000000000000,
    'gas': 500000,
    'maxPriorityFeePerGas': 1999999987,
    'data': nftContract.methods.mintPilot(1).encodeABI()
  };

  const signedTx = await web3.eth.accounts.signTransaction(tx, PRIVATE_KEY);
  const transactionReceipt = await web3.eth.sendSignedTransaction(signedTx.rawTransaction);

  console.log(`Transaction receipt: ${JSON.stringify(transactionReceipt)}`);

}

main();