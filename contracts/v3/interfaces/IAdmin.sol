// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IAdmin {
    function updateNFTMerkleRoot(bytes32 _newRoot) external;
}