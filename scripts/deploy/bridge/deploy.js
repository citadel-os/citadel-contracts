const { ethers } = require("hardhat");

const DRAKMA_TOKEN = process.env.DRAKMA_TOKEN;


//npx hardhat run scripts/deploy/bridge/deploy.js --network sepolia
//npx hardhat run scripts/deploy/bridge/deploy.js --network mainnet
async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("deploying contracts with the account:", deployer.address);

    const weiAmount = (await deployer.getBalance()).toString();
    console.log("account balance:", await ethers.utils.formatEther(weiAmount));

    const gasPrice = await deployer.getGasPrice();
    console.log(`current gas price: ${gasPrice}`);

    const DrakmaLock = await ethers.getContractFactory("DrakmaLock");


    const drakmaLock = await DrakmaLock.deploy(
        DRAKMA_TOKEN
    );
    console.log("drakmaLock deployed to address:", drakmaLock.address);

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
