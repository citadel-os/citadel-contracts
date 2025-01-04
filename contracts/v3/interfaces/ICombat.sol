// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICombat {
    /**
     * @dev Sends a siege from one citadel to another with a pilot and a specified fleet.
     */
    function sendSiege(
        uint256 _fromCitadel, 
        uint256 _toCitadel, 
        uint256 _pilotId, 
        uint256[3] calldata _fleet
    ) external;

    /**
     * @dev Resolves a siege from a given citadel (the "attacker").
     */
    function resolveSiege(uint256 _fromCitadel) external;

    /**
     * @dev Optional: Provide an initializer to set up addresses & carry values
     *      or any other public functions you'd like from the combat facet.
     */
    function initCombatFacet(
        address _drakmaAddress,
        address _combatEngineAddress,
        uint256 _sifGattacaCarry,
        uint256 _mhrudvogThrotCarry,
        uint256 _drebentraakhtCarry
    ) external;
}
