// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IExterminate {
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
}

