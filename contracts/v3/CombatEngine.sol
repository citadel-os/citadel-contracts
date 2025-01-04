// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/ICombatEngine.sol";

/**
 * @dev A stateless contract containing all the big arrays (weaponsProp, shieldProp, etc.)
 *      and purely functional logic for computing offensive/defensive power and destroyed fleets.
 *
 *      It does NOT access DiamondStorage. Any references to DiamondStorage variables have been removed.
 */
contract CombatEngine is ICombatEngine {
    // -----------------------------------------------------------------------
    // Large arrays and base parameters for pure calculations
    // -----------------------------------------------------------------------

    uint256 public constant sifGattacaOP     = 10;
    uint256 public constant mhrudvogThrotOP = 5;
    uint256 public constant drebentraakhtOP = 500;
    uint256 public constant sifGattacaDP     = 5;
    uint256 public constant mhrudvogThrotDP = 40;
    uint256 public constant drebentraakhtDP = 250;

    uint8[] shieldProp = [0,1,1,1,0,0,1,3,0,1,2,0,1,0,0,0,0,0,0,1,2,0,0,0,0,1,1,1,0,0,3,0,0,1,0,1,0,1,0,0,1,0,1,0,0,0,3,2,2,2,1,2,1,3,0,0,2,0,2,0,3,0,0,0,2,0,0,2,3,0,1,1,0,1,0,0,1,1,1,0,0,0,0,0,0,2,0,0,0,0,0,0,3,0,0,2,0,0,1,0,1,0,2,2,1,2,1,0,1,1,0,0,0,2,0,0,0,1,0,1,1,1,0,0,1,0,0,0,0,1,0,0,1,0,2,0,6,4,0,0,2,1,4,2,0,0,0,1,0,2,0,0,0,0,2,0,3,1,0,0,1,0,0,2,1,0,0,0,0,0,1,0,1,0,0,3,1,0,2,0,1,0,0,0,2,0,2,4,0,0,0,0,1,0,0,0,3,0,1,3,0,1,0,1,1,2,0,0,1,1,1,0,2,0,0,0,0,0,2,0,1,0,2,3,1,2,1,0,1,0,2,0,1,1,1,0,1,0,0,1,1,0,0,0,2,2,3,1,1,3,0,0,0,0,2,0,1,0,1,1,1,1,3,0,1,1,0,6,2,0,3,0,1,1,1,1,1,0,2,2,2,1,0,1,0,0,0,2,0,0,0,1,0,3,0,3,2,2,0,0,0,0,0,1,0,0,0,0,2,1,0,1,0,1,0,1,4,0,0,1,0,0,0,1,2,0,0,2,2,1,1,2,0,1,2,3,0,4,1,0,0,1,1,0,0,0,1,0,0,1,1,0,0,1,2,0,0,2,0,1,1,0,3,0,0,3,0,1,0,0,0,2,0,0,0,4,1,1,1,4,0,0,0,2,1,0,0,0,0,0,0,1,0,3,0,0,0,1,0,1,0,0,6,1,2,0,0,2,0,4,5,1,2,0,0,0,1,2,1,1,0,1,1,0,0,0,0,1,1,0,0,0,0,0,1,1,0,1,1,2,2,2,1,1,4,1,0,2,0,2,1,0,0,0,0,0,0,1,0,0,0,0,3,0,0,0,7,1,2,2,0,1,0,5,0,0,0,1,1,2,0,0,0,1,0,0,1,2,0,1,0,0,0,1,0,1,0,1,3,0,0,1,0,0,0,2,2,1,0,0,0,0,3,3,1,0,2,0,2,0,2,0,5,1,0,0,4,0,0,5,0,1,3,0,1,4,0,0,2,1,2,2,0,0,0,0,1,0,0,0,0,0,1,4,1,0,0,1,0,0,0,5,0,0,0,0,0,0,0,0,1,1,1,0,0,0,1,0,1,1,0,0,2,3,1,0,1,2,1,5,0,0,0,0,0,0,1,6,2,0,2,1,0,3,0,0,2,1,0,3,0,2,3,0,1,0,3,0,0,1,0,2,3,1,1,3,1,1,0,1,1,3,0,0,1,0,1,0,0,3,0,2,0,1,0,0,0,0,1,1,0,0,1,1,2,1,0,0,3,1,0,2,1,0,0,3,0,0,2,0,0,0,1,2,0,2,0,0,2,0,0,0,0,0,0,1,0,0,1,1,1,1,0,1,1,2,0,1,3,1,2,0,0,1,3,0,0,0,0,0,1,2,0,0,1,0,0,1,0,1,0,0,1,0,0,1,0,2,0,0,3,1,0,0,0,1,1,2,2,1,0,0,3,0,0,0,2,0,1,0,0,0,1,2,0,2,6,0,0,0,0,2,0,3,1,0,1,1,3,0,0,2,0,0,2,1,0,0,0,1,0,1,1,5,0,0,1,4,2,0,0,1,2,1,0,2,1,1,2,0,0,0,2,0,2,1,0,0,0,0,2,1,0,1,1,1,3,1,0,2,2,3,0,0,1,0,0,0,1,0,1,4,2,1,3,1,0,1,0,1,0,0,6,1,0,3,0,0,1,2,1,0,0,0,0,0,0,2,3,2,0,1,0,1,1,0,0,1,2,2,2,0,0,0,4,0,0,0,3,1,4,1,2,1,5,4,0,0,0,2,1,1,0,0,0,1,2,5,2,0,0,0,0,0,0,3,1,1,3,1,0,0,0,1,0,1,0,3,0,0,2,1,0,1,0,1,0,0,1,0,0,1,0,0,0,3,2,0,1,3,3,0,1,0,1,0,1,0,0,0,1,0,2,0,4,1,0,2,3,1,1,0,1,0,0,6,0,0,3,2,2,0,0,0,0,0,0,0,0,0,0,0,3,2,0,2,0,0,0,0,0,0,2,3,2,3,3,4,3,4,7,5,3,4,4,6,5,4,5,4,4,4,4,4,5,4,4,4,7,4,5,5,5,7];
    uint8[] engineProp = [1,0,1,4,1,0,0,0,1,0,0,1,0,1,0,0,0,2,1,0,0,1,0,3,0,0,0,0,1,1,0,3,1,1,0,1,0,0,0,0,1,0,3,0,1,0,0,3,0,0,3,1,0,0,0,2,0,1,1,0,1,0,0,0,0,0,0,1,7,0,2,1,3,0,0,5,1,0,0,1,0,0,1,1,1,0,0,0,0,1,0,0,3,1,2,0,0,4,0,1,0,3,2,0,0,0,0,0,1,0,0,0,0,0,0,0,3,2,1,0,0,2,0,2,0,1,0,1,0,1,1,0,5,1,0,3,1,0,0,3,0,1,1,1,1,0,0,6,1,0,1,0,1,1,0,0,1,1,0,1,0,0,0,1,0,2,0,0,0,4,0,2,0,5,5,0,2,6,3,0,0,1,0,0,4,0,1,2,1,1,2,1,0,0,2,7,2,0,2,0,2,0,0,1,0,2,5,0,1,4,0,0,0,0,0,1,1,2,1,0,2,1,0,4,1,4,0,1,2,2,0,0,1,0,0,0,0,1,0,2,1,1,0,4,0,1,1,2,1,1,0,1,0,1,0,1,2,3,0,0,0,0,1,3,1,0,2,0,2,0,3,0,0,1,0,6,0,0,1,0,0,2,1,0,0,1,1,0,1,2,1,1,1,1,0,0,0,0,4,0,2,0,1,1,5,0,1,2,2,3,2,2,0,3,1,5,1,1,0,0,1,1,3,2,0,0,0,0,0,0,0,0,0,0,3,0,0,0,2,0,0,0,0,1,0,1,0,1,0,0,1,0,1,0,1,1,1,2,0,1,0,2,1,0,2,3,0,2,0,0,0,1,0,0,4,1,0,0,0,4,0,0,0,4,4,1,5,0,0,1,2,1,1,1,0,2,1,1,1,3,2,0,2,0,0,1,0,0,0,0,0,1,2,0,3,1,0,3,0,0,0,0,0,1,1,0,0,1,1,1,0,0,0,1,0,2,0,1,2,0,1,1,0,0,0,2,0,1,0,2,1,2,1,0,1,0,3,0,2,0,1,3,1,0,0,0,0,1,3,0,0,1,0,1,4,1,0,1,0,1,1,1,2,0,0,0,3,1,1,2,1,2,0,2,2,4,0,0,2,3,2,0,0,0,0,0,2,1,0,4,1,1,0,0,0,0,0,2,0,0,0,0,1,1,1,0,0,0,1,3,1,0,1,3,1,0,4,2,1,0,0,1,1,0,1,1,0,2,0,2,0,2,2,0,1,0,0,0,0,1,2,0,0,2,2,1,1,1,2,0,5,0,0,0,0,0,1,0,1,0,0,1,2,0,2,4,5,1,0,2,0,0,0,4,0,6,3,2,2,0,1,0,1,4,0,0,1,0,0,0,0,1,1,0,0,1,1,0,0,3,0,0,3,1,1,0,0,2,0,2,1,2,0,3,0,1,0,2,1,0,0,4,3,2,0,1,2,0,1,0,0,4,0,2,0,3,3,0,1,0,0,0,1,1,0,2,0,3,1,0,0,1,0,3,1,4,0,3,0,0,4,1,1,1,0,0,3,0,0,0,0,2,0,0,0,4,1,0,0,0,0,0,2,1,3,0,0,0,0,2,0,0,0,2,1,0,3,0,0,1,0,1,0,2,0,0,0,0,1,0,1,1,1,5,5,2,0,2,0,0,0,0,0,1,3,1,0,1,0,2,0,0,0,2,1,2,1,2,2,0,5,1,1,0,0,3,2,0,1,0,0,1,0,2,1,0,3,0,0,3,2,1,1,1,2,0,0,0,1,0,1,2,0,1,2,0,0,1,0,1,3,2,5,0,0,0,0,0,3,2,0,0,4,1,1,0,0,3,0,2,0,0,0,1,2,2,0,1,2,1,2,0,6,0,1,0,1,2,2,2,0,2,0,0,0,3,4,1,1,1,1,4,0,0,2,2,0,2,2,0,1,0,0,0,1,1,0,3,1,0,3,0,3,2,2,0,1,0,1,5,1,0,0,3,0,0,2,0,0,1,4,1,1,1,0,1,0,0,3,0,0,3,1,0,0,0,1,2,0,0,0,0,0,2,2,0,0,0,0,0,4,5,4,2,0,1,0,1,2,0,2,0,2,0,1,0,0,1,1,2,0,0,0,0,2,1,1,0,2,0,0,0,0,0,0,1,0,1,0,0,1,0,0,3,0,4,1,1,0,0,0,1,3,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,0,0,0,0,0,3,0,0,0,0,0,0,0,3,3,3,6,6,6,7,7];
    uint8[] weaponsProp = [0,0,0,1,1,3,0,0,1,3,1,0,0,0,4,4,2,4,0,0,1,1,4,0,0,5,0,1,0,0,0,3,0,0,1,0,0,1,0,0,2,1,0,0,0,0,1,0,3,0,1,0,1,3,0,0,1,1,2,1,0,2,0,0,0,2,1,0,1,1,1,0,0,2,1,2,3,0,0,2,2,0,0,2,0,0,0,3,0,0,0,0,0,0,1,1,1,0,0,0,1,5,0,1,4,0,1,0,3,0,0,0,0,1,0,1,0,0,0,0,3,1,1,1,0,0,2,0,0,5,0,1,1,1,0,0,1,4,1,0,0,1,0,1,0,0,0,1,1,2,0,2,3,0,3,0,3,1,6,2,1,1,0,0,0,0,1,0,1,0,2,2,0,0,0,1,1,0,0,1,0,0,1,0,0,0,4,5,1,0,1,1,1,0,0,0,2,5,0,1,0,0,1,0,2,0,0,3,0,0,1,2,0,2,0,0,0,0,0,2,3,1,1,1,0,0,5,1,0,0,0,0,1,2,2,1,0,0,3,1,0,0,1,0,1,1,1,0,0,0,0,0,1,0,0,2,0,0,0,0,0,0,0,1,0,0,2,0,0,2,1,2,0,1,0,0,5,1,0,2,2,1,2,0,1,3,0,1,2,0,0,1,0,0,2,2,0,1,0,0,1,4,1,0,1,2,0,0,4,0,0,4,0,1,0,1,0,0,1,2,0,1,0,1,3,0,0,1,0,0,1,1,0,1,0,0,0,0,3,1,1,0,1,4,1,0,3,0,0,1,0,0,2,1,5,1,4,2,2,1,2,0,0,1,1,1,0,0,3,0,0,0,2,1,1,2,0,0,1,4,0,1,1,0,2,0,0,0,0,4,2,0,0,1,0,0,0,4,0,0,0,1,1,4,3,1,0,0,1,0,1,0,0,0,0,1,0,0,1,1,1,0,1,4,0,0,2,0,0,0,7,1,0,3,5,1,4,1,0,0,2,1,1,1,0,0,1,4,0,6,1,1,1,1,0,0,3,0,4,3,4,0,1,0,1,0,0,0,3,2,3,2,2,2,0,0,2,1,0,2,1,1,0,1,0,0,2,1,0,0,4,1,0,2,0,2,2,0,2,4,0,0,0,1,1,1,0,1,0,2,0,0,0,1,0,1,1,0,0,0,4,1,1,0,0,0,1,2,0,4,1,1,0,0,1,0,1,0,0,0,1,0,1,0,0,0,0,2,0,3,0,2,0,1,0,2,2,0,0,0,0,0,2,0,0,1,1,0,0,7,0,1,2,2,0,1,2,2,0,2,0,0,1,1,1,0,2,1,0,1,4,0,0,1,0,0,2,1,2,0,0,4,1,0,0,1,2,1,1,1,0,0,0,1,0,1,0,1,1,0,0,1,1,0,2,0,0,0,0,3,1,2,3,0,0,0,0,1,0,2,1,2,0,2,1,1,0,1,2,0,0,5,2,2,5,0,0,0,0,1,7,1,1,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,2,0,0,1,0,1,1,0,0,2,2,0,1,1,1,0,0,2,1,2,0,1,0,2,0,0,2,3,0,0,2,3,3,0,1,4,0,1,0,0,1,0,0,3,0,4,0,1,0,0,0,0,0,0,1,3,0,4,1,1,0,0,0,0,1,2,1,1,1,1,0,0,2,2,4,1,0,1,0,2,0,0,1,1,0,2,1,4,0,0,0,0,1,0,2,0,0,2,1,0,0,1,1,2,0,2,1,0,5,0,0,0,1,0,0,2,2,1,0,0,1,1,2,0,0,0,2,0,5,0,0,2,5,0,0,0,0,0,7,0,2,0,3,0,0,0,3,2,0,2,0,1,2,0,1,0,0,0,0,0,2,3,1,1,0,0,0,1,0,2,0,1,3,1,0,0,1,0,0,0,0,0,0,0,3,0,2,0,0,0,0,2,2,0,0,1,1,0,0,2,1,0,0,1,0,0,0,0,2,5,0,1,0,2,1,0,0,1,3,0,0,0,0,1,3,0,0,1,0,1,0,0,0,1,0,1,0,0,0,2,0,1,1,0,0,0,2,0,0,0,0,0,1,2,2,1,0,0,0,0,0,3,0,2,0,1,0,1,0,0,1,1,0,0,0,0,0,1,0,2,1,1,0,0,6,0,1,2,3,0,0,1,2,1,0,2,0,1,0,2,0,0,1,2,0,2,0,0,0,0,0,0,0,0,3,1,3,3,1,3,2,3,3,3,3,6,5,6,3,3,3,3,3,3,3,6,3,3,3,3,3,3,6,6];
    uint8[] sektMultiple = [16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,4,4,2,2,4,2,4,2,4,8,2,2,2,4,2,4,4,2,4,4,2,4,8,4,2,2,2,2,2,2,8,8,2,4,8,8,2,2,2,4,4,2,4,2,8,4,4,4,2,8,2,4,2,4,4,8,4,2,2,2,2,2,4,8,2,4,4,2,2,2,2,8,4,4,8,2,2,2,4,8,2,2,2,4,8,4,2,2,2,2,4,2,4,2,4,2,4,2,2,2,4,4,2,2,2,2,2,2,2,4,2,2,2,8,2,2,2,4,4,4,4,4,4,2,2,4,4,8,2,2,2,2,4,2,2,2,2,2,2,2,2,2,8,2,4,2,2,4,2,2,8,2,2,2,2,4,4,2,4,2,2,2,4,2,2,8,8,2,4,2,4,2,2,2,2,4,2,4,4,4,8,2,4,4,2,4,4,4,2,2,2,2,2,4,4,4,2,4,8,2,4,2,4,2,4,2,2,8,4,4,4,2,4,2,8,2,8,2,8,2,4,2,4,4,8,4,2,2,2,2,8,4,4,2,8,2,4,2,2,4,2,8,2,2,2,4,2,4,2,8,2,4,2,2,8,8,4,2,2,2,8,2,8,2,2,2,2,4,8,2,2,2,2,2,2,2,2,8,4,2,2,2,2,2,2,2,2,2,4,2,4,2,2,2,4,2,2,2,8,8,4,2,2,4,2,4,4,2,2,2,2,2,4,2,8,4,2,4,4,2,2,2,2,2,2,2,2,4,2,2,4,4,4,2,2,2,4,2,8,2,2,2,4,2,2,4,2,8,2,4,2,2,2,4,2,8,2,2,2,2,8,2,2,4,2,2,2,2,2,4,2,8,4,2,2,2,4,2,8,4,8,2,2,4,2,2,2,4,2,2,2,2,4,4,8,2,2,2,4,4,2,4,4,2,2,2,2,2,2,8,4,2,4,8,2,2,4,2,4,2,2,2,8,2,2,8,2,2,2,2,2,2,4,2,4,4,4,8,2,2,2,8,2,2,2,2,2,2,2,4,2,2,8,8,2,2,2,2,8,2,4,2,4,4,2,8,2,2,2,2,2,8,2,2,2,4,2,2,2,4,4,2,2,2,8,2,4,4,2,2,8,2,2,2,2,2,2,2,2,4,2,2,2,8,4,2,2,4,2,4,4,8,2,2,4,2,2,2,4,4,4,2,2,4,2,8,2,2,4,2,4,4,2,2,8,2,2,2,8,2,8,2,2,2,2,4,8,2,8,4,4,2,8,2,2,2,4,2,2,2,4,4,2,2,2,2,2,4,2,8,2,4,4,2,2,8,4,2,2,2,2,2,2,2,2,4,2,2,4,2,8,2,2,4,8,4,2,2,2,8,8,2,4,4,4,4,4,4,2,4,2,2,4,2,2,4,8,2,8,2,2,2,2,2,4,2,2,8,2,8,4,2,4,4,2,2,2,4,2,2,2,8,2,8,8,2,2,2,8,2,2,8,2,2,4,2,4,2,8,8,2,8,2,2,4,8,8,8,2,2,2,4,8,2,2,2,2,4,4,2,2,8,2,4,4,4,8,2,2,4,2,4,2,4,2,8,2,2,2,2,2,2,2,2,8,2,2,2,8,2,8,2,2,2,8,8,8,2,8,4,4,2,4,2,2,4,4,8,2,2,4,2,2,8,2,8,2,2,2,4,4,4,2,4,2,8,8,2,2,4,4,2,8,8,2,2,2,8,8,4,4,2,2,4,2,2,4,4,4,2,8,4,2,8,2,2,2,2,4,2,4,4,2,4,4,2,2,2,2,2,2,8,2,2,2,2,2,4,2,4,2,2,2,2,2,2,8,2,8,8,2,8,2,2,2,8,4,2,2,4,8,2,2,8,2,2,4,2,2,2,2,2,4,8,2,2,4,2,4,8,8,4,4,2,2,2,2,4,2,2,2,2,2,2,2,4,2,2,8,2,2,2,2,4,2,4,2,4,4,2,2,2,2,2,2,4,2,2,2,4,2,2,2,2,2,4,2,2,2,2,2,2,4,2,8,2,2,2,8,4,2,2,4,2,2,4,2,2,2,8,2,2,4,4,2,2,2,2,2,2,2,4,2,2,2,4,2,4,2,2,2,4,4,4,2,2,2,2,2,2,4,2,4,4,2,2,2,4,2,2,4,4,4,4,4,2,2,2,2,2];


    // -----------------------------------------------------------------------
    // Public API (ICombatEngine)
    // -----------------------------------------------------------------------

    /**
     * @dev Main function called by CitadelCombat to figure out how fleets are destroyed.
     *      We compute offensive power (OP), defensive power (DP), then the destroyed amounts.
     */
    function calculateDestroyedFleet(
        uint256 _offensivePilotId,
        uint256[3] memory _defensivePilotIds,
        uint256[6] memory _fleetTracker,
        uint256 _defensiveCitadelId
    )
        external
        view
        override
        returns (
            uint256 offSifDestroyed,
            uint256 offMhrDestroyed,
            uint256 offDrebDestroyed,
            uint256 defSifDestroyed,
            uint256 defMhrDestroyed,
            uint256 defDrebDestroyed,
            uint256 offensiveWinRatio
        )
    {
        // _fleetTracker = [offSif, offMhr, offDreb, defSif, defMhr, defDreb]
        uint256 op = _combatOP(
            _offensivePilotId,
            _fleetTracker[0],
            _fleetTracker[1],
            _fleetTracker[2]
        );

        uint256 dp = _combatDP(
            _defensiveCitadelId,
            _defensivePilotIds,
            _fleetTracker[3],
            _fleetTracker[4],
            _fleetTracker[5]
        );

        if (dp > 0) {
            (op, dp) = _adjustedOPDP(op, dp);
        }

        // Offensive destroyed
        _fleetTracker[0] = (
            _fleetTracker[0] * dp * 50
        ) / ((op + dp) * 100);

        _fleetTracker[1] = (
            _fleetTracker[1] * dp * 50
        ) / ((op + dp) * 100);

        _fleetTracker[2] = (
            _fleetTracker[2] * dp * 50
        ) / ((op + dp) * 100);

        // Defensive destroyed
        _fleetTracker[3] = (
            _fleetTracker[3] * op * 50
        ) / ((op + dp) * 100);

        _fleetTracker[4] = (
            _fleetTracker[4] * op * 50
        ) / ((op + dp) * 100);

        _fleetTracker[5] = (
            _fleetTracker[5] * op * 50
        ) / ((op + dp) * 100);

        // Offensive Win Ratio = op / (op + dp) * 100
        offensiveWinRatio = (op * 100) / (op + dp);

        return (
            _fleetTracker[0],
            _fleetTracker[1],
            _fleetTracker[2],
            _fleetTracker[3],
            _fleetTracker[4],
            _fleetTracker[5],
            offensiveWinRatio
        );
    }

    // -----------------------------------------------------------------------
    // Internal (pure/view) Functions
    // -----------------------------------------------------------------------

    /**
     * @dev Offensive Power (OP). In your original code, references pilot level as `_pilotLevel`,
     *      but you used `_offensivePilotId`. We keep it consistent with your usage.
     */
    function _combatOP(
        uint256 _pilotLevel,
        uint256 _sifGattaca,
        uint256 _mhrudvogThrot,
        uint256 _drebentraakht
    ) internal pure returns (uint256) {
        // OP = ( (sif*gattacaOP + mhrudvogThrot*mhrudvogThrotOP + drebentraakht*drebentraakhtOP) * (100 + pilotLevel)) / 100
        uint256 base = (
            (_sifGattaca * sifGattacaOP) +
            (_mhrudvogThrot * mhrudvogThrotOP) +
            (_drebentraakht * drebentraakhtOP)
        );
        return (base * (100 + _pilotLevel)) / 100;
    }

    /**
     * @dev Defensive Power (DP). We read certain big arrays by citadelId (e.g. weaponsProp, shieldProp, engineProp).
     */
    function _combatDP(
        uint256 _citadelId,
        uint256[3] memory _pilotIds,
        uint256 _sifGattaca,
        uint256 _mhrudvogThrot,
        uint256 _drebentraakht
    ) internal view returns (uint256) {
        // Step 1: base "multiple" from number of pilot IDs
        uint256 multiple = _pilotIds.length;

        // Step 2: add base multiples from weapon & shield
        multiple += _calculateBaseCitadelMultiple(weaponsProp[_citadelId]);
        multiple += _calculateBaseCitadelMultiple(shieldProp[_citadelId]);

        // Step 3: unique bonuses from weapon, engine, shield
        (uint256 swarmMultiple, uint256 siegeMultiple) = _calculateUniqueBonus(
            weaponsProp[_citadelId],
            engineProp[_citadelId],
            shieldProp[_citadelId]
        );

        // Step 4: compute partial DP
        uint256 tempDP = (
            (
                ((_sifGattaca * sifGattacaDP) * (100 + swarmMultiple)) / 100
            ) +
            (_mhrudvogThrot * mhrudvogThrotDP) +
            (
                (_drebentraakht * drebentraakhtDP) * (100 + siegeMultiple) / 100
            )
        );

        // Step 5: final DP = partial * (100 + multiple) / 100
        return (tempDP * (100 + multiple)) / 100;
    }

    function _calculateBaseCitadelMultiple(uint8 _index) internal pure returns (uint256) {
        if (_index == 0) {
            return 10;
        } else if (_index == 1) {
            return 11;
        } else if (_index == 2) {
            return 12;
        } else if (_index == 3) {
            return 15;
        } else if (_index == 4) {
            return 17;
        } else if (_index == 5) {
            return 20;
        } else if (_index == 6) {
            return 25;
        } else {
            return 35;
        }
    }

    function _calculateUniqueBonus(
        uint8 _weapon,
        uint8 _engine,
        uint8 _shield
    ) internal pure returns (uint256 swarmMultiple, uint256 siegeMultiple) {
        // weapon
        if (_weapon == 0) {
            swarmMultiple += 5;
        } else if (_weapon == 1) {
            siegeMultiple += 5;
        } else if (_weapon == 2) {
            swarmMultiple += 6;
        } else if (_weapon == 3) {
            swarmMultiple += 7;
        } else if (_weapon == 4) {
            siegeMultiple += 7;
        } else if (_weapon == 6) {
            siegeMultiple += 10;
        }

        // shield
        if (_shield == 0) {
            siegeMultiple += 5;
        } else if (_shield == 1) {
            siegeMultiple += 10;
        } else if (_shield == 2) {
            swarmMultiple += 2;
            siegeMultiple += 2;
        } else if (_shield == 3) {
            siegeMultiple += 15;
        } else if (_shield == 4) {
            swarmMultiple += 5;
            siegeMultiple += 5;
        } else if (_shield == 5) {
            swarmMultiple += 15;
        } else {
            swarmMultiple += 25;
        }

        // engine
        if (_engine == 0) {
            swarmMultiple += 1;
            siegeMultiple += 1;
        } else if (_engine == 1) {
            swarmMultiple += 2;
            siegeMultiple += 2;
        } else if (_engine == 5) {
            swarmMultiple += 5;
            siegeMultiple += 5;
        }
    }

    /**
     * @dev Adjusts OP and DP based on an exponential difference factor.
     *      Used to avoid overly one-sided battles.
     */
    function _adjustedOPDP(uint256 op, uint256 dp) internal pure returns (uint256, uint256) {
        // ratio = (op * 100) / dp
        if (dp == 0) {
            // avoid division by zero
            return (op, dp);
        }
        uint256 ratio = (op * 100) / dp;
        uint256 exponent;
        if (ratio < 25) {
            exponent = 6;
        } else if (ratio < 50) {
            exponent = 5;
        } else if (ratio < 75) {
            exponent = 4;
        } else if (ratio < 100) {
            exponent = 3;
        } else if (ratio < 125) {
            exponent = 2;
        } else {
            exponent = 1;
        }

        // new op = (op^2) / (op + 2*dp/exponent)
        // new dp = (dp^2) / (dp + 2*op/exponent)
        uint256 newOp = (op * op) / (op + ((2 * dp) / exponent));
        uint256 newDp = (dp * dp) / (dp + ((2 * op) / exponent));
        return (newOp, newDp);
    }

    function calculateGridTraversal(
        uint256 gridA, 
        uint256 gridB, 
        uint256 gridTraveralTime
    ) public pure returns (uint256) {

        // Convert grid numbers to latitude (lat) and longitude (lon) indices
        uint256 latA = (gridA - 1) / 16;
        uint256 lonA = (gridA - 1) % 16;

        uint256 latB = (gridB - 1) / 16;
        uint256 lonB = (gridB - 1) % 16;

        // Calculate minimal latitude distance considering pole traversal
        uint256 deltaLat = minLatitudeDistance(latA, latB);

        // Calculate longitude difference with wrap-around
        uint256 absLonDiff = lonA > lonB ? lonA - lonB : lonB - lonA;
        uint256 deltaLon = absLonDiff > 8 ? 16 - absLonDiff : absLonDiff;

        // Total moves (number of grids to traverse)
        uint256 totalMoves = deltaLat + deltaLon;

        // Total traversal time
        uint256 traversalTime = totalMoves * gridTraveralTime;

        return traversalTime;
    }

    // Helper function to calculate minimal latitude distance considering pole traversal
    function minLatitudeDistance(uint256 latA, uint256 latB) internal pure returns (uint256) {
        if ((latA == 0 && latB == 15) || (latA == 15 && latB == 0)) {
            // Instant traversal from North Pole to South Pole
            return 0;
        }

        // Direct latitude distance
        uint256 directDistance = latA > latB ? latA - latB : latB - latA;

        // Distance via North and South Poles
        uint256 viaPoles1 = latA + (15 - latB); // Through North Pole to South Pole
        uint256 viaPoles2 = (15 - latA) + latB; // Through South Pole to North Pole

        // Minimal latitude distance
        uint256 minDistance = directDistance;
        if (viaPoles1 < minDistance) {
            minDistance = viaPoles1;
        }
        if (viaPoles2 < minDistance) {
            minDistance = viaPoles2;
        }

        return minDistance;
    }
}