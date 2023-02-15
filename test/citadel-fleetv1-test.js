var chai = require("chai");
const expect = chai.expect;
const { BN, expectEvent, expectRevert } = require("@openzeppelin/test-helpers");
require('@openzeppelin/test-helpers/configure')({
    provider: 'http://127.0.0.1:8545',
  });
const { solidity } = require("ethereum-waffle");
const { ethers } = require("hardhat");

chai.use(solidity);

describe("citadel fleet v1", function () {

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

      this.citadelFleetV1 = await this.CitadelFleetV1.deploy(
        this.drakma.address
      );
      await this.citadelFleetV1.deployed();

    });

    describe("train fleet", function () {
        let sifGattacaPrice = 20000000000000000000; //20
        let mhrudvogThrotPrice = 40000000000000000000; //40
        let drebentraakhtPrice = 800000000000000000000; //800
  
        beforeEach(async function () {});
  
        /*
          1000 sif gattaca = 20000 dk
          200 mhrudvog throt = 8000 dk
          50 drebentraakht = 40000 dk
          68000 total dk
        */
        it("trains 1250 fleet", async function () {
          [owner, addr1] = await ethers.getSigners();
  
          await this.drakma.mintDrakma(owner.address, "68000000000000000000000");
          await this.drakma.approve(this.citadelFleetV1.address, "68000000000000000000000");
          
          await this.citadelFleetV1.trainFleet(40, 1000, 200, 50);
  
          var drakmaBalance = await this.drakma.balanceOf(owner.address);
          expect(Number(drakmaBalance.toString())).to.equal(0);
  
          [
            sifGattaca,
            mhrudvogThrot,
            drebentraakht
          ] = await this.citadelFleetV1.getTrainedFleet(40);
          expect(sifGattaca).to.equal(100);
          expect(mhrudvogThrot).to.equal(0);
          expect(drebentraakht).to.equal(0);
  
          [
            sifGattaca,
            mhrudvogThrot,
            drebentraakht
          ] = await this.citadelFleetV1.getFleetInTraining(40);
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
          await this.drakma.approve(this.citadelFleetV1.address, "136000000000000000000000");  
          await this.citadelFleetV1.trainFleet(40, 1000, 200, 50);
  
          var drakmaBalance = await this.drakma.balanceOf(owner.address);
          expect(Number(drakmaBalance.toString())).to.equal(68000000000000000000000);
  
          [
            sifGattaca,
            mhrudvogThrot,
            drebentraakht
          ] = await this.citadelFleetV1.getTrainedFleet(40);
          expect(sifGattaca).to.equal(100);
          expect(mhrudvogThrot).to.equal(0);
          expect(drebentraakht).to.equal(0);
  
          [
            sifGattaca,
            mhrudvogThrot,
            drebentraakht
          ] = await this.citadelFleetV1.getFleetInTraining(40);
          expect(sifGattaca).to.equal(1000);
          expect(mhrudvogThrot).to.equal(200);
          expect(drebentraakht).to.equal(50);
  
          await expectRevert(
            this.citadelFleetV1.trainFleet(40, 1000, 200, 50),
            "cannot train new fleet until previous has finished"
          );
  
          var drakmaBalance = await this.drakma.balanceOf(owner.address);
          expect(Number(drakmaBalance.toString())).to.equal(68000000000000000000000);
  
          [
            sifGattaca,
            mhrudvogThrot,
            drebentraakht
          ] = await this.citadelFleetV1.getTrainedFleet(40);
          expect(sifGattaca).to.equal(100);
          expect(mhrudvogThrot).to.equal(0);
          expect(drebentraakht).to.equal(0);
  
          [
            sifGattaca,
            mhrudvogThrot,
            drebentraakht
          ] = await this.citadelFleetV1.getFleetInTraining(40);
          expect(sifGattaca).to.equal(1000);
          expect(mhrudvogThrot).to.equal(200);
          expect(drebentraakht).to.equal(50);
        });
  
  
      });
      describe("admin", function () {

      it("updates fleet params", async function () {
        [owner, addr1] = await ethers.getSigners();
        
        // params not public, expect no error thrown
        await this.citadelFleetV1.updateFleetParams("10000000000000000000", "20000000000000000000", "800000000000000000000", 60, 60, 60);

      });

    });
});