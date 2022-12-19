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
          isOnline
        ] = await this.citadelGameV1.getCitadelMining(40);
        expect(Number(timeOfLastClaim.toString())).to.be.greaterThan(0);
        expect(Number(timeOfLastRaid.toString())).to.be.greaterThan(0);
        expect(Number(timeOfLastRaidClaim.toString())).to.be.greaterThan(0);
        expect(unclaimedDrakma).to.equal(0);
        expect(isOnline).to.equal(true);
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

    describe("dims from grid", function () {

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
          isOnline
        ] = await this.citadelGameV1.getCitadelMining(40);
        expect(Number(timeOfLastClaim.toString())).to.equal(0);
        expect(Number(timeOfLastRaid.toString())).to.equal(0);
        expect(Number(timeOfLastRaidClaim.toString())).to.equal(0);
        expect(unclaimedDrakma).to.equal(0);
        expect(isOnline).to.equal(false);

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

      it("reverts dim of unlit citadel", async function () {
        [owner, addr1] = await ethers.getSigners();

        await this.citadelNFT.approve(this.citadelGameV1.address, 40);

        await expectRevert(
          this.citadelGameV1.dimGrid(40),
          "must own lit citadel to withdraw"
        );

        ownerOfCitadel40 = await this.citadelNFT.ownerOf(40);
        expect(ownerOfCitadel40).to.equal(owner.address);

        var drakmaBalance = await this.drakma.balanceOf(owner.address);
        expect(Number(drakmaBalance.toString())).to.equal(0);
        
      });
    });

    describe("claims drakma from grid", function () {

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

        await this.citadelGameV1.claim(40);
        ownerOfCitadel40 = await this.citadelNFT.ownerOf(40);
        expect(ownerOfCitadel40).to.equal(this.citadelGameV1.address);

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
          isOnline
        ] = await this.citadelGameV1.getCitadelMining(40);
        expect(Number(timeOfLastClaim.toString())).to.be.greaterThan(0);
        expect(Number(timeOfLastRaid.toString())).to.be.greaterThan(0);
        expect(Number(timeOfLastRaidClaim.toString())).to.be.greaterThan(0);
        expect(unclaimedDrakma).to.equal(0);
        expect(isOnline).to.equal(true);

        gridLit = await this.citadelGameV1.getGrid(512);
        expect(gridLit).to.equal(true);
      });

      it("reverts claim of unowned citadel", async function () {
        [owner, addr1] = await ethers.getSigners();

        await this.citadelNFT.approve(this.citadelGameV1.address, 40);
        await this.pilotNFT.approve(this.citadelGameV1.address, 1);
        await this.pilotNFT.approve(this.citadelGameV1.address, 2);

        await this.citadelGameV1.liteGrid(40, [1,2], 512, 1);


        await expectRevert(
          this.citadelGameV1.connect(addr1).claim(40),
          "must own citadel to claim"
        );

        ownerOfCitadel40 = await this.citadelNFT.ownerOf(40);
        expect(ownerOfCitadel40).to.equal(this.citadelGameV1.address);
        
        ownerOfPilot1 = await this.pilotNFT.ownerOf(1);
        expect(ownerOfPilot1).to.equal(this.citadelGameV1.address);

        ownerOfPilot2 = await this.pilotNFT.ownerOf(2);
        expect(ownerOfPilot2).to.equal(this.citadelGameV1.address);
      });

      it("reverts claim of dim citadel", async function () {
        [owner, addr1] = await ethers.getSigners();

        await expectRevert(
          this.citadelGameV1.connect(addr1).claim(40),
          "must own citadel to claim"
        );
      });
    });

    describe("train fleet", function () {
      var sifGattacaPrice = 0; //20
      var mhrudvogThrotPrice = 0; //40
      var drebentraakhtPrice = 0; //800

      beforeEach(async function () {
        await this.pilotNFT.reservePILOT(256);
        await this.citadelNFT.reserveCitadel(1024);
        sifGattacaPrice = await this.citadelGameV1.sifGattacaPrice();
        mhrudvogThrotPrice = await this.citadelGameV1.mhrudvogThrotPrice();
        drebentraakhtPrice = await this.citadelGameV1.drebentraakhtPrice();
      });

      /*
        1000 sif gattaca = 20000 dk
        200 mhrudvog throt = 8000 dk
        50 drebentraakht = 40000 dk
        68000 total dk
      */
      it("trains 1250 fleet", async function () {
        [owner, addr1] = await ethers.getSigners();

        await this.drakma.mintDrakma(owner.address, "68000000000000000000000");
        await this.drakma.approve(this.citadelGameV1.address, "68000000000000000000000");

        await this.citadelNFT.approve(this.citadelGameV1.address, 40);
        await this.pilotNFT.approve(this.citadelGameV1.address, 1);
        await this.pilotNFT.approve(this.citadelGameV1.address, 2);

        await this.citadelGameV1.liteGrid(40, [1,2], 512, 1);

        await this.citadelGameV1.trainFleet(40, 1000, 200, 50);

        var drakmaBalance = await this.drakma.balanceOf(owner.address);
        expect(Number(drakmaBalance.toString())).to.equal(0);

        [
          sifGattaca,
          mhrudvogThrot,
          drebentraakht
        ] = await this.citadelGameV1.getCitadelFleetCount(40);
        expect(sifGattaca).to.equal(10);
        expect(mhrudvogThrot).to.equal(2);
        expect(drebentraakht).to.equal(0);

        [
          sifGattaca,
          mhrudvogThrot,
          drebentraakht
        ] = await this.citadelGameV1.getCitadelFleetCountTraining(40);
        expect(sifGattaca).to.equal(1000);
        expect(mhrudvogThrot).to.equal(200);
        expect(drebentraakht).to.equal(50);
      });
      
      /*
        2000 sif gattaca = 40000 dk
        200 mhrudvog throt = 16000 dk
        50 drebentraakht = 80000 dk
        136000 total dk
      */
      it("reverts double train of fleet", async function () {
        [owner, addr1] = await ethers.getSigners();

        await this.drakma.mintDrakma(owner.address, "136000000000000000000000");
        await this.drakma.approve(this.citadelGameV1.address, "136000000000000000000000");

        await this.citadelNFT.approve(this.citadelGameV1.address, 40);
        await this.pilotNFT.approve(this.citadelGameV1.address, 1);
        await this.pilotNFT.approve(this.citadelGameV1.address, 2);

        await this.citadelGameV1.liteGrid(40, [1,2], 512, 1);

        await this.citadelGameV1.trainFleet(40, 1000, 200, 50);

        var drakmaBalance = await this.drakma.balanceOf(owner.address);
        expect(Number(drakmaBalance.toString())).to.equal(68000000000000000000000);

        [
          sifGattaca,
          mhrudvogThrot,
          drebentraakht
        ] = await this.citadelGameV1.getCitadelFleetCount(40);
        expect(sifGattaca).to.equal(10);
        expect(mhrudvogThrot).to.equal(2);
        expect(drebentraakht).to.equal(0);

        [
          sifGattaca,
          mhrudvogThrot,
          drebentraakht
        ] = await this.citadelGameV1.getCitadelFleetCountTraining(40);
        expect(sifGattaca).to.equal(1000);
        expect(mhrudvogThrot).to.equal(200);
        expect(drebentraakht).to.equal(50);

        await expectRevert(
          this.citadelGameV1.trainFleet(40, 1000, 200, 50),
          "cannot train new fleet until previous has finished"
        );

        var drakmaBalance = await this.drakma.balanceOf(owner.address);
        expect(Number(drakmaBalance.toString())).to.equal(68000000000000000000000);

        [
          sifGattaca,
          mhrudvogThrot,
          drebentraakht
        ] = await this.citadelGameV1.getCitadelFleetCount(40);
        expect(sifGattaca).to.equal(10);
        expect(mhrudvogThrot).to.equal(2);
        expect(drebentraakht).to.equal(0);

        [
          sifGattaca,
          mhrudvogThrot,
          drebentraakht
        ] = await this.citadelGameV1.getCitadelFleetCountTraining(40);
        expect(sifGattaca).to.equal(1000);
        expect(mhrudvogThrot).to.equal(200);
        expect(drebentraakht).to.equal(50);
      });


    });

    describe.only("raiding", function () {

      beforeEach(async function () {
        [owner, addr1] = await ethers.getSigners();
        await this.pilotNFT.reservePILOT(256);
        await this.citadelNFT.reserveCitadel(1024);

        await this.citadelNFT.approve(this.citadelGameV1.address, 40);
        await this.citadelGameV1.liteGrid(40, [], 512, 1);

        await this.citadelNFT.approve(this.citadelGameV1.address, 1021);
        await this.pilotNFT.approve(this.citadelGameV1.address, 1);
        await this.pilotNFT.approve(this.citadelGameV1.address, 2);
        await this.pilotNFT.approve(this.citadelGameV1.address, 5);
        await this.pilotNFT.approve(this.citadelGameV1.address, 6);
        await this.citadelGameV1.liteGrid(1021, [1,2,5,6], 1, 1);

        await this.citadelNFT.transferFrom(owner.address, addr1.address, 1023);
        await this.pilotNFT.transferFrom(owner.address, addr1.address, 3);
        await this.pilotNFT.transferFrom(owner.address, addr1.address, 4);
        await this.citadelNFT.connect(addr1).approve(this.citadelGameV1.address, 1023);
        await this.pilotNFT.connect(addr1).approve(this.citadelGameV1.address, 3);
        await this.pilotNFT.connect(addr1).approve(this.citadelGameV1.address, 4);

        await this.citadelGameV1.connect(addr1).liteGrid(1023, [3,4], 513, 2);

      });

      it("sends raid from 40 to 1023", async function () {
        [owner, addr1] = await ethers.getSigners();

        await this.citadelGameV1.sendRaid(40, 1023, [], 10, 0, 0);

        [
          sifGattaca40,
          mhrudvogThrot40,
          drebentraakht40
        ] = await this.citadelGameV1.getCitadelFleetCount(40);
        expect(Number(sifGattaca40.toString())).to.be.lessThan(10);
        expect(Number(mhrudvogThrot40.toString())).to.equal(2);
        expect(Number(drebentraakht40.toString())).to.equal(0);

        [
          sifGattaca1023,
          mhrudvogThrot1023,
          drebentraakht1023
        ] = await this.citadelGameV1.getCitadelFleetCount(1023);
        expect(Number(sifGattaca1023.toString())).to.be.lessThan(10);
        expect(Number(mhrudvogThrot1023.toString())).to.be.lessThanOrEqual(2);
        expect(Number(drebentraakht1023.toString())).to.equal(0);

      });

      it("sends raid from 1023 to 40", async function () {
        [owner, addr1] = await ethers.getSigners();

        await this.citadelGameV1.connect(addr1).sendRaid(1023, 40, [3,4], 10, 0, 0);

        [
          sifGattaca1023,
          mhrudvogThrot1023,
          drebentraakht1023
        ] = await this.citadelGameV1.getCitadelFleetCount(1023);
        expect(Number(sifGattaca1023.toString())).to.be.lessThan(10);
        expect(Number(mhrudvogThrot1023.toString())).to.be.lessThanOrEqual(2);
        expect(Number(drebentraakht1023.toString())).to.equal(0);

        [
          sifGattaca40,
          mhrudvogThrot40,
          drebentraakht40
        ] = await this.citadelGameV1.getCitadelFleetCount(40);
        expect(Number(sifGattaca40.toString())).to.be.lessThan(10);
        expect(Number(mhrudvogThrot40.toString())).to.be.lessThanOrEqual(2);
        expect(Number(drebentraakht40.toString())).to.equal(0);

        [
          timeOfLastClaim40,
          timeOfLastRaid40,
          timeOfLastRaidClaim40,
          unclaimedDrakma40,
          isOnline40
        ] = await this.citadelGameV1.getCitadelMining(40);
        expect(Number(unclaimedDrakma40.toString())).to.equal(0);
        expect(isOnline40).to.equal(true);

        [
          timeOfLastClaim1023,
          timeOfLastRaid1023,
          timeOfLastRaidClaim1023,
          unclaimedDrakma1023,
          isOnline1023
        ] = await this.citadelGameV1.getCitadelMining(1023);
        expect(Number(unclaimedDrakma1023.toString())).to.be.greaterThan(0);
        expect(isOnline1023).to.equal(true);

        drakmaAddr1 = await this.drakma.balanceOf(addr1.address);
        expect(Number(drakmaAddr1.toString())).to.be.greaterThan(0);


      });

    });


});