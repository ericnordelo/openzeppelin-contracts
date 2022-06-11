// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/Address.sol";
import "../../vendor/polygon/IFxMessageProcessor.sol";

abstract contract BaseRelayMock {
    // needed to parse custom errors
    error NotCrossChainCall();
    error InvalidCrossChainSender(address sender, address expected);

    address internal _currentSender;

    function relayAs(
        address target,
        bytes calldata data,
        address sender
    ) external virtual {
        address previousSender = _currentSender;

        _currentSender = sender;

        (bool success, bytes memory returndata) = target.call(data);
        Address.verifyCallResult(success, returndata, "low-level call reverted");

        _currentSender = previousSender;
    }
}

/**
 * AMB
 */
contract BridgeAMBMock is BaseRelayMock {
    function messageSender() public view returns (address) {
        return _currentSender;
    }
}

/**
 * Arbitrum
 */
contract BridgeArbitrumL1Mock is BaseRelayMock {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address public immutable inbox = address(new BridgeArbitrumL1Inbox());
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address public immutable outbox = address(new BridgeArbitrumL1Outbox());

    function allowedInboxList(uint256) public view returns (address) {
        return inbox;
    }

    function activeOutbox() public view returns (address) {
        return outbox;
    }

    function currentSender() public view returns (address) {
        return _currentSender;
    }
}

contract BridgeArbitrumL1Inbox {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address public immutable bridge = msg.sender;

    function createRetryableTicket(
        address destAddr,
        uint256 arbTxCallValue,
        uint256 maxSubmissionCost,
        address submissionRefundAddress,
        address valueRefundAddress,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes calldata data
    ) external payable returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        destAddr,
                        arbTxCallValue,
                        maxSubmissionCost,
                        submissionRefundAddress,
                        valueRefundAddress,
                        maxGas,
                        gasPriceBid,
                        data
                    )
                )
            );
    }
}

contract BridgeArbitrumL1Outbox {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address public immutable bridge = msg.sender;

    function l2ToL1Sender() public view returns (address) {
        return BridgeArbitrumL1Mock(bridge).currentSender();
    }
}

contract BridgeArbitrumL2Mock is BaseRelayMock {
    function isTopLevelCall() public view returns (bool) {
        return _currentSender != address(0);
    }

    function wasMyCallersAddressAliased() public pure returns (bool) {
        return true;
    }

    function myCallersAddressWithoutAliasing() public view returns (address) {
        return _currentSender;
    }

    function sendTxToL1(address destination, bytes calldata calldataForL1) external payable returns (uint256) {
        return uint256(keccak256(abi.encode(destination, calldataForL1)));
    }
}

/**
 * Optimism
 */
contract BridgeOptimismMock is BaseRelayMock {
    function xDomainMessageSender() public view returns (address) {
        return _currentSender;
    }

    function sendMessage(
        address target,
        bytes calldata message,
        uint32 gasLimit
    ) external {}
}

/**
 * Polygon
 */
contract BridgePolygonChildMock is BaseRelayMock {
    function relayAs(
        address target,
        bytes calldata data,
        address sender
    ) external override {
        IFxMessageProcessor(target).processMessageFromRoot(0, sender, data);
    }
}
