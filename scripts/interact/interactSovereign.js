const API_KEY = process.env.API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const PUBLIC_KEY = process.env.PUBLIC_KEY;
const SOVEREIGN_COLLECTIVE = process.env.SOVEREIGN_COLLECTIVE;

async function main() {
    const SovereignCollective = await ethers.getContractFactory("SovereignCollectiveV1");
    const sovereign = await SovereignCollective.attach(SOVEREIGN_COLLECTIVE);

    tx = await sovereign.resetClaims();
    console.log(tx);



    // sovereignCounter = await pilotNFT.sovereignCounter();
    // console.log(sovereignCounter);

}

main();