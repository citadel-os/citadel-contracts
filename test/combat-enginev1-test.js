var chai = require("chai");
const expect = chai.expect;
const { BN, expectEvent, expectRevert } = require("@openzeppelin/test-helpers");
const { solidity } = require("ethereum-waffle");
const { ethers } = require("hardhat");

chai.use(solidity);

describe("combat engine v1", function () {
    const ETH_DIVISOR = 1000000000000000000;
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
    
    describe.only("combat engine", function () {
      let sifGattacaOP = 0;
      let mhrudvogThrotOP = 0;
      let drebentraakhtOP = 0;


      beforeEach(async function () {
        sifGattacaOP = await this.combatEngineV1.sifGattacaOP();
        mhrudvogThrotOP = await this.combatEngineV1.mhrudvogThrotOP();
        drebentraakhtOP = await this.combatEngineV1.drebentraakhtOP();
      });

      it("checks basic op", async function () {
        [owner, addr1] = await ethers.getSigners();
        let sifGattaca = 100;
        let mhrudvogThrot = 0;
        let drebentraakht = 5;
        let pilot = [];

        let expectedOP = (sifGattaca * sifGattacaOP) + 
          (mhrudvogThrot * mhrudvogThrotOP) +
          (drebentraakht * drebentraakhtOP);
        let op = await this.combatEngineV1.combatOP(0, pilot, sifGattaca, mhrudvogThrot, drebentraakht);
        
        expect(op).to.equal(expectedOP);
      });
    });


});