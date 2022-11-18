const API_URL = process.env.API_URL;
const API_KEY = process.env.API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const PUBLIC_KEY = process.env.PUBLIC_KEY;
const CITADEL_NFT = process.env.CITADEL_NFT;
const CITADEL1_PRIVATE = process.env.CITADEL1_PRIVATE;
const CITADEL1_PUBLIC = process.env.CITADEL1_PUBLIC;
const CITADEL2_PRIVATE = process.env.CITADEL2_PRIVATE;
const CITADEL2_PUBLIC = process.env.CITADEL2_PUBLIC;
const CITADEL3_PRIVATE = process.env.CITADEL3_PRIVATE;
const CITADEL3_PUBLIC = process.env.CITADEL3_PUBLIC;
const CITADEL4_PRIVATE = process.env.CITADEL4_PRIVATE;
const CITADEL4_PUBLIC = process.env.CITADEL4_PUBLIC;
const CITADEL5_PRIVATE = process.env.CITADEL5_PRIVATE;
const CITADEL5_PUBLIC = process.env.CITADEL5_PUBLIC;
const CITADEL6_PRIVATE = process.env.CITADEL6_PRIVATE;
const CITADEL6_PUBLIC = process.env.CITADEL6_PUBLIC;
const CITADEL7_PRIVATE = process.env.CITADEL7_PRIVATE;
const CITADEL7_PUBLIC = process.env.CITADEL7_PUBLIC;
const CITADEL8_PRIVATE = process.env.CITADEL8_PRIVATE;
const CITADEL8_PUBLIC = process.env.CITADEL8_PUBLIC;

const { createAlchemyWeb3 } = require("@alch/alchemy-web3");
const web3 = createAlchemyWeb3(API_URL);

const contract = require("../artifacts/contracts/CitadelNFT.sol/CitadelNFT.json");
const nftContract = new web3.eth.Contract(contract.abi, CITADEL_NFT);

async function main() {
  const nonce = await web3.eth.getTransactionCount(CITADEL4_PUBLIC, "latest"); //get latest nonce
  const hexProof = [
    '0xdc277dacabb85065c477482140b12993e9430e1e9915773a654a43121f32832a',
    '0xd0de7c830ae94a463cf6493b3af5b437df5360571e95d897d89c6336dc63ce3d',
    '0xb977c2508cfe96f4109ad925b56775959d2f8baf091c532ac3318402565907ba'
  ];

  //the transaction
  const tx = {
    from: CITADEL4_PUBLIC,
    to: CITADEL_NFT,
    nonce: nonce,
    gas: 500000,
    maxPriorityFeePerGas: 1999999987,
    data: nftContract.methods.mintCitadel(hexProof).encodeABI(),
  };

  const signedTx = await web3.eth.accounts.signTransaction(
    tx,
    CITADEL4_PRIVATE
  );
  const transactionReceipt = await web3.eth.sendSignedTransaction(
    signedTx.rawTransaction
  );

  console.log(`Transaction receipt: ${JSON.stringify(transactionReceipt)}`);
}

main();
