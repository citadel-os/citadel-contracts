const API_KEY = process.env.API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const PUBLIC_KEY = process.env.PUBLIC_KEY;
const DRAKMA_ADDRESS = process.env.DRAKMA_ADDRESS;
const CITADEL_NFT = process.env.CITADEL_NFT;
const PILOT_NFT = process.env.PILOT_NFT;
const METAMASK_HOT = process.env.METAMASK_HOT;

const { ethers } = require("hardhat");

async function main() {

    const Drakma = await ethers.getContractFactory("Drakma");
    const drakma = await Drakma.attach(DRAKMA_ADDRESS);

    const Citadel = await ethers.getContractFactory("CitadelNFT");
    const citadel = await Citadel.attach(CITADEL_NFT);

    const Pilot = await ethers.getContractFactory("PilotNFT");
    const pilot = await Pilot.attach(PILOT_NFT);

    // jsays 0x17b0C91e4F925F9f7522949835e1DC3B202cd838
    const transferToAddress = "0x56DBD1086A7c9E3A3Aca1414fBA45a99d20Ef05F";
    await drakma.mintDrakma(transferToAddress, "1000000000000000000000000"); //1M drakma
    await citadel.transferFrom(PUBLIC_KEY, transferToAddress, 4);
    await citadel.transferFrom(PUBLIC_KEY, transferToAddress, 5);
    await pilot.transferFrom(PUBLIC_KEY, transferToAddress, 4);
    await pilot.transferFrom(PUBLIC_KEY, transferToAddress, 5);
    await pilot.transferFrom(PUBLIC_KEY, transferToAddress, 6);
    await pilot.transferFrom(PUBLIC_KEY, transferToAddress, 7);
    console.log("transfered");

}

main()
.then(() => process.exit(0))
.catch((error) => {
  console.error(error);
  process.exit(1);
});