const { ethers } = require("hardhat");

const CITADEL_NFT = process.env.CITADEL_NFT;
const DRAKMA_ADDRESS = process.env.DRAKMA_ADDRESS;
const CITADEL_EXORDIUM = process.env.CITADEL_EXORDIUM;

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("deploying contracts with the account:", deployer.address);

  const weiAmount = (await deployer.getBalance()).toString();
  console.log("account balance:", await ethers.utils.formatEther(weiAmount));

  // const CitadelNFT = await ethers.getContractFactory("CitadelNFT");
  // const citadelNFT = await CitadelNFT.deploy(
  //   "CITADEL",
  //   "CITADEL",
  //   "https://gateway.pinata.cloud/ipfs/QmXXC2PHUeiFtUFVdLNnYodWUNdZnK2jbT8prE6R51mGT6/"
  // );
  // console.log("nft contract deployed to address:", citadelNFT.address);
  // await citadelNFT.reserveCitadel(1024);
  // console.log("citadel minted");

  // const CitadelExordium = await ethers.getContractFactory("CitadelExordium");
  // const citadelExordium = await CitadelExordium.deploy(
  //   CITADEL_NFT,
  //   DRAKMA_ADDRESS
  // );
  // console.log("exordium contract deployed to address:", citadelExordium.address);

  const PilotNFT = await ethers.getContractFactory("PilotNFT");
  const pilotNFT = await PilotNFT.deploy(
    DRAKMA_ADDRESS,
    CITADEL_EXORDIUM,
    "https://gateway.pinata.cloud/ipfs/QmboggQM8emj7rhxaasaLFRBD5f686Zvs2R6TC3L8LaCgZ/"
  );
  console.log("pilot contract deployed to address:", pilotNFT.address);
  await pilotNFT.reservePILOT(1280);
  console.log("pilot reserved");

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
