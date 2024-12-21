const API_KEY = process.env.API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const PUBLIC_KEY = process.env.PUBLIC_KEY;
const CITADEL_NFT = process.env.CITADEL_NFT;
const PILOT_NFT = process.env.PILOT_NFT;
const DRAKMA_TOKEN = process.env.DRAKMA_TOKEN;
const DRAKMA_TOKEN_BASE = process.env.DRAKMA_TOKEN_BASE;
const DRAKMA_RECEIVER = process.env.DRAKMA_RECEIVER;

//npx hardhat run scripts/drakma-bridge/setupBase.js --network basesepolia
async function main() {
    const DrakmaBase = await ethers.getContractFactory("DrakmaBase");
    const drakmaBase = await DrakmaBase.attach(DRAKMA_TOKEN_BASE);

    await drakmaBase.addMinter(
        DRAKMA_RECEIVER
    );

    // put eth in sender

}

main();