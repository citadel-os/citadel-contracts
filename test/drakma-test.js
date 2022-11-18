const { expect } = require('chai');
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');


// Start test block
describe('drakma token', function () {
  before(async function () {
    this.Drakma = await ethers.getContractFactory('Drakma');
  });

  beforeEach(async function () {
    this.drakma = await this.Drakma.deploy();
    await this.drakma.deployed();
  });

  describe('minting', function () {

    it('gets total supply', async function () {
      
      var totalSupply = await this.drakma.totalSupply();
      expect(totalSupply.toNumber()).to.equal(0);
    });

    it('mints a token', async function () {
      
      const [owner] = await ethers.getSigners();
      await this.drakma.mintDrakma(owner.address, 1);
      var totalSupply = await this.drakma.totalSupply();
      expect(totalSupply.toNumber()).to.equal(1);
    });

    it('reverts mint from unauthorized address', async function () {
      
      [owner, addr2] = await ethers.getSigners();

      await expectRevert(
        this.drakma.connect(addr2).mintDrakma(addr2.address, 1),
        'drakma: must have minter role to mint',
      );
      
      var totalSupply = await this.drakma.totalSupply();
      expect(totalSupply.toNumber()).to.equal(0);
    });

    it('mints tokens to enforced cap', async function () {
      
      const [owner] = await ethers.getSigners();
      await this.drakma.mintDrakma(owner.address, "10000000000000000000000000000");
      var totalSupply = await this.drakma.totalSupply();
      expect(totalSupply).to.equal("10000000000000000000000000000");
    });

    it('mints tokens above enforced cap', async function () {
      
      const [owner] = await ethers.getSigners();
      await expectRevert(
        this.drakma.mintDrakma(owner.address, "10000000000000000000000000001"),
        'ERC20Capped: cap exceeded',
      );

      var totalSupply = await this.drakma.totalSupply();
      expect(totalSupply.toNumber()).to.equal(0);
    });

  });

  describe('administration', function () {
    it('adds minter address', async function () {
      
      [owner, addr2] = await ethers.getSigners();

      await this.drakma.addMinter(addr2.address);    
      await this.drakma.mintDrakma(addr2.address, 1);
      var totalSupply = await this.drakma.totalSupply();
      expect(totalSupply.toNumber()).to.equal(1);
    });

    it('reverts add minter from unauthorized acct', async function () {
      
      [owner, addr2] = await ethers.getSigners();

      await expectRevert(
        this.drakma.connect(addr2).addMinter(addr2.address),
        'drakma: must have dev role to add role',
      );
    });

  describe('burning', function () {
    it('mints 1M drakma, burns 500,000 drakma', async function () {
      
      const [owner] = await ethers.getSigners();
      await this.drakma.mintDrakma(owner.address, 1000000);
      var totalSupply = await this.drakma.totalSupply();
      expect(totalSupply.toNumber()).to.equal(1000000);

      await this.drakma.burnDrakma(owner.address, 500000);
      var totalSupply = await this.drakma.totalSupply();
      expect(totalSupply.toNumber()).to.equal(500000);
    });
  });

  describe('transfer', function () {
    it('mints 1M drakma, transfers 500,000 drakma', async function () {
      
      const [owner, addr2] = await ethers.getSigners();
      await this.drakma.mintDrakma(owner.address, 1000000);
      var ownerBalance = await this.drakma.balanceOf(owner.address);
      expect(ownerBalance.toNumber()).to.equal(1000000);

      totalSupply = await this.drakma.totalSupply();
      var totalSupply = await this.drakma.totalSupply();
      expect(totalSupply.toNumber()).to.equal(1000000);

      await this.drakma.transfer(addr2.address, 500000);
      var ownerBalance = await this.drakma.balanceOf(owner.address);
      expect(ownerBalance.toNumber()).to.equal(500000);
      var addr2Balance = await this.drakma.balanceOf(addr2.address);
      expect(addr2Balance.toNumber()).to.equal(500000);

      totalSupply = await this.drakma.totalSupply();
      expect(totalSupply.toNumber()).to.equal(1000000);
    });

    it('reverts transfer that exceeds balance', async function () {
      
      const [owner, addr2] = await ethers.getSigners();
      await this.drakma.mintDrakma(owner.address, 1000000);

      await expectRevert(
        this.drakma.connect(addr2).transfer(owner.address, 1000000),
        'ERC20: transfer amount exceeds balance',
      );

    });
  });
});
});