// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IPILOT {
    function getOnchainPILOT(uint256 tokenId) external view returns (bool, uint8);
    function ownerOf(uint256 tokenId) external view returns (address);
    function getSovereign(uint256 sovereignId) external view returns (bool, uint8, uint8);
}

contract SovereignCollectiveV2 is Ownable {
    IPILOT public immutable pilotCollection;
    
    struct Sovereign {
        bool isSovereign;
        uint256 capitalId;
        uint256 lastBribe;
    }

    mapping(uint256 => Sovereign) public collective;

    address accessAddress;
    
    constructor(IPILOT _pilotCollection) {
        pilotCollection = _pilotCollection;
    }

    function initializeSovereign(uint256 _sovereignId, uint256 _capitalId) public {
        require(msg.sender == accessAddress, "cannot call function directly");
        collective[_sovereignId] = Sovereign(true, _capitalId, block.timestamp);
    }

    function isSovereignOnLite(uint256 _sovereignId) public view returns (bool isSovereign) {
        if (collective[_sovereignId].lastBribe == 0) {
            (isSovereign,,) = pilotCollection.getSovereign(_sovereignId);
            return isSovereign;
        }
        return false;
    }

    function usurpSovereign(uint256 _usurper, uint256 _sovereignId, uint256 _capitalId) public {
        require(msg.sender == accessAddress, "cannot call function directly");
        require(!collective[_usurper].isSovereign, "sovereign cannot usurp sovereign");
        collective[_usurper] = Sovereign(true, _capitalId, block.timestamp);
        collective[_sovereignId].isSovereign = false;
    }

    function bribeCapital(uint256 _sovereignId) public {
        require(msg.sender == accessAddress, "cannot call function directly");
        collective[_sovereignId].lastBribe = block.timestamp;
    }

    // only owner
    function updateAccessAddress(address _accessAddress) external onlyOwner {
        accessAddress = _accessAddress;
    }
}