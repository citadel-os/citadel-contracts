var chai = require("chai");
const expect = chai.expect;
const { solidity } = require("ethereum-waffle");

chai.use(solidity);

// Start test block
describe("raffle", function () {
  before(async function () {
    this.Raffle = await ethers.getContractFactory("CitadelRaffle");
  });

  beforeEach(async function () {
    this.raffle = await this.Raffle.deploy();
    await this.raffle.deployed();
  });

  describe("bounds", function () {
    it("does not exceed 3", async function () {
      await this.raffle.updateParameters(0, 3);
      for (var i = 0; i < 1000; i++) {
        const random = await this.raffle.raffle();

        expect(random.toNumber()).greaterThanOrEqual(0);
        expect(random.toNumber()).lessThanOrEqual(3);
      }
    });

    it("does not exceed 50, does not succeed 44", async function () {
      await this.raffle.updateParameters(44, 50);
      for (var i = 0; i < 1000; i++) {
        const random = await this.raffle.raffle();

        expect(random.toNumber()).greaterThanOrEqual(44);
        expect(random.toNumber()).lessThanOrEqual(50);
      }
    });
  });
});
