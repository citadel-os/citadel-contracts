const API_KEY = process.env.API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const PUBLIC_KEY = process.env.PUBLIC_KEY;
const DRAKMA_ADDRESS = process.env.DRAKMA_ADDRESS;
const CITADEL_NFT = process.env.CITADEL_NFT;
const CITADEL_EXORDIUM = process.env.CITADEL_EXORDIUM;

async function main() {
    const Drakma = await ethers.getContractFactory("Drakma");
    const drakma = await Drakma.attach(DRAKMA_ADDRESS);
    const CitadelExordium = await ethers.getContractFactory("CitadelExordium");
    const citadelExordium = await CitadelExordium.attach(CITADEL_EXORDIUM);
    const CitadelNFT = await ethers.getContractFactory("CitadelNFT");
    const citadelNFT = await CitadelNFT.attach(CITADEL_NFT);

    //await citadelExordium.withdrawDrakma("2300000000000000000000000000");

    await drakma.mintDrakma(CITADEL_EXORDIUM, "100000000000000000000000000"); //100,000,000 drakma
    

    //await citadelNFT.approve(CITADEL_EXORDIUM, 0);
    // await citadelNFT.approve(CITADEL_EXORDIUM, 66);
    // console.log("approved staking");
    
    // //166 drakma / hour base
    // //relik 2656 / hour
    //await citadelExordium.stake([0], 0);
    //console.log("staked citadel");
    //await citadelExordium.claimRewards();
    // console.log("claimed rewards");

    // await citadelExordium.withdraw([66]);
    // console.log("withdraw");

    // var techTree0 = await citadelExordium.getTechTree(22);
    // console.log(techTree0[0]);
    // console.log(techTree0);
    
}

main();