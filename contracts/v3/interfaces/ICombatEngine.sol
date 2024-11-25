// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICombatEngine {
    function calculateGridTraversal(
        uint256 gridA, 
        uint256 gridB
    ) external view returns (uint256);

    function calculateDestroyedFleet(            
        uint256 _offensivePilotId,
        uint256[3] memory _defensivePilotIds,
        uint256[6] memory _fleetTracker,
        uint256 _defensiveCitadelId
    ) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256);

    function calculateMiningOutput(
        uint256 _citadelId, 
        uint256 _nodeId, 
        uint256 lastClaimTime
    ) external pure returns (uint256);

    function getCitadelFleetCount(uint256 _citadelId) external view returns (
        uint256, uint256, uint256
    );
}
