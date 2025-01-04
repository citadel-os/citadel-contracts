const API_KEY = process.env.API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const PUBLIC_KEY = process.env.PUBLIC_KEY;
const CITADEL_NFT = process.env.CITADEL_NFT;
const PILOT_NFT = process.env.PILOT_NFT;
const DRAKMA_LOCK = process.env.DRAKMA_LOCK;
const DRAKMA_TOKEN = process.env.DRAKMA_TOKEN;

//npx hardhat run scripts/bridge/lock.js --network sepolia
async function main() {
    const Drakma = await ethers.getContractFactory("Drakma");
    const drakma = await Drakma.attach(DRAKMA_TOKEN);

    var balance = await drakma.balanceOf(PUBLIC_KEY);
    console.log("wallet balance: " + balance);
    
    const approveTx = await drakma.approve(DRAKMA_LOCK, "10000000000000000000");
    await approveTx.wait(); // Wait for confirmation

    const allowance = await drakma.allowance(PUBLIC_KEY, DRAKMA_LOCK);
    console.log("allowance:", allowance.toString());
    
    const DrakmaLock = await ethers.getContractFactory("DrakmaLock");
    const drakmaLock = await DrakmaLock.attach(DRAKMA_LOCK);

    await drakmaLock.lock(
      "10000000000000000000"
    );

}

main();