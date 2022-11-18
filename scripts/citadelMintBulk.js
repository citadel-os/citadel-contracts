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
  const nonce6 = await web3.eth.getTransactionCount(CITADEL6_PUBLIC, "latest"); //get latest nonce
  const hexProof6 = [
    "0x43c1e6c11bae462cda9508ba49ff818e7c01f3f533d2d654a2f56dbd510a1492",
    "0x385541f1f80e7261e05876ef0e5bed9a620b67c4a2ff9eedbceb9a5985c49299",
    "0x5c0965c65dfb1547d128efb3e61004f43995418da2d36870318fd1d53a6ec3ab",
  ];

  const tx6 = {
    from: CITADEL6_PUBLIC,
    to: CITADEL_NFT,
    nonce: nonce6,
    gas: 500000,
    maxPriorityFeePerGas: 1999999987,
    data: nftContract.methods.mintCitadel(hexProof6).encodeABI(),
  };

  const signedTx6 = await web3.eth.accounts.signTransaction(
    tx6,
    CITADEL6_PRIVATE
  );
  const transactionReceipt6 = await web3.eth.sendSignedTransaction(
    signedTx6.rawTransaction
  );

  console.log(`Transaction receipt: ${JSON.stringify(transactionReceipt6)}`);

  const nonce7 = await web3.eth.getTransactionCount(CITADEL7_PUBLIC, "latest"); //get latest nonce
  const hexProof7 = [
    "0x8be3906b5af3949238c3be02d5b50c2e418a9defd1881dad44b5e38b11445189",
    "0x385541f1f80e7261e05876ef0e5bed9a620b67c4a2ff9eedbceb9a5985c49299",
    "0x5c0965c65dfb1547d128efb3e61004f43995418da2d36870318fd1d53a6ec3ab",
  ];

  //the transaction
  const tx7 = {
    from: CITADEL7_PUBLIC,
    to: CITADEL_NFT,
    nonce: nonce7,
    gas: 500000,
    maxPriorityFeePerGas: 1999999987,
    data: nftContract.methods.mintCitadel(hexProof7).encodeABI(),
  };

  const signedTx7 = await web3.eth.accounts.signTransaction(
    tx7,
    CITADEL7_PRIVATE
  );
  const transactionReceipt7 = await web3.eth.sendSignedTransaction(
    signedTx7.rawTransaction
  );

  console.log(`Transaction receipt: ${JSON.stringify(transactionReceipt7)}`);
}

main();
