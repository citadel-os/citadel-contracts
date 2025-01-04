// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DrakmaBase is Context, AccessControlEnumerable, ERC20Capped, ERC20Burnable, ReentrancyGuard {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant DEV_ROLE = keccak256("DEV_ROLE");

    // creates Drakma ERC20 with a 10B cap
    constructor() ERC20("Drakma", "DK") ERC20Capped(10000000000 * 10**18) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(DEV_ROLE, _msgSender());
    }

    /**
     * @dev Mint Drakma to a single address.
     */
    function mintDrakma(address to, uint256 amount) external nonReentrant {
        require(hasRole(MINTER_ROLE, _msgSender()), "drakma: must have minter role to mint");
        _mint(to, amount);
    }

    /**
     * @dev Mint Drakma to multiple addresses in a single transaction.
     *
     * Requirements:
     * - Caller must have the MINTER_ROLE.
     * - `_recipients` and `_amounts` arrays must have the same length.
     */
    function bulkMintDrakma(
        address[] calldata _recipients,
        uint256[] calldata _amounts
    ) external nonReentrant {
        require(hasRole(MINTER_ROLE, _msgSender()), "drakma: must have minter role to mint");
        require(_recipients.length == _amounts.length, "drakma: invalid input arrays");

        for (uint256 i = 0; i < _recipients.length; i++) {
            _mint(_recipients[i], _amounts[i]);
        }
    }

    /**
     * @dev Adds a new minter. Caller must have DEV_ROLE.
     */
    function addMinter(address account) external virtual {
        require(hasRole(DEV_ROLE, _msgSender()), "drakma: must have dev role to add minter");
        grantRole(MINTER_ROLE, account);
    }

    /**
     * @dev Internal override to respect the ERC20Capped cap.
     */
    function _mint(address account, uint256 amount) internal virtual override(ERC20, ERC20Capped) {
        super._mint(account, amount);
    }
}

