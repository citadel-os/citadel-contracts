// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IExplore {
    function liteGrid(
        uint256 _citadelId,
        uint256[3] calldata _pilotIds,
        uint256 _gridId,
        uint8 _capitalId
    ) external;
    function claim(uint256 _citadelId) external;
}