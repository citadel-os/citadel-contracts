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

    //jsays 0x17b0C91e4F925F9f7522949835e1DC3B202cd838
    // jobu 0xc71bdB836F0A84Fa33512e7896d9e281A751Fffa
    // adam 0x99a7F3037693B8d6236be052fAC344C4dC3175f3
    const transferToAddress = "0xeB57963356A7CaD98ef1bC218e13D925B2A47DAC";
    await drakma.mintDrakma(transferToAddress, "10000000000000000000000000"); //10M drakma
    await citadel.transferFrom(PUBLIC_KEY, transferToAddress, 16);
    await citadel.transferFrom(PUBLIC_KEY, transferToAddress, 17);
    await citadel.transferFrom(PUBLIC_KEY, transferToAddress, 18);
    await citadel.transferFrom(PUBLIC_KEY, transferToAddress, 19);
    await pilot.transferFrom(PUBLIC_KEY, transferToAddress, 16);
    await pilot.transferFrom(PUBLIC_KEY, transferToAddress, 17);
    await pilot.transferFrom(PUBLIC_KEY, transferToAddress, 18);
    await pilot.transferFrom(PUBLIC_KEY, transferToAddress, 19);
    console.log("transfered");

}

main()
.then(() => process.exit(0))
.catch((error) => {
  console.error(error);
  process.exit(1);
});