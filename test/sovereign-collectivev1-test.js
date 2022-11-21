const { expect } = require('chai');
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { ethers } = require('hardhat');


// Start test block
describe('sovereign collective', function () {
  before(async function () {
    this.CitadelNFT = await ethers.getContractFactory("CitadelNFT");
    this.PilotNFT = await ethers.getContractFactory("PilotNFT");
    this.Drakma = await ethers.getContractFactory("Drakma");
    this.CitadelExordium = await ethers.getContractFactory("CitadelExordium");
    this.Sovereign = await ethers.getContractFactory('SovereignCollectiveV1');
  });

  beforeEach(async function () {
    this.drakma = await this.Drakma.deploy();
    await this.drakma.deployed();
    this.citadelNFT = await this.CitadelNFT.deploy(
        "Citadel",
        "Citadel",
        "https://gateway.pinata.cloud/ipfs/QmUEWVbqGG31kVZqTBZsEYk3z26djBPMPxhHxuV3893kHX/"
      );
    await this.citadelNFT.deployed();
    this.citadelExordium = await this.CitadelExordium.deploy(
        this.citadelNFT.address,
        this.drakma.address
    );
    this.pilotNFT = await this.PilotNFT.deploy(
        this.drakma.address,
        this.citadelExordium.address,
        "https://gateway.pinata.cloud/ipfs/QmUEWVbqGG31kVZqTBZsEYk3z26djBPMPxhHxuV3893kHX/"
      );
    await this.pilotNFT.deployed();

    this.sovereign = await this.Sovereign.deploy(
        this.pilotNFT.address,
        this.drakma.address
      );
    await this.sovereign.deployed();


  });

    describe('administration', function () {
        it('withdraws drakma from contract', async function () {
            const [owner, addr2] = await ethers.getSigners();
            await this.drakma.mintDrakma(this.sovereign.address, 10000000);
            await this.sovereign.withdrawDrakma(10000000);
            var ownerBalance = await this.drakma.balanceOf(owner.address);
            expect(ownerBalance.toNumber()).to.equal(10000000);
        });

        it('reverts withdraw drakma request from non-owner account', async function() {
            const [owner, addr1] = await ethers.getSigners();
            await expectRevert(
                this.sovereign.connect(addr1).withdrawDrakma(1),
                "Ownable: caller is not the owner"
            );
        });
    });

    describe('claim', function () {
        it('claim happy path', async function () {
            const [owner, addr2] = await ethers.getSigners();
            await this.drakma.mintDrakma(this.sovereign.address, "128000000000000000000000000");

            await this.drakma.mintDrakma(owner.address, "8000000000000000000000000");
            await this.drakma.approve(this.pilotNFT.address, "8000000000000000000000000");
  
            await this.pilotNFT.reservePILOT(2);
  
            await this.pilotNFT.sovereignty(0);
            await this.pilotNFT.sovereignty(1);
            
            drakmaBalance = await this.drakma.balanceOf(owner.address);
            expect(Number(drakmaBalance.toString())).to.equal(0);

            await this.sovereign.claimSovereign(0);
            await this.sovereign.claimSovereign(1);

            drakmaBalance = await this.drakma.balanceOf(owner.address);
            expect(Number(drakmaBalance.toString())).to.equal(2000000000000000000000000);

            remainingClaims = await this.sovereign.getClaimsRemaining();
            expect(remainingClaims).to.equal(126);

            await this.drakma.mintDrakma(this.sovereign.address, "2000000000000000000000000");
            await this.sovereign.resetClaims();

            remainingClaims = await this.sovereign.getClaimsRemaining();
            expect(remainingClaims).to.equal(128);

            await this.sovereign.claimSovereign(0);
            await this.sovereign.claimSovereign(1);

            drakmaBalance = await this.drakma.balanceOf(owner.address);
            expect(Number(drakmaBalance.toString())).to.equal(4000000000000000000000000);

        });

        it('reverts claim of non-sovereign', async function () {
            const [owner, addr2] = await ethers.getSigners();
            await this.drakma.mintDrakma(this.sovereign.address, "128000000000000000000000000");

            await this.pilotNFT.reservePILOT(1);
            await expectRevert(
                this.sovereign.claimSovereign(0),
                "pilot must be sovereign to claim"
            );
        });

        it('reverts claim of pilot not owned', async function () {
            const [owner, addr2] = await ethers.getSigners();
            await this.drakma.mintDrakma(this.sovereign.address, "128000000000000000000000000");

            await this.pilotNFT.reservePILOT(1);
            await expectRevert(
                this.sovereign.connect(addr2).claimSovereign(0),
                "must own pilot to claim"
            );
        });

        it('reverts second claim of sovereign', async function () {
            const [owner, addr2] = await ethers.getSigners();
            await this.drakma.mintDrakma(this.sovereign.address, "128000000000000000000000000");

            await this.drakma.mintDrakma(owner.address, "4000000000000000000000000");
            await this.drakma.approve(this.pilotNFT.address, "4000000000000000000000000");
  
            await this.pilotNFT.reservePILOT(1);  
            await this.pilotNFT.sovereignty(0);
            await this.sovereign.claimSovereign(0);
            await expectRevert(
                this.sovereign.claimSovereign(0),
                "sovereign has already claimed"
            );
        });

    });
});