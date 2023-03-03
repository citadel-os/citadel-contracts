const { ethers } = require("hardhat");

const CITADEL_NFT = process.env.CITADEL_NFT;
const DRAKMA_ADDRESS = process.env.DRAKMA_ADDRESS;
const CITADEL_EXORDIUM = process.env.CITADEL_EXORDIUM;
const PILOT_NFT = process.env.PILOT_NFT;
const CITADEL_GAMEENGINEV1 = process.env.CITADEL_GAMEENGINEV1;
const CITADEL_FLEETV1 = process.env.CITADEL_FLEETV1;

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("deploying contracts with the account:", deployer.address);

  const weiAmount = (await deployer.getBalance()).toString();
  console.log("account balance:", await ethers.utils.formatEther(weiAmount));

  const Drakma = await ethers.getContractFactory("Drakma");
  const drakma = await Drakma.deploy();
  console.log("drakma deployed to address:", drakma.address);


}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });