const { ethers } = require("hardhat");

const CITADEL_NFT = process.env.CITADEL_NFT;
const DRAKMA_ADDRESS = process.env.DRAKMA_ADDRESS;
const CITADEL_EXORDIUM = process.env.CITADEL_EXORDIUM;
const PILOT_NFT = process.env.PILOT_NFT;
const CITADEL_SOVEREIGN_COLLECTIVEV2 = process.env.CITADEL_SOVEREIGN_COLLECTIVEV2;
const CITADEL_COMBATENGINEV2 = process.env.CITADEL_COMBATENGINEV2;
const CITADEL_STORAGEV2 = process.env.CITADEL_STORAGEV2;

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("deploying contracts with the account:", deployer.address);

  const weiAmount = (await deployer.getBalance()).toString();
  console.log("account balance:", await ethers.utils.formatEther(weiAmount));

  const gasPrice = await deployer.getGasPrice();
  console.log(`Current gas price: ${gasPrice}`);

  // const SovereignCollectiveV2 = await ethers.getContractFactory("SovereignCollectiveV2");
  // const sovereignCollectiveV2 = await SovereignCollectiveV2.deploy(
  //   PILOT_NFT
  // );
  // console.log("sovereign collective v2 deployed to address:", sovereignCollectiveV2.address);

  // const CombatEngineV2 = await ethers.getContractFactory("CombatEngineV2");
  // const combatEngineV2 = await CombatEngineV2.deploy(
  //   PILOT_NFT,
  //   DRAKMA_ADDRESS
  // );
  // console.log("combat engine deployed to address:", combatEngineV2.address);

  // const StorageV2 = await ethers.getContractFactory("StorageV2");
  // const storageV2 = await StorageV2.deploy(
  //   CITADEL_COMBATENGINEV2
  // );
  // console.log("fleet engine deployed to address:", storageV2.address);

  // const CitadelGameV2 = await ethers.getContractFactory("CitadelGameV2");
  // const citadelGameV2 = await CitadelGameV2.deploy(
  //   CITADEL_NFT,
  //   PILOT_NFT,
  //   DRAKMA_ADDRESS,
  //   CITADEL_STORAGEV2,
  //   CITADEL_COMBATENGINEV2,
  //   CITADEL_SOVEREIGN_COLLECTIVEV2
  // );
  // console.log("citadel game contract deployed to address:", citadelGameV2.address);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });