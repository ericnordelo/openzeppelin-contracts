const { BridgeHelper } = require('../helpers/crosschain');
const { expectRevertCustomError } = require('../helpers/customError');
const { expectEvent } = require('@openzeppelin/test-helpers');
const { utils } = require('ethers');
const { web3 } = require('hardhat');

function randomAddress() {
  return web3.utils.toChecksumAddress(web3.utils.randomHex(20));
}

const CrossChainEnabledAMBMock = artifacts.require('CrossChainEnabledAMBMock');
const CrossChainEnabledArbitrumL1Mock = artifacts.require('CrossChainEnabledArbitrumL1Mock');
const CrossChainEnabledArbitrumL2Mock = artifacts.require('CrossChainEnabledArbitrumL2Mock');
const CrossChainEnabledOptimismL1Mock = artifacts.require('CrossChainEnabledOptimismL1Mock');
const CrossChainEnabledOptimismL2Mock = artifacts.require('CrossChainEnabledOptimismL2Mock');
const CrossChainEnabledPolygonChildMock = artifacts.require('CrossChainEnabledPolygonChildMock');

function shouldBehaveLikeReceiver(sender = randomAddress()) {
  it('should reject same-chain calls', async function () {
    await expectRevertCustomError(this.contract.crossChainRestricted(), 'NotCrossChainCall()');

    await expectRevertCustomError(this.contract.crossChainOwnerRestricted(), 'NotCrossChainCall()');
  });

  it('should restrict to cross-chain call from a invalid sender', async function () {
    await expectRevertCustomError(
      this.bridge.call(sender, this.contract, 'crossChainOwnerRestricted()'),
      `InvalidCrossChainSender("${sender}", "${await this.contract.owner()}")`,
    );
  });

  it('should grant access to cross-chain call from the owner', async function () {
    await this.bridge.call(await this.contract.owner(), this.contract, 'crossChainOwnerRestricted()');
  });
}

contract('CrossChainEnabled', function () {
  const destination = randomAddress();
  const calldata = '0x';

  describe('AMB', function () {
    beforeEach(async function () {
      this.bridge = await BridgeHelper.deploy('AMB');
      this.contract = await CrossChainEnabledAMBMock.new(this.bridge.address);
    });

    shouldBehaveLikeReceiver();
  });

  describe('Arbitrum-L1', function () {
    const bridgeId = '0xf99ba2be';
    const bridgeParameters = {
      bridgeId,
      totalL2GasCosts: 0,
      l2CallValue: 0,
      maxSubmissionCost: 10,
      excessFeeRefundAddress: randomAddress(),
      callValueRefundAddress: randomAddress(),
      maxGas: utils.parseEther('0.1'),
      gasPriceBid: 5,
    };

    function encodeArbitrumL1Params(params) {
      return utils.defaultAbiCoder.encode(
        ['bytes4', 'uint256', 'uint256', 'uint256', 'address', 'address', 'uint256', 'uint256'],
        [...Object.values(params)],
      );
    }

    beforeEach(async function () {
      this.bridge = await BridgeHelper.deploy('Arbitrum-L1');
      this.contract = await CrossChainEnabledArbitrumL1Mock.new(this.bridge.address);
    });

    it('should emit L1 to L2 retryable ticket id', async function () {
      const crossChainTxParameters = encodeArbitrumL1Params(bridgeParameters);

      expectEvent(
        await this.contract.sendCrossChainMessage(destination, calldata, crossChainTxParameters),
        'RetryableTicketCreated',
      );
    });

    it('should restrict cross-chain calls with wrong bridge Id', async function () {
      const wrongBridgeId = web3.utils.keccak256('wrong bridge id').slice(0, 10);

      bridgeParameters.bridgeId = wrongBridgeId;

      const crossChainTxParameters = encodeArbitrumL1Params(bridgeParameters);

      await expectRevertCustomError(
        this.contract.sendCrossChainMessage(destination, calldata, crossChainTxParameters),
        `InvalidTargetBridge("${wrongBridgeId}", "${bridgeId}")`,
      );
    });

    shouldBehaveLikeReceiver();
  });

  describe('Arbitrum-L2', function () {
    const bridgeId = '0xcf0303bf';
    const bridgeParameters = {
      bridgeId,
      depositValue: 0,
    };

    function encodeArbitrumL2Params(params) {
      return utils.defaultAbiCoder.encode(['bytes4', 'uint256'], [...Object.values(params)]);
    }

    beforeEach(async function () {
      this.bridge = await BridgeHelper.deploy('Arbitrum-L2');
      this.contract = await CrossChainEnabledArbitrumL2Mock.new();
    });

    it('should emit L2 to L1 transaction id', async function () {
      const crossChainTxParameters = encodeArbitrumL2Params(bridgeParameters);

      expectEvent(
        await this.contract.sendCrossChainMessage(destination, calldata, crossChainTxParameters),
        'L2ToL1TxSubmitted',
      );
    });

    it('should restrict cross-chain calls with wrong bridge Id', async function () {
      const wrongBridgeId = web3.utils.keccak256('wrong bridge id').slice(0, 10);

      bridgeParameters.bridgeId = wrongBridgeId;

      const crossChainTxParameters = encodeArbitrumL2Params(bridgeParameters);

      await expectRevertCustomError(
        this.contract.sendCrossChainMessage(destination, calldata, crossChainTxParameters),
        `InvalidTargetBridge("${wrongBridgeId}", "${bridgeId}")`,
      );
    });

    shouldBehaveLikeReceiver();
  });

  describe('Optimism', function () {
    function encodeOptimismParams(params) {
      return utils.defaultAbiCoder.encode(['bytes4', 'uint32', 'uint256'], [...Object.values(params)]);
    }

    describe('Optimism-L1', function () {
      const bridgeId = '0x8a69005a';
      const bridgeParameters = {
        bridgeId,
        gasLimit: utils.parseEther('0.000000000001'),
        depositValue: 0,
      };

      beforeEach(async function () {
        this.bridge = await BridgeHelper.deploy('Optimism-L1');
        this.contract = await CrossChainEnabledOptimismL1Mock.new(this.bridge.address);

        console.log(await this.bridge.bridge.messenger());
      });

      it('should send cross-chain message successfuly', async function () {
        const crossChainTxParameters = encodeOptimismParams(bridgeParameters);

        await this.contract.sendCrossChainMessage(destination, calldata, crossChainTxParameters);
      });

      it('should restrict cross-chain calls with wrong bridge Id', async function () {
        const wrongBridgeId = web3.utils.keccak256('wrong bridge id').slice(0, 10);

        bridgeParameters.bridgeId = wrongBridgeId;

        const crossChainTxParameters = encodeOptimismParams(bridgeParameters);

        await expectRevertCustomError(
          this.contract.sendCrossChainMessage(destination, calldata, crossChainTxParameters),
          `InvalidTargetBridge("${wrongBridgeId}", "${bridgeId}")`,
        );
      });

      shouldBehaveLikeReceiver();
    });

    describe('Optimism-L2', function () {
      const bridgeId = '0xa2b60698';
      const bridgeParameters = {
        bridgeId,
        gasLimit: utils.parseEther('0.000000000001'),
        depositValue: 0,
      };

      beforeEach(async function () {
        this.bridge = await BridgeHelper.deploy('Optimism-L2');
        this.contract = await CrossChainEnabledOptimismL2Mock.new(this.bridge.address);
      });

      it('should send cross-chain message successfuly', async function () {
        const crossChainTxParameters = encodeOptimismParams(bridgeParameters);

        await this.contract.sendCrossChainMessage(destination, calldata, crossChainTxParameters);
      });

      it('should restrict cross-chain calls with wrong bridge Id', async function () {
        const wrongBridgeId = web3.utils.keccak256('wrong bridge id').slice(0, 10);

        bridgeParameters.bridgeId = wrongBridgeId;

        const crossChainTxParameters = encodeOptimismParams(bridgeParameters);

        await expectRevertCustomError(
          this.contract.sendCrossChainMessage(destination, calldata, crossChainTxParameters),
          `InvalidTargetBridge("${wrongBridgeId}", "${bridgeId}")`,
        );
      });

      shouldBehaveLikeReceiver();
    });
  });

  describe('Polygon-Child', function () {
    beforeEach(async function () {
      this.bridge = await BridgeHelper.deploy('Polygon-Child');
      this.contract = await CrossChainEnabledPolygonChildMock.new(this.bridge.address);
    });

    shouldBehaveLikeReceiver();
  });
});
