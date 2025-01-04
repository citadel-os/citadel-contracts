// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ICombatEngine.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @dev This library holds all of the "game" state for your Citadel app.
 * Each facet uses `DiamondStorage.diamondStorage()` to read and write.
 */
library DiamondStorage {
    bytes32 constant GAME_STORAGE_POSITION = keccak256("citadel.game.storage.v1");

    // ---------------------
    //     Structs
    // ---------------------
    struct Node {
        uint256 gridId;
        bool isLit;
        uint256 citadelId;
    }

    struct CitadelNode {
        uint256 nodeId;
        uint256 timeOfLastClaim;
        uint256 timeLit;
        uint256 timeLastSieged;
        uint256 unclaimedDrakma;
        uint256[3] pilot;
        uint8 faction;
        uint8 orbitHeight;
        uint8 marker;
    }

    struct Fleet {
        uint256 sifGattaca;
        uint256 mhrudvogThrot;
        uint256 drebentraakht;
    }

    struct FleetReinforce {
        Fleet fleet;
        uint256 toCitadel;
        uint256 fleetArrivalTime;
    }

    struct FleetAcademy {
        Fleet stationedFleet;
        Fleet trainingFleet;
        uint256 trainingStarted;
        uint256 trainingDone;
        bool isValue;
    }

    struct Siege {
        uint256 toCitadel;
        Fleet fleet;
        uint256 pilot;
        uint256 timeSiegeHits;
        uint256 offensiveCarryCapacity;
        uint256 drakmaSieged;
        uint256 offensiveSifGattacaDestroyed;
        uint256 offensiveMhrudvogThrotDestroyed;
        uint256 offensiveDrebentraakhtDestroyed;
        uint256 defensiveSifGattacaDestroyed;
        uint256 defensiveMhrudvogThrotDestroyed;
        uint256 defensiveDrebentraakhtDestroyed;
    }

    struct GameStorage {
        // Basic game parameters
        uint256 maxCitadel;
        uint256 maxNode;
        uint256 claimInterval;
        uint256 gameStart;
        uint8 pilotMultiple;
        uint8 levelMultiple;
        uint256 gridTraversalTime;
        uint256 sifGattacaTrainingTime;
        uint256 mhrudvogThrotTrainingTime;
        uint256 drebentraakhtTrainingTime;
        uint256 siegeMaxExpiry;

        // References to external contracts
        IERC20 drakma;
        ICombatEngine combatEngine;
        IERC721 citadelCollection;
        IERC721 pilotCollection;

        // "Carry" values for each fleet type
        uint256 sifGattacaCary;
        uint256 mhrudvogThrotCary;
        uint256 drebentraakhtCary;

        // Actual game data
        mapping(uint256 => Node) node; 
        mapping(uint256 => CitadelNode) citadelNode;
        mapping(uint256 => FleetAcademy) fleet;
        mapping(uint256 => FleetReinforce) reinforcements;
        mapping(uint256 => bool) pilot;
        mapping(uint256 => uint256) nodeMultiple;
        mapping(uint256 => Siege) siege;
    }

    /**
     * @dev Returns a pointer to the app's GameStorage struct in contract storage.
     */
    function diamondStorage() internal pure returns (GameStorage storage ds) {
        bytes32 position = GAME_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}
