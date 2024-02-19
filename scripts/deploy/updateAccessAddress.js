const API_KEY = process.env.API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const PUBLIC_KEY = process.env.PUBLIC_KEY;
const CITADEL_STORAGEV2 = process.env.CITADEL_STORAGEV2;
const CITADEL_COMBATENGINEV2 = process.env.CITADEL_COMBATENGINEV2;
const CITADEL_SOVEREIGN_COLLECTIVEV2 = process.env.CITADEL_SOVEREIGN_COLLECTIVEV2;
const CITADEL_GAMEV2 = process.env.CITADEL_GAMEV2;

async function main() {
    // const StorageV2 = await ethers.getContractFactory("StorageV2");
    // const storageV2 = await StorageV2.attach(CITADEL_STORAGEV2);

    // await storageV2.updateAccessAddress(
    //     CITADEL_GAMEV2
    // );

    const SovereignCollectiveV2 = await ethers.getContractFactory("SovereignCollectiveV2");
    const sovereignCollectiveV2 = await SovereignCollectiveV2.attach(CITADEL_SOVEREIGN_COLLECTIVEV2);

    await sovereignCollectiveV2.updateAccessAddress(
        CITADEL_GAMEV2
    );


}

main();