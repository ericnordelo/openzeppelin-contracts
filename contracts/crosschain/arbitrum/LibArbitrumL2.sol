// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (crosschain/arbitrum/LibArbitrumL2.sol)

pragma solidity ^0.8.4;

import {IArbSys as ArbitrumL2_Bridge} from "../../vendor/arbitrum/IArbSys.sol";
import "../errors.sol";

/**
 * @dev Primitives for cross-chain aware contracts for
 * https://arbitrum.io/[Arbitrum].
 *
 * This version should only be used on L2 to process cross-chain messages
 * originating from L1, or to send cross-chain messages from L2 to L1. For
 * the other side, use {LibArbitrumL1}.
 */
library LibArbitrumL2 {
    /**
     * @dev Returns whether the current function call is the result of a
     * cross-chain message relayed by `arbsys`.
     */
    address public constant ARBSYS = 0x0000000000000000000000000000000000000064;

    function isCrossChain(address arbsys) internal view returns (bool) {
        return ArbitrumL2_Bridge(arbsys).isTopLevelCall();
    }

    /**
     * @dev Returns the address of the sender that triggered the current
     * cross-chain message through `arbsys`.
     *
     * NOTE: {isCrossChain} should be checked before trying to recover the
     * sender, as it will revert with `NotCrossChainCall` if the current
     * function call is not the result of a cross-chain message.
     */
    function crossChainSender(address arbsys) internal view returns (address) {
        if (!isCrossChain(arbsys)) revert NotCrossChainCall();

        return
            ArbitrumL2_Bridge(arbsys).wasMyCallersAddressAliased()
                ? ArbitrumL2_Bridge(arbsys).myCallersAddressWithoutAliasing()
                : msg.sender;
    }

    /**
     * @dev Sends a cross-chain message from L2 to L1 via `arbsys`.
     *
     * NOTE: Check https://developer.offchainlabs.com/docs/l1_l2_messages#l2-to-l1-messages-lifecycle[L2 to L1 Messages Lifecycle]
     * from Arbitrum docs to understand the full lifecycle.
     */
    function sendCrossChainMessage(
        address arbsys,
        address destination,
        bytes memory data,
        bytes memory bridgeConfig
    ) internal returns (uint256 crossChainTxId) {
        uint256 amountToDeposit = bridgeConfig.length > 0 ? abi.decode(bridgeConfig, (uint256)) : 0;

        crossChainTxId = ArbitrumL2_Bridge(arbsys).sendTxToL1{value: amountToDeposit}(destination, data);
    }
}
