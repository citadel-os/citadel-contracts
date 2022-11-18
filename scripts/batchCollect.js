const API_KEY = process.env.API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const PUBLIC_KEY = process.env.PUBLIC_KEY;
const CITADEL_EXORDIUM = process.env.CITADEL_EXORDIUM;
const CITADEL_MAX = 1024;

const {fs} = require('file-system');

let CITADEL = [];
async function main() {
    const CitadelExordium = await ethers.getContractFactory("CitadelExordium");
    const citadelExordium = await CitadelExordium.attach(CITADEL_EXORDIUM);

    for (var i=0; i <CITADEL_MAX; i++) {
        console.log(i);
        walletAddress = await citadelExordium.getCitadelStaker(i);
        console.log(walletAddress);
        data = await citadelExordium.getStaker(walletAddress);
        citadel = {
            walletAddress: walletAddress,
            tokenId: i,
            amountStaked: Number(data[0].toString()),
            techIndex: Number(data[2].toString())
        }
        CITADEL[i] = citadel;
    }
    writeCitadel();
}

function writeCitadel() {
    console.log("write citadels");
    for (let i = 0; i < CITADEL.length; i++) {
        citadel = CITADEL[i];
        fileName = "output-stakers/" + i;
        fs.writeFileSync(fileName, JSON.stringify(citadel));
    }
}

function printCitadel() {
    console.log("print citadel");
    for(var i = 0; i < CITADEL.length; i++) {
        citadel = CITADEL[i];
        console.log(citadel.tokenId);
    }
}

main();
