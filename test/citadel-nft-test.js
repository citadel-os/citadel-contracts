var chai = require("chai");
const expect = chai.expect;
const { BN, expectEvent, expectRevert } = require("@openzeppelin/test-helpers");
const { solidity } = require("ethereum-waffle");
const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");

chai.use(solidity);

// Start test block
describe("citadel nft", function () {
  whitelist = [
    "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266",
    "0x56DBD1086A7c9E3A3Aca1414fBA45a99d20Ef05F",
    "0x29d7d1dd5b6f9c864d9db560d72a247c178ae86b",
    "0xe4fEB387cB1dAff4bf9108581B116e5FA737Bea2",
    "0xDFd5293D8e347dFe59E90eFd55b2956a1343963d",
    "0x1eb026649B6ac698cBad1dA9abD5a8fD54E09132",
    "0x11b58341350ae2b89be7Fadf646F116803611B93",
    "0x70997970c51812dc3a010c7d01b50e0d17dc79c8",
  ];
  before(async function () {
    this.Citadel = await ethers.getContractFactory("CitadelNFT");
    const leafNodes = whitelist.map((addr) => keccak256(addr));
    const merkleTree = new MerkleTree(leafNodes, keccak256, {
      sortPairs: true,
    });

    const leaf1 = keccak256(whitelist[0]);
    this.hexProofAcct1 = merkleTree.getHexProof(leaf1);

    const leaf8 = keccak256(whitelist[7]);
    this.hexProofAcct8 = merkleTree.getHexProof(leaf8);
  });

  beforeEach(async function () {
    this.citadel = await this.Citadel.deploy(
      "Citadel",
      "Citadel",
      "https://gateway.pinata.cloud/ipfs/QmUEWVbqGG31kVZqTBZsEYk3z26djBPMPxhHxuV3893kHX/"
    );
    await this.citadel.deployed();
  });

  // describe("minting", function () {
  //   it("gets max supply", async function () {
  //     var maxSupply = await this.citadel.MAX_CITADEL();
  //     expect(maxSupply.toNumber()).to.equal(1024);
  //   });

  //   it("ensures contract has correct owner", async function () {
  //     const [owner] = await ethers.getSigners();
  //     expect(await this.citadel.owner()).to.equal(await owner.address);
  //   });

  //   it("mints a citadel", async function () {
  //     const [owner] = await ethers.getSigners();
  //     const tokenId = await this.citadel.totalSupply();

  //     expect(await this.citadel.mintCitadel(this.hexProofAcct1))
  //       .to.emit(this.citadel, "Transfer")
  //       .withArgs(ethers.constants.AddressZero, owner.address, tokenId);

  //     var citadelBalance = await this.citadel.balanceOf(owner.address);
  //     expect(citadelBalance.toNumber()).to.eq(1);
  //   });

  //   it("mints a citadel, fails to mint a second citadel", async function () {
  //     const [owner] = await ethers.getSigners();
  //     const tokenId = await this.citadel.totalSupply();

  //     expect(await this.citadel.mintCitadel(this.hexProofAcct1))
  //       .to.emit(this.citadel, "Transfer")
  //       .withArgs(ethers.constants.AddressZero, owner.address, tokenId);

  //     var citadelBalance = await this.citadel.balanceOf(owner.address);
  //     expect(citadelBalance.toNumber()).to.eq(1);

  //     await expectRevert(
  //       this.citadel.mintCitadel(this.hexProofAcct1),
  //       "ADDRESS_CLAIMED"
  //     );

  //     var citadelBalance = await this.citadel.balanceOf(owner.address);
  //     expect(citadelBalance.toNumber()).to.eq(1);
  //   });

  //   it("fails to mint citadel with stolen proof", async function () {
  //     const [owner, addr2] = await ethers.getSigners();

  //     await expectRevert(
  //       this.citadel.connect(addr2).mintCitadel(this.hexProofAcct1),
  //       "INVALID_PROOF"
  //     );

  //     var citadelBalance = await this.citadel
  //       .connect(addr2)
  //       .balanceOf(owner.address);
  //     expect(citadelBalance.toNumber()).to.eq(0);
  //   });

  //   it("mints citadel from address2", async function () {
  //     const [owner, addr2] = await ethers.getSigners();
  //     const tokenId = await this.citadel.totalSupply();

  //     expect(await this.citadel.connect(addr2).mintCitadel(this.hexProofAcct8))
  //       .to.emit(this.citadel, "Transfer")
  //       .withArgs(ethers.constants.AddressZero, addr2.address, tokenId);

  //     var citadelBalance = await this.citadel
  //       .connect(addr2)
  //       .balanceOf(addr2.address);
  //     expect(citadelBalance.toNumber()).to.eq(1);
  //   });

  //   it("reverts mint of citadel from address3, not on whitelist", async function () {
  //     const [owner, addr2, addr3] = await ethers.getSigners();

  //     await expectRevert(
  //       this.citadel.connect(addr3).mintCitadel([]),
  //       "INVALID_PROOF"
  //     );

  //     var citadelBalance = await this.citadel
  //       .connect(addr3)
  //       .balanceOf(addr3.address);
  //     expect(citadelBalance.toNumber()).to.eq(0);
  //   });

  //   it("update merkle root, mint citadel acct 4", async function () {
  //     [owner, addr2, addr3, addr4] = await ethers.getSigners();
  //     const tokenId = await this.citadel.totalSupply();

  //     await this.citadel.updateMerkleRoot(
  //       "0xfc75de997a507fbe5e55a49259e30e7670c36f09677014b2f434bf6a5ccea7ba"
  //     );

  //     var whitelist2 = [
  //       "0x90f79bf6eb2c4f870365e785982e1f101e93b906",
  //       "0x15d34aaf54267db7d7c367839aaf71a00a2c6a65",
  //       "0x9965507d1a55bcc2695c58ba16fb37d819b0a4dc",
  //       "0x976ea74026e726554db657fa54763abd0c3a0aa9",
  //     ];

  //     const leafNodes = whitelist2.map((addr) => keccak256(addr));
  //     const merkleTree = new MerkleTree(leafNodes, keccak256, {
  //       sortPairs: true,
  //     });

  //     leaf = keccak256(whitelist2[0]);
  //     const hexProofAcct4 = merkleTree.getHexProof(leaf);

  //     expect(await this.citadel.connect(addr4).mintCitadel(hexProofAcct4))
  //       .to.emit(this.citadel, "Transfer")
  //       .withArgs(ethers.constants.AddressZero, addr4.address, tokenId);

  //     var citadelBalance = await this.citadel
  //       .connect(addr4)
  //       .balanceOf(addr4.address);
  //     expect(citadelBalance.toNumber()).to.eq(1);
  //   });
  // });

  describe("administration", function () {
    it("reserves citadel", async function () {
      [owner] = await ethers.getSigners();
      await this.citadel.reserveCitadel(10);

      var citadelBalance = await this.citadel.balanceOf(owner.address);
      expect(citadelBalance.toNumber()).to.eq(10);
    });

    it("update token uri", async function () {
      [owner] = await ethers.getSigners();
      await this.citadel.reserveCitadel(10);

      var uri = await this.citadel.tokenURI(1);
      expect(uri.search("QmUEWV")).to.be.greaterThan(0);

      var newURI = "https://citadel.pm/meta/";
      await this.citadel.updateBaseURI(newURI);
      uri = await this.citadel.tokenURI(1);
      expect(uri.search(newURI)).to.be.greaterThanOrEqual(0);
    });
  });

  describe("citadel utility", function () {
    it("uplevels a citadel on-chain", async function () {
      [owner, addr2] = await ethers.getSigners();
      await this.citadel.reserveCitadel(10);

      var citadelBalance = await this.citadel.balanceOf(owner.address);
      expect(citadelBalance.toNumber()).to.eq(10);

      var citadelLevel = await this.citadel.level(1);
      expect(citadelLevel.toNumber()).to.eq(0);

      //uplevel citadel
      await this.citadel.changeLevel(1, 1);
      var citadelLevel = await this.citadel.level(1);
      expect(citadelLevel.toNumber()).to.eq(1);

      //downlevel citadel
      await this.citadel.changeLevel(0, 1);
      var citadelLevel = await this.citadel.level(1);
      expect(citadelLevel.toNumber()).to.eq(0);

      //uplevel beyond bounds citadel
      await expectRevert(
        this.citadel.changeLevel(10, 1),
        "MAX_LEVEL"
      );

      //uplevel citadel from non dev account
      await expectRevert(
        this.citadel.connect(addr2).changeLevel(1, 1),
        "Ownable: caller is not the owner"
      );
    });
  });
});
