// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IAdmin {
    function updatePilotMerkleRoot(bytes32 _newRoot) external;
    function updateCitadelMerkleRoot(bytes32 _newRoot) external;
}