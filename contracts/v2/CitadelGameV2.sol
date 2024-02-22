// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";

interface ISTORAGEV2 {
    function liteGrid(
        uint256 _citadelId,
        uint256[3] calldata _pilotIds, 
        uint256 _gridId,
        uint8 _capitalId,
        uint256 sovereignUntil
    ) external;
    function claim(
        uint256 _citadelId
    ) external returns (uint256);
    function trainFleet(
        uint256 _citadelId, 
        uint256 _sifGattaca, 
        uint256 _mhrudvogThrot, 
        uint256 _drebentraakht
    ) external;
    function sendSiege(
        uint256 _fromCitadel, 
        uint256 _toCitadel, 
        uint256 _pilotId, 
        uint256[3] calldata _fleet
    ) external returns (uint256);
    function resolveSiege(uint256 _fromCitadel) external returns (uint256);
    function sendReinforcements(
        uint256 _fromCitadel,
        uint256 _toCitadel,
        uint256[3] calldata _fleet
    ) external;
    function bribeCapital(uint256 _citadelId, uint8 _capitalId) external returns (uint256);
    function getCapital(uint8 _capitalId) external view returns (uint256, uint256, uint256, string memory, uint256);
    function sackCapital(uint256 _citadelId, uint8 _capitalId, uint256 bribeAmt, string calldata name) external returns (uint256);
    function overthrowSovereign(uint256 _fromCitadelId, uint256 _toCitadelId, uint8 _capitalId) external returns (uint256);
    function grid(uint256 _citadelId) external returns (bool, uint256, bool, uint256);
}

interface ICOMBATENGINE {
    function calculateTrainingCost(
        uint256 _sifGattaca, 
        uint256 _mhrudvogThrot, 
        uint256 _drebentraakht
    ) external returns (uint256);
}

interface ISOVEREIGN {
    function initializeSovereign(uint256 _sovereignId, uint256 _capitalId) external;
    function isSovereignOnLite(uint256 _sovereignId) external view returns (bool);
    function bribeCapital(uint256 _sovereignId, uint256 _capitalId) external;
    function isSovereign(uint256 _sovereignId) external view returns (bool);
    function usurpSovereign(uint256 _usurper, uint256 _sovereignId, uint256 _capitalId) external;
}


