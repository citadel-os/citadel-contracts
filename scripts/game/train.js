const API_KEY = process.env.API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const PUBLIC_KEY = process.env.PUBLIC_KEY;
const CITADEL_NFT = process.env.CITADEL_NFT;
const PILOT_NFT = process.env.PILOT_NFT;
const CITADEL_GAMEV2 = process.env.CITADEL_GAMEV2;
const CITADEL_STORAGEV2 = process.env.CITADEL_STORAGEV2;
const DRAKMA_ADDRESS = process.env.DRAKMA_ADDRESS;

//npx hardhat run scripts/game/train.js --network sepolia
const CITADELID = 1022;

async function main() {
    
    const GameV2 = await ethers.getContractFactory("CitadelGameV2");
    const gameV2 = await GameV2.attach(CITADEL_GAMEV2);

    const StorageV2 = await ethers.getContractFactory("StorageV2");
    const storageV2 = await StorageV2.attach(CITADEL_STORAGEV2);

    const Drakma = await ethers.getContractFactory("Drakma");
    const drakma = await Drakma.attach(DRAKMA_ADDRESS);

    //await drakma.approve(CITADEL_GAMEV2, "2048000000000000000000000");

    await gameV2.trainFleet(CITADELID, 2, 2, 1);

    // let fleetTraining = await storageV2.getCitadelFleetCount(CITADELID);
    // console.log(fleetTraining);

}

main();