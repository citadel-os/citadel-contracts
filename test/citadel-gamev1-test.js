var chai = require("chai");
const expect = chai.expect;
const { BN, expectEvent, expectRevert } = require("@openzeppelin/test-helpers");
const { solidity } = require("ethereum-waffle");
const { ethers } = require("hardhat");

chai.use(solidity);

describe("citadel game v1", function () {

    before(async function () {
        this.CitadelNFT = await ethers.getContractFactory("CitadelNFT");
        this.PilotNFT = await ethers.getContractFactory("PilotNFT");
        this.Drakma = await ethers.getContractFactory("Drakma");
        this.CitadelExordium = await ethers.getContractFactory("CitadelExordium");
        this.CombatEngineV1 = await ethers.getContractFactory("CombatEngineV1");
        this.CitadelGameV1 = await ethers.getContractFactory("CitadelGameV1");
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
      await this.citadelExordium.deployed();

      this.pilotNFT = await this.PilotNFT.deploy(
          this.drakma.address,
          this.citadelExordium.address,
          "https://gateway.pinata.cloud/ipfs/QmUEWVbqGG31kVZqTBZsEYk3z26djBPMPxhHxuV3893kHX/"
        );
      await this.pilotNFT.deployed();

      this.combatEngineV1 = await this.CombatEngineV1.deploy(
        this.pilotNFT.address
      );
      await this.combatEngineV1.deployed();

      this.citadelGameV1 = await this.CitadelGameV1.deploy(
        this.citadelNFT.address,
        this.pilotNFT.address,
        this.drakma.address,
        this.combatEngineV1.address
      );
      await this.citadelGameV1.deployed();

      await this.drakma.mintDrakma(this.citadelGameV1.address, "2400000000000000000000000000");
    });
    
    describe("lite to grid", function () {

      beforeEach(async function () {
        await this.pilotNFT.reservePILOT(256);
        await this.citadelNFT.reserveCitadel(1024);
      });

      it("lites a citadel and 2 pilot to grid", async function () {
        [owner, addr1] = await ethers.getSigners();
        await this.citadelNFT.approve(this.citadelGameV1.address, 40);
        await this.pilotNFT.approve(this.citadelGameV1.address, 1);
        await this.pilotNFT.approve(this.citadelGameV1.address, 2);

        await this.citadelGameV1.liteGrid(40, [1,2], 512, 1);
        
        ownerOfCitadel40 = await this.citadelNFT.ownerOf(40);
        expect(ownerOfCitadel40).to.equal(this.citadelGameV1.address);
        
        ownerOfPilot1 = await this.pilotNFT.ownerOf(1);
        expect(ownerOfPilot1).to.equal(this.citadelGameV1.address);

        ownerOfPilot2 = await this.pilotNFT.ownerOf(2);
        expect(ownerOfPilot2).to.equal(this.citadelGameV1.address);

        [
          walletAddress,
          gridId,
          factionId,
          pilotCount,
          isLit,
          fleetPoints
        ] = await this.citadelGameV1.getCitadel(40);
        expect(walletAddress).to.equal(owner.address);
        expect(gridId).to.equal(512);
        expect(factionId).to.equal(1);
        expect(pilotCount).to.equal(2);
        expect(isLit).to.equal(true);
        expect(fleetPoints).to.equal(0);

        [
          timeOfLastClaim,
          timeOfLastRaid,
          timeOfLastRaidClaim,
          unclaimedDrakma,
          isOnline,
          timeWentOffline
        ] = await this.citadelGameV1.getCitadelMining(40);
        expect(Number(timeOfLastClaim.toString())).to.be.greaterThan(0);
        expect(Number(timeOfLastRaid.toString())).to.be.greaterThan(0);
        expect(Number(timeOfLastRaidClaim.toString())).to.be.greaterThan(0);
        expect(unclaimedDrakma).to.equal(0);
        expect(isOnline).to.equal(true);
        expect(timeWentOffline).to.equal(0);
      });

      it("reverts unowned citadel staked", async function () {
        [owner, addr1] = await ethers.getSigners();

        await expectRevert(
          this.citadelGameV1.connect(addr1).liteGrid(40, [1,2], 512, 1),
          "must own citadel to stake"
        );
      });

      it("reverts unowned pilot staked", async function () {
        [owner, addr1] = await ethers.getSigners();

        await this.citadelNFT.transferFrom(owner.address, addr1.address, 40);
        await this.pilotNFT.transferFrom(owner.address, addr1.address, 1);
        await this.citadelNFT.connect(addr1).approve(this.citadelGameV1.address, 40);
        await this.pilotNFT.connect(addr1).approve(this.citadelGameV1.address, 1);

        await expectRevert(
          this.citadelGameV1.connect(addr1).liteGrid(40, [1,2], 512, 1),
          "must own pilot to stake"
        );
      });

      it("reverts invalid grid", async function () {
        [owner, addr1] = await ethers.getSigners();
        await this.citadelNFT.approve(this.citadelGameV1.address, 40);
        await this.pilotNFT.approve(this.citadelGameV1.address, 1);
        await this.pilotNFT.approve(this.citadelGameV1.address, 2);

        await expectRevert(
          this.citadelGameV1.liteGrid(40, [1,2], 5000, 1),
          "invalid grid"
        );
      });

      it("reverts invalid faction", async function () {
        [owner, addr1] = await ethers.getSigners();
        await this.citadelNFT.approve(this.citadelGameV1.address, 40);
        await this.pilotNFT.approve(this.citadelGameV1.address, 1);
        await this.pilotNFT.approve(this.citadelGameV1.address, 2);

        await expectRevert(
          this.citadelGameV1.liteGrid(40, [1,2], 512, 7),
          "invalid faction"
        );
      });
      
      it("reverts stake to lit grid", async function () {
        [owner, addr1] = await ethers.getSigners();

        await this.citadelNFT.approve(this.citadelGameV1.address, 40);
        await this.pilotNFT.approve(this.citadelGameV1.address, 1);
        await this.pilotNFT.approve(this.citadelGameV1.address, 2);

        await this.citadelGameV1.liteGrid(40, [1,2], 512, 1);

        await this.citadelNFT.approve(this.citadelGameV1.address, 41);

        await expectRevert(
          this.citadelGameV1.liteGrid(41, [], 512, 1),
          "grid already lit"
        );
      });
    });

    describe.only("dims from grid", function () {

      beforeEach(async function () {
        await this.pilotNFT.reservePILOT(256);
        await this.citadelNFT.reserveCitadel(1024);
      });

      it("withdraws citadel and pilot from grid", async function () {
        [owner, addr1] = await ethers.getSigners();

        await this.citadelNFT.approve(this.citadelGameV1.address, 40);
        await this.pilotNFT.approve(this.citadelGameV1.address, 1);
        await this.pilotNFT.approve(this.citadelGameV1.address, 2);

        await this.citadelGameV1.liteGrid(40, [1,2], 512, 1);
        ownerOfCitadel40 = await this.citadelNFT.ownerOf(40);
        expect(ownerOfCitadel40).to.equal(this.citadelGameV1.address);
        
        ownerOfPilot1 = await this.pilotNFT.ownerOf(1);
        expect(ownerOfPilot1).to.equal(this.citadelGameV1.address);

        ownerOfPilot2 = await this.pilotNFT.ownerOf(2);
        expect(ownerOfPilot2).to.equal(this.citadelGameV1.address);

        var gridLit = await this.citadelGameV1.getGrid(512);
        expect(gridLit).to.equal(true);

        await this.citadelGameV1.dimGrid(40);
        ownerOfCitadel40 = await this.citadelNFT.ownerOf(40);
        expect(ownerOfCitadel40).to.equal(owner.address);
        
        ownerOfPilot1 = await this.pilotNFT.ownerOf(1);
        expect(ownerOfPilot1).to.equal(owner.address);

        ownerOfPilot2 = await this.pilotNFT.ownerOf(2);
        expect(ownerOfPilot2).to.equal(owner.address);

        var drakmaBalance = await this.drakma.balanceOf(owner.address);
        expect(Number(drakmaBalance.toString())).to.be.greaterThan(0);

        [
          walletAddress,
          gridId,
          factionId,
          pilotCount,
          isLit,
          fleetPoints
        ] = await this.citadelGameV1.getCitadel(40);
        expect(walletAddress).to.equal("0x0000000000000000000000000000000000000000");
        expect(gridId).to.equal(0);
        expect(factionId).to.equal(0);
        expect(pilotCount).to.equal(0);
        expect(isLit).to.equal(false);
        expect(fleetPoints).to.equal(0);

        [
          timeOfLastClaim,
          timeOfLastRaid,
          timeOfLastRaidClaim,
          unclaimedDrakma,
          isOnline,
          timeWentOffline
        ] = await this.citadelGameV1.getCitadelMining(40);
        expect(Number(timeOfLastClaim.toString())).to.equal(0);
        expect(Number(timeOfLastRaid.toString())).to.equal(0);
        expect(Number(timeOfLastRaidClaim.toString())).to.equal(0);
        expect(unclaimedDrakma).to.equal(0);
        expect(isOnline).to.equal(false);
        expect(timeWentOffline).to.equal(0);

        gridLit = await this.citadelGameV1.getGrid(512);
        expect(gridLit).to.equal(false);
      });

      it("reverts dim of unowned citadel", async function () {
        [owner, addr1] = await ethers.getSigners();

        await this.citadelNFT.approve(this.citadelGameV1.address, 40);
        await this.pilotNFT.approve(this.citadelGameV1.address, 1);
        await this.pilotNFT.approve(this.citadelGameV1.address, 2);

        await this.citadelGameV1.liteGrid(40, [1,2], 512, 1);


        await expectRevert(
          this.citadelGameV1.connect(addr1).dimGrid(40),
          "must own lit citadel to withdraw"
        );

        ownerOfCitadel40 = await this.citadelNFT.ownerOf(40);
        expect(ownerOfCitadel40).to.equal(this.citadelGameV1.address);
        
        ownerOfPilot1 = await this.pilotNFT.ownerOf(1);
        expect(ownerOfPilot1).to.equal(this.citadelGameV1.address);

        ownerOfPilot2 = await this.pilotNFT.ownerOf(2);
        expect(ownerOfPilot2).to.equal(this.citadelGameV1.address);
      });
    });


});