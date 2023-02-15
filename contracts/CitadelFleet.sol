// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CitadelFleetV1 is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable drakma;

    struct Fleet {
        uint256 sifGattaca;
        uint256 mhrudvogThrot;
        uint256 drebentraakht;
    }

    struct FleetTraining {
        Fleet fleet;
        Fleet trainingFleet;
        uint256 trainingStarted;
        uint256 trainingDone;
        bool isValue;
    }

    constructor(IERC20 _drakma) {
        drakma = _drakma;
    }

    mapping(uint256 => FleetTraining) fleet; // index is _citadelId

    uint256 periodFinish = 1735700987; //JAN 1 2025, 2PM PT 
    uint256 sifGattacaPrice = 20000000000000000000;
    uint256 mhrudvogThrotPrice = 40000000000000000000;
    uint256 drebentraakhtPrice = 800000000000000000000;
    uint256 sifGattacaTrainingTime = 5 minutes;
    uint256 mhrudvogThrotTrainingTime = 15 minutes;
    uint256 drebentraakhtTrainingTime = 1 hours;

    function trainFleet(uint256 _citadelId, uint256 _sifGattaca, uint256 _mhrudvogThrot, uint256 _drebentraakht) external nonReentrant {
        resolveTraining(_citadelId);
        require(
            fleet[_citadelId].trainingDone == 0,
            "cannot train new fleet until previous has finished"
        );

        (uint256 trainingCost, uint256 timeTrainingDone) = calculateTrainingCost(_sifGattaca, _mhrudvogThrot, _drebentraakht);
        require(
            block.timestamp + timeTrainingDone < periodFinish,
            "cannot train fleet passed the end of the season"
        );

        require(drakma.transferFrom(msg.sender, address(this), trainingCost));

        // allocate 10 sifGattaca on first train
        if(!fleet[_citadelId].isValue) {
            fleet[_citadelId].fleet.sifGattaca = 10;
            fleet[_citadelId].isValue = true;
        }

        fleet[_citadelId].trainingStarted = lastTimeRewardApplicable();
        fleet[_citadelId].trainingDone = timeTrainingDone;
        fleet[_citadelId].trainingFleet.sifGattaca = _sifGattaca;
        fleet[_citadelId].trainingFleet.mhrudvogThrot = _mhrudvogThrot;
        fleet[_citadelId].trainingFleet.drebentraakht = _drebentraakht;
    }

    function resolveTraining(uint256 _citadelId) public {
        // TODO resolve partially done
        if(fleet[_citadelId].trainingDone <= lastTimeRewardApplicable()) {
            (
                uint256 trainedSifGattaca, 
                uint256 trainedMhrudvogThrot, 
                uint256 trainedDrebentraakht
            ) = calculateTrainedFleet(_citadelId);


            fleet[_citadelId].trainingDone = 0;
            fleet[_citadelId].trainingStarted = 0;
            fleet[_citadelId].fleet.sifGattaca += trainedSifGattaca;
            fleet[_citadelId].trainingFleet.sifGattaca = 0;
            fleet[_citadelId].fleet.mhrudvogThrot += trainedMhrudvogThrot;
            fleet[_citadelId].trainingFleet.mhrudvogThrot = 0;
            fleet[_citadelId].fleet.drebentraakht += trainedDrebentraakht;
            fleet[_citadelId].trainingFleet.drebentraakht = 0;
        }
    }

    function calculateTrainingCost(
        uint256 _sifGattaca, 
        uint256 _mhrudvogThrot, 
        uint256 _drebentraakht
    ) public view returns (uint256, uint256) {
        uint256 timeTrainingDone = 0;
        timeTrainingDone = _sifGattaca * sifGattacaTrainingTime;
        timeTrainingDone += _mhrudvogThrot * mhrudvogThrotTrainingTime;
        timeTrainingDone += _drebentraakht * drebentraakhtTrainingTime;
        timeTrainingDone += lastTimeRewardApplicable();

        uint256 trainingCost = 0;
        trainingCost += _sifGattaca * sifGattacaPrice;
        trainingCost += _mhrudvogThrot * mhrudvogThrotPrice;
        trainingCost += _drebentraakht * drebentraakhtPrice;

        return (trainingCost, timeTrainingDone);
    }

    function getTrainedFleet(uint256 _citadelId) public view returns (
        uint256, uint256, uint256
    ) {
        uint256 sifGattaca = fleet[_citadelId].fleet.sifGattaca;
        uint256 mhrudvogThrot = fleet[_citadelId].fleet.mhrudvogThrot;
        uint256 drebentraakht = fleet[_citadelId].fleet.drebentraakht;

        (
            uint256 trainedSifGattaca, 
            uint256 trainedMhrudvogThrot, 
            uint256 trainedDrebentraakht
        ) = calculateTrainedFleet(_citadelId);

        return (
            sifGattaca + trainedSifGattaca, 
            mhrudvogThrot + trainedMhrudvogThrot, 
            drebentraakht + trainedDrebentraakht
        );
    }

    function calculateTrainedFleet(uint256 _citadelId) public view returns (uint256, uint256, uint256) {
        if(fleet[_citadelId].trainingDone <= lastTimeRewardApplicable()) {
            return(
                fleet[_citadelId].trainingFleet.sifGattaca, 
                fleet[_citadelId].trainingFleet.mhrudvogThrot, 
                fleet[_citadelId].trainingFleet.drebentraakht
            );
        }

        uint256 sifGattacaTrained = 0;
        uint256 mhrudvogThrotTrained = 0;
        uint256 drebentraakhtTrained = 0;
        uint256 timeHolder = fleet[_citadelId].trainingStarted;

        sifGattacaTrained = (block.timestamp - timeHolder) / sifGattacaTrainingTime > fleet[_citadelId].trainingFleet.sifGattaca 
            ? fleet[_citadelId].trainingFleet.sifGattaca 
            : (block.timestamp - timeHolder) / sifGattacaTrainingTime;
        
        if(sifGattacaTrained == fleet[_citadelId].trainingFleet.sifGattaca) {
            timeHolder += (sifGattacaTrainingTime * sifGattacaTrained);
            mhrudvogThrotTrained = (block.timestamp - timeHolder) / mhrudvogThrotTrainingTime > fleet[_citadelId].trainingFleet.mhrudvogThrot
                ? fleet[_citadelId].trainingFleet.mhrudvogThrot 
                : (block.timestamp - timeHolder) / mhrudvogThrotTrainingTime;
        }

        if(mhrudvogThrotTrained == fleet[_citadelId].trainingFleet.mhrudvogThrot) {
            timeHolder += (mhrudvogThrotTrainingTime * mhrudvogThrotTrained);
            drebentraakhtTrained = (block.timestamp - timeHolder) / drebentraakhtTrainingTime > fleet[_citadelId].trainingFleet.drebentraakht
                ? fleet[_citadelId].trainingFleet.drebentraakht
                : (block.timestamp - timeHolder) / drebentraakhtTrainingTime;
        }
        
        return (sifGattacaTrained, mhrudvogThrotTrained, drebentraakhtTrained);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    // only owner
    function withdrawDrakma(uint256 amount) external onlyOwner {
        drakma.safeTransfer(msg.sender, amount);
    }

    function updateFleetParams(
        uint256 _sifGattacaPrice, 
        uint256 _mhrudvogThrotPrice, 
        uint256 _drebentraakhtPrice, 
        uint256 _sifGattacaTrainingTime,
        uint256 _mhrudvogThrotTrainingTime,
        uint256 _drebentraakhtTrainingTime
    ) external onlyOwner {
        sifGattacaPrice = _sifGattacaPrice;
        mhrudvogThrotPrice = _mhrudvogThrotPrice;
        drebentraakhtPrice = _drebentraakhtPrice;
        sifGattacaTrainingTime = _sifGattacaTrainingTime;
        mhrudvogThrotTrainingTime = _mhrudvogThrotTrainingTime;
        drebentraakhtTrainingTime = _drebentraakhtTrainingTime;
    }

    function updateGameParams(
        uint256 _periodFinish
    ) external onlyOwner {
        periodFinish = _periodFinish;
    }
}


