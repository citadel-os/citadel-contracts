var chai = require("chai");
const expect = chai.expect;
const { BN, expectEvent, expectRevert } = require("@openzeppelin/test-helpers");
const { solidity } = require("ethereum-waffle");
const { ethers } = require("hardhat");

chai.use(solidity);

describe("citadel exordium", function () {
    before(async function () {
        this.CitadelNFT = await ethers.getContractFactory("CitadelNFT");
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
      });
    
    describe("tech tree", function () {

        beforeEach(async function () {
            await this.drakma.mintDrakma(this.citadelExordium.address, "2400000000000000000000000000");
            var totalSupply = await this.drakma.totalSupply();
            expect(Number(totalSupply.toString())).to.equal(2400000000000000000000000000);
            var exordiumBalance = await this.drakma.balanceOf(this.citadelExordium.address);
            expect(Number(exordiumBalance.toString())).to.equal(2400000000000000000000000000);
        });

        it("stakes relik, gains research in tech 0", async function () {
            [owner] = await ethers.getSigners();
            await this.citadelNFT.reserveCitadel(2);
      
            var citadelBalance = await this.citadelNFT.balanceOf(owner.address);
            expect(citadelBalance.toNumber()).to.eq(2);

            await this.citadelNFT.approve(this.citadelExordium.address, 0);
            await this.citadelNFT.approve(this.citadelExordium.address, 1);

            const citadelToStake = [0,1];
            await this.citadelExordium.stake(citadelToStake, 0);

            var userStakingInfo = await this.citadelExordium.userStakeInfo(owner.address);
            expect(userStakingInfo[0]).to.equal(32);
            expect(userStakingInfo[1]).to.equal(0);

            await this.citadelExordium.claimRewards();

            var researchCompleted = await this.citadelExordium.getTechTree(0);
            expect(Number(researchCompleted[0].toString())).to.be.greaterThan(0);
            expect(researchCompleted[1]).to.be.equal(true);

            var researchCompleted = await this.citadelExordium.getTechTree(1);
            expect(Number(researchCompleted[0].toString())).to.be.equal(0);
            expect(researchCompleted[1]).to.be.equal(false);

            var techTree = await this.citadelExordium.getAllTechTree();
            for(var i = 0; i < 32; i++) {
                if(i == 0) {
                    expect(Number(techTree[i].toString())).to.be.greaterThan(0);
                } else {
                    expect(Number(techTree[i].toString())).to.be.equal(0);
                }
            }

            var walletDataFinal = await this.citadelExordium.getStaker(owner.address);
            expect(Number(walletDataFinal[0].toString())).to.be.equal(32); //amt staked (2 relik X 16 per relik)
            expect(Number(walletDataFinal[1].toString())).to.be.equal(0); //unclaimed rewards
            expect(Number(walletDataFinal[2].toString())).to.be.equal(0); //staked tech index
            expect(walletDataFinal[3]).to.be.equal(true); //has tech (preservative algorithms)

            var tokenOwner0 = await this.citadelExordium.getCitadelStaker(0);
            expect(tokenOwner0).to.be.equal(owner.address);

            var tokenOwner5 = await this.citadelExordium.getCitadelStaker(5);
            expect(tokenOwner5).to.be.equal("0x0000000000000000000000000000000000000000");
        });

        it("stakes non-relik, gains no research in tech 0", async function () {
            [owner] = await ethers.getSigners();
            await this.citadelNFT.reserveCitadel(65);
      
            var citadelBalance = await this.citadelNFT.balanceOf(owner.address);
            expect(citadelBalance.toNumber()).to.eq(65);

            await this.citadelNFT.approve(this.citadelExordium.address, 64);

            const citadelToStake = [64];
            await this.citadelExordium.stake(citadelToStake, 0);

            var userStakingInfo = await this.citadelExordium.userStakeInfo(owner.address);
            expect(userStakingInfo[0]).to.equal(4);
            expect(userStakingInfo[1]).to.equal(0);

            await this.citadelExordium.claimRewards();

            var researchCompleted = await this.citadelExordium.getTechTree(0);
            expect(Number(researchCompleted[0].toString())).to.be.equal(0);

        });
    });

    describe("staking", function () {
        beforeEach(async function () {
            await this.drakma.mintDrakma(this.citadelExordium.address, "2400000000000000000000000000");
            var totalSupply = await this.drakma.totalSupply();
            expect(Number(totalSupply.toString())).to.equal(2400000000000000000000000000);
            var exordiumBalance = await this.drakma.balanceOf(this.citadelExordium.address);
            expect(Number(exordiumBalance.toString())).to.equal(2400000000000000000000000000);
        });

        it("mints, sets approval, and stakes citadel", async function () {
            [owner] = await ethers.getSigners();
            await this.citadelNFT.reserveCitadel(2);
      
            var citadelBalance = await this.citadelNFT.balanceOf(owner.address);
            expect(citadelBalance.toNumber()).to.eq(2);

            await this.citadelNFT.approve(this.citadelExordium.address, 0);
            await this.citadelNFT.approve(this.citadelExordium.address, 1);

            const citadelToStake = [0,1];
            await this.citadelExordium.stake(citadelToStake, 0);

            var userStakingInfo = await this.citadelExordium.userStakeInfo(owner.address);
            expect(userStakingInfo[0]).to.equal(32);
            expect(userStakingInfo[1]).to.equal(0);
        });

        it("fails to stake unowned", async function () {
            [owner, addr2] = await ethers.getSigners();
            await this.citadelNFT.reserveCitadel(2);

            await expectRevert(
                this.citadelNFT.connect(addr2).approve(this.citadelExordium.address, 0),
                "ApprovalCallerNotOwnerNorApproved()"
              );

            const citadelToStake = [0];
            await expectRevert(
                this.citadelExordium.connect(addr2).stake(citadelToStake, 0),
                "Can't stake tokens you don't own!"
            );
        });

        it("mints, sets approval, stakes citadel, and withdraws citadel", async function () {
            [owner] = await ethers.getSigners();
            await this.citadelNFT.reserveCitadel(2);
      
            var citadelBalancePre = await this.citadelNFT.balanceOf(owner.address);
            expect(citadelBalancePre.toNumber()).to.eq(2);

            await this.citadelNFT.approve(this.citadelExordium.address, 0);
            await this.citadelNFT.approve(this.citadelExordium.address, 1);

            const citadelToStake = [0,1];
            await this.citadelExordium.stake(citadelToStake, 0);

            var userStakingInfo = await this.citadelExordium.userStakeInfo(owner.address);
            expect(userStakingInfo[0]).to.equal(32);
            expect(userStakingInfo[1]).to.equal(0);

            var citadelBalanceStaked = await this.citadelNFT.balanceOf(owner.address);
            expect(citadelBalanceStaked.toNumber()).to.eq(0);

            var walletData = await this.citadelExordium.getStaker(owner.address);
            expect(Number(walletData[0].toString())).to.be.equal(32); //amt staked (2 relik X 16 per relik)
            expect(Number(walletData[1].toString())).to.be.equal(0); //unclaimed rewards

            await this.citadelExordium.withdraw(citadelToStake);

            walletData = await this.citadelExordium.getStaker(owner.address);
            expect(Number(walletData[1].toString())).to.be.greaterThan(0); //unclaimed rewards

            var userStakingInfoWithdraw = await this.citadelExordium.userStakeInfo(owner.address);
            expect(userStakingInfoWithdraw[0]).to.equal(0);
            expect(Number(userStakingInfoWithdraw[1].toString())).to.be.greaterThan(0);

            var citadelBalancePost = await this.citadelNFT.balanceOf(owner.address);
            expect(citadelBalancePost.toNumber()).to.eq(2);
        });

        it("mints, sets approval, stakes citadel, and claims drakma", async function () {
            [owner] = await ethers.getSigners();
            await this.citadelNFT.reserveCitadel(65);
      
            var citadelBalancePre = await this.citadelNFT.balanceOf(owner.address);
            expect(citadelBalancePre.toNumber()).to.eq(65);

            await this.citadelNFT.approve(this.citadelExordium.address, 0);
            await this.citadelNFT.approve(this.citadelExordium.address, 1);

            const citadelToStake = [0,1];
            await this.citadelExordium.stake(citadelToStake, 0);

            var userStakingInfo = await this.citadelExordium.userStakeInfo(owner.address);
            expect(userStakingInfo[0]).to.equal(32);
            expect(userStakingInfo[1]).to.equal(0);

            var citadelBalanceStaked = await this.citadelNFT.balanceOf(owner.address);
            expect(citadelBalanceStaked.toNumber()).to.eq(63); // 2 of 65 staked

            await this.citadelExordium.claimRewards();
            var drakmaBalance = await this.drakma.balanceOf(owner.address);
            expect(Number(drakmaBalance.toString())).to.be.greaterThan(0);
        });
    });

    describe("no drakma funding", function () {

        beforeEach(async function () {
            await this.drakma.mintDrakma(this.citadelExordium.address, "1");
            var totalSupply = await this.drakma.totalSupply();
            expect(Number(totalSupply.toString())).to.equal(1);
            var exordiumBalance = await this.drakma.balanceOf(this.citadelExordium.address);
            expect(Number(exordiumBalance.toString())).to.equal(1);
        });

        it("can withdraw citadel when drakma runs out", async function () {
            [owner] = await ethers.getSigners();
            await this.citadelNFT.reserveCitadel(2);
      
            var citadelBalancePre = await this.citadelNFT.balanceOf(owner.address);
            expect(citadelBalancePre.toNumber()).to.eq(2);

            await this.citadelNFT.approve(this.citadelExordium.address, 0);
            await this.citadelNFT.approve(this.citadelExordium.address, 1);

            const citadelToStake = [0,1];
            await this.citadelExordium.stake(citadelToStake, 0);

            var userStakingInfo = await this.citadelExordium.userStakeInfo(owner.address);
            expect(userStakingInfo[0]).to.equal(32);
            expect(userStakingInfo[1]).to.equal(0);

            var citadelBalanceStaked = await this.citadelNFT.balanceOf(owner.address);
            expect(citadelBalanceStaked.toNumber()).to.eq(0); // 2 of 65 staked

            await expectRevert(
                this.citadelExordium.claimRewards(),
                "ERC20: transfer amount exceeds balance"
              );
            
            var drakmaBalance = await this.drakma.balanceOf(owner.address);
            expect(Number(drakmaBalance.toString())).to.equal(0);

            await this.citadelExordium.withdraw(citadelToStake);

            var userStakingInfoWithdraw = await this.citadelExordium.userStakeInfo(owner.address);
            expect(userStakingInfoWithdraw[0]).to.equal(0);
            expect(Number(userStakingInfoWithdraw[1].toString())).to.be.greaterThan(0);

            var citadelBalanceStaked = await this.citadelNFT.balanceOf(owner.address);
            expect(citadelBalanceStaked.toNumber()).to.eq(2);
        });

    });

    describe("withdraw drakma", function () {

        beforeEach(async function () {
            await this.drakma.mintDrakma(this.citadelExordium.address, "2400000000000000000000000000");
            var totalSupply = await this.drakma.totalSupply();
            expect(Number(totalSupply.toString())).to.equal(2400000000000000000000000000);
            var exordiumBalance = await this.drakma.balanceOf(this.citadelExordium.address);
            expect(Number(exordiumBalance.toString())).to.equal(2400000000000000000000000000);
        });

        it("withdraws drakma from owner account", async function () {
            [owner] = await ethers.getSigners();

            var ownerBalancePre = await this.drakma.balanceOf(owner.address);
            expect(Number(ownerBalancePre.toString())).to.equal(0);

            await this.citadelExordium.withdrawDrakma("2400000000000000000000000000");

            var exordiumBalance = await this.drakma.balanceOf(this.citadelExordium.address);
            expect(Number(exordiumBalance.toString())).to.equal(0);

            var ownerBalancePost = await this.drakma.balanceOf(owner.address);
            expect(Number(ownerBalancePost.toString())).to.equal(2400000000000000000000000000);
        });

        it("fails to withdraw drakma from non-owner account", async function () {
            [owner, addr2] = await ethers.getSigners();

            var ownerBalancePre = await this.drakma.balanceOf(addr2.address);
            expect(Number(ownerBalancePre.toString())).to.equal(0);

            await expectRevert(
                this.citadelExordium.connect(addr2).withdrawDrakma("2400000000000000000000000000"),
                "Ownable: caller is not the owner"
              );


            var exordiumBalance = await this.drakma.balanceOf(this.citadelExordium.address);
            expect(Number(exordiumBalance.toString())).to.equal(2400000000000000000000000000);

            var ownerBalancePost = await this.drakma.balanceOf(addr2.address);
            expect(Number(ownerBalancePost.toString())).to.equal(0);
        });
    });
});