// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./IExterminate.sol";
import "./DiamondStorage.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract CitadelExterminate is DiamondStorage, Ownable, IExterminate {

}