// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (crosschain/optimism/CrossChainEnabledOptimism.sol)

pragma solidity ^0.8.4;

import "../CrossChainEnabled.sol";
import "./LibOptimismL2.sol";

/**
 * @dev https://www.optimism.io/[Optimism] specialization or the
 * {CrossChainEnabled} abstraction.
 *
 * The bridge (`L1StandardBridge`) contract is provided and maintained by
 * the optimism team. You can find the address of this contract on mainnet and
 * kovan in the https://github.com/ethereum-optimism/optimism/tree/develop/packages/contracts/deployments[deployments section of Optimism monorepo].
 *
 * _Available since v4.6._
 */
abstract contract CrossChainEnabledOptimismL2 is CrossChainEnabled {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _l1StandardBridge;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address l1StandardBridge) {
        _l1StandardBridge = l1StandardBridge;
    }

    /**
     * @dev see {CrossChainEnabled-_isCrossChain}
     */
    function _isCrossChain() internal view virtual override returns (bool) {
        return LibOptimismL2.isCrossChain(_l1StandardBridge);
    }

    /**
     * @dev see {CrossChainEnabled-_crossChainSender}
     */
    function _crossChainSender() internal view virtual override onlyCrossChain returns (address) {
        return LibOptimismL2.crossChainSender(_l1StandardBridge);
    }

    /**
     * @dev see {CrossChainEnabled-_sendCrossChainMessage}
     */
    function _sendCrossChainMessage(
        address destination,
        bytes memory data,
        bytes memory crossChainTxParams
    ) internal virtual override {
        LibOptimismL2.sendCrossChainMessage(_l1StandardBridge, destination, data, crossChainTxParams);
    }
}
