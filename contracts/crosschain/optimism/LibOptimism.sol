// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (crosschain/optimism/LibOptimism.sol)

pragma solidity ^0.8.4;

import {ICrossDomainMessenger as Optimism_Bridge} from "../../vendor/optimism/ICrossDomainMessenger.sol";
import "../errors.sol";

/**
 * @dev Primitives for cross-chain aware contracts for https://www.optimism.io/[Optimism].
 * See the https://community.optimism.io/docs/developers/bridge/messaging/#accessing-msg-sender[documentation]
 * for the functionality used here.
 */
library LibOptimism {
    /**
     * @dev Returns whether the current function call is the result of a
     * cross-chain message relayed by `messenger`.
     */
    function isCrossChain(address messenger) internal view returns (bool) {
        return msg.sender == messenger;
    }

    /**
     * @dev Returns the address of the sender that triggered the current
     * cross-chain message through `messenger`.
     *
     * NOTE: {isCrossChain} should be checked before trying to recover the
     * sender, as it will revert with `NotCrossChainCall` if the current
     * function call is not the result of a cross-chain message.
     */
    function crossChainSender(address messenger) internal view returns (address) {
        if (!isCrossChain(messenger)) revert NotCrossChainCall();

        return Optimism_Bridge(messenger).xDomainMessageSender();
    }

    /**
     * @dev Sends a message from L2 to L1 via `messenger`.
     *
     * Returns zero because the protocol doesn't return the transaction unique Id.
     */
    function sendCrossChainMessageL2ToL1(
        address messenger,
        address destination,
        bytes memory calldataForL1
    ) internal returns (uint256) {
        // the gasLimit parameter is irrelevant sending a message from L2 to L1
        Optimism_Bridge(messenger).sendMessage(destination, calldataForL1, 0);

        // Optimism doesn't return a unique Id for the transaction
        return 0;
    }

    /**
     * @dev Sends a cross-chain message via `messenger`.
     *
     * NOTE: Check https://community.optimism.io/docs/developers/bridge/messaging/#[Fees for sending data between L1 and L2]
     * to understand gasLimit implications.
     */
    function sendCrossChainMessage(
        address messenger,
        address destination,
        bytes memory data,
        bytes memory bridgeConfig
    ) internal {
        uint32 gasLimit = bridgeConfig.length > 0 ? abi.decode(bridgeConfig, (uint32)) : 0;

        Optimism_Bridge(messenger).sendMessage(destination, data, gasLimit);
    }
}
