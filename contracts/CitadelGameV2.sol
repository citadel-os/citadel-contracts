// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CitadelGameV2 is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable drakma;

    event CitadelEvent(
        uint256 citadelId
    );

    struct CitadelLit {
        address walletAddress;
        uint256 gridId;
        uint8 factionId;
        uint256 timeOfLastClaim;
        uint256 timeLit;
        uint256 timeLastRaided;
        uint256 unclaimedDrakma;
        uint256[] pilot;
    }

    mapping(uint256 => CitadelLit) citadel; // index is _citadelId
    mapping(uint256 => address) citadelOwners; // index is _citadelId
    mapping(uint256 => address) pilotOwners; // index is _pilotId
    mapping(uint256 => bool) grid; // index is _gridId

    uint256 maxGrid = 1023;
    uint8 maxFaction = 4;
    uint256 periodFinish = 1735700987; //JAN 1 2025, 2PM PT 

    constructor(
        IERC20 _drakma
    ) {
        drakma = _drakma;
    }

    // lite
    // external functions
    function liteGrid(uint256 _citadelId, uint256[] calldata _pilotIds, uint256 _gridId, uint8 _factionId) external nonReentrant {
        require(citadelOwners[_citadelId] == msg.sender, "must own citadel to lite");
        require(grid[_gridId] == false, "grid already lit");
        require(_gridId <= maxGrid && _gridId != 0, "invalid grid");
        require(_factionId <= maxFaction, "invalid faction");
        for (uint256 i; i < _pilotIds.length; ++i) {
            require(
                pilotOwners[i] == msg.sender,
                "must own pilot to lite"
            );
        }

        uint256 blockTimeNow = lastTimeRewardApplicable();
        citadel[_citadelId].walletAddress = msg.sender;
        citadel[_citadelId].gridId = _gridId;
        citadel[_citadelId].factionId = _factionId;
        citadel[_citadelId].timeLit = blockTimeNow;
        citadel[_citadelId].timeLastRaided = blockTimeNow;
        citadel[_citadelId].timeOfLastClaim = 0;
        grid[_gridId] = true;

        emit CitadelEvent(
            _citadelId
        );
    }

    // dim
    // claim

    // public views
    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }


}