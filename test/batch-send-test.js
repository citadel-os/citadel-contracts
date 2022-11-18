const { expect } = require('chai');
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');


// Start test block
describe('batch send drakma token', function () {
  before(async function () {
    this.Drakma = await ethers.getContractFactory('Drakma');
    this.BatchSend = await ethers.getContractFactory('BatchSend');
  });

  beforeEach(async function () {
    this.drakma = await this.Drakma.deploy();
    await this.drakma.deployed();

    this.batchSend = await this.BatchSend.deploy(this.drakma.address);
    await this.batchSend.deployed();
  });

  describe('batch send', function () {

    it('sends 100 drakma to one person', async function () {
      
        const [owner, addr2] = await ethers.getSigners();

        await this.drakma.mintDrakma(this.batchSend.address, 100);
        var totalSupply = await this.drakma.totalSupply();
        expect(totalSupply.toNumber()).to.equal(100);

        const sendTo = [addr2.address];
        const sendAmt = [100]

        await this.batchSend.multisendToken(sendTo, sendAmt);

        var addr2Balance = await this.drakma.balanceOf(addr2.address);
        expect(addr2Balance.toNumber()).to.equal(100);

    });

    it('sends 100 drakma to two people', async function () {
      
        const [owner, addr2, addr3] = await ethers.getSigners();

        await this.drakma.mintDrakma(this.batchSend.address, 200);
        var totalSupply = await this.drakma.totalSupply();
        expect(totalSupply.toNumber()).to.equal(200);

        const sendTo = [addr2.address, addr3.address];
        const sendAmt = [100, 100];

        await this.batchSend.multisendToken(sendTo, sendAmt);

        var addr2Balance = await this.drakma.balanceOf(addr2.address);
        expect(addr2Balance.toNumber()).to.equal(100);

        var addr3Balance = await this.drakma.balanceOf(addr3.address);
        expect(addr3Balance.toNumber()).to.equal(100);

    });
});
});