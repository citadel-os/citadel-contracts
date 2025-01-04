// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

/**
 * @dev DiamondLib: Provides diamondCut and delegateCall for an EIP-2535 Diamond.
 */
library DiamondLib {
    // --------------------------------------------------------
    // Data structure for storing function selectors -> facets
    // --------------------------------------------------------
    struct FacetCut {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    // Each selector => which facet?
    struct FacetAddresses {
        mapping(bytes4 => address) addresses;
    }

    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    function diamondStorage() internal pure returns (FacetAddresses storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /**
     * @dev Add or replace facet address for each function selector passed in.
     */
    function diamondCut(FacetCut[] memory _cuts) internal {
        FacetAddresses storage ds = diamondStorage();
        for (uint256 i = 0; i < _cuts.length; i++) {
            address facet = _cuts[i].facetAddress;
            bytes4[] memory selectors = _cuts[i].functionSelectors;
            for (uint256 j = 0; j < selectors.length; j++) {
                ds.addresses[selectors[j]] = facet;
            }
        }
    }

    /**
     * @dev Delegatecall to the facet that holds the logic for the given selector.
     */
    function delegateCall(bytes4 _selector) internal {
        FacetAddresses storage ds = diamondStorage();
        address facet = ds.addresses[_selector];
        require(facet != address(0), "Function does not exist in facets");

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}
