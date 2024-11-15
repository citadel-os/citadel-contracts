// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./interfaces/ILite.sol";
import "./DiamondStorage.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract CitadelLite is DiamondStorage, Ownable, ILite, ReentrancyGuard {
    IERC20 public immutable drakma;

    constructor(
        IERC20 _drakmaAddress
    ) {
        drakma = _drakmaAddress;
    }

    function liteGrid(
        uint256 _citadelId,
        uint256[3] calldata _pilotIds,
        uint256 _nodeId,
        uint8 _factionId,
        uint8 _orbitHeight
    ) external nonReentrant {
        require(_nodeId <= DiamondStorage.maxNode && _nodeId != 0, "invalid node");
        // TODO: check for citadel ownership
        require(!DiamondStorage.node[_nodeId].isLit, "Node already lit");

        for (uint256 i; i < _pilotIds.length; ++i) {
            if (_pilotIds[i] != 0) {
                // TODO: check for pilot ownership
                require(!DiamondStorage.pilot[_pilotIds[i]], "Pilot already used");
                DiamondStorage.pilot[_pilotIds[i]] = true;
            }
        }

        require(DiamondStorage.citadel[_citadelId].timeLit == 0, "Citadel already lit");

        // Transfer Drakma based on orbit height
        uint256 drakmaAmount;
        if (_orbitHeight == 1) {
            drakmaAmount = 1_000_000 * 10 ** 18;
        } else if (_orbitHeight == 2) {
            drakmaAmount = 800_000 * 10 ** 18;
        } else if (_orbitHeight == 3) {
            drakmaAmount = 600_000 * 10 ** 18;
        } else if (_orbitHeight == 4) {
            drakmaAmount = 400_000 * 10 ** 18;
        } else if (_orbitHeight == 5) {
            drakmaAmount = 0;
        } else {
            revert("Invalid orbit height");
        }

        if (drakmaAmount > 0) {
            require(
                drakma.transferFrom(msg.sender, address(this), drakmaAmount),
                "Drakma transfer failed"
            );
        }

        uint256 gridId = getGrid(_nodeId);

        DiamondStorage.citadel[_citadelId] = CitadelNode(
            _nodeId,
            0,
            block.timestamp,
            0,
            0,
            _pilotIds,
            _factionId,
            _orbitHeight
        );

        DiamondStorage.node[_nodeId] = Node(gridId, true, _citadelId);

    }




}