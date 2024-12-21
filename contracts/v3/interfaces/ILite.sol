// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ILite {
    function liteGrid(
        uint256 _citadelId,
        uint256[3] calldata _pilotIds,
        uint256 _nodeId,
        uint8 _factionId,
        uint8 _orbitHeight,
        bytes32[] calldata proof
    ) external;
    function trainFleet(
        uint256 _citadelId, 
        uint256 _sifGattaca, 
        uint256 _mhrudvogThrot, 
        uint256 _drebentraakht
    ) external;
}