// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (crosschain/optimism/LibOptimism.sol)

pragma solidity ^0.8.4;

import {ICrossDomainMessenger as Optimism_Bridge} from "../../vendor/optimism/ICrossDomainMessenger.sol";
import "../errors.sol";

/**
 * @dev Primitives for cross-chain aware contracts for https://www.optimism.io/[Optimism].
 * See the https://community.optimism.io/docs/developers/bridge/messaging/#accessing-msg-sender[documentation]
 * for the functionality used here.
 *
 * This version should only be used on L1 to process cross-chain messages
 * originating from L2, or to send cross-chain messages from L1 to L2. For
 * the other side, use {LibOptimismL2}.
 */
library LibOptimismL1 {
    /**
     * @dev This is the keccak256('Optimism-L1L2')
     */
    bytes32 public constant BRIDGE_ID = 0x8a69005a3baed81c73049b861e928740f14876213fc1cafd636c7aa14c2576b1;

    /**
     * @dev These are the parameters required for sending the cross-chain message.
     *
     * @param bridgeId This Id is used to ensure this bridge only send messages intended for this bridge,
     * avoiding some unexpected scenarios if a config for a different bridge matches.
     */
    struct CrossChainTxParams {
        bytes32 bridgeId;
        uint32 gasLimit;
    }

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
     * @dev Sends a cross-chain message via `messenger`.
     *
     * NOTE: Check https://community.optimism.io/docs/developers/bridge/messaging/#[Fees for sending data between L1 and L2]
     * to understand gasLimit implications.
     *
     * @param messenger The CrossDomainMessenger contract representing the bridge.
     * @param destination The address of the cross-chain target contract.
     * @param data The calldata of the cross-chain call.
     * @param crossChainTxParams An ABI encoded {CrossChainTxParams} representing the parameters required
     * for the message to be sent through the bridge.
     */
    function sendCrossChainMessage(
        address messenger,
        address destination,
        bytes memory data,
        bytes memory crossChainTxParams
    ) internal {
        CrossChainTxParams memory params = abi.decode(crossChainTxParams, (CrossChainTxParams));

        if (BRIDGE_ID != params.bridgeId) revert InvalidTargetBridge(params.bridgeId, BRIDGE_ID);

        Optimism_Bridge(messenger).sendMessage(destination, data, params.gasLimit);
    }
}
