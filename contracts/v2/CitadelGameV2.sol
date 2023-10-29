// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface ISTORAGEV2 {
    function liteGrid(
        uint256 _citadelId,
        uint256[] calldata _pilotIds, 
        uint256 _gridId, 
        uint8 _capitalId,
        uint256 sovereignUntil
    ) external;
    function claim(
        uint256 _citadelId
    ) external returns (uint256);
    function dimGrid(
        uint256 _citadelId,
        uint256 _pilotId
    ) external;
    function trainFleet(
        uint256 _citadelId, 
        uint256 _sifGattaca, 
        uint256 _mhrudvogThrot, 
        uint256 _drebentraakht
    ) external;
    function sendSiege(
        uint256 _fromCitadel, 
        uint256 _toCitadel, 
        uint256[] calldata _pilot, 
        uint256[] calldata _fleet
    ) external returns (uint256);
    function sendReinforcements(
        uint256 _fromCitadel,
        uint256 _toCitadel,
        uint256[] calldata _fleet
    ) external;
    function bribeCapital(uint256 _citadelId, uint8 _capitalId) external returns (uint256);
    function getCapital(uint8 _capitalId) external view returns (uint256, uint256, uint256);
}

interface ICOMBATENGINE {
    function calculateTrainingCost(
        uint256 _sifGattaca, 
        uint256 _mhrudvogThrot, 
        uint256 _drebentraakht
    ) external returns (uint256);
}

interface IPROPAGANDA {
    function dispatchCitadelEvent(
        uint256 _citadelId
    ) external view;
}

interface ISOVEREIGN {
    function initializeSovereign(uint256 _sovereignId, uint256 _capitalId) external;
    function isSovereignOnLite(uint256 _sovereignId) external view returns (uint256 sovereignUntil);
    function bribeCapital(uint256 _sovereignId, uint256 _capitalId) external;
}


contract CitadelGameV2 is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // imports
    IERC20 public immutable drakma;
    IERC721 public immutable citadelCollection;
    IERC721 public immutable pilotCollection;
    ISTORAGEV2 public immutable storageEngine;
    ICOMBATENGINE public immutable combatEngine;
    IPROPAGANDA public immutable propaganda;
    ISOVEREIGN public immutable sovereignCollective;

    // variables
    uint256 maxGrid = 1023;
    uint8 maxFaction = 4;

    constructor(
        IERC721 _citadelCollection, 
        IERC721 _pilotCollection, 
        IERC20 _drakma, 
        ISTORAGEV2 _storageEngine,
        ICOMBATENGINE _combatEngine,
        IPROPAGANDA _propaganda,
        ISOVEREIGN _sovereignCollective
    ) {
        citadelCollection = _citadelCollection;
        pilotCollection = _pilotCollection;
        drakma = _drakma;
        storageEngine = _storageEngine;
        combatEngine = _combatEngine;
        propaganda = _propaganda;
        sovereignCollective = _sovereignCollective;
    }

    function liteGrid(
        uint256 _citadelId, 
        uint256[] calldata _pilotIds, 
        uint256 _gridId, 
        uint8 _capitalId
    ) external nonReentrant {
        require(_gridId <= maxGrid && _gridId != 0, "invalid grid");
        require(_capitalId <= maxFaction, "invalid capital");
        uint256 sovereignUntil;
        for (uint256 i; i < _pilotIds.length; ++i) {
            require(
                pilotCollection.ownerOf(_pilotIds[i]) == msg.sender,
                "must own pilot to lite"
            );
            if (sovereignCollective.isSovereignOnLite(_pilotIds[i]) > block.timestamp) {
                sovereignUntil = block.timestamp + 64 days;
                sovereignCollective.initializeSovereign(_pilotIds[i], _capitalId);
            }
        }
        storageEngine.liteGrid(_citadelId, _pilotIds, _gridId, _capitalId, sovereignUntil);
    }

    function dimGrid(uint256 _citadelId, uint256 _pilotId) external nonReentrant {
        require(
            pilotCollection.ownerOf(_pilotId) == msg.sender,
            "must own pilot to dim"
        );

        storageEngine.dimGrid(_citadelId, _pilotId);
    }

    function claim(uint256 _citadelId) external nonReentrant {
        require(
            citadelCollection.ownerOf(_citadelId) == msg.sender,
            "must own citadel"
        );
        uint256 drakmaToClaim = storageEngine.claim(_citadelId);
        if(drakmaToClaim > 0) {
            drakma.safeTransfer(msg.sender, drakmaToClaim);
        }
    }

    function trainFleet(uint256 _citadelId, uint256 _sifGattaca, uint256 _mhrudvogThrot, uint256 _drebentraakht) external nonReentrant {
        require(
            citadelCollection.ownerOf(_citadelId) == msg.sender,
            "must own citadel"
        );
        uint256 trainingCost = combatEngine.calculateTrainingCost(_sifGattaca, _mhrudvogThrot, _drebentraakht);
        require(drakma.transferFrom(msg.sender, address(this), trainingCost));
        storageEngine.trainFleet(_citadelId, _sifGattaca, _mhrudvogThrot, _drebentraakht);
    }

    function sendSiege(
        uint256 _fromCitadel, 
        uint256 _toCitadel, 
        uint256[] calldata _pilot, 
        uint256[] calldata _fleet
    ) external nonReentrant {
        require(_fromCitadel != _toCitadel, "cannot siege own citadel");
        require(
            citadelCollection.ownerOf(_fromCitadel) == msg.sender,
            "must own citadel"
        );

        uint256 dk = storageEngine.sendSiege(_fromCitadel, _toCitadel, _pilot, _fleet);
        if (dk > 0) {
            drakma.safeTransfer(msg.sender, dk);
        }

        propaganda.dispatchCitadelEvent(_fromCitadel);
    }

    function sendReinforcements(
        uint256 _fromCitadel,
        uint256 _toCitadel,
        uint256[] calldata _fleet
    ) external nonReentrant {
        require(
            citadelCollection.ownerOf(_fromCitadel) == msg.sender,
            "must own citadel"
        );

        storageEngine.sendReinforcements(_fromCitadel, _toCitadel, _fleet);

        propaganda.dispatchCitadelEvent(_fromCitadel);
        propaganda.dispatchCitadelEvent(_toCitadel);
    }

    function bribeCapital(
        uint256 _sovereignId,
        uint8 _capitalId,
        uint256 _citadelId
    ) external nonReentrant {
        require(
            pilotCollection.ownerOf(_sovereignId) == msg.sender,
            "must own sovereign"
        );
        require(
            citadelCollection.ownerOf(_citadelId) == msg.sender,
            "must own citadel"
        );

        uint256 bribeAmt = storageEngine.bribeCapital(_citadelId, _capitalId);
        require(drakma.transferFrom(msg.sender, address(this), bribeAmt));
        sovereignCollective.bribeCapital(_sovereignId, _capitalId);
    }
}
