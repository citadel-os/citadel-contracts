// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IDrakma {
    function burn(address from, uint256 amount) external;
}

contract DrakmaSenderBridge is Ownable, ReentrancyGuard {
    address public baseContractAddress;
    IRouterClient public router;
    IERC20 public drakmaToken;
    uint64 public destinationChainSelector;

    struct Message {
        uint64 sourceChainSelector;
        address sender;
        uint256 drakmaBurned;
    }

    event MessageSent(
        bytes32 messageId,
        address sender,
        uint256 fees,
        uint256 drakmaBurned
    );

    constructor(
        address _baseContractAddress,
        address _router,
        address _drakmaTokenAddress,
        uint64 _destinationChainSelector
    ) {
        baseContractAddress = _baseContractAddress;
        router = IRouterClient(_router);
        drakmaToken = IERC20(_drakmaTokenAddress);
        destinationChainSelector = _destinationChainSelector;
    }

    function _sendMessage(
        uint256 message
    ) internal returns (bytes32 messageId) {
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(baseContractAddress),
            data: abi.encode(message),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 400_000})
            ),
            feeToken: address(0)
        });

        uint256 fees = router.getFee(destinationChainSelector, evm2AnyMessage);

        messageId = router.ccipSend{value: fees}(
            destinationChainSelector,
            evm2AnyMessage
        );

        emit MessageSent(messageId, msg.sender, fees, message);

        return messageId;
    }

    function bridge(uint256 _amt) external nonReentrant {
        require(_amt > 0, "Invalid amount");
        require(drakmaToken.transferFrom(msg.sender, address(this), _amt), "Transfer failed");

        ERC20Burnable(address(drakmaToken)).burn(_amt);

        _sendMessage(_amt);
    }

    function withdrawEth() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    receive() external payable {}
}