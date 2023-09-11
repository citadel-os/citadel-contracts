// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface ISTORAGEV2 {
    function liteGrid(
        uint256[] calldata _pilotIds, 
        uint256 _gridId, 
        uint8 _factionId
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
    function sendRaid(
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
}

interface ICOMBATENGINE {
    function calculateTrainingCost(
        uint256 _sifGattaca, 
        uint256 _mhrudvogThrot, 
        uint256 _drebentraakht
    ) external returns (uint256);
}


contract WarlordTechnocracyV2 is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // imports
    IERC20 public immutable drakma;
    IERC721 public immutable citadelCollection;
    IERC721 public immutable pilotCollection;
    ISTORAGEV2 public immutable storageEngine;
    ICOMBATENGINE public immutable combatEngine;

    // variables
    uint256 maxGrid = 1023;
    uint8 maxFaction = 4;

    // events
    event CitadelEvent(
        uint256 citadelId
    );

    event DispatchRaid(
        uint256 fromCitadelId, 
        uint256 toCitadelId,
        uint256 timeRaidHit,
        uint256 offensiveCarryCapacity,
        uint256 drakmaRaided,
        uint256 offensiveSifGattacaDestroyed,
        uint256 offensiveMhrudvogThrotDestroyed,
        uint256 offensiveDrebentraakhtDestroyed,
        uint256 defensiveSifGattacaDestroyed,
        uint256 defensiveMhrudvogThrotDestroyed,
        uint256 defensiveDrebentraakhtDestroyed
    );

    constructor(
        IERC721 _citadelCollection, 
        IERC721 _pilotCollection, 
        IERC20 _drakma, 
        ISTORAGEV2 _storageEngine,
        ICOMBATENGINE _combatEngine
    ) {
        citadelCollection = _citadelCollection;
        pilotCollection = _pilotCollection;
        drakma = _drakma;
        storageEngine = _storageEngine;
        combatEngine = _combatEngine;
    }

    function liteGrid(uint256[] calldata _pilotIds, uint256 _gridId, uint8 _factionId) external nonReentrant {
        require(_gridId <= maxGrid && _gridId != 0, "invalid grid");
        require(_factionId <= maxFaction, "invalid faction");
        for (uint256 i; i < _pilotIds.length; ++i) {
            require(
                pilotCollection.ownerOf(_pilotIds[i]) == msg.sender,
                "must own pilot to lite"
            );
        }
        storageEngine.liteGrid(_pilotIds, _gridId, _factionId);
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

    function sendRaid(
        uint256 _fromCitadel, 
        uint256 _toCitadel, 
        uint256[] calldata _pilot, 
        uint256[] calldata _fleet
    ) external nonReentrant {
        require(_fromCitadel != _toCitadel, "cannot raid own citadel");
        require(
            citadelCollection.ownerOf(_fromCitadel) == msg.sender,
            "must own citadel"
        );

        uint256 dk = storageEngine.sendRaid(_fromCitadel, _toCitadel, _pilot, _fleet);
        if (dk > 0) {
            drakma.safeTransfer(msg.sender, dk);
        }

        emit CitadelEvent(
            _fromCitadel
        );
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

        emit CitadelEvent(
            _fromCitadel
        );

        emit CitadelEvent(
            _toCitadel
        );
    }
}
