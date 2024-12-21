const API_KEY = process.env.API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const PUBLIC_KEY = process.env.PUBLIC_KEY;
const CITADEL_NFT = process.env.CITADEL_NFT;
const PILOT_NFT = process.env.PILOT_NFT;
const DRAKMA_SENDER = process.env.DRAKMA_SENDER;
const DRAKMA_TOKEN = process.env.DRAKMA_TOKEN;

//npx hardhat run scripts/drakma-bridge/bridge.js --network sepolia
async function main() {
    const Drakma = await ethers.getContractFactory("Drakma");
    const drakma = await Drakma.attach(DRAKMA_TOKEN);

    var balance = await drakma.balanceOf(PUBLIC_KEY);
    console.log("wallet balance: " + balance);
    await drakma.approve(DRAKMA_SENDER, "10000000000000000000");

    const approveTx = await drakma.approve(DRAKMA_SENDER, "10000000000000000000");
    await approveTx.wait(); // Wait for confirmation

    const allowance = await drakma.allowance(PUBLIC_KEY, DRAKMA_SENDER);
    console.log("allowance:", allowance.toString());
    
    const DrakmaSenderBridge = await ethers.getContractFactory("DrakmaSenderBridge");
    const drakmaSenderBridge = await DrakmaSenderBridge.attach(DRAKMA_SENDER);

    await drakmaSenderBridge.bridge(
      "10000000000000000000"
    );

}

main();