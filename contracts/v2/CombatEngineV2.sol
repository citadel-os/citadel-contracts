// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


interface IPILOT {
    function getOnchainPILOT(uint256 tokenId) external view returns (bool, uint8);
}

contract CombatEngineV2 is Ownable {
    using SafeERC20 for IERC20;

    // imports
    IERC20 public immutable drakma;
    IPILOT public immutable pilotCollection;

    // citadel props
    uint8[] shieldProp = [0,1,1,1,0,0,1,3,0,1,2,0,1,0,0,0,0,0,0,1,2,0,0,0,0,1,1,1,0,0,3,0,0,1,0,1,0,1,0,0,1,0,1,0,0,0,3,2,2,2,1,2,1,3,0,0,2,0,2,0,3,0,0,0,2,0,0,2,3,0,1,1,0,1,0,0,1,1,1,0,0,0,0,0,0,2,0,0,0,0,0,0,3,0,0,2,0,0,1,0,1,0,2,2,1,2,1,0,1,1,0,0,0,2,0,0,0,1,0,1,1,1,0,0,1,0,0,0,0,1,0,0,1,0,2,0,6,4,0,0,2,1,4,2,0,0,0,1,0,2,0,0,0,0,2,0,3,1,0,0,1,0,0,2,1,0,0,0,0,0,1,0,1,0,0,3,1,0,2,0,1,0,0,0,2,0,2,4,0,0,0,0,1,0,0,0,3,0,1,3,0,1,0,1,1,2,0,0,1,1,1,0,2,0,0,0,0,0,2,0,1,0,2,3,1,2,1,0,1,0,2,0,1,1,1,0,1,0,0,1,1,0,0,0,2,2,3,1,1,3,0,0,0,0,2,0,1,0,1,1,1,1,3,0,1,1,0,6,2,0,3,0,1,1,1,1,1,0,2,2,2,1,0,1,0,0,0,2,0,0,0,1,0,3,0,3,2,2,0,0,0,0,0,1,0,0,0,0,2,1,0,1,0,1,0,1,4,0,0,1,0,0,0,1,2,0,0,2,2,1,1,2,0,1,2,3,0,4,1,0,0,1,1,0,0,0,1,0,0,1,1,0,0,1,2,0,0,2,0,1,1,0,3,0,0,3,0,1,0,0,0,2,0,0,0,4,1,1,1,4,0,0,0,2,1,0,0,0,0,0,0,1,0,3,0,0,0,1,0,1,0,0,6,1,2,0,0,2,0,4,5,1,2,0,0,0,1,2,1,1,0,1,1,0,0,0,0,1,1,0,0,0,0,0,1,1,0,1,1,2,2,2,1,1,4,1,0,2,0,2,1,0,0,0,0,0,0,1,0,0,0,0,3,0,0,0,7,1,2,2,0,1,0,5,0,0,0,1,1,2,0,0,0,1,0,0,1,2,0,1,0,0,0,1,0,1,0,1,3,0,0,1,0,0,0,2,2,1,0,0,0,0,3,3,1,0,2,0,2,0,2,0,5,1,0,0,4,0,0,5,0,1,3,0,1,4,0,0,2,1,2,2,0,0,0,0,1,0,0,0,0,0,1,4,1,0,0,1,0,0,0,5,0,0,0,0,0,0,0,0,1,1,1,0,0,0,1,0,1,1,0,0,2,3,1,0,1,2,1,5,0,0,0,0,0,0,1,6,2,0,2,1,0,3,0,0,2,1,0,3,0,2,3,0,1,0,3,0,0,1,0,2,3,1,1,3,1,1,0,1,1,3,0,0,1,0,1,0,0,3,0,2,0,1,0,0,0,0,1,1,0,0,1,1,2,1,0,0,3,1,0,2,1,0,0,3,0,0,2,0,0,0,1,2,0,2,0,0,2,0,0,0,0,0,0,1,0,0,1,1,1,1,0,1,1,2,0,1,3,1,2,0,0,1,3,0,0,0,0,0,1,2,0,0,1,0,0,1,0,1,0,0,1,0,0,1,0,2,0,0,3,1,0,0,0,1,1,2,2,1,0,0,3,0,0,0,2,0,1,0,0,0,1,2,0,2,6,0,0,0,0,2,0,3,1,0,1,1,3,0,0,2,0,0,2,1,0,0,0,1,0,1,1,5,0,0,1,4,2,0,0,1,2,1,0,2,1,1,2,0,0,0,2,0,2,1,0,0,0,0,2,1,0,1,1,1,3,1,0,2,2,3,0,0,1,0,0,0,1,0,1,4,2,1,3,1,0,1,0,1,0,0,6,1,0,3,0,0,1,2,1,0,0,0,0,0,0,2,3,2,0,1,0,1,1,0,0,1,2,2,2,0,0,0,4,0,0,0,3,1,4,1,2,1,5,4,0,0,0,2,1,1,0,0,0,1,2,5,2,0,0,0,0,0,0,3,1,1,3,1,0,0,0,1,0,1,0,3,0,0,2,1,0,1,0,1,0,0,1,0,0,1,0,0,0,3,2,0,1,3,3,0,1,0,1,0,1,0,0,0,1,0,2,0,4,1,0,2,3,1,1,0,1,0,0,6,0,0,3,2,2,0,0,0,0,0,0,0,0,0,0,0,3,2,0,2,0,0,0,0,0,0,2,3,2,3,3,4,3,4,7,5,3,4,4,6,5,4,5,4,4,4,4,4,5,4,4,4,7,4,5,5,5,7];
    uint8[] engineProp = [1,0,1,4,1,0,0,0,1,0,0,1,0,1,0,0,0,2,1,0,0,1,0,3,0,0,0,0,1,1,0,3,1,1,0,1,0,0,0,0,1,0,3,0,1,0,0,3,0,0,3,1,0,0,0,2,0,1,1,0,1,0,0,0,0,0,0,1,7,0,2,1,3,0,0,5,1,0,0,1,0,0,1,1,1,0,0,0,0,1,0,0,3,1,2,0,0,4,0,1,0,3,2,0,0,0,0,0,1,0,0,0,0,0,0,0,3,2,1,0,0,2,0,2,0,1,0,1,0,1,1,0,5,1,0,3,1,0,0,3,0,1,1,1,1,0,0,6,1,0,1,0,1,1,0,0,1,1,0,1,0,0,0,1,0,2,0,0,0,4,0,2,0,5,5,0,2,6,3,0,0,1,0,0,4,0,1,2,1,1,2,1,0,0,2,7,2,0,2,0,2,0,0,1,0,2,5,0,1,4,0,0,0,0,0,1,1,2,1,0,2,1,0,4,1,4,0,1,2,2,0,0,1,0,0,0,0,1,0,2,1,1,0,4,0,1,1,2,1,1,0,1,0,1,0,1,2,3,0,0,0,0,1,3,1,0,2,0,2,0,3,0,0,1,0,6,0,0,1,0,0,2,1,0,0,1,1,0,1,2,1,1,1,1,0,0,0,0,4,0,2,0,1,1,5,0,1,2,2,3,2,2,0,3,1,5,1,1,0,0,1,1,3,2,0,0,0,0,0,0,0,0,0,0,3,0,0,0,2,0,0,0,0,1,0,1,0,1,0,0,1,0,1,0,1,1,1,2,0,1,0,2,1,0,2,3,0,2,0,0,0,1,0,0,4,1,0,0,0,4,0,0,0,4,4,1,5,0,0,1,2,1,1,1,0,2,1,1,1,3,2,0,2,0,0,1,0,0,0,0,0,1,2,0,3,1,0,3,0,0,0,0,0,1,1,0,0,1,1,1,0,0,0,1,0,2,0,1,2,0,1,1,0,0,0,2,0,1,0,2,1,2,1,0,1,0,3,0,2,0,1,3,1,0,0,0,0,1,3,0,0,1,0,1,4,1,0,1,0,1,1,1,2,0,0,0,3,1,1,2,1,2,0,2,2,4,0,0,2,3,2,0,0,0,0,0,2,1,0,4,1,1,0,0,0,0,0,2,0,0,0,0,1,1,1,0,0,0,1,3,1,0,1,3,1,0,4,2,1,0,0,1,1,0,1,1,0,2,0,2,0,2,2,0,1,0,0,0,0,1,2,0,0,2,2,1,1,1,2,0,5,0,0,0,0,0,1,0,1,0,0,1,2,0,2,4,5,1,0,2,0,0,0,4,0,6,3,2,2,0,1,0,1,4,0,0,1,0,0,0,0,1,1,0,0,1,1,0,0,3,0,0,3,1,1,0,0,2,0,2,1,2,0,3,0,1,0,2,1,0,0,4,3,2,0,1,2,0,1,0,0,4,0,2,0,3,3,0,1,0,0,0,1,1,0,2,0,3,1,0,0,1,0,3,1,4,0,3,0,0,4,1,1,1,0,0,3,0,0,0,0,2,0,0,0,4,1,0,0,0,0,0,2,1,3,0,0,0,0,2,0,0,0,2,1,0,3,0,0,1,0,1,0,2,0,0,0,0,1,0,1,1,1,5,5,2,0,2,0,0,0,0,0,1,3,1,0,1,0,2,0,0,0,2,1,2,1,2,2,0,5,1,1,0,0,3,2,0,1,0,0,1,0,2,1,0,3,0,0,3,2,1,1,1,2,0,0,0,1,0,1,2,0,1,2,0,0,1,0,1,3,2,5,0,0,0,0,0,3,2,0,0,4,1,1,0,0,3,0,2,0,0,0,1,2,2,0,1,2,1,2,0,6,0,1,0,1,2,2,2,0,2,0,0,0,3,4,1,1,1,1,4,0,0,2,2,0,2,2,0,1,0,0,0,1,1,0,3,1,0,3,0,3,2,2,0,1,0,1,5,1,0,0,3,0,0,2,0,0,1,4,1,1,1,0,1,0,0,3,0,0,3,1,0,0,0,1,2,0,0,0,0,0,2,2,0,0,0,0,0,4,5,4,2,0,1,0,1,2,0,2,0,2,0,1,0,0,1,1,2,0,0,0,0,2,1,1,0,2,0,0,0,0,0,0,1,0,1,0,0,1,0,0,3,0,4,1,1,0,0,0,1,3,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,0,0,0,0,0,3,0,0,0,0,0,0,0,3,3,3,6,6,6,7,7];
    uint8[] weaponsProp = [0,0,0,1,1,3,0,0,1,3,1,0,0,0,4,4,2,4,0,0,1,1,4,0,0,5,0,1,0,0,0,3,0,0,1,0,0,1,0,0,2,1,0,0,0,0,1,0,3,0,1,0,1,3,0,0,1,1,2,1,0,2,0,0,0,2,1,0,1,1,1,0,0,2,1,2,3,0,0,2,2,0,0,2,0,0,0,3,0,0,0,0,0,0,1,1,1,0,0,0,1,5,0,1,4,0,1,0,3,0,0,0,0,1,0,1,0,0,0,0,3,1,1,1,0,0,2,0,0,5,0,1,1,1,0,0,1,4,1,0,0,1,0,1,0,0,0,1,1,2,0,2,3,0,3,0,3,1,6,2,1,1,0,0,0,0,1,0,1,0,2,2,0,0,0,1,1,0,0,1,0,0,1,0,0,0,4,5,1,0,1,1,1,0,0,0,2,5,0,1,0,0,1,0,2,0,0,3,0,0,1,2,0,2,0,0,0,0,0,2,3,1,1,1,0,0,5,1,0,0,0,0,1,2,2,1,0,0,3,1,0,0,1,0,1,1,1,0,0,0,0,0,1,0,0,2,0,0,0,0,0,0,0,1,0,0,2,0,0,2,1,2,0,1,0,0,5,1,0,2,2,1,2,0,1,3,0,1,2,0,0,1,0,0,2,2,0,1,0,0,1,4,1,0,1,2,0,0,4,0,0,4,0,1,0,1,0,0,1,2,0,1,0,1,3,0,0,1,0,0,1,1,0,1,0,0,0,0,3,1,1,0,1,4,1,0,3,0,0,1,0,0,2,1,5,1,4,2,2,1,2,0,0,1,1,1,0,0,3,0,0,0,2,1,1,2,0,0,1,4,0,1,1,0,2,0,0,0,0,4,2,0,0,1,0,0,0,4,0,0,0,1,1,4,3,1,0,0,1,0,1,0,0,0,0,1,0,0,1,1,1,0,1,4,0,0,2,0,0,0,7,1,0,3,5,1,4,1,0,0,2,1,1,1,0,0,1,4,0,6,1,1,1,1,0,0,3,0,4,3,4,0,1,0,1,0,0,0,3,2,3,2,2,2,0,0,2,1,0,2,1,1,0,1,0,0,2,1,0,0,4,1,0,2,0,2,2,0,2,4,0,0,0,1,1,1,0,1,0,2,0,0,0,1,0,1,1,0,0,0,4,1,1,0,0,0,1,2,0,4,1,1,0,0,1,0,1,0,0,0,1,0,1,0,0,0,0,2,0,3,0,2,0,1,0,2,2,0,0,0,0,0,2,0,0,1,1,0,0,7,0,1,2,2,0,1,2,2,0,2,0,0,1,1,1,0,2,1,0,1,4,0,0,1,0,0,2,1,2,0,0,4,1,0,0,1,2,1,1,1,0,0,0,1,0,1,0,1,1,0,0,1,1,0,2,0,0,0,0,3,1,2,3,0,0,0,0,1,0,2,1,2,0,2,1,1,0,1,2,0,0,5,2,2,5,0,0,0,0,1,7,1,1,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,2,0,0,1,0,1,1,0,0,2,2,0,1,1,1,0,0,2,1,2,0,1,0,2,0,0,2,3,0,0,2,3,3,0,1,4,0,1,0,0,1,0,0,3,0,4,0,1,0,0,0,0,0,0,1,3,0,4,1,1,0,0,0,0,1,2,1,1,1,1,0,0,2,2,4,1,0,1,0,2,0,0,1,1,0,2,1,4,0,0,0,0,1,0,2,0,0,2,1,0,0,1,1,2,0,2,1,0,5,0,0,0,1,0,0,2,2,1,0,0,1,1,2,0,0,0,2,0,5,0,0,2,5,0,0,0,0,0,7,0,2,0,3,0,0,0,3,2,0,2,0,1,2,0,1,0,0,0,0,0,2,3,1,1,0,0,0,1,0,2,0,1,3,1,0,0,1,0,0,0,0,0,0,0,3,0,2,0,0,0,0,2,2,0,0,1,1,0,0,2,1,0,0,1,0,0,0,0,2,5,0,1,0,2,1,0,0,1,3,0,0,0,0,1,3,0,0,1,0,1,0,0,0,1,0,1,0,0,0,2,0,1,1,0,0,0,2,0,0,0,0,0,1,2,2,1,0,0,0,0,0,3,0,2,0,1,0,1,0,0,1,1,0,0,0,0,0,1,0,2,1,1,0,0,6,0,1,2,3,0,0,1,2,1,0,2,0,1,0,2,0,0,1,2,0,2,0,0,0,0,0,0,0,0,3,1,3,3,1,3,2,3,3,3,3,6,5,6,3,3,3,3,3,3,3,6,3,3,3,3,3,3,6,6];
    uint8[] sektMultiple = [16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,4,4,2,2,4,2,4,2,4,8,2,2,2,4,2,4,4,2,4,4,2,4,8,4,2,2,2,2,2,2,8,8,2,4,8,8,2,2,2,4,4,2,4,2,8,4,4,4,2,8,2,4,2,4,4,8,4,2,2,2,2,2,4,8,2,4,4,2,2,2,2,8,4,4,8,2,2,2,4,8,2,2,2,4,8,4,2,2,2,2,4,2,4,2,4,2,4,2,2,2,4,4,2,2,2,2,2,2,2,4,2,2,2,8,2,2,2,4,4,4,4,4,4,2,2,4,4,8,2,2,2,2,4,2,2,2,2,2,2,2,2,2,8,2,4,2,2,4,2,2,8,2,2,2,2,4,4,2,4,2,2,2,4,2,2,8,8,2,4,2,4,2,2,2,2,4,2,4,4,4,8,2,4,4,2,4,4,4,2,2,2,2,2,4,4,4,2,4,8,2,4,2,4,2,4,2,2,8,4,4,4,2,4,2,8,2,8,2,8,2,4,2,4,4,8,4,2,2,2,2,8,4,4,2,8,2,4,2,2,4,2,8,2,2,2,4,2,4,2,8,2,4,2,2,8,8,4,2,2,2,8,2,8,2,2,2,2,4,8,2,2,2,2,2,2,2,2,8,4,2,2,2,2,2,2,2,2,2,4,2,4,2,2,2,4,2,2,2,8,8,4,2,2,4,2,4,4,2,2,2,2,2,4,2,8,4,2,4,4,2,2,2,2,2,2,2,2,4,2,2,4,4,4,2,2,2,4,2,8,2,2,2,4,2,2,4,2,8,2,4,2,2,2,4,2,8,2,2,2,2,8,2,2,4,2,2,2,2,2,4,2,8,4,2,2,2,4,2,8,4,8,2,2,4,2,2,2,4,2,2,2,2,4,4,8,2,2,2,4,4,2,4,4,2,2,2,2,2,2,8,4,2,4,8,2,2,4,2,4,2,2,2,8,2,2,8,2,2,2,2,2,2,4,2,4,4,4,8,2,2,2,8,2,2,2,2,2,2,2,4,2,2,8,8,2,2,2,2,8,2,4,2,4,4,2,8,2,2,2,2,2,8,2,2,2,4,2,2,2,4,4,2,2,2,8,2,4,4,2,2,8,2,2,2,2,2,2,2,2,4,2,2,2,8,4,2,2,4,2,4,4,8,2,2,4,2,2,2,4,4,4,2,2,4,2,8,2,2,4,2,4,4,2,2,8,2,2,2,8,2,8,2,2,2,2,4,8,2,8,4,4,2,8,2,2,2,4,2,2,2,4,4,2,2,2,2,2,4,2,8,2,4,4,2,2,8,4,2,2,2,2,2,2,2,2,4,2,2,4,2,8,2,2,4,8,4,2,2,2,8,8,2,4,4,4,4,4,4,2,4,2,2,4,2,2,4,8,2,8,2,2,2,2,2,4,2,2,8,2,8,4,2,4,4,2,2,2,4,2,2,2,8,2,8,8,2,2,2,8,2,2,8,2,2,4,2,4,2,8,8,2,8,2,2,4,8,8,8,2,2,2,4,8,2,2,2,2,4,4,2,2,8,2,4,4,4,8,2,2,4,2,4,2,4,2,8,2,2,2,2,2,2,2,2,8,2,2,2,8,2,8,2,2,2,8,8,8,2,8,4,4,2,4,2,2,4,4,8,2,2,4,2,2,8,2,8,2,2,2,4,4,4,2,4,2,8,8,2,2,4,4,2,8,8,2,2,2,8,8,4,4,2,2,4,2,2,4,4,4,2,8,4,2,8,2,2,2,2,4,2,4,4,2,4,4,2,2,2,2,2,2,8,2,2,2,2,2,4,2,4,2,2,2,2,2,2,8,2,8,8,2,8,2,2,2,8,4,2,2,4,8,2,2,8,2,2,4,2,2,2,2,2,4,8,2,2,4,2,4,8,8,4,4,2,2,2,2,4,2,2,2,2,2,2,2,4,2,2,8,2,2,2,2,4,2,4,2,4,4,2,2,2,2,2,2,4,2,2,2,4,2,2,2,2,2,4,2,2,2,2,2,2,4,2,8,2,2,2,8,4,2,2,4,2,2,4,2,2,2,8,2,2,4,4,2,2,2,2,2,2,2,4,2,2,2,4,2,4,2,2,2,4,4,4,2,2,2,2,2,2,4,2,4,4,2,2,2,4,2,2,4,4,4,4,4,2,2,2,2,2];

    uint8 pilotMultiple = 20;
    uint8 levelMultiple = 2;
    uint256 sifGattacaOP = 10;
    uint256 mhrudvogThrotOP = 5;
    uint256 drebentraakhtOP = 500;
    uint256 sifGattacaDP = 5;
    uint256 mhrudvogThrotDP = 40;
    uint256 drebentraakhtDP = 250;
    uint256 public subgridDistortion = 1;
    uint256 public gridTraversalTime = 30 minutes;
    uint256 sifGattacaPrice = 20000000000000000000;
    uint256 mhrudvogThrotPrice = 40000000000000000000;
    uint256 drebentraakhtPrice = 800000000000000000000;
    uint256 sifGattacaTrainingTime = 5 minutes;
    uint256 mhrudvogThrotTrainingTime = 15 minutes;
    uint256 drebentraakhtTrainingTime = 1 hours;
    address treasuryAddress;

    mapping(uint256 => uint256) gridMultiple; // index is _gridId
    
    constructor(IPILOT _pilotCollection, IERC20 _drakma) {
        pilotCollection = _pilotCollection;
        drakma = _drakma;
    }

    function combatOP(
        uint256 _pilotId, 
        uint256 _sifGattaca, 
        uint256 _mhrudvogThrot, 
        uint256 _drebentraakht
    ) public view returns (uint256) {
        uint256 multiple = 0;
        (,uint8 level) = pilotCollection.getOnchainPILOT(_pilotId);
        multiple += pilotMultiple + (level * levelMultiple);

        return (((
            (_sifGattaca * sifGattacaOP) +
            (_mhrudvogThrot * mhrudvogThrotOP) +
            (_drebentraakht * drebentraakhtOP)) 
            * (100 + multiple)) 
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
        uint256 multiple = 0;
        for (uint256 i; i < _pilotIds.length; ++i) {
            if (i != 0) {
                (,uint8 level) = pilotCollection.getOnchainPILOT(_pilotIds[i]);
                multiple += pilotMultiple + (level * levelMultiple);
            }
        }

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
            (op, dp) = adjustedOPDP(op, dp);
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

    function adjustedOPDP(uint256 op, uint256 dp) public view returns (uint256, uint256) {
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

    function calculateMiningOutput(
        uint256 _citadelId, 
        uint256 _gridId, 
        uint256 lastClaimTime
    ) public view returns (uint256) {
        uint256 baseMiningRatePerHour = drakma.balanceOf(treasuryAddress) / 100000000;
        uint256 miningMultiple = calculateMiningMultiple(_citadelId, engineProp[_citadelId], shieldProp[_citadelId]);
        return (
            ((block.timestamp - lastClaimTime) *
                ((baseMiningRatePerHour * ((100 + getGridMultiple(_gridId)) / 100)) / 3600) *
                ((100 + miningMultiple) / 100))
        );
    }

    function isTreasuryMaxed(uint256 treasuryBal) public view returns (bool) {
        uint256 max = drakma.balanceOf(treasuryAddress) / 16;
        if (treasuryBal > max) {
            return true;
        }
        return false;
    }

    function calculateBaseCitadelMultiple(uint8 index) internal view returns (uint256) {
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
    ) internal view returns (uint256, uint256) {
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

    function calculateMiningMultiple(uint256 _citadelId, uint8 _engine, uint8 _shield) internal view returns (uint256) {
        uint256 multiple = sektMultiple[_citadelId];
        if (_shield == 6) {
            multiple += 5;
        }

        if (_engine == 3) {
            multiple += 1;
        } else if (_engine == 7) {
            multiple += 5;
        }

        return multiple;
    }

    function getGridMultiple(uint256 _gridId) public view returns (uint256) {
        return gridMultiple[_gridId];
    }

    function calculateGridDistance(uint256 _a, uint256 _b) public view returns (uint256) {

        return Math.sqrt(uint256((int(_a % 32) - int(_b % 32))**2 + (int(_a / 32) - int(_b / 32))**2));
    }

    function calculateGridTraversal(
        uint256 _gridA, 
        uint256 _gridB
    ) public view returns (uint256, uint256) {
        uint256 timeRaidHits = block.timestamp;
        uint256 gridDistance = calculateGridDistance(_gridA, _gridB);
        
        if (gridDistance > subgridDistortion) {
            timeRaidHits += (gridDistance * gridTraversalTime);
        }

        return (timeRaidHits, gridDistance);
    }

    function calculateTrainingCost(
        uint256 _sifGattaca, 
        uint256 _mhrudvogThrot, 
        uint256 _drebentraakht
    ) public view returns (uint256) {
        uint256 trainingCost = 0;
        trainingCost += _sifGattaca * sifGattacaPrice;
        trainingCost += _mhrudvogThrot * mhrudvogThrotPrice;
        trainingCost += _drebentraakht * drebentraakhtPrice;

        return trainingCost;
    }

    function calculateTrainingTime(
        uint256 _sifGattaca, 
        uint256 _mhrudvogThrot, 
        uint256 _drebentraakht
    ) public view returns (uint256) {
        uint256 timeTrainingDone = block.timestamp;
        timeTrainingDone = _sifGattaca * sifGattacaTrainingTime;
        timeTrainingDone += _mhrudvogThrot * mhrudvogThrotTrainingTime;
        timeTrainingDone += _drebentraakht * drebentraakhtTrainingTime;

        return timeTrainingDone;
    }

    function calculateTrainedFleet(
        uint256[3] calldata _fleet,
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

    function updateGameParams(
        uint256 _subgridDistortion,
        uint256 _gridTraversalTime,
        address _treasuryAddress

    ) external onlyOwner {
        subgridDistortion = _subgridDistortion;
        gridTraversalTime = _gridTraversalTime;
        treasuryAddress = _treasuryAddress;
    }

    function doomRiot(
        uint256 _gridId, 
        uint8 _multiple
    ) external onlyOwner {
        gridMultiple[_gridId] = _multiple;
    }
}