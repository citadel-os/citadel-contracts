const API_KEY = process.env.API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const PUBLIC_KEY = process.env.PUBLIC_KEY;
const CITADEL_NFT = process.env.CITADEL_NFT;
const PILOT_NFT = process.env.PILOT_NFT;
const CITADEL_GAMEV1 = process.env.CITADEL_GAMEV1;

async function main() {
    const GameV1 = await ethers.getContractFactory("CitadelGameV1");
    const gameV1 = await GameV1.attach(CITADEL_GAMEV1);

    // let raid = await gameV1.getRaid(3);
    // console.log(raid);


    // let res = await gameV1.resolveRaid(3);
    // console.log(res);

    let res = await gameV1.sendRaid(
        4, 
        8, 
        [], 
        100, 
        0, 
        0
    );
    console.log(res);
}

main();