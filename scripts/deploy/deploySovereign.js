const { ethers } = require("hardhat");

const CITADEL_NFT = process.env.CITADEL_NFT;
const DRAKMA_ADDRESS = process.env.DRAKMA_ADDRESS;
const CITADEL_EXORDIUM = process.env.CITADEL_EXORDIUM;
const PILOT_NFT = process.env.PILOT_NFT;

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("deploying contracts with the account:", deployer.address);

  const weiAmount = (await deployer.getBalance()).toString();
  console.log("account balance:", await ethers.utils.formatEther(weiAmount));

  const SovereignCollective = await ethers.getContractFactory("SovereignCollectiveV1");
  const sovereign = await SovereignCollective.deploy(
    PILOT_NFT,
    DRAKMA_ADDRESS
  );
  console.log("sovereign collective contract deployed to address:", sovereign.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
