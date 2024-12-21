const { ethers } = require("hardhat");

const DRAKMA_TOKEN_BASE = process.env.DRAKMA_TOKEN_BASE;
const CCIP_BASE_ROUTER = process.env.CCIP_BASE_ROUTER;
const CHAIN_ETH_SELECTOR = process.env.CHAIN_ETH_SELECTOR;

//npx hardhat run scripts/deploy/drakma-bridge/deployReceiver.js --network basesepolia
//npx hardhat run scripts/deploy/drakma-bridge/deployReceiver.js --network base
async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("deploying contracts with the account:", deployer.address);

    const weiAmount = (await deployer.getBalance()).toString();
    console.log("account balance:", await ethers.utils.formatEther(weiAmount));

    const gasPrice = await deployer.getGasPrice();
    console.log(`current gas price: ${gasPrice}`);

    const DrakmaReceiverBridge = await ethers.getContractFactory("DrakmaReceiverBridge");
    const drakmaReceiverBridge = await DrakmaReceiverBridge.deploy(
        CCIP_BASE_ROUTER,
        DRAKMA_TOKEN_BASE
    );
    console.log("drakmaReceiverBridge deployed to address:", drakmaReceiverBridge.address);

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });