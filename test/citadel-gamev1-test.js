var chai = require("chai");
const expect = chai.expect;
const { BN, expectEvent, expectRevert } = require("@openzeppelin/test-helpers");
require('@openzeppelin/test-helpers/configure')({
  provider: 'http://127.0.0.1:8545',
});
const { solidity } = require("ethereum-waffle");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

chai.use(solidity);

describe("citadel game v1", function () {

    before(async function () {
        this.CitadelNFT = await ethers.getContractFactory("CitadelNFT");
        this.PilotNFT = await ethers.getContractFactory("PilotNFT");
        this.Drakma = await ethers.getContractFactory("Drakma");
        this.CitadelExordium = await ethers.getContractFactory("CitadelExordium");
        this.CombatEngineV1 = await ethers.getContractFactory("CombatEngineV1");
        this.CitadelFleetV1 = await ethers.getContractFactory("CitadelFleetV1");
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

      this.citadelFleetV1 = await this.CitadelFleetV1.deploy(
        this.drakma.address
      );
      await this.citadelFleetV1.deployed();

      this.citadelGameV1 = await this.CitadelGameV1.deploy(
        this.citadelNFT.address,
        this.pilotNFT.address,
        this.drakma.address,
        this.combatEngineV1.address,
        this.citadelFleetV1.address
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
        ] = await this.citadelGameV1.getCitadel(40);
        expect(walletAddress).to.equal(owner.address);
        expect(gridId).to.equal(512);
        expect(factionId).to.equal(1);
        expect(pilotCount).to.equal(2);

        [
          timeLit,
          timeOfLastClaim,
          timeLastRaided,
          unclaimedDrakma
        ] = await this.citadelGameV1.getCitadelMining(40);
        expect(Number(timeOfLastClaim.toString())).to.equal(0);
        expect(Number(timeLit.toString())).to.be.greaterThan(0);
        expect(unclaimedDrakma).to.equal(0);
      });

      it("reverts unowned citadel staked", async function () {
        [owner, addr1] = await ethers.getSigners();

        await expectRevert(
          this.citadelGameV1.connect(addr1).liteGrid(40, [1,2], 512, 1),
          "must own citadel"
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

    describe("dims grid", function () {

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

        [
          walletAddress,
          gridId,
          factionId,
          pilotCount
        ] = await this.citadelGameV1.getCitadel(40);
        expect(walletAddress).to.equal("0x0000000000000000000000000000000000000000");
        expect(gridId).to.equal(0);
        expect(factionId).to.equal(0);
        expect(pilotCount).to.equal(0);

        [
          timeLit,
          timeOfLastClaim,
          timeLastRaided,
          unclaimedDrakma
        ] = await this.citadelGameV1.getCitadelMining(40);
        expect(Number(timeOfLastClaim.toString())).to.equal(0);
        expect(unclaimedDrakma).to.equal(0);

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
          "must own citadel"
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
          "must own citadel"
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
          pilotCount
        ] = await this.citadelGameV1.getCitadel(40);
        expect(walletAddress).to.equal(owner.address);
        expect(gridId).to.equal(512);
        expect(factionId).to.equal(1);
        expect(pilotCount).to.equal(2);

        [
          timeLit,
          timeOfLastClaim,
          timeLastRaided,
          unclaimedDrakma
        ] = await this.citadelGameV1.getCitadelMining(40);
        expect(Number(timeOfLastClaim.toString())).to.be.greaterThan(0);
        expect(unclaimedDrakma).to.equal(0);

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
          "must own citadel"
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
          "must own citadel"
        );
      });

      it("reverts second claim inside interval", async function () {
        [owner, addr1] = await ethers.getSigners();

        await this.citadelNFT.approve(this.citadelGameV1.address, 40);
        await this.citadelGameV1.liteGrid(40, [], 512, 1);
        await this.citadelGameV1.claim(40);

        await expectRevert(
          this.citadelGameV1.claim(40),
          "one claim per interval permitted"
        );
      });
    });

    describe("raiding", function () {

      beforeEach(async function () {
        [owner, addr1] = await ethers.getSigners();
        await this.pilotNFT.reservePILOT(256);
        await this.citadelNFT.reserveCitadel(1024);

        await this.citadelNFT.approve(this.citadelGameV1.address, 40);
        await this.citadelGameV1.liteGrid(40, [], 512, 1);
        await this.drakma.mintDrakma(owner.address, "20000000000000000000");
        await this.drakma.approve(this.citadelFleetV1.address, "20000000000000000000");
        await this.citadelFleetV1.trainFleet(40, 1, 0, 0);

        await this.citadelNFT.approve(this.citadelGameV1.address, 1021);
        await this.pilotNFT.approve(this.citadelGameV1.address, 1);
        await this.pilotNFT.approve(this.citadelGameV1.address, 2);
        await this.pilotNFT.approve(this.citadelGameV1.address, 5);
        await this.pilotNFT.approve(this.citadelGameV1.address, 6);
        await this.citadelGameV1.liteGrid(1021, [1,2,5,6], 1, 1);
        await this.drakma.mintDrakma(owner.address, "20000000000000000000");
        await this.drakma.approve(this.citadelFleetV1.address, "20000000000000000000");
        await this.citadelFleetV1.trainFleet(1021, 1, 0, 0);

        await this.citadelNFT.transferFrom(owner.address, addr1.address, 1023);
        await this.pilotNFT.transferFrom(owner.address, addr1.address, 3);
        await this.pilotNFT.transferFrom(owner.address, addr1.address, 4);
        await this.citadelNFT.connect(addr1).approve(this.citadelGameV1.address, 1023);
        await this.pilotNFT.connect(addr1).approve(this.citadelGameV1.address, 3);
        await this.pilotNFT.connect(addr1).approve(this.citadelGameV1.address, 4);
        await this.citadelGameV1.connect(addr1).liteGrid(1023, [3,4], 513, 2);
        await this.drakma.mintDrakma(owner.address, "20000000000000000000");
        await this.drakma.approve(this.citadelFleetV1.address, "20000000000000000000");
        await this.citadelFleetV1.trainFleet(1023, 1, 0, 0);

      });

      it("sends direct neighbor raid from 40 to 1023", async function () {
        [owner, addr1] = await ethers.getSigners();

        await this.citadelGameV1.sendRaid(40, 1023, [], 100, 0, 0);

        [
          sifGattaca40,
          mhrudvogThrot40,
          drebentraakht40
        ] = await this.citadelGameV1.getCitadelFleetCount(40);
        expect(Number(sifGattaca40.toString())).to.be.lessThan(100);
        expect(Number(sifGattaca40.toString())).to.be.greaterThan(0);
        expect(Number(mhrudvogThrot40.toString())).to.equal(0);
        expect(Number(drebentraakht40.toString())).to.equal(0);

        [
          sifGattaca1023,
          mhrudvogThrot1023,
          drebentraakht1023
        ] = await this.citadelGameV1.getCitadelFleetCount(1023);
        expect(Number(sifGattaca1023.toString())).to.be.lessThan(100);
        expect(Number(mhrudvogThrot1023.toString())).to.equal(0);
        expect(Number(drebentraakht1023.toString())).to.equal(0);

      });

      it("sends direct neighbor raid from 1023 to 40", async function () {
        [owner, addr1] = await ethers.getSigners();

        [
          sifGattaca1023,
          mhrudvogThrot1023,
          drebentraakht1023
        ] = await this.citadelGameV1.getCitadelFleetCount(1023);

        [
          sifGattaca40,
          mhrudvogThrot40,
          drebentraakht40
        ] = await this.citadelGameV1.getCitadelFleetCount(40);
        
        await this.citadelGameV1.connect(addr1).sendRaid(1023, 40, [3,4], 100, 0, 0);

        [
          sifGattaca1023,
          mhrudvogThrot1023,
          drebentraakht1023
        ] = await this.citadelGameV1.getCitadelFleetCount(1023);
        expect(Number(sifGattaca1023.toString())).to.be.lessThan(100);
        expect(Number(sifGattaca1023.toString())).to.be.greaterThan(0);
        expect(Number(mhrudvogThrot1023.toString())).to.equal(0);
        expect(Number(drebentraakht1023.toString())).to.equal(0);

        [
          sifGattaca40,
          mhrudvogThrot40,
          drebentraakht40
        ] = await this.citadelGameV1.getCitadelFleetCount(40);
        expect(Number(sifGattaca40.toString())).to.be.lessThan(100);
        expect(Number(sifGattaca40.toString())).to.be.greaterThan(0);
        expect(Number(mhrudvogThrot40.toString())).to.equal(0);
        expect(Number(drebentraakht40.toString())).to.equal(0);

        [
          timeLit40,
          timeOfLastClaim40,
          timeLastRaided40,
          unclaimedDrakma40
        ] = await this.citadelGameV1.getCitadelMining(40);
        expect(Number(timeLastRaided40.toString())).to.be.greaterThan(0);
        expect(Number(unclaimedDrakma40.toString())).to.equal(0);

        [
          timeLit1023,
          timeOfLastClaim1023,
          timeLastRaided1023,
          unclaimedDrakma1023
        ] = await this.citadelGameV1.getCitadelMining(1023);
        expect(Number(unclaimedDrakma1023.toString())).to.be.greaterThan(0);

        drakmaAddr1 = await this.drakma.balanceOf(addr1.address);
        expect(Number(drakmaAddr1.toString())).to.be.greaterThan(0);
      });

      it("sends distant raid from 1023 to 1021", async function () {
        [owner, addr1] = await ethers.getSigners();

        await this.citadelGameV1.connect(addr1).sendRaid(1023, 1021, [3,4], 100, 0, 0);

        [
          sifGattaca1023,
          mhrudvogThrot1023,
          drebentraakht1023
        ] = await this.citadelGameV1.getCitadelFleetCount(1023);
        expect(Number(sifGattaca1023.toString())).to.equal(0);
        expect(Number(mhrudvogThrot1023.toString())).to.equal(0);
        expect(Number(drebentraakht1023.toString())).to.equal(0);

        [
          sifGattaca1021,
          mhrudvogThrot1021,
          drebentraakht1021
        ] = await this.citadelGameV1.getCitadelFleetCount(1021);
        expect(Number(sifGattaca1021.toString())).to.equal(100);
        expect(Number(mhrudvogThrot1021.toString())).to.equal(0);
        expect(Number(drebentraakht1021.toString())).to.equal(0);

        [
          timeLit1023,
          timeOfLastClaim1023,
          timeLastRaided1023,
          unclaimedDrakma1023
        ] = await this.citadelGameV1.getCitadelMining(1023);

        [
          timeLit1021,
          timeOfLastClaim1021,
          timeLastRaided1021,
          unclaimedDrakma1021
        ] = await this.citadelGameV1.getCitadelMining(1021);

        [
          toCitadel,
          sifGattacaRaid,
          mhrudvogThrotRaid,
          drebentraakhtRaid,
          pilotSentRaid,
          timeRaidHits,
        ] = await this.citadelGameV1.getRaid(1023);
        expect(Number(toCitadel.toString())).to.equal(1021);
        expect(Number(sifGattacaRaid.toString())).to.equal(100);
        expect(Number(drebentraakhtRaid.toString())).to.equal(0);
        expect(Number(pilotSentRaid.toString())).to.equal(2);
        expect(Number(timeRaidHits.toString())).to.greaterThan(Number(timeLastRaided1021.toString()))
      });

      it("resolves distant raid from 1023 to 1021", async function () {
        [owner, addr1] = await ethers.getSigners();

        await this.citadelGameV1.connect(addr1).sendRaid(1023, 1021, [3,4], 100, 0, 0);

        [
          sifGattaca1023,
          mhrudvogThrot1023,
          drebentraakht1023
        ] = await this.citadelGameV1.getCitadelFleetCount(1023);
        expect(Number(sifGattaca1023.toString())).to.equal(0);
        expect(Number(mhrudvogThrot1023.toString())).to.equal(0);
        expect(Number(drebentraakht1023.toString())).to.equal(0);

        [
          sifGattaca1021,
          mhrudvogThrot1021,
          drebentraakht1021
        ] = await this.citadelGameV1.getCitadelFleetCount(1021);
        expect(Number(sifGattaca1021.toString())).to.equal(100);
        expect(Number(mhrudvogThrot1021.toString())).to.equal(0);
        expect(Number(drebentraakht1021.toString())).to.equal(0);

        [
          timeLit1023,
          timeOfLastClaim1023,
          timeLastRaided1023,
          unclaimedDrakma1023
        ] = await this.citadelGameV1.getCitadelMining(1023);

        [
          timeLit1021,
          timeOfLastClaim1021,
          timeLastRaided1021,
          unclaimedDrakma1021
        ] = await this.citadelGameV1.getCitadelMining(1021);

        [
          toCitadel,
          sifGattacaRaid,
          mhrudvogThrotRaid,
          drebentraakhtRaid,
          pilotSentRaid,
          timeRaidHits,
        ] = await this.citadelGameV1.getRaid(1023);
        expect(Number(toCitadel.toString())).to.equal(1021);
        expect(Number(sifGattacaRaid.toString())).to.equal(100);
        expect(Number(drebentraakhtRaid.toString())).to.equal(0);
        expect(Number(pilotSentRaid.toString())).to.equal(2);
        expect(Number(timeRaidHits.toString())).to.greaterThan(Number(timeLastRaided1021.toString()));

        // fast forward block time to simulate fleet desertion
        await time.increase(432000); // 5 days
        await this.citadelGameV1.resolveRaid(1023);
        [
          sifGattaca1021,
          mhrudvogThrot1021,
          drebentraakht1021
        ] = await this.citadelGameV1.getCitadelFleetCount(1021);
        expect(Number(sifGattaca1021.toString())).to.be.greaterThanOrEqual(200);
        expect(Number(mhrudvogThrot1021.toString())).to.equal(0);
        expect(Number(drebentraakht1021.toString())).to.equal(0);

        [
          toCitadel,
          sifGattacaRaid,
          mhrudvogThrotRaid,
          drebentraakhtRaid,
          pilotSentRaid,
          timeRaidHits,
        ] = await this.citadelGameV1.getRaid(1023);
        expect(Number(toCitadel.toString())).to.equal(0);
        expect(Number(timeRaidHits.toString())).to.be.equal(0);
      });

      it("reverts raid sent to same citadel", async function () {
        [owner, addr1] = await ethers.getSigners();
        await expectRevert(
          this.citadelGameV1.sendRaid(40, 40, [], 10, 0, 0),
          "cannot raid own citadel"
        );
      });

      it("reverts raid sent from un-owned citadel", async function () {
        [owner, addr1] = await ethers.getSigners();
        await expectRevert(
          this.citadelGameV1.connect(addr1).sendRaid(40, 1023, [], 100, 0, 0),
          "must own citadel"
        );
      });

      it("reverts raid with more fleet than trained", async function () {
        [owner, addr1] = await ethers.getSigners();

        await expectRevert(
          this.citadelGameV1.sendRaid(40, 1023, [], 101, 0, 0),
          "cannot send more fleet than in citadel"
        );

        await expectRevert(
          this.citadelGameV1.sendRaid(40, 1023, [], 0, 101, 0),
          "cannot send more fleet than in citadel"
        );

        await expectRevert(
          this.citadelGameV1.sendRaid(40, 1023, [], 0, 0, 2),
          "cannot send more fleet than in citadel"
        );
      });

      it("reverts raid with less than min fleet sent", async function () {
        [owner, addr1] = await ethers.getSigners();

        await expectRevert(
          this.citadelGameV1.sendRaid(40, 1023, [], 1, 0, 0),
          "fleet sent in raid must exceed minimum for raiding"
        );
      });

      it("reverts raid with unowned pilot", async function () {
        [owner, addr1] = await ethers.getSigners();

        await expectRevert(
          this.citadelGameV1.sendRaid(40, 1023, [3,4], 10, 0, 0),
          "pilot sent must be staked to raiding citadel"
        );
      });

    });

    describe("reinforcements", function () {

      beforeEach(async function () {
        [owner, addr1] = await ethers.getSigners();
        await this.pilotNFT.reservePILOT(256);
        await this.citadelNFT.reserveCitadel(1024);

        await this.citadelNFT.approve(this.citadelGameV1.address, 40);
        await this.citadelGameV1.liteGrid(40, [], 512, 1);
        await this.drakma.mintDrakma(owner.address, "20000000000000000000");
        await this.drakma.approve(this.citadelFleetV1.address, "20000000000000000000");
        await this.citadelFleetV1.trainFleet(40, 1, 0, 0);

        await this.citadelNFT.approve(this.citadelGameV1.address, 1021);
        await this.pilotNFT.approve(this.citadelGameV1.address, 1);
        await this.pilotNFT.approve(this.citadelGameV1.address, 2);
        await this.pilotNFT.approve(this.citadelGameV1.address, 5);
        await this.pilotNFT.approve(this.citadelGameV1.address, 6);
        await this.citadelGameV1.liteGrid(1021, [1,2,5,6], 1, 1);
        await this.drakma.mintDrakma(owner.address, "20000000000000000000");
        await this.drakma.approve(this.citadelFleetV1.address, "20000000000000000000");
        await this.citadelFleetV1.trainFleet(1021, 1, 0, 0);

        await this.citadelNFT.transferFrom(owner.address, addr1.address, 1023);
        await this.pilotNFT.transferFrom(owner.address, addr1.address, 3);
        await this.pilotNFT.transferFrom(owner.address, addr1.address, 4);
        await this.citadelNFT.connect(addr1).approve(this.citadelGameV1.address, 1023);
        await this.pilotNFT.connect(addr1).approve(this.citadelGameV1.address, 3);
        await this.pilotNFT.connect(addr1).approve(this.citadelGameV1.address, 4);
        await this.citadelGameV1.connect(addr1).liteGrid(1023, [3,4], 513, 2);
        await this.drakma.mintDrakma(owner.address, "20000000000000000000");
        await this.drakma.approve(this.citadelFleetV1.address, "20000000000000000000");
        await this.citadelFleetV1.trainFleet(1023, 1, 0, 0);

      });

      it("sends direct neighbor reinforcements from 40 to 1023", async function () {
        [owner, addr1] = await ethers.getSigners();

        await this.citadelGameV1.sendReinforcements(40, 1023, 100, 0, 0);

        [
          sifGattaca40,
          mhrudvogThrot40,
          drebentraakht40
        ] = await this.citadelGameV1.getCitadelFleetCount(40);
        expect(Number(sifGattaca40.toString())).to.equal(0);
        expect(Number(mhrudvogThrot40.toString())).to.equal(0);
        expect(Number(drebentraakht40.toString())).to.equal(0);

        [
          sifGattaca1023,
          mhrudvogThrot1023,
          drebentraakht1023
        ] = await this.citadelGameV1.getCitadelFleetCount(1023);
        expect(Number(sifGattaca1023.toString())).to.equal(100);
        expect(Number(mhrudvogThrot1023.toString())).to.equal(0);
        expect(Number(drebentraakht1023.toString())).to.equal(0);

      });

      it("sends distant reinforcments from 1023 to 1021", async function () {
        [owner, addr1] = await ethers.getSigners();

        await this.citadelGameV1.connect(addr1).sendReinforcements(1023, 1021, 100, 0, 0);

        [
          sifGattaca1023,
          mhrudvogThrot1023,
          drebentraakht1023
        ] = await this.citadelGameV1.getCitadelFleetCount(1023);
        expect(Number(sifGattaca1023.toString())).to.equal(0);
        expect(Number(mhrudvogThrot1023.toString())).to.equal(0);
        expect(Number(drebentraakht1023.toString())).to.equal(0);

        [
          sifGattaca1021,
          mhrudvogThrot1021,
          drebentraakht1021
        ] = await this.citadelGameV1.getCitadelFleetCount(1021);
        expect(Number(sifGattaca1021.toString())).to.equal(100);
        expect(Number(mhrudvogThrot1021.toString())).to.equal(0);
        expect(Number(drebentraakht1021.toString())).to.equal(0);

      });

      it("reverts reinforcements from unowned citadel", async function () {
        [owner, addr1] = await ethers.getSigners();

        await expectRevert(
          this.citadelGameV1.sendReinforcements(1023, 40, 100, 0, 0),
          "must own citadel"
        );
      });

      it("reverts reinforcements with too many fleet sent", async function () {
        [owner, addr1] = await ethers.getSigners();

        await expectRevert(
          this.citadelGameV1.sendReinforcements(40, 1023, 200, 0, 0),
          "cannot send more fleet than in citadel"
        );
      });

      it("reverts multiple reinforcements in flight", async function () {
        [owner, addr1] = await ethers.getSigners();

        await this.citadelGameV1.sendReinforcements(40, 1023, 10, 0, 0);

        await expectRevert(
          this.citadelGameV1.sendReinforcements(40, 1023, 10, 0, 0),
          "only one reinforcement in flight"
        );
      });
    });

    describe("admin", function () {

      beforeEach(async function () {
        [owner, addr1] = await ethers.getSigners();
        await this.pilotNFT.reservePILOT(256);
        await this.citadelNFT.reserveCitadel(1024);

        await this.citadelNFT.approve(this.citadelGameV1.address, 40);
        await this.citadelGameV1.liteGrid(40, [], 512, 1);

        await this.citadelNFT.transferFrom(owner.address, addr1.address, 1023);
        await this.pilotNFT.transferFrom(owner.address, addr1.address, 3);
        await this.pilotNFT.transferFrom(owner.address, addr1.address, 4);
        await this.citadelNFT.connect(addr1).approve(this.citadelGameV1.address, 1023);
        await this.pilotNFT.connect(addr1).approve(this.citadelGameV1.address, 3);
        await this.pilotNFT.connect(addr1).approve(this.citadelGameV1.address, 4);

        await this.citadelGameV1.connect(addr1).liteGrid(1023, [3,4], 513, 2);

      });

      it("reverts escape hatch when closed", async function () {
        [owner, addr1] = await ethers.getSigners();

        await expectRevert(
          this.citadelGameV1.escapeHatch(40),
          "escapeHatch is closed"
        );
      });

      it("reverts escape hatch of unowned CITADEL", async function () {
        [owner, addr1] = await ethers.getSigners();

        await this.citadelGameV1.updateGameParams(1674943200, true);

        await expectRevert(
          this.citadelGameV1.escapeHatch(1023),
          "must own citadel"
        );
      });

      it("uses escape hatch", async function () {
        [owner, addr1] = await ethers.getSigners();

        await this.citadelGameV1.updateGameParams(1674943200, true);

        await this.citadelGameV1.escapeHatch(40);

        ownerOfCitadel40 = await this.citadelNFT.ownerOf(40);
        expect(ownerOfCitadel40).to.equal(owner.address);

      });

    });


});