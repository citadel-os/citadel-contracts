const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("deploying contracts with the account:", deployer.address);

  const weiAmount = (await deployer.getBalance()).toString();
  console.log("account balance:", await ethers.utils.formatEther(weiAmount));

  const CitadelRelik = await ethers.getContractFactory("CitadelRelik");
  const citadelRelik = await CitadelRelik.deploy(
    "CITADEL RELIK",
    "RELIK",
    "https://gateway.pinata.cloud/ipfs/QmTFtLkG63xCvDza6XHkFERKq5SatMz1oX9NdQUXDat2W1/"
  );
  console.log("nft contract deployed to address:", citadelRelik.address);

  const nextTokenId = await citadelRelik.getNextTokenId();
  console.log("next token id:", nextTokenId);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
