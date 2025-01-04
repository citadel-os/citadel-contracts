// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DiamondStorage.sol";
import "./interfaces/IAdmin.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CitadelAdmin is Ownable, DiamondStorage, IAdmin {


}
