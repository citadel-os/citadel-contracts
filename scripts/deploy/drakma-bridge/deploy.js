const { ethers } = require("hardhat");

const DRAKMA_TOKEN = process.env.DRAKMA_TOKEN;
const DRAKMA_SENDER = process.env.DRAKMA_SENDER;
const DRAKMA_RECEIVER = process.env.DRAKMA_RECEIVER;
const CCIP_ETH_ROUTER = process.env.CCIP_ETH_ROUTER;
const CHAIN_BASE_SELECTOR = process.env.CHAIN_BASE_SELECTOR;

//npx hardhat run scripts/deploy/drakma-bridge/deploy.js --network sepolia
//npx hardhat run scripts/deploy/drakma-bridge/deploy.js --network mainnet
async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("deploying contracts with the account:", deployer.address);

    const weiAmount = (await deployer.getBalance()).toString();
    console.log("account balance:", await ethers.utils.formatEther(weiAmount));

    const gasPrice = await deployer.getGasPrice();
    console.log(`current gas price: ${gasPrice}`);

    const DrakmaSenderBridge = await ethers.getContractFactory("DrakmaSenderBridge");

    // console.log(DRAKMA_RECEIVER);
    // console.log(CCIP_ETH_ROUTER);
    // console.log(DRAKMA_TOKEN);
    // console.log(CHAIN_BASE_SELECTOR);
    const drakmaSenderBridge = await DrakmaSenderBridge.deploy(
        DRAKMA_RECEIVER,
        CCIP_ETH_ROUTER,
        DRAKMA_TOKEN,
        CHAIN_BASE_SELECTOR
    );
    console.log("drakmaSenderBridge deployed to address:", drakmaSenderBridge.address);

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
