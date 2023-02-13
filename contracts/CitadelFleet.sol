// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CitadelFleetV1 is Ownable {

    constructor() {}

    uint256 periodFinish = 1735700987; //JAN 1 2025, 2PM PT 
    uint256 sifGattacaPrice = 20000000000000000000;
    uint256 mhrudvogThrotPrice = 40000000000000000000;
    uint256 drebentraakhtPrice = 800000000000000000000;
    uint256 sifGattacaTrainingTime = 5 minutes;
    uint256 mhrudvogThrotTrainingTime = 15 minutes;
    uint256 drebentraakhtTrainingTime = 1 hours;

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

    function calculateTrainedFleet(
        uint256 _sifGattaca,
        uint256 _mhrudvogThrot,
        uint256 _drebentraakht,
        uint256 _timeTrainingStarted,
        uint256 _timeTrainingDone
    ) public view returns (uint256, uint256, uint256) {
        //TODO factor in time training started
        if(_timeTrainingDone <= lastTimeRewardApplicable()) {
            return(_sifGattaca, _mhrudvogThrot, _drebentraakht);
        }
        return (0, 0, 0);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    // only owner
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


