// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract DiamondStorage {
    uint256 maxCitadel = 1024;
    uint256 maxNode = 2048;
    uint256 claimInterval = 64 days;
    uint256 gameStart;
    uint8 pilotMultiple = 20;
    uint8 levelMultiple = 2;
    uint256 public gridTraversalTime = 30 minutes;
    uint256 sifGattacaTrainingTime = 5 minutes;
    uint256 mhrudvogThrotTrainingTime = 15 minutes;
    uint256 drebentraakhtTrainingTime = 1 hours;
    uint256 siegeMaxExpiry = 24 hours;

    bytes32 public nftMerkleRoot;

    event CitadelEvent(
        uint256 citadelId
    );

    event DispatchSiege(
        uint256 fromCitadelId, 
        uint256 toCitadelId,
        uint256 timeSiegeHit,
        uint256 offensiveCarryCapacity,
        uint256 drakmaSieged,
        uint256 offensiveSifGattacaDestroyed,
        uint256 offensiveMhrudvogThrotDestroyed,
        uint256 offensiveDrebentraakhtDestroyed,
        uint256 defensiveSifGattacaDestroyed,
        uint256 defensiveMhrudvogThrotDestroyed,
        uint256 defensiveDrebentraakhtDestroyed
    );

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
    }

    mapping(uint256 => Node) node; // index is _nodeId
    mapping(uint256 => CitadelNode) citadelNode; // index is _citadelId
    mapping(uint256 => FleetAcademy) fleet; // index is _citadelId
    mapping(uint256 => FleetReinforce) reinforcements; // index is _fromCitadelId
    mapping(uint256 => bool) pilot; // index is _pilotId, value isLit
    mapping(uint256 => uint256) nodeMultiple; // index is _nodeId
    mapping(uint256 => Siege) siege; // index is _fromCitadelId


    function getGridFromNode(uint256 _nodeId) internal pure returns (uint256) {
        uint256 gridId = (_nodeId - 1) / 8 + 1;
        return gridId;
    }

    /// @notice Verify that (owner, tokenId) is part of the merkle tree
    /// @param owner The address to verify
    /// @param tokenId The tokenId owned by that address
    /// @param proof The Merkle proof
    /// @return True if verified, false otherwise
    function verifyOwnership(
        address owner,
        uint256 tokenId,
        bytes32[] calldata proof,
        bool isCitadel
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(owner, tokenId, isCitadel));
        return MerkleProof.verify(proof, nftMerkleRoot, leaf);
    }

    // diamond storage functionality
    struct FacetAddresses {
        mapping(bytes4 => address) addresses;
    }

    function diamondStorage() internal pure returns (FacetAddresses storage ds) {
        bytes32 position = keccak256("diamond.standard.diamond.storage");
        assembly {
            ds.slot := position
        }
    }




}