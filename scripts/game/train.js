const API_KEY = process.env.API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const PUBLIC_KEY = process.env.PUBLIC_KEY;
const CITADEL_NFT = process.env.CITADEL_NFT;
const PILOT_NFT = process.env.PILOT_NFT;
const CITADEL_GAMEV1 = process.env.CITADEL_GAMEV1;

const CITADELID = 995;

async function main() {
    const GameV1 = await ethers.getContractFactory("CitadelGameV1");
    const gameV1 = await GameV1.attach(CITADEL_GAMEV1);

    fleetTraining = await gameV1.getCitadelFleetCountTraining(CITADELID);
    console.log(fleetTraining);


    fleetInCitadel = await gameV1.getCitadelFleetCount(CITADELID);
    console.log(fleetInCitadel);

}

main();