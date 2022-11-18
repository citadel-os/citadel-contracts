const { ethers } = require("hardhat");

const CITADEL_NFT = process.env.CITADEL_NFT;
const DRAKMA_ADDRESS = process.env.DRAKMA_ADDRESS;

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("deploying contracts with the account:", deployer.address);

  const weiAmount = (await deployer.getBalance()).toString();
  console.log("account balance:", await ethers.utils.formatEther(weiAmount));

  const BatchSend = await ethers.getContractFactory("BatchSend");
  const batchSend = await BatchSend.deploy(
    DRAKMA_ADDRESS
  );
  console.log("batchSend contract deployed to address:", batchSend.address);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
