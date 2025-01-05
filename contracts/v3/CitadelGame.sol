// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

import "./DiamondStorage.sol";
import "./DiamondLib.sol"; 
import "./interfaces/ILite.sol";
import "./interfaces/IAdmin.sol";
import "./interfaces/ICombat.sol";
import "./interfaces/ICombatEngine.sol";

/**
 * @dev The Diamond (proxy) contract for the Citadel game.
 */
contract CitadelGame is Ownable {
    constructor(
        address liteAddress,
        address adminAddress,
        address combatAddress,
        address combatEngineAddress
    ) {
        // 1. Initialize base storage
        DiamondStorage.GameStorage storage ds = DiamondStorage.diamondStorage();
        ds.maxCitadel = 1024;
        ds.maxNode = 1024;
        ds.claimInterval = 64 days;
        ds.gameStart = block.timestamp;
        ds.pilotMultiple = 20;
        ds.levelMultiple = 2;
        ds.gridTraversalTime = 30 minutes;
        ds.sifGattacaTrainingTime = 5 minutes;
        ds.mhrudvogThrotTrainingTime = 15 minutes;
        ds.drebentraakhtTrainingTime = 1 hours;
        ds.siegeMaxExpiry = 24 hours;
        ds.sifGattacaCary = 10000000000000000000;
        ds.mhrudvogThrotCary = 2000000000000000000;
        ds.drebentraakhtCary = 400000000000000000000;

        // Initialize interfaces
        ds.combatEngine = ICombatEngine(combatEngineAddress);

        // 2. Build a list of facets & function selectors
        //    - Lite
        bytes4[] memory liteSelectors = new bytes4[](2);
        liteSelectors[0] = ILite.liteCitadel.selector;
        liteSelectors[1] = ILite.litePilot.selector;

        //    - Admin (Example has none)
        bytes4[] memory adminSelectors = new bytes4[](0);

        //    - Combat
        bytes4[] memory combatSelectors = new bytes4[](2);
        combatSelectors[0] = ICombat.sendSiege.selector;
        combatSelectors[1] = ICombat.resolveSiege.selector;
        // if you want to expose initCombatFacet(...) externally, add that as well:
        //   combatSelectors[2] = ICombat.initCombatFacet.selector;

        // 3. Prepare the diamond cuts
        DiamondLib.FacetCut[] memory cuts = new DiamondLib.FacetCut[](3);

        cuts[0] = DiamondLib.FacetCut({
            facetAddress: liteAddress,
            functionSelectors: liteSelectors
        });

        cuts[1] = DiamondLib.FacetCut({
            facetAddress: adminAddress,
            functionSelectors: adminSelectors
        });

        cuts[2] = DiamondLib.FacetCut({
            facetAddress: combatAddress,
            functionSelectors: combatSelectors
        });

        // 4. Perform the diamond cut to register them
        DiamondLib.diamondCut(cuts);
    }

    // Optionally let the owner set up external token addresses, etc.
    function initGameTokens(
        address _drakma,
        address _citadelCollection,
        address _pilotCollection
    ) external onlyOwner {
        DiamondStorage.GameStorage storage ds = DiamondStorage.diamondStorage();
        ds.drakma = IERC20(_drakma);
        ds.citadelCollection = IERC721(_citadelCollection);
        ds.pilotCollection = IERC721(_pilotCollection);
    }

    // Owner can also dynamically update/replace facets later
    function updateFacets(DiamondLib.FacetCut[] memory _cuts) external onlyOwner {
        DiamondLib.diamondCut(_cuts);
    }

    fallback() external payable {
        DiamondLib.delegateCall(msg.sig);
    }

    receive() external payable {}
}

