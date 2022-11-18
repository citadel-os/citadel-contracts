const API_KEY = process.env.API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const PUBLIC_KEY = process.env.PUBLIC_KEY;
const DRAKMA_ADDRESS = process.env.DRAKMA_ADDRESS;
const CITADEL_ADDRESS = process.env.PUBLIC_KEY;
const METAMASK_HOT = process.env.METAMASK_HOT;

const { ethers } = require("hardhat");

async function main() {

    console.log(DRAKMA_ADDRESS);
    const Drakma = await ethers.getContractFactory("Drakma");
    const drakma = await Drakma.attach(DRAKMA_ADDRESS);

    console.log("drakma address:" + DRAKMA_ADDRESS);
    var symbol = await drakma.symbol();
    var totalSupply = await drakma.totalSupply();
    console.log("drakma symbol is: " + symbol);
    console.log("total supply: " + totalSupply);

    await drakma.mintDrakma("0x68756A6df2280141b55189C7b3099F9e82c09eff", "100000000000000000000000000"); //1,000,000,000 drakma
    //await drakma.mintDrakma(PUBLIC_KEY, "1000000000000000000000"); // 1000 drakma

    var balance = await drakma.balanceOf(PUBLIC_KEY);
    console.log("wallet balance: " + balance);

}

main()
.then(() => process.exit(0))
.catch((error) => {
  console.error(error);
  process.exit(1);
});