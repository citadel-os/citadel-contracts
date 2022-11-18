var chai = require("chai");
const expect = chai.expect;
const { BN, expectEvent, expectRevert } = require("@openzeppelin/test-helpers");
const { solidity } = require("ethereum-waffle");

chai.use(solidity);

// Start test block
describe("citadel relik", function () {
  const ETH_DIVISOR = 1000000000000000000;
  before(async function () {
    this.CitadelRelik = await ethers.getContractFactory("CitadelRelik");
  });

  beforeEach(async function () {
    this.citadelRelik = await this.CitadelRelik.deploy(
      "Citadel Relik",
      "Citadel Relik",
      "https://gateway.pinata.cloud/ipfs/QmUEWVbqGG31kVZqTBZsEYk3z26djBPMPxhHxuV3893kHX/"
    );
    await this.citadelRelik.deployed();
  });

  describe("minting", function () {
    it("gets max supply", async function () {
      var maxSupply = await this.citadelRelik.MAX_RELIK();
      expect(maxSupply.toNumber()).to.equal(64);
    });

    it("ensures contract has correct owner", async function () {
      const [owner] = await ethers.getSigners();
      expect(await this.citadelRelik.owner()).to.equal(await owner.address);
    });
  });

  describe("administration", function () {
    it("reserves citadel relik", async function () {
      [owner] = await ethers.getSigners();
      await this.citadelRelik.reserveRelik(10);

      var citadelBalance = await this.citadelRelik.balanceOf(owner.address);
      expect(citadelBalance.toNumber()).to.eq(10);
    });

    it("mints above cap, stops at cap", async function () {
      [owner, addr2] = await ethers.getSigners();

      await this.citadelRelik.reserveRelik(65);

      var citadelBalance = await this.citadelRelik.balanceOf(owner.address);
      expect(citadelBalance.toNumber()).to.eq(64);
    });

    it("adds dev address", async function () {
      [owner, addr2] = await ethers.getSigners();

      await this.citadelRelik.addDevRole(addr2.address);

      await this.citadelRelik.connect(addr2).reserveRelik(10);

      var citadelBalance = await this.citadelRelik.balanceOf(addr2.address);
      expect(citadelBalance.toNumber()).to.eq(10);
    });

    it("reverts add dev role from unauthed address", async function () {
      [owner, addr2] = await ethers.getSigners();

      await expectRevert(
        this.citadelRelik.connect(addr2).addDevRole(addr2.address),
        "must have dev role to add role"
      );
    });

    it("update token uri", async function () {
      [owner] = await ethers.getSigners();
      await this.citadelRelik.reserveRelik(10);

      var uri = await this.citadelRelik.tokenURI(1);
      expect(uri.search("QmUEWV")).to.be.greaterThan(0);

      var newURI = "https://citadel.pm/meta/";
      await this.citadelRelik.updateBaseURI(newURI);
      uri = await this.citadelRelik.tokenURI(1);
      expect(uri.search(newURI)).to.be.greaterThanOrEqual(0);
    });
  });
});
