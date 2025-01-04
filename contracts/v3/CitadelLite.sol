// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./interfaces/ILite.sol";
import "./DiamondStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @dev Facet that implements the "lite" functions for Citadel.
 *      It references the Diamond Storage (GameStorage) via DiamondStorage.diamondStorage().
 */
contract CitadelLite is ILite, Ownable, ReentrancyGuard {
    // ------------------------------------------------------------------------
    // No constructor -- we rely on the Diamond to set token addresses in storage
    // ------------------------------------------------------------------------

    // Event definitions (optional, from your original code)
    event CitadelEvent(uint256 citadelId);
    event CitadelActionEvent(uint256 fromCitadelId, uint256 toCitadelId);

    // Prices for training each fleet type (with 18 decimals, e.g. 20 tokens => 20e18)
    uint256 constant sifGattacaPrice       = 20_000_000_000_000_000_000;    // 20 tokens
    uint256 constant mhrudvogThrotPrice   = 40_000_000_000_000_000_000;    // 40 tokens
    uint256 constant drebentraakhtPrice   = 800_000_000_000_000_000_000;   // 800 tokens

    // ------------------------------------------------------------------------
    // Utility Functions
    // ------------------------------------------------------------------------

    function getGridFromNode(uint256 _nodeId) internal pure returns (uint256) {
        return (_nodeId - 1) / 8 + 1;
    }

    function getNodeFromCitadel(uint256 _citadelId) internal view returns (uint256) {
        DiamondStorage.GameStorage storage ds = DiamondStorage.diamondStorage();

        if (ds.citadelNode[_citadelId].timeLit == 0) {
            if (_citadelId % 2 == 0) {
                return _citadelId / 2;
            } else {
                return 1024 - (_citadelId / 2);
            }
        } else {
            return ds.citadelNode[_citadelId].nodeId;
        }
    }

    // ------------------------------------------------------------------------
    // ILite Functions
    // ------------------------------------------------------------------------

    function liteCitadel(
        uint256 _citadelId,
        uint256 _nodeId,
        uint8 _factionId
    ) external nonReentrant {
        DiamondStorage.GameStorage storage ds = DiamondStorage.diamondStorage();

        require(_nodeId <= ds.maxNode && _nodeId != 0, "invalid node");
        require(!ds.node[_nodeId].isLit, "Node already lit");
        require(ds.citadelCollection.ownerOf(_citadelId) == msg.sender, "must own citadel");
        require(ds.citadelNode[_citadelId].timeLit == 0, "Citadel already lit");

        ds.citadelNode[_citadelId].nodeId = _nodeId;
        ds.citadelNode[_citadelId].timeOfLastClaim = 0;
        ds.citadelNode[_citadelId].timeLit = block.timestamp;
        ds.citadelNode[_citadelId].timeLastSieged = 0;
        ds.citadelNode[_citadelId].unclaimedDrakma = 0;
        ds.citadelNode[_citadelId].pilot = [uint256(0), 0, 0];
        ds.citadelNode[_citadelId].faction = _factionId;
        ds.citadelNode[_citadelId].orbitHeight = 5;
        ds.citadelNode[_citadelId].marker = 0;

        ds.node[_nodeId].isLit = true;
        ds.node[_nodeId].citadelId = _citadelId;

        emit CitadelEvent(_citadelId);
    }

    function litePilot(
        uint256 _citadelId,
        uint256[3] calldata _pilotIds,
        uint8 _factionId
    ) external nonReentrant {
        DiamondStorage.GameStorage storage ds = DiamondStorage.diamondStorage();

        if (ds.citadelNode[_citadelId].timeLit > 0) {
            require(ds.citadelCollection.ownerOf(_citadelId) == msg.sender, "must own citadel");
            require(ds.citadelNode[_citadelId].faction == _factionId, "must lite to the same faction");
        }

        for (uint256 i; i < _pilotIds.length; ++i) {
            if (_pilotIds[i] != 0) {
                require(ds.pilotCollection.ownerOf(_pilotIds[i]) == msg.sender, "must own pilot");
                require(!ds.pilot[_pilotIds[i]], "Pilot already used");
                ds.pilot[_pilotIds[i]] = true;
            }
        }

        if (ds.citadelNode[_citadelId].timeLit == 0) {
            uint256 nodeId = getNodeFromCitadel(_citadelId);
            ds.citadelNode[_citadelId].nodeId = nodeId;
            ds.citadelNode[_citadelId].timeOfLastClaim = 0;
            ds.citadelNode[_citadelId].timeLit = block.timestamp;
            ds.citadelNode[_citadelId].timeLastSieged = 0;
            ds.citadelNode[_citadelId].unclaimedDrakma = 0;
            ds.citadelNode[_citadelId].pilot = _pilotIds;
            ds.citadelNode[_citadelId].faction = _factionId;
            ds.citadelNode[_citadelId].orbitHeight = 5;
            ds.citadelNode[_citadelId].marker = 0;

            ds.node[nodeId].isLit = true;
            ds.node[nodeId].citadelId = _citadelId;
        } else {
            ds.citadelNode[_citadelId].pilot = _pilotIds;
        }

        emit CitadelEvent(_citadelId);
    }

    // ------------------------------------------------------------------------
    // Additional logic from the original CitadelLite
    // ------------------------------------------------------------------------

    function orbitCitadel(uint256 _citadelId, uint8 _orbitHeight) external nonReentrant {
        DiamondStorage.GameStorage storage ds = DiamondStorage.diamondStorage();

        require(ds.citadelCollection.ownerOf(_citadelId) == msg.sender, "must own citadel");
        require(ds.citadelNode[_citadelId].timeLit != 0, "Citadel not lit");

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
                ds.drakma.transferFrom(msg.sender, address(this), drakmaAmount),
                "Drakma transfer failed"
            );
        }

        ds.citadelNode[_citadelId].orbitHeight = _orbitHeight;
    }

    function trainFleet(
        uint256 _citadelId,
        uint256 _sifGattaca,
        uint256 _mhrudvogThrot,
        uint256 _drebentraakht
    ) external nonReentrant {
        DiamondStorage.GameStorage storage ds = DiamondStorage.diamondStorage();

        uint256 trainingCost = calculateTrainingCost(_sifGattaca, _mhrudvogThrot, _drebentraakht);
        require(ds.drakma.transferFrom(msg.sender, address(this), trainingCost), "Drakma transfer fail");

        resolveTraining(_citadelId);

        require(ds.fleet[_citadelId].trainingDone == 0, "cannot train");

        // allocate 100 sifGattaca on first train
        if (!ds.fleet[_citadelId].isValue) {
            ds.fleet[_citadelId].stationedFleet.sifGattaca = 100;
            ds.fleet[_citadelId].isValue = true;
        }

        ds.fleet[_citadelId].trainingStarted = block.timestamp;
        ds.fleet[_citadelId].trainingDone =
            block.timestamp + calculateTrainingTime(_sifGattaca, _mhrudvogThrot, _drebentraakht);

        ds.fleet[_citadelId].trainingFleet.sifGattaca = _sifGattaca;
        ds.fleet[_citadelId].trainingFleet.mhrudvogThrot = _mhrudvogThrot;
        ds.fleet[_citadelId].trainingFleet.drebentraakht = _drebentraakht;
    }

    function resolveTraining(uint256 _citadelId) internal {
        DiamondStorage.GameStorage storage ds = DiamondStorage.diamondStorage();

        if (
            ds.fleet[_citadelId].trainingDone <= block.timestamp && 
            ds.fleet[_citadelId].trainingDone != 0
        ) {
            ds.fleet[_citadelId].trainingDone = 0;
            ds.fleet[_citadelId].trainingStarted = 0;

            ds.fleet[_citadelId].stationedFleet.sifGattaca += ds.fleet[_citadelId].trainingFleet.sifGattaca;
            ds.fleet[_citadelId].trainingFleet.sifGattaca = 0;

            ds.fleet[_citadelId].stationedFleet.mhrudvogThrot += ds.fleet[_citadelId].trainingFleet.mhrudvogThrot;
            ds.fleet[_citadelId].trainingFleet.mhrudvogThrot = 0;

            ds.fleet[_citadelId].stationedFleet.drebentraakht += ds.fleet[_citadelId].trainingFleet.drebentraakht;
            ds.fleet[_citadelId].trainingFleet.drebentraakht = 0;
        }
    }

    function calculateTrainingCost(
        uint256 _sifGattaca,
        uint256 _mhrudvogThrot,
        uint256 _drebentraakht
    ) internal pure returns (uint256) {
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
        DiamondStorage.GameStorage storage ds = DiamondStorage.diamondStorage();

        // Summation of each type's training time * quantity
        uint256 timeTrainingDone = 0;
        timeTrainingDone += _sifGattaca * ds.sifGattacaTrainingTime;
        timeTrainingDone += _mhrudvogThrot * ds.mhrudvogThrotTrainingTime;
        timeTrainingDone += _drebentraakht * ds.drebentraakhtTrainingTime;

        return timeTrainingDone;
    }
}

