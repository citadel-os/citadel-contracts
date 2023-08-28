// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface ISTORAGEV2 {
    function liteGrid(
        uint256[] calldata _pilotIds, 
        uint256 _gridId, 
        uint8 _factionId
    ) external;
    function claim(
        uint256 _citadelId
    ) external returns (uint256);
    function dimGrid(
        uint256 _citadelId,
        uint256 _pilotId
    ) external;
}


contract CitadelGameV2 is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // imports
    IERC20 public immutable drakma;
    IERC721 public immutable citadelCollection;
    IERC721 public immutable pilotCollection;
    ISTORAGEV2 public immutable storageEngine;

    // variables
    uint256 maxGrid = 1023;
    uint8 maxFaction = 4;

    constructor(
        IERC721 _citadelCollection, 
        IERC721 _pilotCollection, 
        IERC20 _drakma, 
        ISTORAGEV2 _storageEngine
    ) {
        citadelCollection = _citadelCollection;
        pilotCollection = _pilotCollection;
        drakma = _drakma;
        storageEngine = _storageEngine;
    }

    function liteGrid(uint256[] calldata _pilotIds, uint256 _gridId, uint8 _factionId) external nonReentrant {
        require(_gridId <= maxGrid && _gridId != 0, "invalid grid");
        require(_factionId <= maxFaction, "invalid faction");
        for (uint256 i; i < _pilotIds.length; ++i) {
            require(
                pilotCollection.ownerOf(_pilotIds[i]) == msg.sender,
                "must own pilot to lite"
            );
        }
        storageEngine.liteGrid(_pilotIds, _gridId, _factionId);
    }

    function dimGrid(uint256 _citadelId, uint256 _pilotId) external nonReentrant {
        require(
            pilotCollection.ownerOf(_pilotId) == msg.sender,
            "must own pilot to dim"
        );

        storageEngine.dimGrid(_citadelId, _pilotId);
    }

    function claim(uint256 _citadelId) external nonReentrant {
        require(
            citadelCollection.ownerOf(_citadelId) == msg.sender,
            "must own citadel"
        );
        uint256 drakmaToClaim = storageEngine.claim(_citadelId);
        if(drakmaToClaim > 0) {
            drakma.safeTransfer(msg.sender, drakmaToClaim);
        }
    }

    
}
