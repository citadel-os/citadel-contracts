// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @dev Interface for the stateless CombatEngine
 *      that calculates fleet outcomes without accessing DiamondStorage.
 */
interface ICombatEngine {
    /**
     * @dev Calculates how much of each fleet (offensive and defensive) is destroyed,
     *      plus an "offensive win ratio" percentage.
     *
     * @param _offensivePilotId   Pilot level or ID for offensive side
     * @param _defensivePilotIds  Array of pilot levels/IDs for the defender
     * @param _fleetTracker       [offSif, offMhr, offDreb, defSif, defMhr, defDreb]
     * @param _defensiveCitadelId Citadel ID for the defender (used to compute DP)
     *
     * @return (offSifDestroyed, offMhrDestroyed, offDrebDestroyed,
     *          defSifDestroyed, defMhrDestroyed, defDrebDestroyed,
     *          offensiveWinRatio)
     */
    function calculateDestroyedFleet(
        uint256 _offensivePilotId,
        uint256[3] memory _defensivePilotIds,
        uint256[6] memory _fleetTracker,
        uint256 _defensiveCitadelId
    )
        external
        view
        returns (
            uint256, 
            uint256, 
            uint256, 
            uint256, 
            uint256, 
            uint256, 
            uint256
        );

    function calculateGridTraversal(
    uint256 gridA, 
    uint256 gridB, 
    uint256 gridTraveralTime
    ) external view returns (uint256);
}


