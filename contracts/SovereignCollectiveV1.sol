// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IPILOT {
    function getOnchainPILOT(uint256 tokenId) external view returns (bool, uint8);
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract SovereignCollectiveV1 is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    IPILOT public immutable pilotCollection;
    IERC20 public immutable drakma;
    
    uint256[] claims;

    constructor(IPILOT _pilotCollection, IERC20 _drakma) {
        pilotCollection = _pilotCollection;
        drakma = _drakma;
    }
    
    // only owner
    function withdrawDrakma(uint256 amount) external onlyOwner {
        drakma.safeTransfer(msg.sender, amount);
    }

    function resetClaims() external onlyOwner {
        delete claims;
    }

    function claimSovereign(uint256 _sovereignId) external nonReentrant {
        require(
            pilotCollection.ownerOf(_sovereignId) == msg.sender,
            "must own pilot to claim"
        );
        require(claims.length < 128, "claims exceeded for this period");
        (bool isSovereign,) = pilotCollection.getOnchainPILOT(_sovereignId);
        require(isSovereign == true, "pilot must be sovereign to claim");
        bool alreadyClaimed = false;
        for (uint256 i; i < claims.length; ++i) {
            if(claims[i] == _sovereignId) {
                alreadyClaimed = true;
                break;
            }
        }
        require(alreadyClaimed == false, "sovereign has already claimed");
        drakma.safeTransfer(msg.sender, getClaimAmount());
        claims.push(_sovereignId);
    }

    function getClaimAmount() public view returns (uint256) {
        uint256 amount = 0;
        if(claims.length < 128) {
            amount = drakma.balanceOf(address(this)) / (128 - claims.length);
        }
        return amount;
    }

    function getClaimsRemaining() public view returns (uint256) {
        return (128 - claims.length);
    }
    
}