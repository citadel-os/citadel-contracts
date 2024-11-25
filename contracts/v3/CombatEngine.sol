// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "./DiamondStorage.sol";

contract CombatEngine is DiamondStorage {

    uint256 sifGattacaOP = 10;
    uint256 mhrudvogThrotOP = 5;
    uint256 drebentraakhtOP = 500;
    uint256 sifGattacaDP = 5;
    uint256 mhrudvogThrotDP = 40;
    uint256 drebentraakhtDP = 250;

    uint8[] shieldProp = [0,1,1,1,0,0,1,3,0,1,2,0,1,0,0,0,0,0,0,1,2,0,0,0,0,1,1,1,0,0,3,0,0,1,0,1,0,1,0,0,1,0,1,0,0,0,3,2,2,2,1,2,1,3,0,0,2,0,2,0,3,0,0,0,2,0,0,2,3,0,1,1,0,1,0,0,1,1,1,0,0,0,0,0,0,2,0,0,0,0,0,0,3,0,0,2,0,0,1,0,1,0,2,2,1,2,1,0,1,1,0,0,0,2,0,0,0,1,0,1,1,1,0,0,1,0,0,0,0,1,0,0,1,0,2,0,6,4,0,0,2,1,4,2,0,0,0,1,0,2,0,0,0,0,2,0,3,1,0,0,1,0,0,2,1,0,0,0,0,0,1,0,1,0,0,3,1,0,2,0,1,0,0,0,2,0,2,4,0,0,0,0,1,0,0,0,3,0,1,3,0,1,0,1,1,2,0,0,1,1,1,0,2,0,0,0,0,0,2,0,1,0,2,3,1,2,1,0,1,0,2,0,1,1,1,0,1,0,0,1,1,0,0,0,2,2,3,1,1,3,0,0,0,0,2,0,1,0,1,1,1,1,3,0,1,1,0,6,2,0,3,0,1,1,1,1,1,0,2,2,2,1,0,1,0,0,0,2,0,0,0,1,0,3,0,3,2,2,0,0,0,0,0,1,0,0,0,0,2,1,0,1,0,1,0,1,4,0,0,1,0,0,0,1,2,0,0,2,2,1,1,2,0,1,2,3,0,4,1,0,0,1,1,0,0,0,1,0,0,1,1,0,0,1,2,0,0,2,0,1,1,0,3,0,0,3,0,1,0,0,0,2,0,0,0,4,1,1,1,4,0,0,0,2,1,0,0,0,0,0,0,1,0,3,0,0,0,1,0,1,0,0,6,1,2,0,0,2,0,4,5,1,2,0,0,0,1,2,1,1,0,1,1,0,0,0,0,1,1,0,0,0,0,0,1,1,0,1,1,2,2,2,1,1,4,1,0,2,0,2,1,0,0,0,0,0,0,1,0,0,0,0,3,0,0,0,7,1,2,2,0,1,0,5,0,0,0,1,1,2,0,0,0,1,0,0,1,2,0,1,0,0,0,1,0,1,0,1,3,0,0,1,0,0,0,2,2,1,0,0,0,0,3,3,1,0,2,0,2,0,2,0,5,1,0,0,4,0,0,5,0,1,3,0,1,4,0,0,2,1,2,2,0,0,0,0,1,0,0,0,0,0,1,4,1,0,0,1,0,0,0,5,0,0,0,0,0,0,0,0,1,1,1,0,0,0,1,0,1,1,0,0,2,3,1,0,1,2,1,5,0,0,0,0,0,0,1,6,2,0,2,1,0,3,0,0,2,1,0,3,0,2,3,0,1,0,3,0,0,1,0,2,3,1,1,3,1,1,0,1,1,3,0,0,1,0,1,0,0,3,0,2,0,1,0,0,0,0,1,1,0,0,1,1,2,1,0,0,3,1,0,2,1,0,0,3,0,0,2,0,0,0,1,2,0,2,0,0,2,0,0,0,0,0,0,1,0,0,1,1,1,1,0,1,1,2,0,1,3,1,2,0,0,1,3,0,0,0,0,0,1,2,0,0,1,0,0,1,0,1,0,0,1,0,0,1,0,2,0,0,3,1,0,0,0,1,1,2,2,1,0,0,3,0,0,0,2,0,1,0,0,0,1,2,0,2,6,0,0,0,0,2,0,3,1,0,1,1,3,0,0,2,0,0,2,1,0,0,0,1,0,1,1,5,0,0,1,4,2,0,0,1,2,1,0,2,1,1,2,0,0,0,2,0,2,1,0,0,0,0,2,1,0,1,1,1,3,1,0,2,2,3,0,0,1,0,0,0,1,0,1,4,2,1,3,1,0,1,0,1,0,0,6,1,0,3,0,0,1,2,1,0,0,0,0,0,0,2,3,2,0,1,0,1,1,0,0,1,2,2,2,0,0,0,4,0,0,0,3,1,4,1,2,1,5,4,0,0,0,2,1,1,0,0,0,1,2,5,2,0,0,0,0,0,0,3,1,1,3,1,0,0,0,1,0,1,0,3,0,0,2,1,0,1,0,1,0,0,1,0,0,1,0,0,0,3,2,0,1,3,3,0,1,0,1,0,1,0,0,0,1,0,2,0,4,1,0,2,3,1,1,0,1,0,0,6,0,0,3,2,2,0,0,0,0,0,0,0,0,0,0,0,3,2,0,2,0,0,0,0,0,0,2,3,2,3,3,4,3,4,7,5,3,4,4,6,5,4,5,4,4,4,4,4,5,4,4,4,7,4,5,5,5,7];
    uint8[] engineProp = [1,0,1,4,1,0,0,0,1,0,0,1,0,1,0,0,0,2,1,0,0,1,0,3,0,0,0,0,1,1,0,3,1,1,0,1,0,0,0,0,1,0,3,0,1,0,0,3,0,0,3,1,0,0,0,2,0,1,1,0,1,0,0,0,0,0,0,1,7,0,2,1,3,0,0,5,1,0,0,1,0,0,1,1,1,0,0,0,0,1,0,0,3,1,2,0,0,4,0,1,0,3,2,0,0,0,0,0,1,0,0,0,0,0,0,0,3,2,1,0,0,2,0,2,0,1,0,1,0,1,1,0,5,1,0,3,1,0,0,3,0,1,1,1,1,0,0,6,1,0,1,0,1,1,0,0,1,1,0,1,0,0,0,1,0,2,0,0,0,4,0,2,0,5,5,0,2,6,3,0,0,1,0,0,4,0,1,2,1,1,2,1,0,0,2,7,2,0,2,0,2,0,0,1,0,2,5,0,1,4,0,0,0,0,0,1,1,2,1,0,2,1,0,4,1,4,0,1,2,2,0,0,1,0,0,0,0,1,0,2,1,1,0,4,0,1,1,2,1,1,0,1,0,1,0,1,2,3,0,0,0,0,1,3,1,0,2,0,2,0,3,0,0,1,0,6,0,0,1,0,0,2,1,0,0,1,1,0,1,2,1,1,1,1,0,0,0,0,4,0,2,0,1,1,5,0,1,2,2,3,2,2,0,3,1,5,1,1,0,0,1,1,3,2,0,0,0,0,0,0,0,0,0,0,3,0,0,0,2,0,0,0,0,1,0,1,0,1,0,0,1,0,1,0,1,1,1,2,0,1,0,2,1,0,2,3,0,2,0,0,0,1,0,0,4,1,0,0,0,4,0,0,0,4,4,1,5,0,0,1,2,1,1,1,0,2,1,1,1,3,2,0,2,0,0,1,0,0,0,0,0,1,2,0,3,1,0,3,0,0,0,0,0,1,1,0,0,1,1,1,0,0,0,1,0,2,0,1,2,0,1,1,0,0,0,2,0,1,0,2,1,2,1,0,1,0,3,0,2,0,1,3,1,0,0,0,0,1,3,0,0,1,0,1,4,1,0,1,0,1,1,1,2,0,0,0,3,1,1,2,1,2,0,2,2,4,0,0,2,3,2,0,0,0,0,0,2,1,0,4,1,1,0,0,0,0,0,2,0,0,0,0,1,1,1,0,0,0,1,3,1,0,1,3,1,0,4,2,1,0,0,1,1,0,1,1,0,2,0,2,0,2,2,0,1,0,0,0,0,1,2,0,0,2,2,1,1,1,2,0,5,0,0,0,0,0,1,0,1,0,0,1,2,0,2,4,5,1,0,2,0,0,0,4,0,6,3,2,2,0,1,0,1,4,0,0,1,0,0,0,0,1,1,0,0,1,1,0,0,3,0,0,3,1,1,0,0,2,0,2,1,2,0,3,0,1,0,2,1,0,0,4,3,2,0,1,2,0,1,0,0,4,0,2,0,3,3,0,1,0,0,0,1,1,0,2,0,3,1,0,0,1,0,3,1,4,0,3,0,0,4,1,1,1,0,0,3,0,0,0,0,2,0,0,0,4,1,0,0,0,0,0,2,1,3,0,0,0,0,2,0,0,0,2,1,0,3,0,0,1,0,1,0,2,0,0,0,0,1,0,1,1,1,5,5,2,0,2,0,0,0,0,0,1,3,1,0,1,0,2,0,0,0,2,1,2,1,2,2,0,5,1,1,0,0,3,2,0,1,0,0,1,0,2,1,0,3,0,0,3,2,1,1,1,2,0,0,0,1,0,1,2,0,1,2,0,0,1,0,1,3,2,5,0,0,0,0,0,3,2,0,0,4,1,1,0,0,3,0,2,0,0,0,1,2,2,0,1,2,1,2,0,6,0,1,0,1,2,2,2,0,2,0,0,0,3,4,1,1,1,1,4,0,0,2,2,0,2,2,0,1,0,0,0,1,1,0,3,1,0,3,0,3,2,2,0,1,0,1,5,1,0,0,3,0,0,2,0,0,1,4,1,1,1,0,1,0,0,3,0,0,3,1,0,0,0,1,2,0,0,0,0,0,2,2,0,0,0,0,0,4,5,4,2,0,1,0,1,2,0,2,0,2,0,1,0,0,1,1,2,0,0,0,0,2,1,1,0,2,0,0,0,0,0,0,1,0,1,0,0,1,0,0,3,0,4,1,1,0,0,0,1,3,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,0,0,0,0,0,3,0,0,0,0,0,0,0,3,3,3,6,6,6,7,7];
    uint8[] weaponsProp = [0,0,0,1,1,3,0,0,1,3,1,0,0,0,4,4,2,4,0,0,1,1,4,0,0,5,0,1,0,0,0,3,0,0,1,0,0,1,0,0,2,1,0,0,0,0,1,0,3,0,1,0,1,3,0,0,1,1,2,1,0,2,0,0,0,2,1,0,1,1,1,0,0,2,1,2,3,0,0,2,2,0,0,2,0,0,0,3,0,0,0,0,0,0,1,1,1,0,0,0,1,5,0,1,4,0,1,0,3,0,0,0,0,1,0,1,0,0,0,0,3,1,1,1,0,0,2,0,0,5,0,1,1,1,0,0,1,4,1,0,0,1,0,1,0,0,0,1,1,2,0,2,3,0,3,0,3,1,6,2,1,1,0,0,0,0,1,0,1,0,2,2,0,0,0,1,1,0,0,1,0,0,1,0,0,0,4,5,1,0,1,1,1,0,0,0,2,5,0,1,0,0,1,0,2,0,0,3,0,0,1,2,0,2,0,0,0,0,0,2,3,1,1,1,0,0,5,1,0,0,0,0,1,2,2,1,0,0,3,1,0,0,1,0,1,1,1,0,0,0,0,0,1,0,0,2,0,0,0,0,0,0,0,1,0,0,2,0,0,2,1,2,0,1,0,0,5,1,0,2,2,1,2,0,1,3,0,1,2,0,0,1,0,0,2,2,0,1,0,0,1,4,1,0,1,2,0,0,4,0,0,4,0,1,0,1,0,0,1,2,0,1,0,1,3,0,0,1,0,0,1,1,0,1,0,0,0,0,3,1,1,0,1,4,1,0,3,0,0,1,0,0,2,1,5,1,4,2,2,1,2,0,0,1,1,1,0,0,3,0,0,0,2,1,1,2,0,0,1,4,0,1,1,0,2,0,0,0,0,4,2,0,0,1,0,0,0,4,0,0,0,1,1,4,3,1,0,0,1,0,1,0,0,0,0,1,0,0,1,1,1,0,1,4,0,0,2,0,0,0,7,1,0,3,5,1,4,1,0,0,2,1,1,1,0,0,1,4,0,6,1,1,1,1,0,0,3,0,4,3,4,0,1,0,1,0,0,0,3,2,3,2,2,2,0,0,2,1,0,2,1,1,0,1,0,0,2,1,0,0,4,1,0,2,0,2,2,0,2,4,0,0,0,1,1,1,0,1,0,2,0,0,0,1,0,1,1,0,0,0,4,1,1,0,0,0,1,2,0,4,1,1,0,0,1,0,1,0,0,0,1,0,1,0,0,0,0,2,0,3,0,2,0,1,0,2,2,0,0,0,0,0,2,0,0,1,1,0,0,7,0,1,2,2,0,1,2,2,0,2,0,0,1,1,1,0,2,1,0,1,4,0,0,1,0,0,2,1,2,0,0,4,1,0,0,1,2,1,1,1,0,0,0,1,0,1,0,1,1,0,0,1,1,0,2,0,0,0,0,3,1,2,3,0,0,0,0,1,0,2,1,2,0,2,1,1,0,1,2,0,0,5,2,2,5,0,0,0,0,1,7,1,1,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,2,0,0,1,0,1,1,0,0,2,2,0,1,1,1,0,0,2,1,2,0,1,0,2,0,0,2,3,0,0,2,3,3,0,1,4,0,1,0,0,1,0,0,3,0,4,0,1,0,0,0,0,0,0,1,3,0,4,1,1,0,0,0,0,1,2,1,1,1,1,0,0,2,2,4,1,0,1,0,2,0,0,1,1,0,2,1,4,0,0,0,0,1,0,2,0,0,2,1,0,0,1,1,2,0,2,1,0,5,0,0,0,1,0,0,2,2,1,0,0,1,1,2,0,0,0,2,0,5,0,0,2,5,0,0,0,0,0,7,0,2,0,3,0,0,0,3,2,0,2,0,1,2,0,1,0,0,0,0,0,2,3,1,1,0,0,0,1,0,2,0,1,3,1,0,0,1,0,0,0,0,0,0,0,3,0,2,0,0,0,0,2,2,0,0,1,1,0,0,2,1,0,0,1,0,0,0,0,2,5,0,1,0,2,1,0,0,1,3,0,0,0,0,1,3,0,0,1,0,1,0,0,0,1,0,1,0,0,0,2,0,1,1,0,0,0,2,0,0,0,0,0,1,2,2,1,0,0,0,0,0,3,0,2,0,1,0,1,0,0,1,1,0,0,0,0,0,1,0,2,1,1,0,0,6,0,1,2,3,0,0,1,2,1,0,2,0,1,0,2,0,0,1,2,0,2,0,0,0,0,0,0,0,0,3,1,3,3,1,3,2,3,3,3,3,6,5,6,3,3,3,3,3,3,3,6,3,3,3,3,3,3,6,6];
    uint8[] sektMultiple = [16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,4,4,2,2,4,2,4,2,4,8,2,2,2,4,2,4,4,2,4,4,2,4,8,4,2,2,2,2,2,2,8,8,2,4,8,8,2,2,2,4,4,2,4,2,8,4,4,4,2,8,2,4,2,4,4,8,4,2,2,2,2,2,4,8,2,4,4,2,2,2,2,8,4,4,8,2,2,2,4,8,2,2,2,4,8,4,2,2,2,2,4,2,4,2,4,2,4,2,2,2,4,4,2,2,2,2,2,2,2,4,2,2,2,8,2,2,2,4,4,4,4,4,4,2,2,4,4,8,2,2,2,2,4,2,2,2,2,2,2,2,2,2,8,2,4,2,2,4,2,2,8,2,2,2,2,4,4,2,4,2,2,2,4,2,2,8,8,2,4,2,4,2,2,2,2,4,2,4,4,4,8,2,4,4,2,4,4,4,2,2,2,2,2,4,4,4,2,4,8,2,4,2,4,2,4,2,2,8,4,4,4,2,4,2,8,2,8,2,8,2,4,2,4,4,8,4,2,2,2,2,8,4,4,2,8,2,4,2,2,4,2,8,2,2,2,4,2,4,2,8,2,4,2,2,8,8,4,2,2,2,8,2,8,2,2,2,2,4,8,2,2,2,2,2,2,2,2,8,4,2,2,2,2,2,2,2,2,2,4,2,4,2,2,2,4,2,2,2,8,8,4,2,2,4,2,4,4,2,2,2,2,2,4,2,8,4,2,4,4,2,2,2,2,2,2,2,2,4,2,2,4,4,4,2,2,2,4,2,8,2,2,2,4,2,2,4,2,8,2,4,2,2,2,4,2,8,2,2,2,2,8,2,2,4,2,2,2,2,2,4,2,8,4,2,2,2,4,2,8,4,8,2,2,4,2,2,2,4,2,2,2,2,4,4,8,2,2,2,4,4,2,4,4,2,2,2,2,2,2,8,4,2,4,8,2,2,4,2,4,2,2,2,8,2,2,8,2,2,2,2,2,2,4,2,4,4,4,8,2,2,2,8,2,2,2,2,2,2,2,4,2,2,8,8,2,2,2,2,8,2,4,2,4,4,2,8,2,2,2,2,2,8,2,2,2,4,2,2,2,4,4,2,2,2,8,2,4,4,2,2,8,2,2,2,2,2,2,2,2,4,2,2,2,8,4,2,2,4,2,4,4,8,2,2,4,2,2,2,4,4,4,2,2,4,2,8,2,2,4,2,4,4,2,2,8,2,2,2,8,2,8,2,2,2,2,4,8,2,8,4,4,2,8,2,2,2,4,2,2,2,4,4,2,2,2,2,2,4,2,8,2,4,4,2,2,8,4,2,2,2,2,2,2,2,2,4,2,2,4,2,8,2,2,4,8,4,2,2,2,8,8,2,4,4,4,4,4,4,2,4,2,2,4,2,2,4,8,2,8,2,2,2,2,2,4,2,2,8,2,8,4,2,4,4,2,2,2,4,2,2,2,8,2,8,8,2,2,2,8,2,2,8,2,2,4,2,4,2,8,8,2,8,2,2,4,8,8,8,2,2,2,4,8,2,2,2,2,4,4,2,2,8,2,4,4,4,8,2,2,4,2,4,2,4,2,8,2,2,2,2,2,2,2,2,8,2,2,2,8,2,8,2,2,2,8,8,8,2,8,4,4,2,4,2,2,4,4,8,2,2,4,2,2,8,2,8,2,2,2,4,4,4,2,4,2,8,8,2,2,4,4,2,8,8,2,2,2,8,8,4,4,2,2,4,2,2,4,4,4,2,8,4,2,8,2,2,2,2,4,2,4,4,2,4,4,2,2,2,2,2,2,8,2,2,2,2,2,4,2,4,2,2,2,2,2,2,8,2,8,8,2,8,2,2,2,8,4,2,2,4,8,2,2,8,2,2,4,2,2,2,2,2,4,8,2,2,4,2,4,8,8,4,4,2,2,2,2,4,2,2,2,2,2,2,2,4,2,2,8,2,2,2,2,4,2,4,2,4,4,2,2,2,2,2,2,4,2,2,2,4,2,2,2,2,2,4,2,2,2,2,2,2,4,2,8,2,2,2,8,4,2,2,4,2,2,4,2,2,2,8,2,2,4,4,2,2,2,2,2,2,2,4,2,2,2,4,2,4,2,2,2,4,4,4,2,2,2,2,2,2,4,2,4,4,2,2,2,4,2,2,4,4,4,4,4,2,2,2,2,2];


    function combatOP(
        uint256 _pilotLevel, 
        uint256 _sifGattaca, 
        uint256 _mhrudvogThrot, 
        uint256 _drebentraakht
    ) public view returns (uint256) {
        return (((
            (_sifGattaca * sifGattacaOP) +
            (_mhrudvogThrot * mhrudvogThrotOP) +
            (_drebentraakht * drebentraakhtOP)) 
            * (100 + _pilotLevel)) 
            / 100
        );
    }

    function combatDP(
        uint256 _citadelId, 
        uint256[3] memory _pilotIds, 
        uint256 _sifGattaca, 
        uint256 _mhrudvogThrot, 
        uint256 _drebentraakht
    ) public view returns (uint256) {
        uint256 swarmMultiple = 0;
        uint256 siegeMultiple = 0;
        uint256 multiple = _pilotIds.length;


        multiple += calculateBaseCitadelMultiple(weaponsProp[_citadelId]);
        multiple += calculateBaseCitadelMultiple(shieldProp[_citadelId]);

        (swarmMultiple, siegeMultiple) = calculateUniqueBonus(
            weaponsProp[_citadelId], 
            engineProp[_citadelId], 
            shieldProp[_citadelId]
        );

        uint256 dp = ((
            (
                ((_sifGattaca * sifGattacaDP) * (100 + swarmMultiple) / 100) +
                (_mhrudvogThrot * mhrudvogThrotDP) +
                ((_drebentraakht * drebentraakhtDP) * (100 + siegeMultiple) / 100)
            ) 
            * (100 + multiple)) / 100
        );
        return dp;
    }

    function calculateBaseCitadelMultiple(uint8 index) internal pure returns (uint256) {
        if (index == 0) {
            return 10;
        } else if (index == 1) {
            return 11;
        } else if (index == 2) {
            return 12;
        } else if (index == 3) {
            return 15;
        } else if (index == 4) {
            return 17;
        } else if (index == 5) {
            return 20;
        } else if (index == 6) {
            return 25;
        } else {
            return 35;
        }
    }

    function calculateUniqueBonus(
        uint8 weapon, 
        uint8 engine, 
        uint8 shield
    ) internal pure returns (uint256, uint256) {
        uint256 swarmMultiple = 0;
        uint256 siegeMultiple = 0;
        if (weapon == 0) {
            swarmMultiple += 5;
        } else if (weapon == 1) {
            siegeMultiple += 5;
        } else if (weapon == 2) {
            swarmMultiple += 6;
        } else if (weapon == 3) {
            swarmMultiple += 7;
        } else if (weapon == 4) {
            siegeMultiple += 7;
        } else if (weapon == 6) {
            siegeMultiple += 10;
        }

        if (shield == 0) {
            siegeMultiple += 5;
        } else if (shield == 1) {
            siegeMultiple += 10;
        } else if (shield == 2) {
            swarmMultiple += 2;
            siegeMultiple += 2;
        } else if (shield == 3) {
            siegeMultiple += 15;
        } else if (shield == 4) {
            swarmMultiple += 5;
            siegeMultiple += 5;
        } else if (shield == 5) {
            swarmMultiple += 15;
        } else {
            swarmMultiple += 25;
        }

        if (engine == 0) {
            swarmMultiple += 1;
            siegeMultiple += 1;
        } else if (engine == 1) {
            swarmMultiple += 2;
            siegeMultiple += 2;
        } else if (engine == 5) {
            swarmMultiple += 5;
            siegeMultiple += 5;
        }
        
        return (swarmMultiple, siegeMultiple);
    }

    function calculateGridTraversal(uint256 gridA, uint256 gridB) public view returns (uint256) {

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
        uint256 traversalTime = totalMoves * gridTraversalTime;

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

        /*
        fleetTracker used to reduce local variables
        [0] uint256 _offensiveSifGattaca, 
        [1] uint256 _offensiveMhrudvogThrot, 
        [2] uint256 _offensiveDrebentraakht,
        [3] uint256 _defensiveSifGattaca, 
        [4] uint256 _defensiveMhrudvogThrot, 
        [5] uint256 _defensiveDrebentraakht
    */
    function calculateDestroyedFleet(            
        uint256 _offensivePilotId,
        uint256[3] memory _defensivePilotIds,
        uint256[6] memory _fleetTracker,
        uint256 _defensiveCitadelId
    ) public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        uint256 op = combatOP(
            _offensivePilotId, 
            _fleetTracker[0], 
            _fleetTracker[1], 
            _fleetTracker[2]
        );

        uint256 dp = combatDP(
            _defensiveCitadelId, 
            _defensivePilotIds, 
            _fleetTracker[3], 
            _fleetTracker[4], 
            _fleetTracker[5]
        );

        if (dp > 0) {
            (op, dp) = _adjustedOPDP(op, dp);
        }

        // offensive fleet destroyed & reuse var
       _fleetTracker[0] = (
            _fleetTracker[0] * dp * 50
        ) / ((op + dp) * 100);

        _fleetTracker[1] = (
            _fleetTracker[1] * dp * 50
        ) / ((op + dp) * 100);

        _fleetTracker[2] = (
            _fleetTracker[2] * dp * 50
        ) / ((op + dp) * 100);

        // defensive fleet destroyed & reuse var
        _fleetTracker[3] = (
            _fleetTracker[3] * op * 50
        ) / ((op + dp) * 100);
        
        _fleetTracker[4] = (
            _fleetTracker[4] * op * 50
        ) / ((op + dp) * 100);
        
        _fleetTracker[5] = (
            _fleetTracker[5] * op * 50
        ) / ((op + dp) * 100);

        return (
            _fleetTracker[0],
            _fleetTracker[1],
            _fleetTracker[2],
            _fleetTracker[3],
            _fleetTracker[4],
            _fleetTracker[5],
            (
                op
            ) / (op + dp) * 100
        );
    }

    function _adjustedOPDP(uint256 op, uint256 dp) internal pure returns (uint256, uint256) {
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

        return (
            (op * op) / (op + (2 * dp) / exponent),
            (dp * dp) / (dp + (2 * op) / exponent)
        );
    }

    function getCitadelFleetCount(uint256 _citadelId) public view returns (
        uint256, uint256, uint256
    ) {
        uint256[3] memory fleetArr;
        fleetArr[0] = fleet[_citadelId].stationedFleet.sifGattaca;
        fleetArr[1] = fleet[_citadelId].stationedFleet.mhrudvogThrot;
        fleetArr[2] = fleet[_citadelId].stationedFleet.drebentraakht;

        (
            uint256 trainedSifGattaca, 
            uint256 trainedMhrudvogThrot, 
            uint256 trainedDrebentraakht
        ) = calculateTrainedFleet(
            fleetArr, 
            fleet[_citadelId].trainingStarted, 
            fleet[_citadelId].trainingDone
        );

        return (
            fleetArr[0] + trainedSifGattaca, 
            fleetArr[1] + trainedMhrudvogThrot, 
            fleetArr[2] + trainedDrebentraakht
        );
    }

    function calculateTrainedFleet(
        uint256[3] memory _fleet,
        uint256 _timeTrainingStarted,
        uint256 _timeTrainingDone
    ) public view returns (uint256, uint256, uint256) {
        if(_timeTrainingDone <= block.timestamp) {
            return(
                _fleet[0], 
                _fleet[1], 
                _fleet[2]
            );
        }

        uint256 sifGattacaTrained = 0;
        uint256 mhrudvogThrotTrained = 0;
        uint256 drebentraakhtTrained = 0;
        uint256 timeHolder = _timeTrainingStarted;

        sifGattacaTrained = (block.timestamp - timeHolder) / sifGattacaTrainingTime > _fleet[0] 
            ? _fleet[0]
            : (block.timestamp - timeHolder) / sifGattacaTrainingTime;
        
        if(sifGattacaTrained == _fleet[0]) {
            timeHolder += (sifGattacaTrainingTime * sifGattacaTrained);
            mhrudvogThrotTrained = (block.timestamp - timeHolder) / mhrudvogThrotTrainingTime > _fleet[1]
                ? _fleet[1]
                : (block.timestamp - timeHolder) / mhrudvogThrotTrainingTime;
        }

        if(mhrudvogThrotTrained == _fleet[1]) {
            timeHolder += (mhrudvogThrotTrainingTime * mhrudvogThrotTrained);
            drebentraakhtTrained = (block.timestamp - timeHolder) / drebentraakhtTrainingTime > _fleet[2]
                ? _fleet[2]
                : (block.timestamp - timeHolder) / drebentraakhtTrainingTime;
        }
        
        return (sifGattacaTrained, mhrudvogThrotTrained, drebentraakhtTrained);
    }

    function calculateMiningOutput(
        uint256 _citadelId, 
        uint256 _nodeId, 
        uint256 lastClaimTime
    ) public pure returns (uint256) {
        // uint256 baseMiningRatePerHour = drakma.balanceOf(treasuryAddress) / 100000000;
        // uint256 miningMultiple = calculateMiningMultiple(_citadelId, engineProp[_citadelId], shieldProp[_citadelId]);
        // return (
        //     ((block.timestamp - lastClaimTime) *
        //         ((baseMiningRatePerHour * ((100 + getGridMultiple(_gridId)) / 100)) / 3600) *
        //         ((100 + miningMultiple) / 100))
        // );

        // TODO revisit
        return 1;
    }

    function _calculateMiningMultiple(
        uint256 _citadelId,
        uint8 _engine,
        uint8 _shield
    ) internal view returns (uint256) {
        uint256 multiple = 1;

        if (_shield == 6) {
            multiple += 5;
        }

        if (_engine == 3) {
            multiple += 1;
        } else if (_engine == 7) {
            multiple += 5;
        }

        CitadelNode memory citadel = citadelNode[_citadelId];

        uint8 orbit = citadel.orbitHeight;

        uint256 orbitMultiplier;
        if (orbit == 1) {
            orbitMultiplier = 25;
        } else if (orbit == 2) {
            orbitMultiplier = 20;
        } else if (orbit == 3) {
            orbitMultiplier = 15;
        } else if (orbit == 4) {
            orbitMultiplier = 10;
        } else if (orbit == 5) {
            orbitMultiplier = 5;
        }

        multiple += orbitMultiplier;

        // Factor in distance from pole
        uint256 gridId = getGridFromNode(citadel.nodeId);
        uint256 poleMultiplier;

        if ((gridId >= 1 && gridId <= 16) || (gridId >= 240 && gridId <= 256)) {
            poleMultiplier = 5;
        } else if ((gridId >= 17 && gridId <= 32) || (gridId >= 224 && gridId <= 239)) {
            poleMultiplier = 4;
        } else if ((gridId >= 33 && gridId <= 48) || (gridId >= 208 && gridId <= 223)) {
            poleMultiplier = 3;
        } else if ((gridId >= 49 && gridId <= 64) || (gridId >= 192 && gridId <= 207)) {
            poleMultiplier = 2;
        } else {
            poleMultiplier = 1;
        }

        multiple += poleMultiplier;

        return multiple;
    }

}