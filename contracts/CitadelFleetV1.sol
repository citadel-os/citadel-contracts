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


    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function getTrainedFleet(
        uint256 _sifGattaca,
        uint256 _mhrudvogThrot,
        uint256 _drebentraakht
    ) public view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        // uint256 sifGattaca = fleet[_citadelId].fleet.sifGattaca;
        // uint256 mhrudvogThrot = fleet[_citadelId].fleet.mhrudvogThrot;
        // uint256 drebentraakht = fleet[_citadelId].fleet.drebentraakht;
        // if(fleet[_citadelId].trainingDone <= lastTimeRewardApplicable()) {
        //     sifGattaca += fleet[_citadelId].trainingFleet.sifGattaca;
        //     mhrudvogThrot += fleet[_citadelId].trainingFleet.mhrudvogThrot;
        //     drebentraakht += fleet[_citadelId].trainingFleet.drebentraakht;
        // }
        return (0, 0, 0, 0, 0, 0);
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




