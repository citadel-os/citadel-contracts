const API_KEY = process.env.API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const PUBLIC_KEY = process.env.PUBLIC_KEY;
const CITADEL_NFT = process.env.CITADEL_NFT;
const PILOT_NFT = process.env.PILOT_NFT;
const CITADEL_GAMEV1 = process.env.CITADEL_GAMEV1;
const CITADEL_FLEETV1 = process.env.CITADEL_FLEETV1;
const CITADEL_GAMEENGINEV1 = process.env.CITADEL_GAMEENGINEV1;

const CITADELID = 4;

async function main() {
    const CombatEngineV1 = await ethers.getContractFactory("CombatEngineV1");
    const combatEngineV1 = await CombatEngineV1.attach(CITADEL_GAMEENGINEV1);



    resp = await combatEngineV1.calculateDestroyedFleet([],[],[1000,1000,1000,100,10,10,10]);
    console.log(resp);



}

main();