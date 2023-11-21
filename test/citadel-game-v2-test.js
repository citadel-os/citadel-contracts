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

describe("citadel game v2", function () {

    before(async function () {
        this.CitadelNFT = await ethers.getContractFactory("CitadelNFT");
        this.PilotNFT = await ethers.getContractFactory("PilotNFT");
        this.Drakma = await ethers.getContractFactory("Drakma");
        this.CitadelExordium = await ethers.getContractFactory("CitadelExordium");
        this.Propaganda = await ethers.getContractFactory("PropagandaV2");
        this.SovereignCollectiveV2 = await ethers.getContractFactory("SovereignCollectiveV2");
        this.CombatEngineV2 = await ethers.getContractFactory("CombatEngineV2");
        this.StorageV2 = await ethers.getContractFactory("StorageV2");
        this.CitadelGameV2 = await ethers.getContractFactory("CitadelGameV2");
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

      this.sovereignCollectiveV2 = await this.SovereignCollectiveV2.deploy(
        this.pilotNFT.address
      );
      await this.sovereignCollectiveV2.deployed();

      this.propaganda = await this.Propaganda.deploy();
      await this.propaganda.deployed();

      this.combatEngineV2 = await this.CombatEngineV2.deploy(
        this.pilotNFT.address,
        this.drakma.address
      );
      await this.combatEngineV2.deployed();

      this.storageV2 = await this.StorageV2.deploy(
        this.combatEngineV2.address,
        this.propaganda.address
      );
      await this.storageV2.deployed();

      this.citadelGameV2 = await this.CitadelGameV2.deploy(
        this.citadelNFT.address,
        this.pilotNFT.address,
        this.drakma.address,
        this.storageV2.address,
        this.combatEngineV2.address,
        this.propaganda.address,
        this.sovereignCollectiveV2.address
      );
      await this.citadelGameV2.deployed();

      this.storageV2.updateAccessAddress(this.citadelGameV2.address);
      this.sovereignCollectiveV2.updateAccessAddress(this.citadelGameV2.address);
      this.combatEngineV2.updateGameParams(
        1,
        30 * 60 * 1000,
        this.citadelGameV2.address
      );

      await this.drakma.mintDrakma(this.citadelGameV2.address, "2400000000000000000000000000");
    });
    
    describe("lite to grid", function () {
        beforeEach(async function () {
            [owner, addr1] = await ethers.getSigners();
            await this.pilotNFT.reservePILOT(256);
            await this.citadelNFT.reserveCitadel(1024);

            await this.drakma.mintDrakma(owner.address, "4000000000000000000000000");
            await this.drakma.approve(this.pilotNFT.address, "4000000000000000000000000");
  
            await this.pilotNFT.sovereignty(3);
            [sovereign, level] = await this.pilotNFT.getOnchainPILOT(3);
            expect(sovereign).to.equal(true);
        });

      it("lites 2 pilot to grid", async function () {
        [owner, addr1] = await ethers.getSigners();

        let citadelId = 2;
        let gridId = 660;
        let capitalId = 1;
        await this.citadelGameV2.liteGrid(citadelId, [1,2], gridId, capitalId);
        let grid = await this.storageV2.grid(gridId);
        expect(grid.isCapital).to.equal(false);
        expect(grid.sovereignUntil).to.equal(0);
        expect(grid.isLit).to.equal(true);
        expect(grid.citadelId).to.equal(citadelId);

        let citadel = await this.storageV2.citadel(citadelId);
        expect(citadel.capitalId).to.equal(capitalId);
        expect(citadel.timeOfLastClaim).to.equal(0);
        expect(Number(citadel.timeLit.toString())).to.be.greaterThan(0);
        expect(citadel.unclaimedDrakma).to.equal(0);
        expect(citadel.marker).to.equal(0);
        
      });

      it("lites sovereign pilot to grid", async function () {
        [owner, addr1] = await ethers.getSigners();

        let citadelId = 2;
        let gridId = 660;
        let capitalId = 1;
        await this.citadelGameV2.liteGrid(citadelId, [2,3], gridId, capitalId);
        let grid = await this.storageV2.grid(gridId);
        expect(grid.isCapital).to.equal(false);
        expect(Number(grid.sovereignUntil.toString())).to.be.greaterThan(0);
        expect(grid.isLit).to.equal(true);
        expect(grid.citadelId).to.equal(citadelId);

        let citadel = await this.storageV2.citadel(citadelId);
        expect(citadel.capitalId).to.equal(capitalId);
        expect(citadel.timeOfLastClaim).to.equal(0);
        expect(Number(citadel.timeLit.toString())).to.be.greaterThan(0);
        expect(citadel.unclaimedDrakma).to.equal(0);
        expect(citadel.marker).to.equal(0);
        
      });

      it("reverts unowned citadel lit", async function () {
        [owner, addr1] = await ethers.getSigners();

        await expectRevert(
          this.citadelGameV2.connect(addr1).liteGrid(40, [1,2], 660, 1),
          "must own citadel"
        );
      });

      it("reverts invalid capital", async function () {
        [owner, addr1] = await ethers.getSigners();

        await expectRevert(
          this.citadelGameV2.liteGrid(40, [1,2], 660, 8),
          "invalid capital"
        );
      });

      it("reverts unowned pilot staked", async function () {
        [owner, addr1] = await ethers.getSigners();

        await this.citadelNFT.transferFrom(owner.address, addr1.address, 40);
        await this.pilotNFT.transferFrom(owner.address, addr1.address, 1);

        await expectRevert(
          this.citadelGameV2.connect(addr1).liteGrid(40, [1,2], 512, 1),
          "must own pilot to lite"
        );
      });

      it("reverts invalid grid", async function () {
        [owner, addr1] = await ethers.getSigners();

        await expectRevert(
          this.citadelGameV2.liteGrid(40, [1,2], 5000, 1),
          "invalid grid"
        );
      });

      it("reverts stake to lit grid", async function () {
        [owner, addr1] = await ethers.getSigners();

        await this.citadelGameV2.liteGrid(40, [1,2], 512, 1);

        await expectRevert(
          this.citadelGameV2.liteGrid(41, [], 512, 1),
          "cannot lite"
        );
      });

    });

    describe("claims drakma from grid", function () {
      beforeEach(async function () {
          [owner, addr1] = await ethers.getSigners();
          await this.pilotNFT.reservePILOT(256);
          await this.citadelNFT.reserveCitadel(1024);
      });

      it("reverts claim of unowned citadel", async function () {
        [owner, addr1] = await ethers.getSigners();
        await this.citadelGameV2.liteGrid(40, [1,2], 512, 1);
        await expectRevert(
          this.citadelGameV2.connect(addr1).claim(40),
          "must own citadel"
        );
      });

      it("claims dim citadel", async function () {
        [owner, addr1] = await ethers.getSigners();


        await this.citadelGameV2.claim(40);

        drakmaOwner = await this.drakma.balanceOf(owner.address);
        expect(Number(drakmaOwner.toString())).to.be.greaterThan(0);

      });

      it("reverts second claim inside interval", async function () {
        [owner, addr1] = await ethers.getSigners();

        await this.citadelGameV2.liteGrid(40, [], 512, 1);
        await this.citadelGameV2.claim(40);

        drakmaOwner = await this.drakma.balanceOf(owner.address);
        expect(Number(drakmaOwner.toString())).to.be.greaterThan(0);

        await expectRevert(
          this.citadelGameV2.claim(40),
          "one claim per interval permitted"
        );
      });


    });

    describe.only("raiding", function () {
      beforeEach(async function () {
        [owner, addr1] = await ethers.getSigners();
        await this.pilotNFT.reservePILOT(256);
        await this.citadelNFT.reserveCitadel(1024);

        await this.citadelGameV2.liteGrid(40, [1], 628, 1);
        await this.drakma.mintDrakma(owner.address, "20000000000000000000");
        await this.drakma.approve(this.citadelGameV2.address, "20000000000000000000");
        await this.citadelGameV2.trainFleet(40, 1, 0, 0);

        await this.citadelGameV2.liteGrid(1021, [2,5,6], 272, 1);
        await this.drakma.mintDrakma(owner.address, "20000000000000000000");
        await this.drakma.approve(this.citadelGameV2.address, "20000000000000000000");
        await this.citadelGameV2.trainFleet(1021, 1, 0, 0);

        await this.citadelNFT.transferFrom(owner.address, addr1.address, 1023);
        await this.pilotNFT.transferFrom(owner.address, addr1.address, 3);
        await this.pilotNFT.transferFrom(owner.address, addr1.address, 4);
        await this.citadelGameV2.connect(addr1).liteGrid(1023, [3,4], 629, 2);
        await this.drakma.mintDrakma(owner.address, "20000000000000000000");
        await this.drakma.approve(this.citadelGameV2.address, "20000000000000000000");
        await this.citadelGameV2.trainFleet(1023, 1, 0, 0);

      });

      it("sends direct neighbor raid from 40 to 1023", async function () {
        [owner, addr1] = await ethers.getSigners();

        await this.citadelGameV2.sendSiege(40, 1023, 1, [100,0,0]);

      });

    });

    describe("reinforcements", function () {

        beforeEach(async function () {
            [owner, addr1] = await ethers.getSigners();
            await this.pilotNFT.reservePILOT(256);
            await this.citadelNFT.reserveCitadel(1024);

        });


    });

    describe("admin", function () {

        beforeEach(async function () {
            [owner, addr1] = await ethers.getSigners();
            await this.pilotNFT.reservePILOT(256);
            await this.citadelNFT.reserveCitadel(1024);

        });

    });
});
