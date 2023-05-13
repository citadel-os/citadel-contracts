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
        int256 sifGattaca;
        int256 mhrudvogThrot;
        int256 drebentraakht;
    }

    struct FleetTraining {
        Fleet fleet;
        Fleet trainingFleet;
        int256 trainingStarted;
        int256 trainingDone;
        bool isValue;
    }

    mapping(uint256 => FleetTraining) fleet; // index is _citadelId

    uint256 periodFinish = 1735700987; //JAN 1 2025, 2PM PT 
    int256 sifGattacaPrice = 20000000000000000000;
    int256 mhrudvogThrotPrice = 40000000000000000000;
    int256 drebentraakhtPrice = 800000000000000000000;
    int256 sifGattacaTrainingTime = 5 minutes;
    int256 mhrudvogThrotTrainingTime = 15 minutes;
    int256 drebentraakhtTrainingTime = 1 hours;

    event CitadelEvent(
        uint256 citadelId
    );

    constructor(IERC20 _drakma) {
        drakma = _drakma;
    }

    function trainFleet(uint256 _citadelId, int256 _sifGattaca, int256 _mhrudvogThrot, int256 _drebentraakht) external nonReentrant {
        resolveTraining(_citadelId);
        require(
            fleet[_citadelId].trainingDone == 0,
            "cannot train new fleet until previous has finished"
        );

        (int256 trainingCost, int256 timeTrainingDone) = calculateTrainingCost(_sifGattaca, _mhrudvogThrot, _drebentraakht);
        require(
            uint256(timeTrainingDone) < periodFinish,
            "cannot train fleet passed the end of the season"
        );

        require(drakma.transferFrom(msg.sender, address(this), uint256(trainingCost)));

        // allocate 100 sifGattaca on first train
        if(!fleet[_citadelId].isValue) {
            fleet[_citadelId].fleet.sifGattaca = 100;
            fleet[_citadelId].isValue = true;
        }

        fleet[_citadelId].trainingStarted = int256(lastTimeRewardApplicable());
        fleet[_citadelId].trainingDone = timeTrainingDone;
        fleet[_citadelId].trainingFleet.sifGattaca = _sifGattaca;
        fleet[_citadelId].trainingFleet.mhrudvogThrot = _mhrudvogThrot;
        fleet[_citadelId].trainingFleet.drebentraakht = _drebentraakht;

        emit CitadelEvent(
            _citadelId
        );
    }

    function resolveTraining(uint256 _citadelId) public {
        if(fleet[_citadelId].trainingDone <= int256(lastTimeRewardApplicable())) {
            fleet[_citadelId].trainingDone = 0;
            fleet[_citadelId].trainingStarted = 0;
            fleet[_citadelId].fleet.sifGattaca += fleet[_citadelId].trainingFleet.sifGattaca;
            fleet[_citadelId].trainingFleet.sifGattaca = 0;
            fleet[_citadelId].fleet.mhrudvogThrot += fleet[_citadelId].trainingFleet.mhrudvogThrot;
            fleet[_citadelId].trainingFleet.mhrudvogThrot = 0;
            fleet[_citadelId].fleet.drebentraakht += fleet[_citadelId].trainingFleet.drebentraakht;
            fleet[_citadelId].trainingFleet.drebentraakht = 0;
        }
    }

    function calculateTrainingCost(
        int256 _sifGattaca, 
        int256 _mhrudvogThrot, 
        int256 _drebentraakht
    ) public view returns (int256, int256) {
        int256 trainingCost = 0;
        trainingCost += _sifGattaca * sifGattacaPrice;
        trainingCost += _mhrudvogThrot * mhrudvogThrotPrice;
        trainingCost += _drebentraakht * drebentraakhtPrice;

        int256 timeTrainingDone = 0;
        timeTrainingDone = _sifGattaca * sifGattacaTrainingTime;
        timeTrainingDone += _mhrudvogThrot * mhrudvogThrotTrainingTime;
        timeTrainingDone += _drebentraakht * drebentraakhtTrainingTime;
        timeTrainingDone += int256(lastTimeRewardApplicable());

        return (trainingCost, timeTrainingDone);
    }

    function getTrainedFleet(uint256 _citadelId) public view returns (
        int256, int256, int256
    ) {
        int256 sifGattaca = fleet[_citadelId].fleet.sifGattaca;
        int256 mhrudvogThrot = fleet[_citadelId].fleet.mhrudvogThrot;
        int256 drebentraakht = fleet[_citadelId].fleet.drebentraakht;

        (
            int256 trainedSifGattaca, 
            int256 trainedMhrudvogThrot, 
            int256 trainedDrebentraakht
        ) = calculateTrainedFleet(_citadelId);

        return (
            sifGattaca + trainedSifGattaca, 
            mhrudvogThrot + trainedMhrudvogThrot, 
            drebentraakht + trainedDrebentraakht
        );
    }

    function getFleetInTraining(uint256 _citadelId) public view returns (
        int256, int256, int256
    ) {
        (
            int256 trainedSifGattaca, 
            int256 trainedMhrudvogThrot, 
            int256 trainedDrebentraakht
        ) = calculateTrainedFleet(_citadelId);

        return (
            fleet[_citadelId].trainingFleet.sifGattaca - trainedSifGattaca, 
            fleet[_citadelId].trainingFleet.mhrudvogThrot - trainedMhrudvogThrot, 
            fleet[_citadelId].trainingFleet.drebentraakht - trainedDrebentraakht
        );
    }

    function calculateTrainedFleet(uint256 _citadelId) public view returns (int256, int256, int256) {
        if(fleet[_citadelId].trainingDone <= int256(lastTimeRewardApplicable())) {
            return(
                fleet[_citadelId].trainingFleet.sifGattaca, 
                fleet[_citadelId].trainingFleet.mhrudvogThrot, 
                fleet[_citadelId].trainingFleet.drebentraakht
            );
        }

        int256 sifGattacaTrained = 0;
        int256 mhrudvogThrotTrained = 0;
        int256 drebentraakhtTrained = 0;
        int256 timeHolder = fleet[_citadelId].trainingStarted;

        sifGattacaTrained = (int256(block.timestamp) - timeHolder) / sifGattacaTrainingTime > fleet[_citadelId].trainingFleet.sifGattaca 
            ? fleet[_citadelId].trainingFleet.sifGattaca 
            : (int256(block.timestamp) - timeHolder) / sifGattacaTrainingTime;
        
        if(sifGattacaTrained == fleet[_citadelId].trainingFleet.sifGattaca) {
            timeHolder += (sifGattacaTrainingTime * sifGattacaTrained);
            mhrudvogThrotTrained = (int256(block.timestamp) - timeHolder) / mhrudvogThrotTrainingTime > fleet[_citadelId].trainingFleet.mhrudvogThrot
                ? fleet[_citadelId].trainingFleet.mhrudvogThrot 
                : (int256(block.timestamp) - timeHolder) / mhrudvogThrotTrainingTime;
        }

        if(mhrudvogThrotTrained == fleet[_citadelId].trainingFleet.mhrudvogThrot) {
            timeHolder += (mhrudvogThrotTrainingTime * mhrudvogThrotTrained);
            drebentraakhtTrained = (int256(block.timestamp) - timeHolder) / drebentraakhtTrainingTime > fleet[_citadelId].trainingFleet.drebentraakht
                ? fleet[_citadelId].trainingFleet.drebentraakht
                : (int256(block.timestamp) - timeHolder) / drebentraakhtTrainingTime;
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
        int256 _sifGattacaPrice, 
        int256 _mhrudvogThrotPrice, 
        int256 _drebentraakhtPrice, 
        int256 _sifGattacaTrainingTime,
        int256 _mhrudvogThrotTrainingTime,
        int256 _drebentraakhtTrainingTime
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


