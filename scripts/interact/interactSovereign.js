const API_KEY = process.env.API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const PUBLIC_KEY = process.env.PUBLIC_KEY;
const SOVEREIGN_COLLECTIVE = process.env.SOVEREIGN_COLLECTIVE;

async function main() {
    const SovereignCollective = await ethers.getContractFactory("SovereignCollectiveV1");
    const sovereign = await SovereignCollective.attach(SOVEREIGN_COLLECTIVE);

    tx = await sovereign.resetClaims();
    console.log(tx);

    // tx = await pilotNFT.updateClaimParams(true);
    // console.log(tx);

    //uint256 _pilotPrice, uint256 _pilotMintMax, bool _pilotMintOn, uint256 _sovereignPrice, uint256 _kultPrice
    // tx = await pilotNFT.updateMintParams("125000000000000000", 0, false, "4000000000000000000000000", "100000000000000000000000");
    // console.log(tx);

    // tx = await pilotNFT.withdrawEth();
    // console.log(tx);

    // tx = await pilotNFT.withdrawDrakma("288000000000000000000000000");
    // console.log(tx);

    // sovereignCounter = await pilotNFT.sovereignCounter();
    // console.log(sovereignCounter);

}

main();