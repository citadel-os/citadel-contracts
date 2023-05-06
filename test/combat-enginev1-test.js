var chai = require("chai");
const expect = chai.expect;
const { BN, expectEvent, expectRevert } = require("@openzeppelin/test-helpers");
require('@openzeppelin/test-helpers/configure')({
  provider: 'http://127.0.0.1:8545',
});
const { solidity } = require("ethereum-waffle");
const { ethers } = require("hardhat");

chai.use(solidity);

describe("combat engine v1", function () {

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

    });
    
    describe("combat engine", function () {
      let sifGattacaOP = 10;
      let mhrudvogThrotOP = 5;
      let drebentraakhtOP = 500;
      let sifGattacaDP = 5;
      let mhrudvogThrotDP = 40;
      let drebentraakhtDP = 250;
      let pilotMultiple = 20;
      let levelMultiple = 2;

      beforeEach(async function () {
        await this.pilotNFT.reservePILOT(256);
        await this.citadelNFT.reserveCitadel(1024);
      });

      it("get basic op", async function () {
        [owner, addr1] = await ethers.getSigners();
        let sifGattaca = 500;
        let mhrudvogThrot = 1;
        let drebentraakht = 5;
        let pilot = [];

        let expectedOP = (sifGattaca * sifGattacaOP) + 
          (mhrudvogThrot * mhrudvogThrotOP) +
          (drebentraakht * drebentraakhtOP);
        let op = await this.combatEngineV1.combatOP(pilot, sifGattaca, mhrudvogThrot, drebentraakht);
        
        expect(op).to.equal(expectedOP);
      });

      it("get op with pilots", async function () {
        [owner, addr1] = await ethers.getSigners();
        let sifGattaca = 500;
        let mhrudvogThrot = 1;
        let drebentraakht = 5;
        let pilot = [1, 2];

        let expectedOP = ((sifGattaca * sifGattacaOP) + 
          (mhrudvogThrot * mhrudvogThrotOP) +
          (drebentraakht * drebentraakhtOP)) *
          (1 + ((pilot.length * pilotMultiple) / 100));
        let op = await this.combatEngineV1.combatOP(pilot, sifGattaca, mhrudvogThrot, drebentraakht);

        expect(op).to.equal(expectedOP);
      });

      it("get op with upleveled pilot", async function () {
        [owner, addr1] = await ethers.getSigners();

        let sifGattaca = 500;
        let mhrudvogThrot = 1;
        let drebentraakht = 5;
        let pilot = [1];

        let opPre = await this.combatEngineV1.combatOP(pilot, sifGattaca, mhrudvogThrot, drebentraakht);

        await this.drakma.mintDrakma(owner.address, "100000000000000000000000");
        await this.drakma.approve(this.pilotNFT.address, "100000000000000000000000");
        await this.pilotNFT.upLevel(1);

        let opPost = await this.combatEngineV1.combatOP(pilot, sifGattaca, mhrudvogThrot, drebentraakht);

        expect(Number(opPre.toString())).to.be.lessThan(Number(opPost.toString()));
      });

      /*
        citadel 40
          - weapons telum furor index 2
          - engine chobbakk index 1
          - shield xcid ma index 1
        calculateBaseCitadelMultiple weapons = 12%
        calculateBaseCitadelMultiple shield = 11%
        swarm multiple 8% = 6% + 2%
        siege multiple 12% = 10% + 2%
      */
      it("get basic dp citadel 40", async function () {
        [owner, addr1] = await ethers.getSigners();
        let sifGattaca = 10;
        let mhrudvogThrot = 100;
        let drebentraakht = 5;
        let pilot = [];
  
        let expectedDP = Math.floor(Math.floor(Math.floor((sifGattaca * sifGattacaDP) * 1.08) + 
          Math.floor(mhrudvogThrot * mhrudvogThrotDP) +
          (Math.floor(drebentraakht * drebentraakhtDP)) * 1.12) * 1.23);
        let dp = await this.combatEngineV1.combatDP(40, pilot, sifGattaca, mhrudvogThrot, drebentraakht);

        expect(dp).to.equal(Math.round(expectedDP));
      });

  
      /*
        citadel 1023
          - weapons marbhadh ghxst index 6
          - engine drednaught index 7
          - shield marbhadh greine index 7
        calculateBaseCitadelMultiple weapons = 25%
        calculateBaseCitadelMultiple shield = 35%
        swarm multiple 25%
        siege multiple 10%
        pilot 40%
      */
      it("get basic dp citadel 1023", async function () {
        [owner, addr1] = await ethers.getSigners();
        let sifGattaca = 10;
        let mhrudvogThrot = 200;
        let drebentraakht = 5;
        let pilot = [1,2];
  
        let expectedDP = Math.floor(Math.floor(Math.floor((sifGattaca * sifGattacaDP) * 1.25) + 
          Math.floor(mhrudvogThrot * mhrudvogThrotDP) +
          (Math.floor(drebentraakht * drebentraakhtDP)) * 1.1) * 2);
        let dp = await this.combatEngineV1.combatDP(1023, pilot, sifGattaca, mhrudvogThrot, drebentraakht);
        expect(dp).to.equal(Math.floor(expectedDP));
      });

      /*
        citadel 193
          - weapons rrakatakht furor index 0
          - engine hag gotar index 0
          - shield dag sgiath index 0
        calculateBaseCitadelMultiple weapons = 10%
        calculateBaseCitadelMultiple shield = 10%
        swarm multiple 5%
        siege multiple 5%
        pilot 20%
      */
      it("get basic dp citadel 193", async function () {
        [owner, addr1] = await ethers.getSigners();
        let sifGattaca = 10;
        let mhrudvogThrot = 250;
        let drebentraakht = 8;
        let pilot = [1];
  
        let expectedDP = Math.floor(Math.floor(Math.floor((sifGattaca * sifGattacaDP) * 1.06) + 
          Math.floor(mhrudvogThrot * mhrudvogThrotDP) +
          (Math.floor(drebentraakht * drebentraakhtDP)) * 1.06) * 1.4);
        let dp = await this.combatEngineV1.combatDP(193, pilot, sifGattaca, mhrudvogThrot, drebentraakht);
        expect(dp).to.equal(Math.floor(expectedDP));
      });

      /*
        citadel 1021
          - weapons halmahher furor index 3
          - engine dsgill mak index 6
          - shield daskenwaft index 5
        calculateBaseCitadelMultiple weapons = 15%
        calculateBaseCitadelMultiple shield = 20%
        swarm multiple 15% + 7% = 22%
        siege multiple 0%
        pilot 20%
      */
      it("get basic dp citadel 1021", async function () {
        [owner, addr1] = await ethers.getSigners();
        let sifGattaca = 10;
        let mhrudvogThrot = 250;
        let drebentraakht = 8;
        let pilot = [1];
  
        let expectedDP = Math.floor(Math.floor(Math.floor((sifGattaca * sifGattacaDP) * 1.22) + 
          Math.floor(mhrudvogThrot * mhrudvogThrotDP) +
          (Math.floor(drebentraakht * drebentraakhtDP)) * 1) * 1.55);
        let dp = await this.combatEngineV1.combatDP(1021, pilot, sifGattaca, mhrudvogThrot, drebentraakht);
        expect(dp).to.equal(Math.floor(expectedDP));
      });

      it("calculates destroyed fleet", async function () {
        [owner, addr1] = await ethers.getSigners();

        let offensivePilot = [];
        let defensivePilot = [];
        let fleetTracker = [
          1000, // _offensiveSifGattaca, 
          0, //_offensiveMhrudvogThrot, 
          50, //_offensiveDrebentraakht,
          0, //_defensiveCitadelId,
          0, //_defensiveSifGattaca, 
          250, //_defensiveMhrudvogThrot, 
          0 //_defensiveDrebentraakht
        ]

        let osd1, omd1, odd1, dsd1, dmd1, ddd1;
        [ osd1, omd1, odd1, dsd1, dmd1, ddd1 ] = await this.combatEngineV1.calculateDestroyedFleet(
          offensivePilot, defensivePilot, fleetTracker
        );

        
        // doublt offensive fleet. should see defenders destroyed increase
        // and offensive fleet stay static or shrink.
        fleetTracker = [
          2000, // _offensiveSifGattaca, 
          0, //_offensiveMhrudvogThrot, 
          100, //_offensiveDrebentraakht,
          0, //_defensiveCitadelId,
          0, //_defensiveSifGattaca, 
          250, //_defensiveMhrudvogThrot, 
          0 //_defensiveDrebentraakht
        ]

        let osd2, omd2, odd2, dsd2, dmd2, ddd2;
        [ osd2, omd2, odd2, dsd2, dmd2, ddd2 ] = await this.combatEngineV1.calculateDestroyedFleet(
          offensivePilot, defensivePilot, fleetTracker
        );
        
        expect(Number(dmd2.toString())).to.be.greaterThan(Number(dmd1.toString()));
        expect(Number(osd2.toString())).to.be.lessThan(Number(osd1.toString()));
      });

    });

    describe("grid", function () {

      beforeEach(async function () {

      });

      it("calculates grid distance", async function () {

        let dist0 = await this.combatEngineV1.calculateGridDistance(0, 31);
        expect(dist0).to.equal(31);

        let dist1 = await this.combatEngineV1.calculateGridDistance(0, 66);
        expect(dist1).to.equal(2);

        let dist3 = await this.combatEngineV1.calculateGridDistance(31, 95);
        expect(dist3).to.equal(2);

        let dist4 = await this.combatEngineV1.calculateGridDistance(95, 31);
        expect(dist4).to.equal(2);

        let dist5 = await this.combatEngineV1.calculateGridDistance(0, 1023);
        expect(dist5).to.equal(43);

        let dist6 = await this.combatEngineV1.calculateGridDistance(0, 106);
        expect(dist6).to.equal(10);

        let dist7 = await this.combatEngineV1.calculateGridDistance(512, 513);
        expect(dist7).to.equal(1);

      });

      it("calculates grid traversal", async function () {

        let arr = await this.combatEngineV1.calculateGridTraversal(512, 513);
        let timeRaidHits = arr[0];
        let gridDistance = arr[1];
        expect(gridDistance).to.equal(1);
      });


      it("calculates grid multiple", async function () {

        let multiple0 = await this.combatEngineV1.getGridMultiple(0);
        expect(multiple0).to.equal(0);

        let multiple1 = await this.combatEngineV1.getGridMultiple(0);
        expect(multiple1).to.equal(0);

        let multiple2 = await this.combatEngineV1.getGridMultiple(0);
        expect(multiple2).to.equal(0);

        let multiple3 = await this.combatEngineV1.getGridMultiple(0);
        expect(multiple3).to.equal(0);

        let multiple4 = await this.combatEngineV1.getGridMultiple(1023);
        expect(multiple4).to.equal(0);

      });

      it("creates a doom riot", async function () {

        let multiple0 = await this.combatEngineV1.getGridMultiple(0);
        expect(multiple0).to.equal(0);

        await this.combatEngineV1.doomRiot(0, 35);
        
        multiple0 = await this.combatEngineV1.getGridMultiple(0);
        expect(multiple0).to.equal(35);

        await this.combatEngineV1.doomRiot(0, 0);

        multiple0 = await this.combatEngineV1.getGridMultiple(0);
        expect(multiple0).to.equal(0);

      });

    });


});