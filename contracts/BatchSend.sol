pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BatchSend is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    IERC20 public immutable drakma;

    constructor(IERC20 _drakma) {
        drakma = _drakma;
    }

    function multisendToken(address[] memory _contributors, uint256[] memory _balances) external onlyOwner payable {

        uint8 i = 0;
        for (i; i < _contributors.length; i++) {
            drakma.safeTransfer(_contributors[i], _balances[i]);
        }
    }
}

