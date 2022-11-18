const { ethers } = require("hardhat");

const CITADEL_NFT = process.env.CITADEL_NFT;
const DRAKMA_ADDRESS = process.env.DRAKMA_ADDRESS;
const CITADEL_EXORDIUM = process.env.CITADEL_EXORDIUM;

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("deploying contracts with the account:", deployer.address);

  const weiAmount = (await deployer.getBalance()).toString();
  console.log("account balance:", await ethers.utils.formatEther(weiAmount));

  const PilotNFT = await ethers.getContractFactory("PilotNFT");
  const pilotNFT = await PilotNFT.deploy(
    DRAKMA_ADDRESS,
    CITADEL_EXORDIUM,
    "https://gateway.pinata.cloud/ipfs/QmYiHnY7Z5bgfR83CWqpXi6kjqCMKj8jqxGhcMfBpf4xVm/"
  );
  console.log("pilot contract deployed to address:", pilotNFT.address);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
