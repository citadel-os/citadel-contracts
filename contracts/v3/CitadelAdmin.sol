// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DiamondStorage.sol";
import "./interfaces/IAdmin.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CitadelAdmin is Ownable, DiamondStorage, IAdmin {
     function updatePilotMerkleRoot(bytes32 _newRoot) external onlyOwner {
        DiamondStorage.pilotMerkleRoot = _newRoot;
    }

    function updateCitadelMerkleRoot(bytes32 _newRoot) external onlyOwner {
        DiamondStorage.citadelMerkleRoot = _newRoot;
    }
}
