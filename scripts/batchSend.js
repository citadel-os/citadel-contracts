const {fs} = require('file-system');

const MULTIPLE = 243900;
const CITADEL_MAX = 1024;
const ETH_MULTIPLIER = 1000000000000000000;
let CITADEL = [];
let wallets = [];
let drakma = [];
let walletsCollected = [];


const BATCH_SEND = process.env.BATCH_SEND;

async function main() {

    const BatchSend = await ethers.getContractFactory("BatchSend");
    const batchSend = await BatchSend.attach(BATCH_SEND);

    populateCitadel();
    //dedupWallets();
    printInputs();

    console.log("sending");
    await batchSend.multisendToken(wallets, drakma);
    console.log("completed batch send");

}

function batchWallets(from, to) {
    let j = 0;
    for (let i = from; i < to; i++) {
        //ethers.utils.getAddress(wallets[i]);
        walletsBatch[j] = wallets[i];
        drakmaBatch[j] = drakma[i];
        j++;
    }
}

function dedupWallets() {
    for (let i = 0; i < walletsCollected.length; i++) {
        found = false;
        for(let j = 0; j < wallets.length; j++) {
            if (walletsCollected[i] == wallets[j]) {
                found = true;
                drakma[j] = drakma[j] + 256000;
                break;
            }
        }
        if (!found) {
            index = wallets.length;
            wallets[index] = walletsCollected[i];
            drakma[index] = 256000;
        }
    }

    //stringify
    for (let i = 0; i < wallets.length; i++) {
        drakma[i] = drakma[i] * ETH_MULTIPLIER;
        drakma[i] = drakma[i].toLocaleString('fullwide', {useGrouping:false});
        //drakma[i] = "\"" + drakma[i] + "\"";
    }
}

function populateCitadel() {
    const citadelMap = new Map();
    for (let i = 0; i < CITADEL_MAX; i++) {
        const fileName = "output-stakers/" + i;
        let rawdata = fs.readFileSync(fileName);
        let citadel = JSON.parse(rawdata);
        CITADEL[i] = citadel;
        if (citadel.techIndex >= 0 && citadel.techIndex < 8 && citadel.amountStaked > 0) {
            if (citadelMap.get(citadel.walletAddress)) {
                increment = citadelMap.get(citadel.walletAddress) + 1;
                citadelMap.set(citadel.walletAddress, increment);
            } else {
                citadelMap.set(citadel.walletAddress, 1);
            }
        }
    }

    let count = 0;
    for (let [address, amountStaked] of citadelMap) {
        wallets[count] = address;
        drakmaToSend = amountStaked * MULTIPLE * ETH_MULTIPLIER;
        drakma[count] = drakmaToSend.toLocaleString('fullwide', {useGrouping:false});
        count++;
    }
}

function printInputs() {
    total = 0;
    for (let i = 0; i < drakma.length; i++) {
        dk = drakma[i] / ETH_MULTIPLIER;
        console.log(i + ":" + wallets[i] + " " + dk);
        total = total + dk;
    }
    console.log("total dk to send: " + total);
}



main();