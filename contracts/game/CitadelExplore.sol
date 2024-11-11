// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./IExplore.sol";
import "./DiamondStorage.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface INFT {
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract CitadelExplore is DiamondStorage, Ownable, IExplore, ReentrancyGuard {
    IERC20 public immutable drakma;
    INFT public immutable citadelCollection;
    INFT public immutable pilotCollection;

    constructor(
        INFT _pilotAddress,
        INFT _citadelAddress,
        IERC20 _drakmaAddress
    ) {
        citadelCollection = _citadelAddress;
        pilotCollection = _pilotAddress;
        drakma = _drakmaAddress;
    }

    function liteGrid(
        uint256 _citadelId,
        uint256[3] calldata _pilotIds,
        uint256 _gridId,
        uint8 _capitalId
    ) external nonReentrant {
        require(_gridId <= DiamondStorage.maxGrid && _gridId != 0, "invalid grid");
        require(_capitalId < DiamondStorage.maxCapital, "invalid capital");
        require(
            citadelCollection.ownerOf(_citadelId) == msg.sender,
            "must own citadel"
        );
        require(!DiamondStorage.grid[_gridId].isLit, "cannot lite");
        uint256 sovereignUntil;
        for (uint256 i; i < _pilotIds.length; ++i) {
            if (_pilotIds[i] != 0) {
                require(
                    pilotCollection.ownerOf(_pilotIds[i]) == msg.sender,
                    "must own pilot to lite"
                );
                require(!DiamondStorage.pilot[_pilotIds[i]], "cannot lite");
                DiamondStorage.pilot[_pilotIds[i]] = true;
            }
        }

        require(DiamondStorage.citadel[_citadelId].timeLit == 0, "cannot lite");


        DiamondStorage.citadel[_citadelId] = CitadelGrid(
            _gridId,
            _capitalId,
            0,
            block.timestamp,
            0,
            0,
            _pilotIds,
            0
        );


        DiamondStorage.grid[_gridId] = Grid(false, sovereignUntil, true, _citadelId);

    }

    function claim(uint256 _citadelId) external nonReentrant {
        require(
            citadelCollection.ownerOf(_citadelId) == msg.sender,
            "must own citadel"
        );
        uint256 drakmaToClaim = claimInternal(_citadelId);

        if(drakmaToClaim > 0) {
            drakma.safeTransfer(msg.sender, drakmaToClaim);
        }
    }

    function claimInternal(uint256 _citadelId) internal returns (uint256) {
        require(
            (
                DiamondStorage.citadel[_citadelId].timeOfLastClaim +
                DiamondStorage.claimInterval
            ) < block.timestamp, "one claim per interval permitted");
        uint256 drakmaToClaim = DiamondStorage.calculateMiningOutput(
            _citadelId,
            DiamondStorage.getGridFromCitadel(_citadelId),
            getMiningStartTime(),
            drakma.balanceOf(DiamondStorage.treasuryAddress)
        ) + DiamondStorage.citadel[_citadelId].unclaimedDrakma;

        DiamondStorage.citadel[_citadelId].timeOfLastClaim = block.timestamp;
        DiamondStorage.citadel[_citadelId].unclaimedDrakma = 0;
        if (!isTreasuryMaxed(
            DiamondStorage.capital[DiamondStorage.citadel[_citadelId].capitalId].treasury
        )) {
            DiamondStorage.capital[citadel[_citadelId].capitalId].treasury += (drakmaToClaim / 10);
            return (drakmaToClaim * 9) / 10;
        }
        return (drakmaToClaim / 10);
    }

    function isTreasuryMaxed(uint256 treasuryBal) public view returns (bool) {
        uint256 max = drakma.balanceOf(DiamondStorage.treasuryAddress) / 16;
        if (treasuryBal > max) {
            return true;
        }
        return false;
    }

    function getMiningStartTime() internal view returns(uint256) {
        if(block.timestamp - DiamondStorage.claimInterval < DiamondStorage.gameStart) {
            return DiamondStorage.gameStart;
        }

        return block.timestamp - DiamondStorage.claimInterval;
    }


}