const { BridgeHelper } = require('../helpers/crosschain');
const { expectRevertCustomError } = require('../helpers/customError');
const { expectEvent } = require('@openzeppelin/test-helpers');
const { utils } = require('ethers');

function randomAddress() {
  return web3.utils.toChecksumAddress(web3.utils.randomHex(20));
}

const CrossChainEnabledAMBMock = artifacts.require('CrossChainEnabledAMBMock');
const CrossChainEnabledArbitrumL1Mock = artifacts.require('CrossChainEnabledArbitrumL1Mock');
const CrossChainEnabledArbitrumL2Mock = artifacts.require('CrossChainEnabledArbitrumL2Mock');
const CrossChainEnabledOptimismMock = artifacts.require('CrossChainEnabledOptimismMock');
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

  describe.only('Arbitrum-L1', function () {
    beforeEach(async function () {
      this.bridge = await BridgeHelper.deploy('Arbitrum-L1');
      this.contract = await CrossChainEnabledArbitrumL1Mock.new(this.bridge.address);
    });

    it('should emit L1 to L2 retryable ticket id', async function () {
      const bridgeParameters = {
        totalL2GasCosts: 0,
        l2CallValue: 0,
        maxSubmissionCost: 10,
        excessFeeRefundAddress: randomAddress(),
        callValueRefundAddress: randomAddress(),
        maxGas: utils.parseEther('0.1'),
        gasPriceBid: 5,
      };

      const bridgeConfig = utils.defaultAbiCoder.encode(
        ['uint256', 'uint256', 'uint256', 'address', 'address', 'uint256', 'uint256'],
        [...Object.values(bridgeParameters)],
      );

      expectEvent(
        await this.contract.sendCrossChainMessage(destination, calldata, bridgeConfig),
        'RetryableTicketCreated',
      );
    });

    shouldBehaveLikeReceiver();
  });

  describe.only('Arbitrum-L2', function () {
    beforeEach(async function () {
      this.bridge = await BridgeHelper.deploy('Arbitrum-L2');
      this.contract = await CrossChainEnabledArbitrumL2Mock.new();
    });

    it('should emit L2 to L1 transaction id', async function () {
      const amountToDeposit = 0;
      const bridgeConfig = utils.defaultAbiCoder.encode(['uint256'], [amountToDeposit]);

      expectEvent(await this.contract.sendCrossChainMessage(destination, calldata, bridgeConfig), 'L2ToL1TxSubmitted');
    });

    shouldBehaveLikeReceiver();
  });

  describe.only('Optimism', function () {
    beforeEach(async function () {
      this.bridge = await BridgeHelper.deploy('Optimism');
      this.contract = await CrossChainEnabledOptimismMock.new(this.bridge.address);
    });

    it('should send cross-chain message successfuly', async function () {
      const gasLimit = utils.parseEther('0.000000000001');
      const bridgeConfig = utils.defaultAbiCoder.encode(['uint32'], [gasLimit]);

      await this.contract.sendCrossChainMessage(destination, calldata, bridgeConfig);
    });

    shouldBehaveLikeReceiver();
  });

  describe('Polygon-Child', function () {
    beforeEach(async function () {
      this.bridge = await BridgeHelper.deploy('Polygon-Child');
      this.contract = await CrossChainEnabledPolygonChildMock.new(this.bridge.address);
    });

    shouldBehaveLikeReceiver();
  });
});
