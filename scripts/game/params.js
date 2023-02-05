const API_KEY = process.env.API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const PUBLIC_KEY = process.env.PUBLIC_KEY;
const CITADEL_NFT = process.env.CITADEL_NFT;
const PILOT_NFT = process.env.PILOT_NFT;
const CITADEL_GAMEV1 = process.env.CITADEL_GAMEV1;

async function main() {
    const GameV1 = await ethers.getContractFactory("CitadelGameV1");
    const gameV1 = await GameV1.attach(CITADEL_GAMEV1);

    await gameV1.updateGameParams(
        1738390169,
        1,
        3600,
        true
    );

}

main();