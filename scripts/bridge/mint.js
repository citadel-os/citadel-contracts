const API_KEY = process.env.API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const PUBLIC_KEY = process.env.PUBLIC_KEY;
const DRAKMA_TOKEN_BASE = process.env.DRAKMA_TOKEN_BASE;

//npx hardhat run scripts/bridge/mint.js --network basesepolia
async function main() {
    console.log("Starting");
    const DrakmaBase = await ethers.getContractFactory("DrakmaBase");
    const drakmaBase = await DrakmaBase.attach(DRAKMA_TOKEN_BASE);

        // 3. Define the recipients
    //    Replace these with valid addresses on your test network
    const address1 = PUBLIC_KEY;
    const address2 = "0xc0974aDf4d15DB9104eF68f01123d38a3a59bEc0";

    // 4. Define the amounts
    //    You can adjust the decimal places if your token has 18 decimals, for example:
    //    1 Drakma = 1 * 10^18 wei
    const amount1 = ethers.utils.parseUnits("1000", 18); // 1000 Drakma
    const amount2 = ethers.utils.parseUnits("2000", 18); // 2000 Drakma

    // 5. Call bulkMintDrakma
    console.log("Minting tokens in bulk...");
    const tx = await drakmaBase.bulkMintDrakma(
        [address1, address2], 
        [amount1, amount2]
    );

    // 6. Wait for the transaction to be mined
    await tx.wait();

    console.log("Transaction successful! Hash:", tx.hash);
    console.log(`Minted:
      ${ethers.utils.formatUnits(amount1, 18)} to ${address1},
      ${ethers.utils.formatUnits(amount2, 18)} to ${address2}.`);



}


main();