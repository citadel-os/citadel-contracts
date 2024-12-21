// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./interfaces/ILite.sol";
import "./DiamondStorage.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract CitadelLite is DiamondStorage, Ownable, ILite, ReentrancyGuard {
    IERC20 public immutable drakma;

    uint256 sifGattacaPrice = 20000000000000000000;
    uint256 mhrudvogThrotPrice = 40000000000000000000;
    uint256 drebentraakhtPrice = 800000000000000000000;

    constructor(
        IERC20 _drakmaAddress
    ) {
        drakma = _drakmaAddress;
    }

    function liteGrid(
        uint256 _citadelId,
        uint256[3] calldata _pilotIds,
        uint256 _nodeId,
        uint8 _factionId,
        uint8 _orbitHeight,
        bytes32[] calldata proof
    ) external nonReentrant {
        require(_nodeId <= maxNode && _nodeId != 0, "invalid node");
        require(verifyOwnership(msg.sender, _citadelId, proof, true) == true, "caller does not own citadel");
        require(!node[_nodeId].isLit, "Node already lit");

        for (uint256 i; i < _pilotIds.length; ++i) {
            if (_pilotIds[i] != 0) {
                require(verifyOwnership(msg.sender, _pilotIds[i], proof, false) == true, "caller does not own pilot");
                require(!pilot[_pilotIds[i]], "Pilot already used");
                pilot[_pilotIds[i]] = true;
            }
        }

        require(citadelNode[_citadelId].timeLit == 0, "Citadel already lit");

        // Transfer Drakma based on orbit height
        uint256 drakmaAmount;
        if (_orbitHeight == 1) {
            drakmaAmount = 1_000_000 * 10 ** 18;
        } else if (_orbitHeight == 2) {
            drakmaAmount = 800_000 * 10 ** 18;
        } else if (_orbitHeight == 3) {
            drakmaAmount = 600_000 * 10 ** 18;
        } else if (_orbitHeight == 4) {
            drakmaAmount = 400_000 * 10 ** 18;
        } else if (_orbitHeight == 5) {
            drakmaAmount = 0;
        } else {
            revert("Invalid orbit height");
        }

        if (drakmaAmount > 0) {
            require(
                drakma.transferFrom(msg.sender, address(this), drakmaAmount),
                "Drakma transfer failed"
            );
        }

        citadelNode[_citadelId] = CitadelNode(
            _nodeId,
            0,
            block.timestamp,
            0,
            0,
            _pilotIds,
            _factionId,
            _orbitHeight,
            0
        );

        node[_nodeId] = Node(node[_nodeId].gridId, true, _citadelId);
    }

    function trainFleet(uint256 _citadelId, uint256 _sifGattaca, uint256 _mhrudvogThrot, uint256 _drebentraakht) external nonReentrant {
        uint256 trainingCost = calculateTrainingCost(_sifGattaca, _mhrudvogThrot, _drebentraakht);
        require(drakma.transferFrom(msg.sender, address(this), trainingCost));

        resolveTraining(_citadelId);
        require(
            fleet[_citadelId].trainingDone == 0,
            "cannot train"
        );

            // allocate 100 sifGattaca on first train
        if(!fleet[_citadelId].isValue) {
            fleet[_citadelId].stationedFleet.sifGattaca = 100;
            fleet[_citadelId].isValue = true;
        }

        fleet[_citadelId].trainingStarted = block.timestamp;
        fleet[_citadelId].trainingDone = block.timestamp + calculateTrainingTime(_sifGattaca, _mhrudvogThrot, _drebentraakht);
        fleet[_citadelId].trainingFleet.sifGattaca = _sifGattaca;
        fleet[_citadelId].trainingFleet.mhrudvogThrot = _mhrudvogThrot;
        fleet[_citadelId].trainingFleet.drebentraakht = _drebentraakht;

    }

    function resolveTraining(uint256 _citadelId) internal {
        if(fleet[_citadelId].trainingDone <= block.timestamp) {
            fleet[_citadelId].trainingDone = 0;
            fleet[_citadelId].trainingStarted = 0;
            fleet[_citadelId].stationedFleet.sifGattaca += fleet[_citadelId].trainingFleet.sifGattaca;
            fleet[_citadelId].trainingFleet.sifGattaca = 0;
            fleet[_citadelId].stationedFleet.mhrudvogThrot += fleet[_citadelId].trainingFleet.mhrudvogThrot;
            fleet[_citadelId].trainingFleet.mhrudvogThrot = 0;
            fleet[_citadelId].stationedFleet.drebentraakht += fleet[_citadelId].trainingFleet.drebentraakht;
            fleet[_citadelId].trainingFleet.drebentraakht = 0;
        }
    }

    function calculateTrainingCost(
        uint256 _sifGattaca,
        uint256 _mhrudvogThrot,
        uint256 _drebentraakht
    ) internal view returns (uint256) {
        uint256 trainingCost = 0;
        trainingCost += _sifGattaca * sifGattacaPrice;
        trainingCost += _mhrudvogThrot * mhrudvogThrotPrice;
        trainingCost += _drebentraakht * drebentraakhtPrice;

        return trainingCost;
    }

    function calculateTrainingTime(
        uint256 _sifGattaca,
        uint256 _mhrudvogThrot,
        uint256 _drebentraakht
    ) internal view returns (uint256) {
        uint256 timeTrainingDone = block.timestamp;
        timeTrainingDone = _sifGattaca * sifGattacaTrainingTime;
        timeTrainingDone += _mhrudvogThrot * mhrudvogThrotTrainingTime;
        timeTrainingDone += _drebentraakht * drebentraakhtTrainingTime;

        return timeTrainingDone;
    }




}