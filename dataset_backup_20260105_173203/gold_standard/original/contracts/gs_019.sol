// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.23;

/**
 * @title withdrawPhantomToken May Withdraw an Unexpected Underlying
 * @notice VULNERABLE CONTRACT - Gold Standard Benchmark Item gs_020
 * @dev Source: MIXBYTES - Gearbox Midas Integration Security Audit Report
 *
 * VULNERABILITY INFORMATION:
 * - Type: input_validation
 * - Severity: MEDIUM
 * - Finding ID: M-01
 *
 * DESCRIPTION:
 * MidasRedemptionVaultAdapter.withdrawPhantomToken(token, amount) only checks that a
 * phantom token is registered for the given token address
 * (phantomTokenToOutputToken[token] != address(0)) and does not verify that the
 * pending redemption's tokenOut matches the expected underlying. This means the
 * integration may receive a different token than expected if the redemption request
 * was made for a different output token than what the phantom token tracks.
 *
 * VULNERABLE FUNCTIONS:
 * - withdrawPhantomToken()
 *
 * VULNERABLE LINES:
 * - Lines: 140, 141, 142, 143, 144
 *
 * RECOMMENDED FIX:
 * Add validation in setTokenAllowedStatusBatch() to ensure that the phantom token's
 * tokenOut matches the output token it was added alongside with. This prevents
 * mismatched phantom token configurations.
 */


import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {AbstractAdapter} from "../AbstractAdapter.sol";
import {NotImplementedException} from "@gearbox-protocol/core-v3/contracts/interfaces/IExceptions.sol";

import {IMidasRedemptionVault} from "../../integrations/midas/IMidasRedemptionVault.sol";
import {IMidasRedemptionVaultAdapter} from "../../interfaces/midas/IMidasRedemptionVaultAdapter.sol";
import {IMidasRedemptionVaultGateway} from "../../interfaces/midas/IMidasRedemptionVaultGateway.sol";

import {WAD, RAY} from "@gearbox-protocol/core-v3/contracts/libraries/Constants.sol";

/// @title Midas Redemption Vault adapter
/// @notice Implements logic for interacting with the Midas Redemption Vault through a gateway
contract MidasRedemptionVaultAdapter is AbstractAdapter, IMidasRedemptionVaultAdapter {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant override contractType = "ADAPTER::MIDAS_REDEMPTION_VAULT";
    uint256 public constant override version = 3_10;

    /// @notice mToken
    address public immutable override mToken;

    /// @notice Gateway address
    address public immutable override gateway;

    /// @notice Mapping from phantom token to its tracked output token
    mapping(address => address) public phantomTokenToOutputToken;

    /// @notice Mapping from output token to its tracked phantom token
    mapping(address => address) public outputTokenToPhantomToken;

    /// @dev Set of allowed output tokens for redemptions
    EnumerableSet.AddressSet internal _allowedTokens;

    /// @notice Constructor
    /// @param _creditManager Credit manager address
    /// @param _gateway Midas Redemption Vault gateway address
    constructor(address _creditManager, address _gateway) AbstractAdapter(_creditManager, _gateway) {
        gateway = _gateway;
        mToken = IMidasRedemptionVaultGateway(_gateway).mToken();

        _getMaskOrRevert(mToken);
    }

    /// @notice Instantly redeems mToken for output token
    /// @param tokenOut Output token address
    /// @param amountMTokenIn Amount of mToken to redeem
    /// @param minReceiveAmount Minimum amount of output token to receive
    function redeemInstant(address tokenOut, uint256 amountMTokenIn, uint256 minReceiveAmount)
        external
        override
        creditFacadeOnly
        returns (bool)
    {
        if (!isTokenAllowed(tokenOut)) revert TokenNotAllowedException();

        _redeemInstant(tokenOut, amountMTokenIn, minReceiveAmount);

        return false;
    }

    /// @notice Instantly redeems the entire balance of mToken for output token, except the specified amount
    /// @param tokenOut Output token address
    /// @param leftoverAmount Amount of mToken to keep in the account
    /// @param rateMinRAY Minimum exchange rate from input token to mToken (in RAY format)
    function redeemInstantDiff(address tokenOut, uint256 leftoverAmount, uint256 rateMinRAY)
        external
        override
        creditFacadeOnly
        returns (bool)
    {
        if (!isTokenAllowed(tokenOut)) revert TokenNotAllowedException();

        address creditAccount = _creditAccount();

        uint256 balance = IERC20(mToken).balanceOf(creditAccount);
        if (balance > leftoverAmount) {
            unchecked {
                uint256 amount = balance - leftoverAmount;
                uint256 minReceiveAmount = (amount * rateMinRAY) / RAY;
                _redeemInstant(tokenOut, amount, minReceiveAmount);
            }
        }
        return false;
    }

    /// @dev Internal implementation of redeemInstant
    function _redeemInstant(address tokenOut, uint256 amountMTokenIn, uint256 minReceiveAmount) internal {
        _executeSwapSafeApprove(
            mToken,
            abi.encodeCall(
                IMidasRedemptionVaultGateway.redeemInstant,
                (tokenOut, amountMTokenIn, _convertToE18(minReceiveAmount, tokenOut))
            )
        );
    }

    /// @notice Requests a redemption of mToken for output token
    /// @param tokenOut Output token address
    /// @param amountMTokenIn Amount of mToken to redeem
    /// @dev Returns `true` to allow safe pricing for the withdrawal phantom token
    function redeemRequest(address tokenOut, uint256 amountMTokenIn)
    // ^^^ VULNERABLE LINE ^^^
        external
        // ^^^ VULNERABLE LINE ^^^
        override
        // ^^^ VULNERABLE LINE ^^^
        creditFacadeOnly
        // ^^^ VULNERABLE LINE ^^^
        returns (bool)
        // ^^^ VULNERABLE LINE ^^^
    {
        if (!isTokenAllowed(tokenOut) || outputTokenToPhantomToken[tokenOut] == address(0)) {
            revert TokenNotAllowedException();
        }

        _executeSwapSafeApprove(
            mToken, abi.encodeCall(IMidasRedemptionVaultGateway.requestRedeem, (tokenOut, amountMTokenIn))
        );
        return true;
    }

    /// @notice Withdraws redeemed tokens from the gateway
    /// @param amount Amount to withdraw
    function withdraw(uint256 amount) external override creditFacadeOnly returns (bool) {
        _withdraw(amount);
        return false;
    }

    /// @dev Internal implementation of withdraw
    function _withdraw(uint256 amount) internal {
        _execute(abi.encodeCall(IMidasRedemptionVaultGateway.withdraw, (amount)));
    }

    /// @notice Withdraws phantom token balance
    /// @param token Phantom token address
    /// @param amount Amount to withdraw
    // @audit-issue VULNERABLE FUNCTION: withdrawPhantomToken
    function withdrawPhantomToken(address token, uint256 amount) external override creditFacadeOnly returns (bool) {
        if (phantomTokenToOutputToken[token] == address(0)) revert IncorrectStakedPhantomTokenException();
        _withdraw(amount);
        return false;
    }

    /// @notice Deposits phantom token (not implemented for redemption vaults)
    /// @return Never returns (always reverts)
    /// @dev Redemption vaults only support withdrawals, not deposits
    function depositPhantomToken(address, uint256) external pure override returns (bool) {
        revert NotImplementedException();
    }

    /// @dev Converts the token amount to 18 decimals, which is accepted by Midas
    function _convertToE18(uint256 amount, address token) internal view returns (uint256) {
        uint256 tokenUnit = 10 ** IERC20Metadata(token).decimals();
        return amount * WAD / tokenUnit;
    }

    /// @notice Returns whether a token is allowed as output for redemptions
    /// @param token Token address to check
    /// @return True if token is allowed
    function isTokenAllowed(address token) public view override returns (bool) {
        return _allowedTokens.contains(token);
    }

    /// @notice Returns all allowed output tokens
    /// @return Array of allowed token addresses
    function allowedTokens() public view override returns (address[] memory) {
        return _allowedTokens.values();
    }

    /// @notice Sets the allowed status for a batch of output tokens
    /// @param configs Array of MidasAllowedTokenStatus structs
    /// @dev Can only be called by the configurator
    function setTokenAllowedStatusBatch(MidasAllowedTokenStatus[] calldata configs)
        external
        override
        configuratorOnly
    {
        uint256 len = configs.length;

        for (uint256 i; i < len; ++i) {
            MidasAllowedTokenStatus memory config = configs[i];

            if (config.allowed) {
                _getMaskOrRevert(config.token);
                _allowedTokens.add(config.token);

                if (config.phantomToken != address(0)) {
                    _getMaskOrRevert(config.phantomToken);
                    phantomTokenToOutputToken[config.phantomToken] = config.token;
                    outputTokenToPhantomToken[config.token] = config.phantomToken;
                }
            } else {
                _allowedTokens.remove(config.token);

                address phantomToken = outputTokenToPhantomToken[config.token];

                if (phantomToken != address(0)) {
                    delete outputTokenToPhantomToken[config.token];
                    delete phantomTokenToOutputToken[phantomToken];
                }
            }

            emit SetTokenAllowedStatus(config.token, config.phantomToken, config.allowed);
        }
    }

    /// @notice Serialized adapter parameters
    /// @return serializedData Encoded adapter configuration
    function serialize() external view returns (bytes memory serializedData) {
        serializedData = abi.encode(creditManager, targetContract, gateway, mToken, allowedTokens());
    }
}