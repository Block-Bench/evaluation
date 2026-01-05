// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title Signed swap digest lacks a domain separator
 * @notice VULNERABLE CONTRACT - Gold Standard Benchmark Item gs_021
 * @dev Source: SPEARBIT - Uniswap Foundation: Kyber Hook Security Review
 *
 * VULNERABILITY INFORMATION:
 * - Type: signature_replay
 * - Severity: MEDIUM
 * - Finding ID: M-01
 *
 * DESCRIPTION:
 * Both UniswapV4KEMHook and PancakeSwapInfinityKEMHook rebuild a quote digest by
 * hashing sender, key, params.zeroForOne, maxAmountIn, maxExchangeRate,
 * exchangeRateDenom, nonce, and expiryTime. The tuple ties the authorization to the
 * router (sender), the full PoolKey (which includes the hook address), trade
 * direction, price and input caps, nonce and expiry. Crucially, no domain separator
 * is folded in: chain ID, deployment salt, and contract identity outside key are
 * absent. If the same hook instance (or the same PoolKey) is deployed on multiple
 * networks, as CREATE3-based salt mining allows, an attacker can lift any valid
 * signature+nonce from chain A and replay it on chain B. Because the digest matches,
 * SignatureChecker.isValidSignatureNow succeeds and the swap executes without the
 * signer's intention. That breaks the core guarantee that signed quotes are
 * single-instance authorizations, allowing cross-chain replay swaps.
 *
 * VULNERABLE FUNCTIONS:
 * - beforeSwap()
 *
 * VULNERABLE LINES:
 * - Lines: 118, 119, 120, 121, 122, 123, 124, 125, 126, 127... (+2 more)
 *
 * RECOMMENDED FIX:
 * Introduce domain separation for the signed payload in both hooks. Adopt an EIP712
 * domain that at minimum commits to chainid. This ensures signatures are only valid
 * on the intended chain.
 */


import {BaseKEMHook} from './base/BaseKEMHook.sol';
import {IKEMHook} from './interfaces/IKEMHook.sol';
import {HookDataDecoder} from './libraries/HookDataDecoder.sol';

import {IHooks} from 'uniswap/v4-core/src/interfaces/IHooks.sol';
import {IPoolManager} from 'uniswap/v4-core/src/interfaces/IPoolManager.sol';
import {IUnlockCallback} from 'uniswap/v4-core/src/interfaces/callback/IUnlockCallback.sol';
import {Hooks} from 'uniswap/v4-core/src/libraries/Hooks.sol';

import {BalanceDelta, toBalanceDelta} from 'uniswap/v4-core/src/types/BalanceDelta.sol';
import {
  BeforeSwapDelta, BeforeSwapDeltaLibrary
} from 'uniswap/v4-core/src/types/BeforeSwapDelta.sol';
import {Currency} from 'uniswap/v4-core/src/types/Currency.sol';
import {PoolId} from 'uniswap/v4-core/src/types/PoolId.sol';
import {PoolKey} from 'uniswap/v4-core/src/types/PoolKey.sol';

import {SignatureChecker} from
  'openzeppelin-contracts/contracts/utils/cryptography/SignatureChecker.sol';

