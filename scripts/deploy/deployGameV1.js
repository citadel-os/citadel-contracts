const { ethers } = require("hardhat");

const CITADEL_NFT = process.env.CITADEL_NFT;
const DRAKMA_ADDRESS = process.env.DRAKMA_ADDRESS;
const CITADEL_EXORDIUM = process.env.CITADEL_EXORDIUM;
const PILOT_NFT = process.env.PILOT_NFT;
const CITADEL_GAMEENGINEV1 = process.env.CITADEL_GAMEENGINEV1;

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("deploying contracts with the account:", deployer.address);

  const weiAmount = (await deployer.getBalance()).toString();
  console.log("account balance:", await ethers.utils.formatEther(weiAmount));

//   const CombatEngineV1 = await ethers.getContractFactory("CombatEngineV1");
//   const combatEngineV1 = await CombatEngineV1.deploy(
//     PILOT_NFT
//   );
//   console.log("combat engine contract deployed to address:", combatEngineV1.address);

  const CitadelGameV1 = await ethers.getContractFactory("CitadelGameV1");
  const citadelGameV1 = await CitadelGameV1.deploy(
    CITADEL_NFT,
    PILOT_NFT,
    DRAKMA_ADDRESS,
    CITADEL_GAMEENGINEV1
  );
  console.log("citadel game contract deployed to address:", citadelGameV1.address);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });