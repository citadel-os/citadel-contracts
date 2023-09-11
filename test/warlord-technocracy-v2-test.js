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

describe.only("warlord technocracy v2", function () {

    before(async function () {
        this.CitadelNFT = await ethers.getContractFactory("CitadelNFT");
        this.PilotNFT = await ethers.getContractFactory("PilotNFT");
        this.Drakma = await ethers.getContractFactory("Drakma");
        this.CitadelExordium = await ethers.getContractFactory("CitadelExordium");
        this.CombatEngineV2 = await ethers.getContractFactory("CombatEngineV2");
        this.TechnocracyStorageV2 = await ethers.getContractFactory("TechnocracyStorageV2");
        this.WarlordTechnocracyV2 = await ethers.getContractFactory("WarlordTechnocracyV2");
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

      this.combatEngineV2 = await this.CombatEngineV2.deploy(
        this.pilotNFT.address
      );
      await this.combatEngineV2.deployed();

      this.technocracyStorageV2 = await this.TechnocracyStorageV2.deploy(
        this.combatEngineV2.address
      );
      await this.technocracyStorageV2.deployed();

      this.warlordTechnocracyV2 = await this.WarlordTechnocracyV2.deploy(
        this.citadelNFT.address,
        this.pilotNFT.address,
        this.drakma.address,
        this.technocracyStorageV2.address,
        this.combatEngineV2.address
      );
      await this.warlordTechnocracyV2.deployed();

      this.technocracyStorageV2.updateAccessAddress(this.warlordTechnocracyV2.address);

      await this.drakma.mintDrakma(this.warlordTechnocracyV2.address, "2400000000000000000000000000");
    });
    
    describe("lite to grid", function () {
        beforeEach(async function () {
            [owner, addr1] = await ethers.getSigners();
            await this.pilotNFT.reservePILOT(256);
            await this.citadelNFT.reserveCitadel(1024);

        });

      it("lites 2 pilot to grid", async function () {
        [owner, addr1] = await ethers.getSigners();

        await this.warlordTechnocracyV2.liteGrid([1,2], 512, 1);
        
      });



    describe("dims grid", function () {
        beforeEach(async function () {
            [owner, addr1] = await ethers.getSigners();
            await this.pilotNFT.reservePILOT(256);
            await this.citadelNFT.reserveCitadel(1024);

        });


    });

    describe("claims drakma from grid", function () {
        beforeEach(async function () {
            [owner, addr1] = await ethers.getSigners();
            await this.pilotNFT.reservePILOT(256);
            await this.citadelNFT.reserveCitadel(1024);

        });


    });

    describe("raiding", function () {
        beforeEach(async function () {
            [owner, addr1] = await ethers.getSigners();
            await this.pilotNFT.reservePILOT(256);
            await this.citadelNFT.reserveCitadel(1024);

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
})
});