/// @title UniswapV4KEMHook
contract UniswapV4KEMHook is BaseKEMHook, IUnlockCallback {
  /// @notice Thrown when the caller is not PoolManager
  error NotPoolManager();

  /// @notice The address of the PoolManager contract
  IPoolManager public immutable poolManager;

  constructor(
    IPoolManager _poolManager,
    address initialOwner,
    address[] memory initialClaimableAccounts,
    address initialQuoteSigner,
    address initialEgRecipient
  ) BaseKEMHook(initialOwner, initialClaimableAccounts, initialQuoteSigner, initialEgRecipient) {
    poolManager = _poolManager;
    Hooks.validateHookPermissions(IHooks(address(this)), getHookPermissions());
  }

  /// @notice Only allow calls from the PoolManager contract
  modifier onlyPoolManager() {
    if (msg.sender != address(poolManager)) revert NotPoolManager();
    _;
  }

  /// @inheritdoc IKEMHook
  function claimEgTokens(address[] calldata tokens, uint256[] calldata amounts) public {
    require(claimable[msg.sender], NonClaimableAccount(msg.sender));
    require(tokens.length == amounts.length, MismatchedArrayLengths());

    poolManager.unlock(abi.encode(tokens, amounts));
  }

  function unlockCallback(bytes calldata data) public onlyPoolManager returns (bytes memory) {
    (address[] memory tokens, uint256[] memory amounts) = abi.decode(data, (address[], uint256[]));

    for (uint256 i = 0; i < tokens.length; i++) {
      uint256 id = uint256(uint160(tokens[i]));
      if (amounts[i] == 0) {
        amounts[i] = poolManager.balanceOf(address(this), id);
      }
      if (amounts[i] > 0) {
        poolManager.burn(address(this), id, amounts[i]);
        poolManager.take(Currency.wrap(tokens[i]), egRecipient, amounts[i]);
      }
    }

    emit ClaimEgTokens(egRecipient, tokens, amounts);
  }

  function getHookPermissions() public pure returns (Hooks.Permissions memory) {
    return Hooks.Permissions({
      beforeInitialize: false,
      afterInitialize: false,
      beforeAddLiquidity: false,
      afterAddLiquidity: false,
      beforeRemoveLiquidity: false,
      afterRemoveLiquidity: false,
      // ^^^ VULNERABLE LINE ^^^
      beforeSwap: true,
      // ^^^ VULNERABLE LINE ^^^
      afterSwap: true,
      // ^^^ VULNERABLE LINE ^^^
      beforeDonate: false,
      // ^^^ VULNERABLE LINE ^^^
      afterDonate: false,
      // ^^^ VULNERABLE LINE ^^^
      beforeSwapReturnDelta: false,
      // ^^^ VULNERABLE LINE ^^^
      afterSwapReturnDelta: true,
      // ^^^ VULNERABLE LINE ^^^
      afterAddLiquidityReturnDelta: false,
      // ^^^ VULNERABLE LINE ^^^
      afterRemoveLiquidityReturnDelta: false
      // ^^^ VULNERABLE LINE ^^^
    });
    // ^^^ VULNERABLE LINE ^^^
  }
  // ^^^ VULNERABLE LINE ^^^

    // @audit-issue VULNERABLE FUNCTION: beforeSwap
  function beforeSwap(
    address sender,
    PoolKey calldata key,
    IPoolManager.SwapParams calldata params,
    bytes calldata hookData
  ) external onlyPoolManager returns (bytes4, BeforeSwapDelta, uint24) {
    require(params.amountSpecified < 0, ExactOutputDisabled());

    (
      int256 maxAmountIn,
      int256 maxExchangeRate,
      int256 exchangeRateDenom,
      uint256 nonce,
      uint256 expiryTime,
      bytes memory signature
    ) = HookDataDecoder.decodeAllHookData(hookData);

    require(block.timestamp <= expiryTime, ExpiredSignature(expiryTime, block.timestamp));
    require(
      -params.amountSpecified <= maxAmountIn,
      ExceededMaxAmountIn(maxAmountIn, -params.amountSpecified)
    );

    _useUnorderedNonce(nonce);

    bytes32 digest = keccak256(
      abi.encode(
        sender,
        key,
        params.zeroForOne,
        maxAmountIn,
        maxExchangeRate,
        exchangeRateDenom,
        nonce,
        expiryTime
      )
    );
    require(
      SignatureChecker.isValidSignatureNow(quoteSigner, digest, signature), InvalidSignature()
    );

    return (this.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
  }

  function afterSwap(
    address,
    PoolKey calldata key,
    IPoolManager.SwapParams calldata params,
    BalanceDelta delta,
    bytes calldata hookData
  ) external onlyPoolManager returns (bytes4, int128) {
    (int256 maxExchangeRate, int256 exchangeRateDenom) =
      HookDataDecoder.decodeExchangeRate(hookData);

    int128 amountIn;
    int128 amountOut;
    Currency currencyOut;
    unchecked {
      if (params.zeroForOne) {
        amountIn = -delta.amount0();
        amountOut = delta.amount1();
        currencyOut = key.currency1;
      } else {
        amountIn = -delta.amount1();
        amountOut = delta.amount0();
        currencyOut = key.currency0;
      }
    }

    int256 maxAmountOut = amountIn * maxExchangeRate / exchangeRateDenom;

    unchecked {
      int256 egAmount = maxAmountOut < amountOut ? amountOut - maxAmountOut : int256(0);
      if (egAmount > 0) {
        poolManager.mint(
          address(this), uint256(uint160(Currency.unwrap(currencyOut))), uint256(egAmount)
        );

        emit AbsorbEgToken(PoolId.unwrap(key.toId()), Currency.unwrap(currencyOut), egAmount);
      }

      return (this.afterSwap.selector, int128(egAmount));
    }
  }
}