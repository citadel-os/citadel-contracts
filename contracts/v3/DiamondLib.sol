// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./DiamondStorage.sol";

library DiamondLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetCut {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    function diamondCut(FacetCut[] memory facetCuts) internal {
        DiamondStorage.FacetAddresses storage ds = diamondStorage();
        for (uint i = 0; i < facetCuts.length; i++) {
            FacetCut memory cut = facetCuts[i];
            for (uint j = 0; j < cut.functionSelectors.length; j++) {
                ds.addresses[cut.functionSelectors[j]] = cut.facetAddress;
            }
        }
    }

    function delegateCall(bytes4 functionSelector) internal {
        DiamondStorage.FacetAddresses storage ds = diamondStorage();
        address facetAddress = ds.addresses[functionSelector];
        require(facetAddress != address(0), "facet not found.");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facetAddress, 0, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(0, 0, size)
            switch result
            case 0 { revert(0, size) }
            default { return(0, size) }
        }
    }

    function diamondStorage() internal pure returns (DiamondStorage.FacetAddresses storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}