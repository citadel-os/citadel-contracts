// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract DrakmaLock is Ownable, ReentrancyGuard {

    ERC20Burnable public drakmaToken;

    // Mapping to track the locked amount of each user
    mapping(address => uint256) public lockedAmounts;

    constructor(
        address _drakmaTokenAddress
    ) {
        drakmaToken = ERC20Burnable(_drakmaTokenAddress);
    }

    /**
     * @dev Locks `_amt` of Drakma from the caller into this contract.
     *      The caller must have approved this contract to spend Drakma on their behalf.
     */
    function lock(uint256 _amt) external nonReentrant {
        require(_amt > 0, "Invalid amount");

        // Transfer Drakma from msg.sender to this contract
        bool success = drakmaToken.transferFrom(msg.sender, address(this), _amt);
        require(success, "Transfer failed");

        // Increase the locked amount for the user
        lockedAmounts[msg.sender] += _amt;
    }

    /**
     * @dev Only the contract owner can call this function. It unlocks and transfers
     *      all locked Drakma for a list of addresses. After unlocking, each
     *      address's locked balance is set to zero.
     */
    function unlock(address[] calldata _addresses) external onlyOwner nonReentrant {
        for (uint256 i = 0; i < _addresses.length; i++) {
            address user = _addresses[i];
            uint256 lockedAmt = lockedAmounts[user];

            // If user has locked Drakma, transfer it back and reset locked balance
            if (lockedAmt > 0) {
                bool success = drakmaToken.transfer(user, lockedAmt);
                require(success, "Transfer to user failed");

                lockedAmounts[user] = 0;
            }
        }
    }

    /**
     * @dev Only the contract owner can call this function. It burns all Drakma
     *      tokens currently held in this contract.
     */
    function burnAll() external onlyOwner nonReentrant {
        uint256 contractBalance = drakmaToken.balanceOf(address(this));
        drakmaToken.burn(contractBalance);
    }
}