/*

pragma solidity ^0.8.24;

import "./interfaces/ILite.sol";
import "./DiamondStorage.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


contract CitadelLite is DiamondStorage, Ownable, ILite, ReentrancyGuard {
    IERC20 public immutable drakma;
    IERC721 public immutable citadelCollection;
    IERC721 public immutable pilotCollection;

    uint256 sifGattacaPrice = 20000000000000000000;
    uint256 mhrudvogThrotPrice = 40000000000000000000;
    uint256 drebentraakhtPrice = 800000000000000000000;

    constructor(
        IERC20 _drakmaAddress,
        IERC721 _citadelCollection, 
        IERC721 _pilotCollection
    ) {
        drakma = _drakmaAddress;
        citadelCollection = _citadelCollection;
        pilotCollection = _pilotCollection;
    }

    function orbitCitadel(uint256 _citadelId, uint8 _orbitHeight) external nonReentrant {
        require(
            citadelCollection.ownerOf(_citadelId) == msg.sender,
            "must own citadel"
        );

        require(citadelNode[_citadelId].timeLit != 0, "Citadel not lit");

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

        citadelNode[_citadelId].orbitHeight = _orbitHeight;
    }

    function liteCitadel(
        uint256 _citadelId,
        uint256 _nodeId,
        uint8 _factionId
    ) external nonReentrant {
        require(_nodeId <= maxNode && _nodeId != 0, "invalid node");
        require(!node[_nodeId].isLit, "Node already lit");
        require(
            citadelCollection.ownerOf(_citadelId) == msg.sender,
            "must own citadel"
        );

        require(citadelNode[_citadelId].timeLit == 0, "Citadel already lit");

        citadelNode[_citadelId] = CitadelNode(
            _nodeId,
            0,
            block.timestamp,
            0,
            0,
            [uint256(0), 0, 0],
            _factionId,
            5,
            0
        );

        node[_nodeId] = Node(node[_nodeId].gridId, true, _citadelId);
    }

    function litePilot(
        uint256 _citadelId,
        uint256[3] calldata _pilotIds,
        uint8 _factionId
    ) external nonReentrant {
        if (citadelNode[_citadelId].timeLit > 0) {
            require(
                citadelCollection.ownerOf(_citadelId) == msg.sender,
                "must own citadel"
            );
            require(
                citadelNode[_citadelId].faction == _factionId,
                "must lite to the same faction"
            );
        }

        for (uint256 i; i < _pilotIds.length; ++i) {
            if (_pilotIds[i] != 0) {
                require(
                    pilotCollection.ownerOf(_pilotIds[i]) == msg.sender,
                    "must own pilot"
                );
                require(!pilot[_pilotIds[i]], "Pilot already used");
                pilot[_pilotIds[i]] = true;
            }
        }

        if (citadelNode[_citadelId].timeLit == 0) {
            uint256 nodeId = getNodeFromCitadel(_citadelId);
            citadelNode[_citadelId] = CitadelNode(
                nodeId,
                0,
                block.timestamp,
                0,
                0,
                _pilotIds,
                _factionId,
                5,
                0
            );

            node[nodeId] = Node(node[nodeId].gridId, true, _citadelId);
        } else {
            citadelNode[_citadelId].pilot = _pilotIds;
        }
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

*/