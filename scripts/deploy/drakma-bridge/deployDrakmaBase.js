const { ethers } = require("hardhat");


//npx hardhat run scripts/deploy/drakma-bridge/deployDrakmaBase.js --network basesepolia
//npx hardhat run scripts/deploy/drakma-bridge/deployDrakmaBase.js --network base
async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("deploying contracts with the account:", deployer.address);

    const weiAmount = (await deployer.getBalance()).toString();
    console.log("account balance:", await ethers.utils.formatEther(weiAmount));

    const gasPrice = await deployer.getGasPrice();
    console.log(`current gas price: ${gasPrice}`);

    const DrakmaBase = await ethers.getContractFactory("DrakmaBase");
    const drakmaBase = await DrakmaBase.deploy();
    console.log("drakmaBase deployed to address:", drakmaBase.address);

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });