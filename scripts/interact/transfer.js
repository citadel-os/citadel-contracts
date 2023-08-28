const API_KEY = process.env.API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const PUBLIC_KEY = process.env.PUBLIC_KEY;
const DRAKMA_ADDRESS = process.env.DRAKMA_ADDRESS;
const CITADEL_NFT = process.env.CITADEL_NFT;
const PILOT_NFT = process.env.PILOT_NFT;
const METAMASK_HOT = process.env.METAMASK_HOT;

const { ethers } = require("hardhat");

async function main() {

    const Drakma = await ethers.getContractFactory("Drakma");
    const drakma = await Drakma.attach(DRAKMA_ADDRESS);

    const Citadel = await ethers.getContractFactory("CitadelNFT");
    const citadel = await Citadel.attach(CITADEL_NFT);

    const Pilot = await ethers.getContractFactory("PilotNFT");
    const pilot = await Pilot.attach(PILOT_NFT);

    //jsays 0x17b0C91e4F925F9f7522949835e1DC3B202cd838
    // jobu 0xc71bdB836F0A84Fa33512e7896d9e281A751Fffa
    // adam 0x99a7F3037693B8d6236be052fAC344C4dC3175f3
    // chewie 0xd9E0DD027269cC23180dFA0aB911eDfFcaA65E81
    // vraxen 0x901a0c9edD093977Da063Cad05D957B33F8C5597
    // pakal 0xedd1f30d69898e4cb710cfb47c6114d31e6fed06
    // maximlp 0x5E2F0e40f4e6e43138525D11D91B4961F0933112
    // mugi boy0x35b7d03d4ef836068008f984df89284158722d71
    // adam 0x99a7F3037693B8d6236be052fAC344C4dC3175f3
    // ebum 0xB7ecF9E8167594C8145d16449dF72E1eaC38a0Db
    // chapel 0xC20dd98DE3dDb9c3C769fc294039cbE972e1f0c0
    // mrawkward
    // rybo 0x24922b2Fde313Be81b29C76e53dFA013E4F593B7
    const transferToAddress = "0x24922b2Fde313Be81b29C76e53dFA013E4F593B7";
    await drakma.mintDrakma(transferToAddress, "10000000000000000000000000"); //10M drakma
    await citadel.transferFrom(PUBLIC_KEY, transferToAddress, 40);
    await citadel.transferFrom(PUBLIC_KEY, transferToAddress, 41);
    await pilot.transferFrom(PUBLIC_KEY, transferToAddress, 60);
    await pilot.transferFrom(PUBLIC_KEY, transferToAddress, 61);
    console.log("transfered");

}

main()
.then(() => process.exit(0))
.catch((error) => {
  console.error(error);
  process.exit(1);
});