contract CitadelGameV2 is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // imports
    IERC20 public immutable drakma;
    IERC721 public immutable citadelCollection;
    IERC721 public immutable pilotCollection;
    ISTORAGEV2 public immutable storageEngine;
    ICOMBATENGINE public immutable combatEngine;
    ISOVEREIGN public immutable sovereignCollective;

    // variables
    uint256 maxGrid = 1023;
    uint8 maxCapital = 4;

    // mappings
    mapping(address => uint256) winners; // index is walletAddress

    event CitadelEvent(
        uint256 citadelId
    );

    constructor(
        IERC721 _citadelCollection, 
        IERC721 _pilotCollection, 
        IERC20 _drakma, 
        ISTORAGEV2 _storageEngine,
        ICOMBATENGINE _combatEngine,
        ISOVEREIGN _sovereignCollective
    ) {
        citadelCollection = _citadelCollection;
        pilotCollection = _pilotCollection;
        drakma = _drakma;
        storageEngine = _storageEngine;
        combatEngine = _combatEngine;
        sovereignCollective = _sovereignCollective;
    }

    function liteGrid(
        uint256 _citadelId, 
        uint256[3] calldata _pilotIds, 
        uint256 _gridId, 
        uint8 _capitalId
    ) external nonReentrant {
        require(_gridId <= maxGrid && _gridId != 0, "invalid grid");
        require(_capitalId < maxCapital, "invalid capital");
        require(
            citadelCollection.ownerOf(_citadelId) == msg.sender,
            "must own citadel"
        );
        uint256 sovereignUntil;
        for (uint256 i; i < _pilotIds.length; ++i) {
            if (_pilotIds[i] != 0) {
                require(
                    pilotCollection.ownerOf(_pilotIds[i]) == msg.sender,
                    "must own pilot to lite"
                );
                if (sovereignCollective.isSovereignOnLite(_pilotIds[i]) == true) {
                    sovereignUntil = block.timestamp + 64 days;
                    sovereignCollective.initializeSovereign(_pilotIds[i], _capitalId);
                }
            }
        }
        storageEngine.liteGrid(_citadelId, _pilotIds, _gridId, _capitalId, sovereignUntil);
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
        uint256 trainingCost = combatEngine.calculateTrainingCost(_sifGattaca, _mhrudvogThrot, _drebentraakht);
        require(drakma.transferFrom(msg.sender, address(this), trainingCost));
        storageEngine.trainFleet(_citadelId, _sifGattaca, _mhrudvogThrot, _drebentraakht);
    }

    function sendSiege(
        uint256 _fromCitadel, 
        uint256 _toCitadel, 
        uint256 _pilotId, 
        uint256[3] calldata _fleet
    ) external nonReentrant {
        require(_fromCitadel != _toCitadel);
        require(
            citadelCollection.ownerOf(_fromCitadel) == msg.sender,
            "cannot siege"
        );

        uint256 dk = storageEngine.sendSiege(_fromCitadel, _toCitadel, _pilotId, _fleet);
        if (dk > 0) {
            drakma.safeTransfer(msg.sender, dk);
        }

        emit CitadelEvent(_fromCitadel);
    }

    function resolveSiege(uint256 _fromCitadel) external nonReentrant {
        uint256 dkRake =  storageEngine.resolveSiege(_fromCitadel);
        if (dkRake > 0) {
            drakma.safeTransfer(msg.sender, dkRake);
        }
        emit CitadelEvent(_fromCitadel);
    }

    function sendReinforcements(
        uint256 _fromCitadel,
        uint256 _toCitadel,
        uint256[3] calldata _fleet
    ) external nonReentrant {
        require(
            citadelCollection.ownerOf(_fromCitadel) == msg.sender,
            "must own citadel"
        );

        storageEngine.sendReinforcements(_fromCitadel, _toCitadel, _fleet);

        emit CitadelEvent(_fromCitadel);
        emit CitadelEvent(_toCitadel);
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
        require(
            sovereignCollective.isSovereign(_sovereignId), 
            "pilot must be sovereign"
        );

        uint256 bribeAmt = storageEngine.bribeCapital(_citadelId, _capitalId);
        require(drakma.transferFrom(msg.sender, address(this), bribeAmt));
        sovereignCollective.bribeCapital(_sovereignId, _capitalId);
    }

    function sackCapital(
        uint256 _citadelId,
        uint8 _capitalId, 
        uint256 bribeAmt, 
        string calldata name
    ) external nonReentrant {
        require(
            citadelCollection.ownerOf(_citadelId) == msg.sender,
            "must own citadel"
        );
        require(
            _capitalId < maxCapital,
            "invalid capital"
        );
        uint256 treasuryAmt = storageEngine.sackCapital(_citadelId, _capitalId, bribeAmt, name);

        if (treasuryAmt > 0) {
            require(drakma.transferFrom(address(this), msg.sender, treasuryAmt));
        }
    }

    function overthrowSovereign(
        uint256 _fromCitadelId, 
        uint256 _toCitadelId,
        uint256 _usurper, 
        uint256 _sovereignId,
        uint8 _capitalId
    ) external nonReentrant {
        require(
            pilotCollection.ownerOf(_usurper) == msg.sender,
            "must own usurpur"
        );
        require(
            citadelCollection.ownerOf(_fromCitadelId) == msg.sender,
            "must own citadel"
        );
        require(
            sovereignCollective.isSovereign(_sovereignId), 
            "pilot must be sovereign"
        );
        require(
            _capitalId < maxCapital,
            "invalid capital"
        );
        uint256 overthrowAmt = storageEngine.overthrowSovereign(_fromCitadelId, _toCitadelId, _capitalId);
        if (overthrowAmt > 0) {
            require(drakma.transferFrom(msg.sender, address(this), overthrowAmt));
        }
        sovereignCollective.usurpSovereign(_usurper, _sovereignId, _capitalId);

        emit CitadelEvent(_fromCitadelId);
        emit CitadelEvent(_toCitadelId);
    }

    function winCitadel() external nonReentrant {
        uint8 i;
        while (i < maxCapital) {

            uint256 citadelId;
            (,,,,citadelId) = storageEngine.getCapital(i);
            require(
                citadelCollection.ownerOf(citadelId) == msg.sender,
                "must own citadel"
            );
            i++;
        }
        winners[msg.sender] = block.timestamp;
    }

    // public getters
    function getGrid(uint256 _gridId) public returns (bool, uint256, bool, uint256) {

        return storageEngine.grid(_gridId);
    }
}
