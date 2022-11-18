var chai = require("chai");
const expect = chai.expect;
const { BN, expectEvent, expectRevert } = require("@openzeppelin/test-helpers");
const { solidity } = require("ethereum-waffle");
const { ethers } = require("hardhat");

chai.use(solidity);

describe.only("pilot", function () {
    const ETH_DIVISOR = 1000000000000000000;
    before(async function () {
        this.CitadelNFT = await ethers.getContractFactory("CitadelNFT");
        this.PilotNFT = await ethers.getContractFactory("PilotNFT");
        this.Drakma = await ethers.getContractFactory("Drakma");
        this.CitadelExordium = await ethers.getContractFactory("CitadelExordium");
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
        this.pilotNFT = await this.PilotNFT.deploy(
            this.drakma.address,
            this.citadelExordium.address,
            "https://gateway.pinata.cloud/ipfs/QmUEWVbqGG31kVZqTBZsEYk3z26djBPMPxhHxuV3893kHX/"
          );
        await this.pilotNFT.deployed();
      });
    
    describe("claim while staked", function () {

        beforeEach(async function () {
            [owner, addr1] = await ethers.getSigners();

            await this.pilotNFT.updateClaimParams(true);

            await this.drakma.mintDrakma(this.citadelExordium.address, "2400000000000000000000000000");
            var totalSupply = await this.drakma.totalSupply();
            expect(Number(totalSupply.toString())).to.equal(2400000000000000000000000000);
            var exordiumBalance = await this.drakma.balanceOf(this.citadelExordium.address);
            expect(Number(exordiumBalance.toString())).to.equal(2400000000000000000000000000);

            await this.citadelNFT.reserveCitadel(2);
            await this.pilotNFT.reservePILOT(64);
      
            var citadelBalance = await this.citadelNFT.balanceOf(owner.address);
            expect(citadelBalance.toNumber()).to.eq(2);

            var pilotBalance = await this.pilotNFT.balanceOf(owner.address);
            expect(pilotBalance.toNumber()).to.eq(64);

            await this.citadelNFT.transferFrom(owner.address, addr1.address, 0);
            await this.citadelNFT.transferFrom(owner.address, addr1.address, 1);
            citadelBalance = await this.citadelNFT.balanceOf(addr1.address);
            expect(citadelBalance.toNumber()).to.eq(2);

            await this.citadelNFT.connect(addr1).approve(this.citadelExordium.address, 0);
            await this.citadelNFT.connect(addr1).approve(this.citadelExordium.address, 1);

            const citadelToStake = [0,1];
            await this.citadelExordium.connect(addr1).stake(citadelToStake, 0);

            var userStakingInfo = await this.citadelExordium.userStakeInfo(addr1.address);
            expect(userStakingInfo[0]).to.equal(32);
            expect(userStakingInfo[1]).to.equal(0);

        });

        it("claims 2 pilot for 128,000 DK", async function () {
            [owner, addr1] = await ethers.getSigners();

            await this.drakma.mintDrakma(addr1.address, "128000000000000000000000");
            var drakmaBalance = await this.drakma.balanceOf(addr1.address);
            expect(Number(drakmaBalance.toString())).to.equal(128000000000000000000000);

            await this.drakma.connect(addr1).approve(this.pilotNFT.address, "128000000000000000000000");
            await this.pilotNFT.connect(addr1).claim(0);
            await this.pilotNFT.connect(addr1).claim(1);
            var pilotBalance = await this.pilotNFT.balanceOf(addr1.address);
            expect(pilotBalance.toNumber()).to.eq(2);

            drakmaBalance = await this.drakma.balanceOf(addr1.address);
            expect(Number(drakmaBalance.toString())).to.equal(0);

            pilotTokenId = await this.pilotNFT.getCitadelClaim(0);
            expect(pilotTokenId).to.equal(64);

            pilotTokenId = await this.pilotNFT.getCitadelClaim(1);
            expect(pilotTokenId).to.equal(65);
        });

        it("claims 2 pilot for 128,000 DK, withdraws contract DK", async function () {
            [owner, addr1] = await ethers.getSigners();

            await this.drakma.mintDrakma(addr1.address, "128000000000000000000000");
            var drakmaBalance = await this.drakma.balanceOf(addr1.address);
            expect(Number(drakmaBalance.toString())).to.equal(128000000000000000000000);

            await this.drakma.connect(addr1).approve(this.pilotNFT.address, "128000000000000000000000");
            await this.pilotNFT.connect(addr1).claim(0);
            await this.pilotNFT.connect(addr1).claim(1);
            var pilotBalance = await this.pilotNFT.balanceOf(addr1.address);
            expect(pilotBalance.toNumber()).to.eq(2);

            drakmaBalance = await this.drakma.balanceOf(addr1.address);
            expect(Number(drakmaBalance.toString())).to.equal(0);

            pilotTokenId = await this.pilotNFT.getCitadelClaim(0);
            expect(pilotTokenId).to.equal(64);

            pilotTokenId = await this.pilotNFT.getCitadelClaim(1);
            expect(pilotTokenId).to.equal(65);

            await this.pilotNFT.withdrawDrakma("128000000000000000000000");
            var ownerDrakmaBalance = await this.drakma.balanceOf(owner.address);
            expect(Number(ownerDrakmaBalance.toString())).to.equal(128000000000000000000000);

        });

        it("reverts PILOT claim sent with insufficient DK", async function () {
            [owner, addr1] = await ethers.getSigners();

            await this.drakma.mintDrakma(addr1.address, "5000000000000000000000");
            var drakmaBalance = await this.drakma.balanceOf(addr1.address);
            expect(Number(drakmaBalance.toString())).to.equal(5000000000000000000000);

            await this.drakma.connect(addr1).approve(this.pilotNFT.address, "5000000000000000000000");
            await expectRevert(
                this.pilotNFT.connect(addr1).claim(0),
                "ERC20: insufficient allowance"
            );

            var pilotBalance = await this.pilotNFT.balanceOf(addr1.address);
            expect(pilotBalance.toNumber()).to.eq(0);

            drakmaBalance = await this.drakma.balanceOf(addr1.address);
            expect(Number(drakmaBalance.toString())).to.equal(5000000000000000000000);
        });

        it("reverts double claim from CITADEL", async function () {
            [owner, addr1] = await ethers.getSigners();

            await this.drakma.mintDrakma(addr1.address, "128000000000000000000000");
            var drakmaBalance = await this.drakma.balanceOf(addr1.address);
            expect(Number(drakmaBalance.toString())).to.equal(128000000000000000000000);

            await this.drakma.connect(addr1).approve(this.pilotNFT.address, "128000000000000000000000");
            await this.pilotNFT.connect(addr1).claim(0);

            var pilotBalance = await this.pilotNFT.balanceOf(addr1.address);
            expect(pilotBalance.toNumber()).to.eq(1);

            drakmaBalance = await this.drakma.balanceOf(addr1.address);
            expect(Number(drakmaBalance.toString())).to.equal(64000000000000000000000);

            await expectRevert(
                this.pilotNFT.connect(addr1).claim(0),
                "CITADEL has already claimed a PILOT"
            );

            var pilotBalance = await this.pilotNFT.balanceOf(addr1.address);
            expect(pilotBalance.toNumber()).to.eq(1);

            drakmaBalance = await this.drakma.balanceOf(addr1.address);
            expect(Number(drakmaBalance.toString())).to.equal(64000000000000000000000);
        });
    });

    describe("claim un-staked", function () {

        beforeEach(async function () {
            [owner, addr1] = await ethers.getSigners();

            await this.pilotNFT.updateClaimParams(true);

            await this.drakma.mintDrakma(this.citadelExordium.address, "2400000000000000000000000000");
            var totalSupply = await this.drakma.totalSupply();
            expect(Number(totalSupply.toString())).to.equal(2400000000000000000000000000);
            var exordiumBalance = await this.drakma.balanceOf(this.citadelExordium.address);
            expect(Number(exordiumBalance.toString())).to.equal(2400000000000000000000000000);

            await this.citadelNFT.reserveCitadel(1);
            await this.pilotNFT.reservePILOT(64);
      
            var citadelBalance = await this.citadelNFT.balanceOf(owner.address);
            expect(citadelBalance.toNumber()).to.eq(1);

            var pilotBalance = await this.pilotNFT.balanceOf(owner.address);
            expect(pilotBalance.toNumber()).to.eq(64);

            await this.citadelNFT.transferFrom(owner.address, addr1.address, 0);
            citadelBalance = await this.citadelNFT.balanceOf(addr1.address);
            expect(citadelBalance.toNumber()).to.eq(1);
        });

        it("reverts claim of PILOT with unstaked CITADEL", async function () {
            [owner, addr1] = await ethers.getSigners();

            await this.drakma.mintDrakma(addr1.address, "64000000000000000000000");
            var drakmaBalance = await this.drakma.balanceOf(addr1.address);
            expect(Number(drakmaBalance.toString())).to.equal(64000000000000000000000);

            await this.drakma.connect(addr1).approve(this.pilotNFT.address, "64000000000000000000000");
            
            await expectRevert(
                this.pilotNFT.connect(addr1).claim(0),
                "CITADEL must be staked to EXORDIUM to claim PILOT"
            );

            var pilotBalance = await this.pilotNFT.balanceOf(addr1.address);
            expect(pilotBalance.toNumber()).to.eq(0);

            drakmaBalance = await this.drakma.balanceOf(addr1.address);
            expect(Number(drakmaBalance.toString())).to.equal(64000000000000000000000);
        });
    });

    describe("mint", function () {

        beforeEach(async function () {
            [owner, addr1] = await ethers.getSigners();
            await this.pilotNFT.reservePILOT(64);

            var pilotBalance = await this.pilotNFT.balanceOf(owner.address);
            expect(pilotBalance.toNumber()).to.eq(64);
        });

        it('mints a pilot', async function() {
            const [owner, addr1] = await ethers.getSigners();
            await this.pilotNFT.updateMintParams("100000000000000000", 256, true, "2000000000000000000000000", "256000000000000000000000");
            const pilotPrice = await this.pilotNFT.pilotPrice();
            const tokenId = await this.pilotNFT.totalSupply();

            const prov = ethers.provider;
            const prevBalance = await prov.getBalance(addr1.address) / ETH_DIVISOR;

            expect(
              await this.pilotNFT.connect(addr1).mintPilot(1, {
                value: pilotPrice,
              })
            ).to.emit(this.pilotNFT, "Transfer")
            .withArgs(ethers.constants.AddressZero, addr1.address, tokenId);

            var pilotBalance = await this.pilotNFT.balanceOf(addr1.address);
            expect(pilotBalance.toNumber()).to.eq(1);

            const newBalance = await prov.getBalance(addr1.address) / ETH_DIVISOR;
            expect(newBalance).to.be.lessThan(prevBalance);
        });

        it('mints 5 pilot', async function() {
            const [owner, addr1] = await ethers.getSigners();
            await this.pilotNFT.updateMintParams("100000000000000000", 256, true, "2000000000000000000000000", "256000000000000000000000");
            const pilotPrice = await this.pilotNFT.pilotPrice();
            const tokenId = await this.pilotNFT.totalSupply();

            const prov = ethers.provider;
            const prevBalance = await prov.getBalance(addr1.address) / ETH_DIVISOR;

            ethToSend = pilotPrice * 5;
            expect(
              await this.pilotNFT.connect(addr1).mintPilot(5, {
                value: ethToSend.toString(),
              })
            ).to.emit(this.pilotNFT, "Transfer")
            .withArgs(ethers.constants.AddressZero, addr1.address, tokenId);

            var pilotBalance = await this.pilotNFT.balanceOf(addr1.address);
            expect(pilotBalance.toNumber()).to.eq(5);

            const newBalance = await prov.getBalance(addr1.address) / ETH_DIVISOR;
            expect(newBalance).to.be.lessThan(prevBalance);
        });

        it('reverts pilot mint with not enough eth sent', async function() {
            const [owner, addr1] = await ethers.getSigners();
            await this.pilotNFT.updateMintParams("100000000000000000", 256, true, "2000000000000000000000000", "256000000000000000000000");
            const pilotPrice = await this.pilotNFT.pilotPrice();
            const tokenId = await this.pilotNFT.totalSupply();

            tooLittleEth = pilotPrice / 2;
            await expectRevert(
                this.pilotNFT.connect(addr1).mintPilot(1, {
                    value: tooLittleEth.toString(),
                  }),
                "Not enough eth sent with transaction"
            );

            var pilotBalance = await this.pilotNFT.balanceOf(addr1.address);
            expect(pilotBalance.toNumber()).to.eq(0);
        });

        it('reverts pilot mint when mint function off', async function() {
            const [owner, addr1] = await ethers.getSigners();
            const pilotPrice = await this.pilotNFT.pilotPrice();

            await expectRevert(
                this.pilotNFT.connect(addr1).mintPilot(5, {
                    value: pilotPrice,
                  }),
                "PILOT mint is currently off"
            );

            var pilotBalance = await this.pilotNFT.balanceOf(addr1.address);
            expect(pilotBalance.toNumber()).to.eq(0);
        });

        it('reverts pilot mint when mint amount exceeds mint max', async function() {
            const [owner, addr1] = await ethers.getSigners();
            await this.pilotNFT.updateMintParams("100000000000000000", 1, true, "2000000000000000000000000", "256000000000000000000000");
            const pilotPrice = await this.pilotNFT.pilotPrice();

            const ethToSend = pilotPrice * 5;
            await expectRevert(
                this.pilotNFT.connect(addr1).mintPilot(5, {
                    value: ethToSend.toString(),
                  }),
                "Mint amount exceeded max pilot count"
            );

            var pilotBalance = await this.pilotNFT.balanceOf(addr1.address);
            expect(pilotBalance.toNumber()).to.eq(0);
        });

        it('reverts pilot mint when max supply is exceeded', async function() {
            const [owner, addr1] = await ethers.getSigners();
            await this.pilotNFT.reservePILOT(1983);
            await this.pilotNFT.updateMintParams("100000000000000000", 5, true, "2000000000000000000000000", "256000000000000000000000");
            const pilotPrice = await this.pilotNFT.pilotPrice();

            const ethToSend = pilotPrice * 2;
            await expectRevert(
                this.pilotNFT.connect(addr1).mintPilot(2, {
                    value: ethToSend.toString(),
                  }),
                "Purchase would exceed max supply of pilot nft"
            );

            var pilotBalance = await this.pilotNFT.balanceOf(addr1.address);
            expect(pilotBalance.toNumber()).to.eq(0);
        });

        it('mints 5 pilot, withdraws eth', async function() {
            const [owner, addr1] = await ethers.getSigners();
            await this.pilotNFT.updateMintParams("100000000000000000", 256, true, "2000000000000000000000000", "256000000000000000000000");
            const pilotPrice = await this.pilotNFT.pilotPrice();
            const tokenId = await this.pilotNFT.totalSupply();

            const prov = ethers.provider;
            const prevBalanceAddr1 = await prov.getBalance(addr1.address) / ETH_DIVISOR;
            const prevBalanceOwner = await prov.getBalance(owner.address) / ETH_DIVISOR;

            ethToSend = pilotPrice * 5;
            expect(
              await this.pilotNFT.connect(addr1).mintPilot(5, {
                value: ethToSend.toString(),
              })
            ).to.emit(this.pilotNFT, "Transfer")
            .withArgs(ethers.constants.AddressZero, addr1.address, tokenId);

            var pilotBalance = await this.pilotNFT.balanceOf(addr1.address);
            expect(pilotBalance.toNumber()).to.eq(5);

            const newBalanceAddr1 = await prov.getBalance(addr1.address) / ETH_DIVISOR;
            expect(newBalanceAddr1).to.be.lessThan(prevBalanceAddr1);

            await this.pilotNFT.withdrawEth();

            const newBalanceOwner = await prov.getBalance(owner.address) / ETH_DIVISOR;
            expect(newBalanceOwner).to.be.greaterThan(prevBalanceOwner);
        });

        it('mints 5 pilot, turns contract off, reverts next mint', async function() {
            const [owner, addr1] = await ethers.getSigners();
            await this.pilotNFT.updateMintParams("100000000000000000", 256, true, "2000000000000000000000000", "256000000000000000000000");
            const pilotPrice = await this.pilotNFT.pilotPrice();
            const tokenId = await this.pilotNFT.totalSupply();

            const prov = ethers.provider;
            const prevBalanceAddr1 = await prov.getBalance(addr1.address) / ETH_DIVISOR;

            ethToSend = pilotPrice * 5;
            expect(
              await this.pilotNFT.connect(addr1).mintPilot(5, {
                value: ethToSend.toString(),
              })
            ).to.emit(this.pilotNFT, "Transfer")
            .withArgs(ethers.constants.AddressZero, addr1.address, tokenId);

            var pilotBalance = await this.pilotNFT.balanceOf(addr1.address);
            expect(pilotBalance.toNumber()).to.eq(5);

            const newBalanceAddr1 = await prov.getBalance(addr1.address) / ETH_DIVISOR;
            expect(newBalanceAddr1).to.be.lessThan(prevBalanceAddr1);

            await this.pilotNFT.updateMintParams("100000000000000000", 0, false, "2000000000000000000000000", "256000000000000000000000");

            await expectRevert(
                this.pilotNFT.connect(addr1).mintPilot(5, {
                    value: ethToSend.toString(),
                  }),
                "PILOT mint is currently off"
            );

            pilotBalance = await this.pilotNFT.balanceOf(addr1.address);
            expect(pilotBalance.toNumber()).to.eq(5);

        });
    });

    describe("max supply", function () {

      beforeEach(async function () {

      });

      it('reserves 2048 PILOT, 2049th reverted when max supply exceeded', async function() {
        const [owner, addr1] = await ethers.getSigners();
        await this.pilotNFT.reservePILOT(2048);

        var pilotBalance = await this.pilotNFT.balanceOf(owner.address);
        expect(pilotBalance.toNumber()).to.eq(2048);

        await expectRevert(
          this.pilotNFT.reservePILOT(1),
          "MAX_SUPPLY"
        );

      });

    });

    describe("on-chain upgrades", function () {

        beforeEach(async function () {

        });

        it('mints and uplevels a pilot', async function() {
            const [owner, addr1] = await ethers.getSigners();
            await this.drakma.mintDrakma(addr1.address, "100000000000000000000000");
            await this.drakma.connect(addr1).approve(this.pilotNFT.address, "100000000000000000000000");

            await this.pilotNFT.updateMintParams("100000000000000000", 256, true, "5000000000000000000000000", "100000000000000000000000");
            const pilotPrice = await this.pilotNFT.pilotPrice();
            const tokenId = await this.pilotNFT.totalSupply();

            expect(
              await this.pilotNFT.connect(addr1).mintPilot(1, {
                value: pilotPrice,
              })
            ).to.emit(this.pilotNFT, "Transfer")
            .withArgs(ethers.constants.AddressZero, addr1.address, tokenId);

            var pilotBalance = await this.pilotNFT.balanceOf(addr1.address);
            expect(pilotBalance.toNumber()).to.eq(1);

            [sovereign, level] = await this.pilotNFT.getOnchainPILOT(0);
            expect(sovereign).to.equal(false);
            expect(level).to.equal(0);

            await this.pilotNFT.connect(addr1).upLevel(0);
            [sovereign, level] = await this.pilotNFT.getOnchainPILOT(0);
            expect(sovereign).to.equal(false);
            expect(level).to.equal(1);

            drakmaBalance = await this.drakma.balanceOf(addr1.address);
            expect(Number(drakmaBalance.toString())).to.equal(0);
        });

        it('reserves 2 pilot, grants sovereignty', async function() {
          const [owner, addr1] = await ethers.getSigners();
          await this.drakma.mintDrakma(addr1.address, "8000000000000000000000000");
          await this.drakma.connect(addr1).approve(this.pilotNFT.address, "4000000000000000000000000");

          await this.pilotNFT.reservePILOT(2);
          await this.pilotNFT.transferFrom(owner.address, addr1.address, 0);
          await this.pilotNFT.transferFrom(owner.address, addr1.address, 1);

          var pilotBalance = await this.pilotNFT.balanceOf(addr1.address);
          expect(pilotBalance.toNumber()).to.eq(2);

          [sovereign, level] = await this.pilotNFT.getOnchainPILOT(0);
          expect(sovereign).to.equal(false);
          expect(level).to.equal(0);

          [sovereign, level] = await this.pilotNFT.getOnchainPILOT(1);
          expect(sovereign).to.equal(false);
          expect(level).to.equal(0);

          await this.pilotNFT.connect(addr1).sovereignty(0);
          [sovereign, level] = await this.pilotNFT.getOnchainPILOT(0);
          expect(sovereign).to.equal(true);
          expect(level).to.equal(0);

          drakmaBalance = await this.drakma.balanceOf(addr1.address);
          expect(Number(drakmaBalance.toString())).to.equal(4000000000000000000000000);

          await this.drakma.connect(addr1).approve(this.pilotNFT.address, "4000000000000000000000000");
          await this.pilotNFT.connect(addr1).sovereignty(1);
          [sovereign, level] = await this.pilotNFT.getOnchainPILOT(1);
          expect(sovereign).to.equal(true);
          expect(level).to.equal(0);
          
          drakmaBalance = await this.drakma.balanceOf(addr1.address);
          expect(Number(drakmaBalance.toString())).to.equal(0);
      });

      it('reserves 65 pilot, grants sovereignty to 64, reverts 1', async function() {
        const [owner, addr1] = await ethers.getSigners();
        await this.drakma.mintDrakma(addr1.address, "256000000000000000000000000");
        await this.drakma.connect(addr1).approve(this.pilotNFT.address, "256000000000000000000000000");

        await this.pilotNFT.reservePILOT(65);

        for(i=0; i < 65; i++) {
          await this.pilotNFT.transferFrom(owner.address, addr1.address, i);
        }

        var pilotBalance = await this.pilotNFT.balanceOf(addr1.address);
        expect(pilotBalance.toNumber()).to.eq(65);

        for(i=0; i < 64; i++) {
          await this.pilotNFT.connect(addr1).sovereignty(i);
          [sovereign, level] = await this.pilotNFT.getOnchainPILOT(i);
          expect(sovereign).to.equal(true);
          expect(level).to.equal(0);
        }

        await expectRevert(
          this.pilotNFT.connect(addr1).sovereignty(64),
          "MAX_SOVEREIGN"
        );
      });

      it('reserves 1 pilot, uplevels to 9, reverts 10th', async function() {
        const [owner, addr1] = await ethers.getSigners();
        await this.drakma.mintDrakma(addr1.address, "4500000000000000000000000");
        await this.drakma.connect(addr1).approve(this.pilotNFT.address, "4500000000000000000000000");

        await this.pilotNFT.reservePILOT(1);
        await this.pilotNFT.transferFrom(owner.address, addr1.address, 0);

        var pilotBalance = await this.pilotNFT.balanceOf(addr1.address);
        expect(pilotBalance.toNumber()).to.eq(1);

        for(i=1; i <= 9; i++) {
          await this.pilotNFT.connect(addr1).upLevel(0);
          [sovereign, level] = await this.pilotNFT.getOnchainPILOT(0);
          expect(sovereign).to.equal(false);
          expect(level).to.equal(i);
        }

        drakmaBalance = await this.drakma.balanceOf(addr1.address);
        expect(Number(drakmaBalance.toString())).to.equal(0);

        await expectRevert(
          this.pilotNFT.connect(addr1).upLevel(0),
          "MAX_LEVEL"
        );
      });

      it('reserves 1 pilot, uplevels to 1, reverts 2nd with insufficient DK', async function() {
        const [owner, addr1] = await ethers.getSigners();
        await this.drakma.mintDrakma(addr1.address, "100000000000000000000000");
        await this.drakma.connect(addr1).approve(this.pilotNFT.address, "100000000000000000000000");

        await this.pilotNFT.reservePILOT(1);
        await this.pilotNFT.transferFrom(owner.address, addr1.address, 0);

        var pilotBalance = await this.pilotNFT.balanceOf(addr1.address);
        expect(pilotBalance.toNumber()).to.eq(1);

        await this.pilotNFT.connect(addr1).upLevel(0);
        [sovereign, level] = await this.pilotNFT.getOnchainPILOT(0);
        expect(sovereign).to.equal(false);
        expect(level).to.equal(1);

        drakmaBalance = await this.drakma.balanceOf(addr1.address);
        expect(Number(drakmaBalance.toString())).to.equal(0);

        await expectRevert(
          this.pilotNFT.connect(addr1).upLevel(0),
          "ERC20: insufficient allowance"
        );
      });
    });

    describe("administration", function () {

      beforeEach(async function () {

      });


      it('reverts reserve from non-owner account', async function() {
        const [owner, addr1] = await ethers.getSigners();
        await expectRevert(
          this.pilotNFT.connect(addr1).reservePILOT(1),
          "Ownable: caller is not the owner"
        );

      });

      it('reverts withdraw drakma request from non-owner account', async function() {
        const [owner, addr1] = await ethers.getSigners();
        await expectRevert(
          this.pilotNFT.connect(addr1).withdrawDrakma(1),
          "Ownable: caller is not the owner"
        );

      });

      it('reverts withdraw eth request from non-owner account', async function() {
        const [owner, addr1] = await ethers.getSigners();
        await expectRevert(
          this.pilotNFT.connect(addr1).withdrawEth(),
          "Ownable: caller is not the owner"
        );

      });

      it('reverts updateBaseURI request from non-owner account', async function() {
        const [owner, addr1] = await ethers.getSigners();
        await expectRevert(
          this.pilotNFT.connect(addr1).updateBaseURI("https://citadel.pm"),
          "Ownable: caller is not the owner"
        );

      });

      it('reverts updateMintParams request from non-owner account', async function() {
        const [owner, addr1] = await ethers.getSigners();
        await expectRevert(
          this.pilotNFT.connect(addr1).updateMintParams(1, 1, true, "5000000000000000000000000", "100000000000000000000000"),
          "Ownable: caller is not the owner"
        );
      });

      it('updates mint params', async function() {
        const [owner] = await ethers.getSigners();
        await this.pilotNFT.updateMintParams("125000000000000000", 128, true, "1000000000000000000000000", "128000000000000000000000");
        var pilotMintMax = await this.pilotNFT.pilotMintMax();
        expect(pilotMintMax).to.equal(128);
        var pilotPrice = await this.pilotNFT.pilotPrice();
        expect(pilotPrice.toString()).to.equal("125000000000000000");
        var pilotMintOn = await this.pilotNFT.pilotMintOn();
        expect(pilotMintOn).to.equal(true);
        var sovereignPrice = await this.pilotNFT.sovereignPrice();
        expect(sovereignPrice).to.equal("1000000000000000000000000");
        var kultPrice = await this.pilotNFT.kultPrice()
        expect(kultPrice).to.equal("128000000000000000000000");
      });
  });

  describe("claim, mint, reserve all 2048 PILOT", function () {

    beforeEach(async function () {
        [owner, addr1] = await ethers.getSigners();

        await this.pilotNFT.updateClaimParams(true);

        await this.pilotNFT.reservePILOT(256);
        await this.citadelNFT.reserveCitadel(1024);

        var citadelBalance = await this.citadelNFT.balanceOf(owner.address);
        expect(citadelBalance.toNumber()).to.eq(1024);

        var pilotBalance = await this.pilotNFT.balanceOf(owner.address);
        expect(pilotBalance.toNumber()).to.eq(256);

        var citadelToStake = [];
        for(i = 48; i < 80; i++) {
          await this.citadelNFT.approve(this.citadelExordium.address, i);
          citadelToStake.push(i);
        }
        await this.citadelExordium.stake(citadelToStake, 0);
    });

    it("reserves 256 PILOT, claims 32 PILOT for 5120000 DK, mints 15 PILOT, reserves 1745", async function () {
        [owner, addr1] = await ethers.getSigners();

        await this.drakma.mintDrakma(owner.address, "5120000000000000000000000");
        var addr1Balance = await this.drakma.balanceOf(owner.address);
        expect(Number(addr1Balance.toString())).to.equal(5120000000000000000000000);
        await this.drakma.approve(this.pilotNFT.address, "5120000000000000000000000");
        
        var currentTokenId = 256; // 256 reserved
        var counter = 0;
        for(i = 48; i < 80; i++) {
          await this.pilotNFT.claim(i);
          pilotTokenId = await this.pilotNFT.getCitadelClaim(i);
          expect(pilotTokenId).to.equal(currentTokenId + counter);
          [sovereign, level] = await this.pilotNFT.getOnchainPILOT(pilotTokenId);
          expect(level).to.equal(0);
          if (i < 64) {
            expect(sovereign).to.equal(true);
          } else {
            expect(sovereign).to.equal(false);
          }
          counter++;
        }

        var pilotBalance = await this.pilotNFT.balanceOf(owner.address);
        expect(pilotBalance.toNumber()).to.eq(288);

        drakmaBalance = await this.drakma.balanceOf(addr1.address);
        expect(Number(drakmaBalance.toString())).to.equal(0);

        await this.pilotNFT.updateMintParams("180000000000000000", 15, true, "2000000000000000000000000", "256000000000000000000000");
        const pilotPrice = await this.pilotNFT.pilotPrice();
        
        ethToSend = pilotPrice * 5;
        for (i = 0; i < 3; i++) {
          var tokenId = await this.pilotNFT.totalSupply();
          expect(
            await this.pilotNFT.connect(addr1).mintPilot(5, {
              value: ethToSend.toString(),
            })
          ).to.emit(this.pilotNFT, "Transfer")
          .withArgs(ethers.constants.AddressZero, addr1.address, tokenId);
        }

        for (i=288; i < 304; i++) {
          [sovereign, level] = await this.pilotNFT.getOnchainPILOT(i);
          expect(level).to.equal(0);
          expect(sovereign).to.equal(false);
        }

        var pilotBalance = await this.pilotNFT.balanceOf(addr1.address);
        expect(pilotBalance.toNumber()).to.eq(15);

        await this.pilotNFT.reservePILOT(1745);
        var pilotBalance = await this.pilotNFT.balanceOf(owner.address);
        expect(pilotBalance.toNumber()).to.eq(2033);

    });
  });

  describe("sovereign", function () {

    beforeEach(async function () {
        [owner, addr1] = await ethers.getSigners();

        await this.pilotNFT.reservePILOT(16);
        var pilotBalance = await this.pilotNFT.balanceOf(owner.address);
        expect(pilotBalance.toNumber()).to.eq(16);
    });

    it("grants sovereignty, bribes kult twice", async function () {
        [owner, addr1] = await ethers.getSigners();

        await this.drakma.mintDrakma(owner.address, "4200000000000000000000000");
        await this.drakma.approve(this.pilotNFT.address, "4200000000000000000000000");
        
        [sovereign, level] = await this.pilotNFT.getOnchainPILOT(0);
        expect(level).to.equal(0);
        expect(sovereign).to.equal(false);
        
        [isSovereign, chargeCount, kult] = await this.pilotNFT.getSovereign(0);
        expect(chargeCount).to.equal(0);

        await this.pilotNFT.sovereignty(0);
        [isSovereign, chargeCount, kult] = await this.pilotNFT.getSovereign(0);
        expect(isSovereign).to.equal(true);

        await this.pilotNFT.bribeKult(0, 7);
        [isSovereign, chargeCount, kult] = await this.pilotNFT.getSovereign(0);
        expect(isSovereign).to.equal(true);
        expect(chargeCount).to.equal(1);
        expect(kult).to.equal(7);

        await this.pilotNFT.bribeKult(0, 6);
        [isSovereign, chargeCount, kult] = await this.pilotNFT.getSovereign(0);
        expect(isSovereign).to.equal(true);
        expect(chargeCount).to.equal(2);
        expect(kult).to.equal(6);

        var ownerBalance = await this.drakma.balanceOf(owner.address);
        expect(Number(ownerBalance.toString())).to.equal(0);
    });

    it("fails to bribe non-sovereign", async function () {
      const [owner, addr1] = await ethers.getSigners();
      await this.drakma.mintDrakma(owner.address, "4000000000000000000000000");
      await this.drakma.approve(this.pilotNFT.address, "4000000000000000000000000");
      await this.drakma.mintDrakma(addr1.address, "100000000000000000000000");
      await this.drakma.connect(addr1).approve(this.pilotNFT.address, "100000000000000000000000");

      await this.pilotNFT.sovereignty(0);
      [isSovereign, chargeCount, kult] = await this.pilotNFT.getSovereign(0);
      expect(isSovereign).to.equal(true);
      expect(chargeCount).to.equal(0);

      [isSovereign, chargeCount, kult] = await this.pilotNFT.getSovereign(15);
      expect(isSovereign).to.equal(false);
      expect(chargeCount).to.equal(0);

      await expectRevert(
        this.pilotNFT.connect(addr1).bribeKult(15, 7),
        "Must be sovereign to bribe"
      );

      [isSovereign, chargeCount, kult] = await this.pilotNFT.getSovereign(15);
      expect(isSovereign).to.equal(false);
      expect(chargeCount).to.equal(0);

      var ownerBalance = await this.drakma.balanceOf(owner.address);
      expect(Number(ownerBalance.toString())).to.equal(0);

      var addr1Balance = await this.drakma.balanceOf(addr1.address);
      expect(Number(addr1Balance.toString())).to.equal(100000000000000000000000);
  });

  it('grants sovereignty and overthrows', async function() {
    const [owner, addr1] = await ethers.getSigners();
    await this.drakma.mintDrakma(owner.address, "4000000000000000000000000");
    await this.drakma.approve(this.pilotNFT.address, "4000000000000000000000000");
    await this.drakma.mintDrakma(addr1.address, "4000000000000000000000000");
    await this.drakma.connect(addr1).approve(this.pilotNFT.address, "4000000000000000000000000");

    await this.pilotNFT.reservePILOT(2);

    await this.pilotNFT.sovereignty(0);
    [isSovereign, chargeCount, kult] = await this.pilotNFT.getSovereign(0);
    expect(isSovereign).to.equal(true);
    expect(chargeCount).to.equal(0);

    await this.pilotNFT.connect(addr1).overthrowSovereign(0, 1);
    [isSovereign, chargeCount, kult] = await this.pilotNFT.getSovereign(0);
    expect(isSovereign).to.equal(false);
    expect(chargeCount).to.equal(0);

    [isSovereign, chargeCount, kult] = await this.pilotNFT.getSovereign(1);
    expect(isSovereign).to.equal(true);
    expect(chargeCount).to.equal(0);

    var ownerBalance = await this.drakma.balanceOf(owner.address);
    expect(Number(ownerBalance.toString())).to.equal(0);

    var addr1Balance = await this.drakma.balanceOf(addr1.address);
    expect(Number(addr1Balance.toString())).to.equal(0);

  });

  it('reserves 1 pilot, fully bribes kult, reverts', async function() {
    const [owner, addr1] = await ethers.getSigners();
    await this.drakma.mintDrakma(owner.address, "4900000000000000000000000");
    await this.drakma.approve(this.pilotNFT.address, "4900000000000000000000000");

    await this.pilotNFT.reservePILOT(1);

    await this.pilotNFT.sovereignty(0);
    [isSovereign, chargeCount, kult] = await this.pilotNFT.getSovereign(0);
    expect(isSovereign).to.equal(true);
    expect(chargeCount).to.equal(0);

    for(i=0; i<8; i++) {
      await this.pilotNFT.bribeKult(0, 7);
      [isSovereign, chargeCount, kult] = await this.pilotNFT.getSovereign(0);
      expect(isSovereign).to.equal(true);
      expect(chargeCount).to.equal(i+1);
      expect(kult).to.equal(7);
    }

    await expectRevert(
      this.pilotNFT.bribeKult(0, 7),
      "Sovereign is fully charged"
    );

    await expectRevert(
      this.pilotNFT.bribeKult(0, 10),
      "Invalid KULT"
    );

    var ownerBalance = await this.drakma.balanceOf(owner.address);
    expect(Number(ownerBalance.toString())).to.equal(100000000000000000000000);

    for(i=0; i<8; i++) {
      charge = await this.pilotNFT.getSovereignCharge(0, i);
      expect(Number(charge)).to.be.greaterThan(0);
    }
  });

  it('reverts bribe with insufficient drakma', async function() {
    const [owner, addr1] = await ethers.getSigners();
    await this.drakma.mintDrakma(owner.address, "4000000000000000000000000");
    await this.drakma.approve(this.pilotNFT.address, "4000000000000000000000000");

    await this.pilotNFT.reservePILOT(1);

    await this.pilotNFT.sovereignty(0);
    [isSovereign, chargeCount, kult] = await this.pilotNFT.getSovereign(0);
    expect(isSovereign).to.equal(true);
    expect(chargeCount).to.equal(0);

    await expectRevert(
      this.pilotNFT.bribeKult(0, 7),
      "ERC20: insufficient allowance"
    );

    [isSovereign, chargeCount, kult] = await this.pilotNFT.getSovereign(0);
    expect(isSovereign).to.equal(true);
    expect(chargeCount).to.equal(0);

    var ownerBalance = await this.drakma.balanceOf(owner.address);
    expect(Number(ownerBalance.toString())).to.equal(0);

  });

  it('reverts overthrow with insufficient drakma', async function() {
    const [owner, addr1] = await ethers.getSigners();
    await this.drakma.mintDrakma(owner.address, "4000000000000000000000000");
    await this.drakma.approve(this.pilotNFT.address, "4000000000000000000000000");

    await this.pilotNFT.reservePILOT(1);

    await this.pilotNFT.sovereignty(0);
    [isSovereign, chargeCount, kult] = await this.pilotNFT.getSovereign(0);
    expect(isSovereign).to.equal(true);
    expect(chargeCount).to.equal(0);

    await expectRevert(
      this.pilotNFT.connect(addr1).overthrowSovereign(0, 1),
      "ERC20: insufficient allowance"
    );

    [isSovereign, chargeCount, kult] = await this.pilotNFT.getSovereign(0);
    expect(isSovereign).to.equal(true);
    expect(chargeCount).to.equal(0);

    var ownerBalance = await this.drakma.balanceOf(owner.address);
    expect(Number(ownerBalance.toString())).to.equal(0);

  });

  it('overthrows fully bribed pilot', async function() {
    const [owner, addr1] = await ethers.getSigners();
    await this.drakma.mintDrakma(owner.address, "4800000000000000000000000");
    await this.drakma.approve(this.pilotNFT.address, "4800000000000000000000000");
    await this.drakma.mintDrakma(addr1.address, "12000000000000000000000000");
    await this.drakma.connect(addr1).approve(this.pilotNFT.address, "12000000000000000000000000");

    await this.pilotNFT.reservePILOT(2);

    await this.pilotNFT.sovereignty(0);
    [isSovereign, chargeCount, kult] = await this.pilotNFT.getSovereign(0);
    expect(isSovereign).to.equal(true);
    expect(chargeCount).to.equal(0);

    for(i=0; i<8; i++) {
      await this.pilotNFT.bribeKult(0, 7);
      [isSovereign, chargeCount, kult] = await this.pilotNFT.getSovereign(0);
      expect(isSovereign).to.equal(true);
      expect(chargeCount).to.equal(i+1);
      expect(kult).to.equal(7);
    }

    await this.pilotNFT.connect(addr1).overthrowSovereign(0, 1);
    [isSovereign, chargeCount, kult] = await this.pilotNFT.getSovereign(0);
    expect(isSovereign).to.equal(false);
    expect(chargeCount).to.equal(0);

    [isSovereign, chargeCount, kult] = await this.pilotNFT.getSovereign(1);
    expect(isSovereign).to.equal(true);
    expect(chargeCount).to.equal(0);

    var ownerBalance = await this.drakma.balanceOf(owner.address);
    expect(Number(ownerBalance.toString())).to.equal(0);

    var addr1Balance = await this.drakma.balanceOf(addr1.address);
    expect(Number(addr1Balance.toString())).to.equal(0);

  });

  it('reverts overthrow of non-sovereign PILOT', async function() {
    const [owner, addr1] = await ethers.getSigners();
    await this.drakma.mintDrakma(owner.address, "4000000000000000000000000");
    await this.drakma.approve(this.pilotNFT.address, "4000000000000000000000000");
    await this.drakma.mintDrakma(addr1.address, "40000000000000000000000000");
    await this.drakma.connect(addr1).approve(this.pilotNFT.address, "40000000000000000000000000");

    await this.pilotNFT.reservePILOT(3);

    await this.pilotNFT.sovereignty(0);
    [isSovereign, chargeCount, kult] = await this.pilotNFT.getSovereign(0);
    expect(isSovereign).to.equal(true);
    expect(chargeCount).to.equal(0);

    await expectRevert(
      this.pilotNFT.connect(addr1).overthrowSovereign(1, 2),
      "Must overthrow existing sovereign"
    );

    [isSovereign, chargeCount, kult] = await this.pilotNFT.getSovereign(0);
    expect(isSovereign).to.equal(true);
    expect(chargeCount).to.equal(0);

    [isSovereign, chargeCount, kult] = await this.pilotNFT.getSovereign(1);
    expect(isSovereign).to.equal(false);
    expect(chargeCount).to.equal(0);

    var ownerBalance = await this.drakma.balanceOf(owner.address);
    expect(Number(ownerBalance.toString())).to.equal(0);

    var addr1Balance = await this.drakma.balanceOf(addr1.address);
    expect(Number(addr1Balance.toString())).to.equal(40000000000000000000000000);

  });

  });
});