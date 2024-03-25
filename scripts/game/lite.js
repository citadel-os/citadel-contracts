const API_KEY = process.env.API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const PUBLIC_KEY = process.env.PUBLIC_KEY;
const CITADEL_NFT = process.env.CITADEL_NFT;
const PILOT_NFT = process.env.PILOT_NFT;
const CITADEL_GAMEV2 = process.env.CITADEL_GAMEV2;

const CITADELID = 4;

//npx hardhat run scripts/game/lite.js --network sepolia
async function main() {

    const CitadelNFT = await ethers.getContractFactory("CitadelNFT");
    const citadelNFT = await CitadelNFT.attach(CITADEL_NFT);

    const PilotNFT = await ethers.getContractFactory("PilotNFT");
    const pilotNFT = await PilotNFT.attach(PILOT_NFT);

    const GameV2 = await ethers.getContractFactory("CitadelGameV2");
    const gameV2 = await GameV2.attach(CITADEL_GAMEV2);

    let x = await citadelNFT.ownerOf(1021);
    console.log(x);

    let y = await pilotNFT.ownerOf(1021);
    console.log(y);

    await gameV2.liteGrid(
        1021,
        [1021,0,0],
        1021,
        2
    );

}

main();