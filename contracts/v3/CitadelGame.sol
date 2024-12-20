// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;


import "./interfaces/ILite.sol";
import "./interfaces/IAdmin.sol";
import "./DiamondLib.sol";
import "./DiamondStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";


contract CitadelProtocol is DiamondStorage, Ownable {
    constructor(
        address liteAddress,
        address adminAddress
    ) {
        bytes4[] memory liteSelectors = new bytes4[](1);
        liteSelectors[0] = ILite.liteGrid.selector;

        bytes4[] memory adminSelectors = new bytes4[](2);
        adminSelectors[0] = IAdmin.updateCitadelMerkleRoot.selector;
        adminSelectors[1] = IAdmin.updatePilotMerkleRoot.selector;


        DiamondLib.FacetCut[] memory cuts = new DiamondLib.FacetCut[](2);

        cuts[0] = DiamondLib.FacetCut({
            facetAddress:  liteAddress,
            functionSelectors: liteSelectors
        });

        cuts[1] = DiamondLib.FacetCut({
            facetAddress:  adminAddress,
            functionSelectors: adminSelectors
        });

        DiamondLib.diamondCut(cuts);

        DiamondStorage.gameStart = block.timestamp;
    }

    function updateFacets(DiamondLib.FacetCut[] memory _cuts) external onlyOwner {
        // Perform the diamond cut
        DiamondLib.diamondCut(_cuts);
    }

    fallback() external payable {
        DiamondLib.delegateCall(msg.sig);
    }

    receive() external payable {}
}