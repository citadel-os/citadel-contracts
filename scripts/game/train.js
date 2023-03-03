const API_KEY = process.env.API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const PUBLIC_KEY = process.env.PUBLIC_KEY;
const CITADEL_NFT = process.env.CITADEL_NFT;
const PILOT_NFT = process.env.PILOT_NFT;
const CITADEL_GAMEV1 = process.env.CITADEL_GAMEV1;
const CITADEL_FLEETV1 = process.env.CITADEL_FLEETV1;

const CITADELID = 998;

async function main() {
    const FleetV1 = await ethers.getContractFactory("CitadelFleetV1");
    const fleetV1 = await FleetV1.attach(CITADEL_FLEETV1);

    // fleetTraining = await gameV1.getCitadelFleetCountTraining(CITADELID);
    // console.log(fleetTraining);


    // fleetInCitadel = await gameV1.getCitadelFleetCount(CITADELID);
    // console.log(fleetInCitadel);

    // let fleetTraining = await fleetV1.getFleetInTraining(CITADELID);
    // console.log(fleetTraining);
    // let res = await fleetV1.resolveTraining(CITADELID);
    // console.log(res);

    //uint256 _citadelId, int256 _sifGattaca, int256 _mhrudvogThrot, int256 _drebentraakht
    let train = await fleetV1.trainFleet(3, 200, 0, 0);
    console.log(train);

}

main();