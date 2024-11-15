// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./IExpand.sol";
import "./DiamondStorage.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CitadelExpand is DiamondStorage, Ownable, IExpand, ReentrancyGuard {

    IERC20 public immutable drakma;

    constructor(
        IERC20 _drakmaAddress
    ) {
        drakma = _drakmaAddress;
    }

    function trainFleet(uint256 _citadelId, uint256 _sifGattaca, uint256 _mhrudvogThrot, uint256 _drebentraakht) external nonReentrant {
        uint256 trainingCost = calculateTrainingCost(_sifGattaca, _mhrudvogThrot, _drebentraakht);
        require(drakma.transferFrom(msg.sender, address(this), trainingCost));

        resolveTraining(_citadelId);
        require(
            DiamondStorage.fleet[_citadelId].trainingDone == 0,
            "cannot train"
        );

            // allocate 100 sifGattaca on first train
        if(!DiamondStorage.fleet[_citadelId].isValue) {
            DiamondStorage.fleet[_citadelId].stationedFleet.sifGattaca = 100;
            DiamondStorage.fleet[_citadelId].isValue = true;
        }

        DiamondStorage.fleet[_citadelId].trainingStarted = block.timestamp;
        DiamondStorage.fleet[_citadelId].trainingDone = block.timestamp + calculateTrainingTime(_sifGattaca, _mhrudvogThrot, _drebentraakht);
        DiamondStorage.fleet[_citadelId].trainingFleet.sifGattaca = _sifGattaca;
        DiamondStorage.fleet[_citadelId].trainingFleet.mhrudvogThrot = _mhrudvogThrot;
        DiamondStorage.fleet[_citadelId].trainingFleet.drebentraakht = _drebentraakht;

    }

    function resolveTraining(uint256 _citadelId) internal {
        if(DiamondStorage.fleet[_citadelId].trainingDone <= block.timestamp) {
            DiamondStorage.fleet[_citadelId].trainingDone = 0;
            DiamondStorage.fleet[_citadelId].trainingStarted = 0;
            DiamondStorage.fleet[_citadelId].stationedFleet.sifGattaca += DiamondStorage.fleet[_citadelId].trainingFleet.sifGattaca;
            DiamondStorage.fleet[_citadelId].trainingFleet.sifGattaca = 0;
            DiamondStorage.fleet[_citadelId].stationedFleet.mhrudvogThrot += DiamondStorage.fleet[_citadelId].trainingFleet.mhrudvogThrot;
            DiamondStorage.fleet[_citadelId].trainingFleet.mhrudvogThrot = 0;
            DiamondStorage.fleet[_citadelId].stationedFleet.drebentraakht += DiamondStorage.fleet[_citadelId].trainingFleet.drebentraakht;
            DiamondStorage.fleet[_citadelId].trainingFleet.drebentraakht = 0;
        }
    }

    function calculateTrainingCost(
        uint256 _sifGattaca,
        uint256 _mhrudvogThrot,
        uint256 _drebentraakht
    ) internal view returns (uint256) {
        uint256 trainingCost = 0;
        trainingCost += _sifGattaca * DiamondStorage.sifGattacaPrice;
        trainingCost += _mhrudvogThrot * DiamondStorage.mhrudvogThrotPrice;
        trainingCost += _drebentraakht * DiamondStorage.drebentraakhtPrice;

        return trainingCost;
    }

    function calculateTrainingTime(
        uint256 _sifGattaca,
        uint256 _mhrudvogThrot,
        uint256 _drebentraakht
    ) internal view returns (uint256) {
        uint256 timeTrainingDone = block.timestamp;
        timeTrainingDone = _sifGattaca * DiamondStorage.sifGattacaTrainingTime;
        timeTrainingDone += _mhrudvogThrot * DiamondStorage.mhrudvogThrotTrainingTime;
        timeTrainingDone += _drebentraakht * DiamondStorage.drebentraakhtTrainingTime;

        return timeTrainingDone;
    }

}