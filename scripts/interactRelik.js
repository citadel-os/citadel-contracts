const API_KEY = process.env.API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const PUBLIC_KEY = process.env.PUBLIC_KEY;
const CITADEL_RELIK = process.env.CITADEL_RELIK;

async function main() {
  const CitadelRelik = await ethers.getContractFactory("CitadelRelik");
  const citadelRelik = await CitadelRelik.attach(CITADEL_RELIK);

  await citadelRelik.reserveRelik(12);
  // await citadelRelik.updateBaseURI(
  //   "https://gateway.pinata.cloud/ipfs/QmTFtLkG63xCvDza6XHkFERKq5SatMz1oX9NdQUXDat2W1/"
  // );
  const nextTokenId = await citadelRelik.getNextTokenId();
  console.log(nextTokenId);
}

main();
