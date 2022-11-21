const API_KEY = process.env.API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const PUBLIC_KEY = process.env.PUBLIC_KEY;
const CITADEL_NFT = process.env.CITADEL_NFT;

async function main() {
  const CitadelNFT = await ethers.getContractFactory("CitadelNFT");
  const citadelNFT = await CitadelNFT.attach(CITADEL_NFT);

  await citadelNFT.updateBaseURI(
    "https://gateway.pinata.cloud/ipfs/QmXXC2PHUeiFtUFVdLNnYodWUNdZnK2jbT8prE6R51mGT6/"
  );

  // await citadelNFT.reserveCitadel(1024);


}

main();
