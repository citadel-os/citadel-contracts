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
    
    describe("combat engine", function () {
      let sifGattacaOP = 0;
      let mhrudvogThrotOP = 0;
      let drebentraakhtOP = 0;
      let sifGattacaDP = 0;
      let mhrudvogThrotDP = 0;
      let drebentraakhtDP = 0;
      let pilotMultiple = 0;
      let levelMultiple = 0;

      beforeEach(async function () {
        sifGattacaOP = await this.combatEngineV1.sifGattacaOP();
        mhrudvogThrotOP = await this.combatEngineV1.mhrudvogThrotOP();
        drebentraakhtOP = await this.combatEngineV1.drebentraakhtOP();
        sifGattacaDP = await this.combatEngineV1.sifGattacaDP();
        mhrudvogThrotDP = await this.combatEngineV1.mhrudvogThrotDP();
        drebentraakhtDP = await this.combatEngineV1.drebentraakhtDP();
        pilotMultiple = await this.combatEngineV1.pilotMultiple();
        levelMultiple = await this.combatEngineV1.levelMultiple();

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
        let op = await this.combatEngineV1.combatOP(0, pilot, sifGattaca, mhrudvogThrot, drebentraakht);
        
        expect(op).to.equal(expectedOP);
      });

      it("get op with pilots", async function () {
        [owner, addr1] = await ethers.getSigners();
        let sifGattaca = 100;
        let mhrudvogThrot = 0;
        let drebentraakht = 0;
        let pilot = [1, 2];

        let expectedOP = ((sifGattaca * sifGattacaOP) + 
          (mhrudvogThrot * mhrudvogThrotOP) +
          (drebentraakht * drebentraakhtOP)) *
          (1 + ((pilot.length * pilotMultiple) / 100));
        let op = await this.combatEngineV1.combatOP(0, pilot, sifGattaca, mhrudvogThrot, drebentraakht);
        expect(op).to.equal(expectedOP);
      });

      it("get op with upleveled pilot", async function () {
        [owner, addr1] = await ethers.getSigners();

        await this.drakma.mintDrakma(owner.address, "100000000000000000000000");
        await this.drakma.approve(this.pilotNFT.address, "100000000000000000000000");
        await this.pilotNFT.upLevel(1);

        let sifGattaca = 100;
        let mhrudvogThrot = 0;
        let drebentraakht = 0;
        let pilot = [1];

        let expectedOP = ((sifGattaca * sifGattacaOP) + 
          (mhrudvogThrot * mhrudvogThrotOP) +
          (drebentraakht * drebentraakhtOP)) *
          (1 + ((pilotMultiple + levelMultiple) / 100));
        let op = await this.combatEngineV1.combatOP(0, pilot, sifGattaca, mhrudvogThrot, drebentraakht);
        expect(op).to.equal(expectedOP);
      });

      it.only("get basic dp", async function () {
        [owner, addr1] = await ethers.getSigners();
        let sifGattaca = 10;
        let mhrudvogThrot = 500;
        let drebentraakht = 5;
        let pilot = [];
  
        let expectedDP = (sifGattaca * sifGattacaDP) + 
          (mhrudvogThrot * mhrudvogThrotDP) +
          (drebentraakht * drebentraakhtDP);
        let dp = await this.combatEngineV1.combatDP(0, pilot, sifGattaca, mhrudvogThrot, drebentraakht);
        console.log(dp, expectedDP);
        
        //expect(dp).to.equal(expectedDP);
      });
    });


});