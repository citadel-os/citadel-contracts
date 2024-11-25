// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ICombat {
    function liteGrid(
        uint256 _citadelId,
        uint256[3] calldata _pilotIds,
        uint256 _nodeId,
        uint8 _factionId,
        uint8 _orbitHeight
    ) external;
}