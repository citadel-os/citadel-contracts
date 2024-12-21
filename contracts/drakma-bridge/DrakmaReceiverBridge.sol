// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IDrakma is IERC20 {
    function mintDrakma(address to, uint256 amount) external;
}

contract DrakmaReceiverBridge is CCIPReceiver, Ownable {

    IDrakma public drakmaToken;
    IRouterClient public router;

    event MessageReceived(
        bytes32 messageId,
        address sender,
        uint256 drakmaMinted
    );

    struct Message {
        uint64 sourceChainSelector;
        address sender;
        uint256 drakmaBurned;
    }

    constructor(
        address _router,
        address _drakmaTokenAddress
    ) CCIPReceiver(_router) {
        router = IRouterClient(_router);
        drakmaToken = IDrakma(_drakmaTokenAddress);
    }

    function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
    ) internal override {
        bytes32 messageId = any2EvmMessage.messageId; // fetch the messageId
        address sender = abi.decode(any2EvmMessage.sender, (address)); // abi-decoding of the sender address
        uint256 drakmaBridged = abi.decode(any2EvmMessage.data, (uint256));

        drakmaToken.mintDrakma(sender, drakmaBridged);

        emit MessageReceived(messageId, sender, drakmaBridged);
    }
}