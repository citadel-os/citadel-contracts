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

      this.combatEngineV2 = await this.CombatEngineV2.deploy(
        this.pilotNFT.address,
        this.drakma.address
      );
      await this.combatEngineV2.deployed();

      this.storageV2 = await this.StorageV2.deploy(
        this.combatEngineV2.address
      );
      await this.storageV2.deployed();

      this.citadelGameV2 = await this.CitadelGameV2.deploy(
        this.citadelNFT.address,
        this.pilotNFT.address,
        this.drakma.address,
        this.storageV2.address,
        this.combatEngineV2.address,
        this.sovereignCollectiveV2.address
      );
      await this.citadelGameV2.deployed();

      await this.storageV2.updateAccessAddress(this.citadelGameV2.address);
      await this.sovereignCollectiveV2.updateAccessAddress(this.citadelGameV2.address);
      await this.combatEngineV2.updateGameParams(
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
        await this.citadelGameV2.liteGrid(citadelId, [1,2,0], gridId, capitalId);
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
        expect(citadel.gridId).to.equal(gridId);
        
      });

      it("lites sovereign pilot to grid", async function () {
        [owner, addr1] = await ethers.getSigners();

        let citadelId = 2;
        let gridId = 660;
        let capitalId = 1;
        await this.citadelGameV2.liteGrid(citadelId, [2,3,0], gridId, capitalId);
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
          this.citadelGameV2.connect(addr1).liteGrid(40, [1,2,0], 660, 1),
          "must own citadel"
        );
      });

      it("reverts invalid capital", async function () {
        [owner, addr1] = await ethers.getSigners();

        await expectRevert(
          this.citadelGameV2.liteGrid(40, [1,2,0], 660, 8),
          "invalid capital"
        );
      });

      it("reverts unowned pilot staked", async function () {
        [owner, addr1] = await ethers.getSigners();

        await this.citadelNFT.transferFrom(owner.address, addr1.address, 40);
        await this.pilotNFT.transferFrom(owner.address, addr1.address, 1);

        await expectRevert(
          this.citadelGameV2.connect(addr1).liteGrid(40, [1,2,0], 512, 1),
          "must own pilot to lite"
        );
      });

      it("reverts invalid grid", async function () {
        [owner, addr1] = await ethers.getSigners();

        await expectRevert(
          this.citadelGameV2.liteGrid(40, [1,2,0], 5000, 1),
          "invalid grid"
        );
      });

      it("reverts stake to lit grid", async function () {
        [owner, addr1] = await ethers.getSigners();

        await this.citadelGameV2.liteGrid(40, [1,2,0], 512, 1);

        await expectRevert(
          this.citadelGameV2.liteGrid(41, [0,0,0], 512, 1),
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
        await this.citadelGameV2.liteGrid(40, [1,2,0], 512, 1);
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

        await this.citadelGameV2.liteGrid(40, [0,0,0], 512, 1);
        await this.citadelGameV2.claim(40);

        drakmaOwner = await this.drakma.balanceOf(owner.address);
        expect(Number(drakmaOwner.toString())).to.be.greaterThan(0);

        await expectRevert(
          this.citadelGameV2.claim(40),
          "one claim per interval permitted"
        );
      });


    });

    describe("siege", function () {
      beforeEach(async function () {
        [owner, addr1] = await ethers.getSigners();
        await this.pilotNFT.reservePILOT(256);
        await this.citadelNFT.reserveCitadel(1024);

        await this.citadelGameV2.liteGrid(40, [1,0,0], 628, 1);
        await this.drakma.mintDrakma(owner.address, "20000000000000000000");
        await this.drakma.approve(this.citadelGameV2.address, "20000000000000000000");
        await this.citadelGameV2.trainFleet(40, 1, 0, 0);

        await this.citadelGameV2.liteGrid(1021, [2,5,6], 272, 3);
        await this.drakma.mintDrakma(owner.address, "20000000000000000000");
        await this.drakma.approve(this.citadelGameV2.address, "20000000000000000000");
        await this.citadelGameV2.trainFleet(1021, 1, 0, 0);

        await this.citadelNFT.transferFrom(owner.address, addr1.address, 1023);
        await this.pilotNFT.transferFrom(owner.address, addr1.address, 3);
        await this.pilotNFT.transferFrom(owner.address, addr1.address, 4);
        await this.citadelGameV2.connect(addr1).liteGrid(1023, [3,4,0], 629, 2);
        await this.drakma.mintDrakma(owner.address, "20000000000000000000");
        await this.drakma.approve(this.citadelGameV2.address, "20000000000000000000");

      });

      it("siege with pilot, achieves marker", async function () {
        [owner, addr1] = await ethers.getSigners();
        let pilotId = 1;
        await this.citadelGameV2.sendSiege(40, 1023, pilotId, [100,0,0]);
        
        let citadel40 = await this.storageV2.citadel(40);
        expect(citadel40.capitalId).to.equal(1);
        expect(citadel40.timeOfLastClaim).to.equal(0);
        expect(Number(citadel40.timeLit.toString())).to.be.greaterThan(0);
        expect(Number(citadel40.unclaimedDrakma.toString())).be.greaterThan(0);
        expect(citadel40.marker).to.equal(0);

        let citadel1023 = await this.storageV2.citadel(1023);
        expect(citadel1023.marker).to.equal(1);
      });

      it("siege with pilot defeated", async function () {
        [owner, addr1] = await ethers.getSigners();
        await this.citadelGameV2.trainFleet(1023, 1, 0, 0);
        let pilotId = 1;
        await this.citadelGameV2.sendSiege(40, 1023, pilotId, [100,0,0]);
        
        let citadel40 = await this.storageV2.citadel(40);
        expect(citadel40.marker).to.equal(0);

        let citadel1023 = await this.storageV2.citadel(1023);
        expect(citadel1023.marker).to.equal(0);
      });

      it("sieges with pilot, consecutive siege reverted", async function () {
        [owner, addr1] = await ethers.getSigners();
        
        let pilotId = 1;
        await this.citadelGameV2.sendSiege(40, 1023, pilotId, [100,0,0]);
        
        let citadel40 = await this.storageV2.citadel(40);
        expect(citadel40.marker).to.equal(0);

        let citadel1023 = await this.storageV2.citadel(1023);
        expect(citadel1023.marker).to.equal(1);

        await expectRevert(
          this.citadelGameV2.sendSiege(40, 1023, pilotId, [100,0,0]),
          "cannot siege"
        );

      });

      it("overthrows grid with 3 successful sieges", async function () {
        [owner, addr1] = await ethers.getSigners();
        
        let pilotId = 1;
        await this.citadelGameV2.sendSiege(40, 1023, pilotId, [100,0,0]);
        
        let citadel40 = await this.storageV2.citadel(40);
        expect(citadel40.marker).to.equal(0);
        expect(citadel40.gridId).to.equal(628);

        let citadel1023 = await this.storageV2.citadel(1023);
        expect(citadel1023.marker).to.equal(1);
        expect(citadel1023.gridId).to.equal(629);

        await time.increase(86400); // 1-day
        
        await this.citadelGameV2.sendSiege(40, 1023, pilotId, [100,0,0]);
        citadel1023 = await this.storageV2.citadel(1023);
        expect(citadel1023.marker).to.equal(2);
        expect(citadel1023.gridId).to.equal(629);

        await time.increase(86400); // 1-day
        
        await this.citadelGameV2.sendSiege(40, 1023, pilotId, [100,0,0]);
        citadel1023 = await this.storageV2.citadel(1023);
        expect(citadel1023.marker).to.equal(0);
        expect(citadel1023.gridId).to.equal(628);

        citadel40 = await this.storageV2.citadel(40);
        expect(citadel40.marker).to.equal(0);
        expect(citadel40.gridId).to.equal(629);

      });

      it("sieges with unowned citadel reverted", async function () {
        [owner, addr1] = await ethers.getSigners();
        
        await expectRevert(
          this.citadelGameV2.sendSiege(1023, 40, 0, [100,0,0]),
          "cannot siege"
        );
      });

      it("siege without pilot", async function () {
        [owner, addr1] = await ethers.getSigners();

        await this.citadelGameV2.sendSiege(40, 1023, 0, [100,0,0]);
        
        citadel40 = await this.storageV2.citadel(40);

        let citadel1023 = await this.storageV2.citadel(1023);
        expect(citadel1023.marker).to.equal(0);
        expect(Number(citadel1023.timeLastSieged.toString())).to.be.greaterThan(0);
      });

      it("distant siege without pilot", async function () {
        [owner, addr1] = await ethers.getSigners();
        let fleet40 = await this.storageV2.fleet(40);
        expect(fleet40.stationedFleet.sifGattaca).to.equal(100);
        expect(fleet40.trainingFleet.sifGattaca).to.equal(1);

        await this.citadelGameV2.sendSiege(40, 1021, 0, [100,0,0]);

        fleet40 = await this.storageV2.fleet(40);
        expect(fleet40.stationedFleet.sifGattaca).to.equal(0);
        expect(fleet40.trainingFleet.sifGattaca).to.equal(1);

        let citadel1021 = await this.storageV2.citadel(1021);
        expect(citadel1021.marker).to.equal(0);
        expect(Number(citadel1021.timeLastSieged.toString())).to.equal(0);
      });

    });

    describe("sacking the capital", function () {

      beforeEach(async function () {
        [owner, addr1] = await ethers.getSigners();
        await this.pilotNFT.reservePILOT(256);
        await this.citadelNFT.reserveCitadel(1024);

        await this.citadelGameV2.liteGrid(40, [1,0,0], 302, 1);
        await this.drakma.mintDrakma(owner.address, "20000000000000000000000000");
        await this.drakma.approve(this.citadelGameV2.address, "20000000000000000000000000");
        await this.citadelGameV2.trainFleet(40, 100, 100, 100);

        await this.citadelGameV2.liteGrid(1021, [2,5,6], 304, 1);
        await this.drakma.mintDrakma(owner.address, "20000000000000000000000000");
        await this.drakma.approve(this.citadelGameV2.address, "20000000000000000000000000");
        await this.citadelGameV2.trainFleet(1021, 100, 100, 100);

        await this.citadelNFT.transferFrom(owner.address, addr1.address, 1023);
        await this.pilotNFT.transferFrom(owner.address, addr1.address, 3);
        await this.pilotNFT.transferFrom(owner.address, addr1.address, 4);
        await this.citadelGameV2.connect(addr1).liteGrid(1023, [3,4,0], 303, 3);
        await this.drakma.mintDrakma(addr1.address, "20000000000000000000");
        await this.drakma.connect(addr1).approve(this.citadelGameV2.address, "20000000000000000000");

      });

      it("sacks the network state", async function () {
        [owner, addr1] = await ethers.getSigners();
        
        await this.citadelGameV2.sendSiege(40, 1023, 1, [100,0,0]);

        let citadel1023 = await this.storageV2.citadel(1023);
        expect(citadel1023.marker).to.equal(1);
        expect(citadel1023.gridId).to.equal(303);

        await time.increase(86400); // 1-day
        
        await this.citadelGameV2.sendSiege(1021, 1023, 2, [100,0,0]);
        citadel1023 = await this.storageV2.citadel(1023);
        expect(citadel1023.marker).to.equal(2);
        expect(citadel1023.gridId).to.equal(303);

        await time.increase(86400); // 1-day
        
        await this.citadelGameV2.sendSiege(40, 1023, 1, [100,0,0]);
        citadel1023 = await this.storageV2.citadel(1023);
        expect(citadel1023.marker).to.equal(0);
        expect(citadel1023.gridId).to.equal(302);

        citadel40 = await this.storageV2.citadel(40);
        expect(citadel40.marker).to.equal(0);
        expect(citadel40.gridId).to.equal(303);

        var ownerBalance = await this.drakma.balanceOf(owner.address);
        
        await time.increase(604800); // 7-days
        await this.citadelGameV2.sackCapital(
          40,
          3, 
          1000, 
          "azprime"
        );

        ownerBalance = await this.drakma.balanceOf(owner.address);

      });

  });

  describe("reinforcements", function () {

    beforeEach(async function () {
      [owner, addr1] = await ethers.getSigners();
      await this.pilotNFT.reservePILOT(256);
      await this.citadelNFT.reserveCitadel(1024);

      await this.citadelGameV2.liteGrid(622, [1,0,0], 302, 1);
      await this.drakma.mintDrakma(owner.address, "20000000000000000000000000");
      await this.drakma.approve(this.citadelGameV2.address, "20000000000000000000000000");
      await this.citadelGameV2.trainFleet(622, 100, 100, 100);

      await this.citadelGameV2.liteGrid(623, [2,5,6], 304, 1);
      await this.drakma.mintDrakma(owner.address, "20000000000000000000000000");
      await this.drakma.approve(this.citadelGameV2.address, "20000000000000000000000000");
      await this.citadelGameV2.trainFleet(623, 100, 100, 100);

      await this.citadelNFT.transferFrom(owner.address, addr1.address, 1023);
      await this.pilotNFT.transferFrom(owner.address, addr1.address, 3);
      await this.pilotNFT.transferFrom(owner.address, addr1.address, 4);
      await this.citadelGameV2.connect(addr1).liteGrid(1023, [3,4,0], 303, 3);
      await this.drakma.mintDrakma(addr1.address, "20000000000000000000");
      await this.drakma.connect(addr1).approve(this.citadelGameV2.address, "20000000000000000000");

    });

    it("sends direct neighbor reinforcements from 622 to 623", async function () {
      [owner, addr1] = await ethers.getSigners();

      let fleet = [100, 0, 0];
      await this.citadelGameV2.sendReinforcements(622, 623, fleet);

      [
        sifGattaca622,
        mhrudvogThrot622,
        drebentraakht622
      ] = await this.storageV2.getCitadelFleetCount(622);
      expect(Number(sifGattaca622.toString())).to.equal(0);
      expect(Number(mhrudvogThrot622.toString())).to.equal(0);
      expect(Number(drebentraakht622.toString())).to.equal(0);

      [
        sifGattaca623,
        mhrudvogThrot623,
        drebentraakht623
      ] = await this.storageV2.getCitadelFleetCount(623);
      expect(Number(sifGattaca623.toString())).to.equal(100);
      expect(Number(mhrudvogThrot623.toString())).to.equal(0);
      expect(Number(drebentraakht623.toString())).to.equal(0);

    });

    it("sends distant reinforcments from 622 to 1023", async function () {
      [owner, addr1] = await ethers.getSigners();

      let fleet = [100, 0, 0];
      await this.citadelGameV2.sendReinforcements(622, 1023, fleet);

      [
        sifGattaca1023,
        mhrudvogThrot1023,
        drebentraakht1023
      ] = await this.storageV2.getCitadelFleetCount(1023);
      expect(Number(sifGattaca1023.toString())).to.equal(0);
      expect(Number(mhrudvogThrot1023.toString())).to.equal(0);
      expect(Number(drebentraakht1023.toString())).to.equal(0);

      [
        sifGattaca622,
        mhrudvogThrot622,
        drebentraakht622
      ] = await this.storageV2.getCitadelFleetCount(622);
      expect(Number(sifGattaca622.toString())).to.equal(0);
      expect(Number(mhrudvogThrot622.toString())).to.equal(0);
      expect(Number(drebentraakht622.toString())).to.equal(0);

    });

    it("reverts reinforcements from unowned citadel", async function () {
      [owner, addr1] = await ethers.getSigners();

      let fleet = [100, 0, 0];
      await expectRevert(
        this.citadelGameV2.sendReinforcements(1023, 40, fleet),
        "must own citadel"
      );
    });

    it("reverts reinforcements with too many fleet sent", async function () {
      [owner, addr1] = await ethers.getSigners();

      let fleet = [200, 0, 0];
      await expectRevert(
        this.citadelGameV2.sendReinforcements(622, 623, fleet),
        "cannot send more fleet than in citadel"
      );
    });

    it("reverts multiple reinforcements in flight", async function () {
      [owner, addr1] = await ethers.getSigners();

      let fleet = [10, 0, 0];
      await this.citadelGameV2.sendReinforcements(622, 1023, fleet);

      await expectRevert(
        this.citadelGameV2.sendReinforcements(622, 1023, fleet),
        "cannot reinforce"
      );
    });
  });

  describe.only("wins citadel", function () {

    beforeEach(async function () {
        [owner, addr1] = await ethers.getSigners();
        await this.pilotNFT.reservePILOT(256);
        await this.citadelNFT.reserveCitadel(1024);

    });

    it("wins citadel", async function () {
      [owner, addr1] = await ethers.getSigners();

      await this.citadelGameV2.winCitadel();


    });

    it("fails to win citadel", async function () {
      [owner, addr1] = await ethers.getSigners();

      await this.citadelNFT.transferFrom(owner.address, addr1.address, 495);
      await this.pilotNFT.transferFrom(owner.address, addr1.address, 1);
      await this.citadelGameV2.connect(addr1).liteGrid(495, [1,0,0], 495, 1);

      await expectRevert(
        this.citadelGameV2.winCitadel(),
        "must own citadel"
      );


    });


  });

  describe("admin", function () {

    beforeEach(async function () {
        [owner, addr1] = await ethers.getSigners();
        await this.pilotNFT.reservePILOT(256);
        await this.citadelNFT.reserveCitadel(1024);

    });

    it("reverts direct access to storage contract", async function () {
      [owner, addr1] = await ethers.getSigners();

      await expectRevert(
        this.storageV2.winCitadel(),
        "cannot call function directly"
      );
    });

    it("reverts direct access to sovereign collective contract", async function () {
      [owner, addr1] = await ethers.getSigners();
      await expectRevert(
        this.sovereignCollectiveV2.bribeCapital(1, 1),
        "cannot call function directly"
      );
    });


  });
});
