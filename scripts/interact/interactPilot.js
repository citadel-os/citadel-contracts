const API_KEY = process.env.API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const PUBLIC_KEY = process.env.PUBLIC_KEY;
const CITADEL_NFT = process.env.CITADEL_NFT;
const PILOT_NFT = process.env.PILOT_NFT;

async function main() {
    const PilotNFT = await ethers.getContractFactory("PilotNFT");
    const pilotNFT = await PilotNFT.attach(PILOT_NFT);

    await pilotNFT.updateBaseURI(
      "https://gateway.pinata.cloud/ipfs/QmboggQM8emj7rhxaasaLFRBD5f686Zvs2R6TC3L8LaCgZ/"
    );

    await pilotNFT.reservePILOT(256);

    // tx = await pilotNFT.updateClaimParams(false);
    // console.log(tx);

    // tx = await pilotNFT.updateClaimParams(true);
    // console.log(tx);

    //uint256 _pilotPrice, uint256 _pilotMintMax, bool _pilotMintOn, uint256 _sovereignPrice, uint256 _kultPrice
    // tx = await pilotNFT.updateMintParams("125000000000000000", 0, false, "4000000000000000000000000", "100000000000000000000000");
    // console.log(tx);

    // tx = await pilotNFT.withdrawEth();
    // console.log(tx);

    // tx = await pilotNFT.withdrawDrakma("13000000000000000000000000");
    // console.log(tx);

    // sovereignCounter = await pilotNFT.sovereignCounter();
    // console.log(sovereignCounter);

}

main();