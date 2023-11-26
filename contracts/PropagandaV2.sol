// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract PropagandaV2 is Ownable {
    constructor() {}

    address accessAddressGame;
    address accessAddressStorage;

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

    // only owner
    function updateAccessAddress(address _accessAddressGame, address _accessAddressStorage) external onlyOwner {
        accessAddressGame = _accessAddressGame;
        accessAddressStorage = _accessAddressStorage;
    }

    function dispatchCitadelEvent(uint256 _fromCitadel) public {
        require(msg.sender == accessAddressGame, "cannot call function directly");
        emit CitadelEvent(
            _fromCitadel
        );
    }

    function dispatchSiegeEvent(
        uint256 _fromCitadelId, 
        uint256 _toCitadelId, 
        uint256 _timeSiegeHit, 
        uint256 _offensiveCarryCapacity, 
        uint256 _drakmaSieged, 
        uint256 _offensiveSifGattacaDestroyed, 
        uint256 _offensiveMhrudvogThrotDestroyed, 
        uint256 _offensiveDrebentraakhtDestroyed, 
        uint256 _defensiveSifGattacaDestroyed, 
        uint256 _defensiveMhrudvogThrotDestroyed, 
        uint256 _defensiveDrebentraakhtDestroyed
    ) public {
        require(msg.sender == accessAddressStorage, "cannot call function directly");


        emit DispatchSiege(
            _fromCitadelId, 
            _toCitadelId, 
            _timeSiegeHit, 
            _offensiveCarryCapacity, 
            _drakmaSieged, 
            _offensiveSifGattacaDestroyed, 
            _offensiveMhrudvogThrotDestroyed, 
            _offensiveDrebentraakhtDestroyed, 
            _defensiveSifGattacaDestroyed, 
            _defensiveMhrudvogThrotDestroyed, 
            _defensiveDrebentraakhtDestroyed
        );
    }
}

    