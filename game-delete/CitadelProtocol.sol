// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;


import "./IExplore.sol";
import "./IExpand.sol";
import "./IExploit.sol";
import "./IExterminate.sol";
import "./DiamondLib.sol";
import "./DiamondStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";


contract CitadelProtocol is DiamondStorage, Ownable {
    constructor(
        address exploreAddress,
        address expandAddress,
        address exploitAddress,
        address exterminateAddress
    ) {
        bytes4[] memory exploreSelectors = new bytes4[](2);
        exploreSelectors[0] = IExplore.liteGrid.selector;
        exploreSelectors[1] = IExplore.claim.selector;

        bytes4[] memory expandSelectors = new bytes4[](1);
        expandSelectors[0] = IExpand.trainFleet.selector;

        bytes4[] memory exploitSelectors = new bytes4[](4);
        exploitSelectors[0] = IExploit.sackCapital.selector;
        exploitSelectors[1] = IExploit.bribeCapital.selector;
        exploitSelectors[2] = IExploit.overthrowSovereign.selector;
        exploitSelectors[3] = IExploit.getCapital.selector;

        bytes4[] memory exterminateSelectors = new bytes4[](3);
        exterminateSelectors[0] = IExterminate.sendReinforcements.selector;
        exterminateSelectors[1] = IExterminate.sendSiege.selector;
        exterminateSelectors[2] = IExterminate.resolveSiege.selector;

        DiamondLib.FacetCut[] memory fourXCuts = new DiamondLib.FacetCut[](4);

        fourXCuts[0] = DiamondLib.FacetCut({
            facetAddress: exploreAddress,
            functionSelectors: exploreSelectors
        });

        fourXCuts[1] = DiamondLib.FacetCut({
            facetAddress: expandAddress,
            functionSelectors: expandSelectors
        });

        fourXCuts[2] = DiamondLib.FacetCut({
            facetAddress: exploitAddress,
            functionSelectors: exploitSelectors
        });

        fourXCuts[3] = DiamondLib.FacetCut({
            facetAddress: exterminateAddress,
            functionSelectors: exterminateSelectors
        });

        DiamondLib.diamondCut(fourXCuts);

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