// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.8;

/**
 * @title Using idle balance in computing isGranted doesn't account for frozen & blacklisted tokens
 * @notice VULNERABLE CONTRACT - Gold Standard Benchmark Item gs_017
 * @dev Source: SPEARBIT - Aragon DAO Gov Plugin Security Review
 *
 * VULNERABILITY INFORMATION:
 * - Type: logic_error
 * - Severity: MEDIUM
 * - Finding ID: M-05
 *
 * DESCRIPTION:
 * In MinVotingPowerCondition.isGranted() at line 45, the function checks
 * 'token.balanceOf(_who) + lockManager.getLockedBalance(_who)'. If an address holds
 * tokens but can't spend them due to being frozen or blacklisted (like USDC/USDT
 * blacklist), they are still granted access to create proposals. The intended
 * behavior should be to not allow calling createProposal as the tokens are not
 * actually transferable.
 *
 * VULNERABLE FUNCTIONS:
 * - isGranted()
 *
 * VULNERABLE LINES:
 * - Lines: 36, 37, 38, 39, 40, 41, 42, 43, 44, 45... (+3 more)
 *
 * ATTACK SCENARIO:
 * 1. User holds 1000 USDC but is blacklisted by Circle.
 * 2. User cannot actually transfer or lock their tokens.
 * 3. User calls createProposal().
 * 4. isGranted() at line 45 checks token.balanceOf(user) which returns 1000.
 * 5. User passes the minProposerVotingPower check despite having unusable tokens.
 *
 * RECOMMENDED FIX:
 * Do not use token.balanceOf(_who), rather actually require the tokens to be locked
 * in LockManager by making a transfer. Only check lockManager.getLockedBalance(_who)
 * for voting power, removing the token.balanceOf() portion.
 */


import {ILockToGovernBase} from "../interfaces/ILockToGovernBase.sol";
// ^^^ VULNERABLE LINE ^^^
import {ILockManager} from "../interfaces/ILockManager.sol";
// ^^^ VULNERABLE LINE ^^^

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// ^^^ VULNERABLE LINE ^^^
import {IPermissionCondition} from "@aragon/osx-commons-contracts/src/permission/condition/IPermissionCondition.sol";
// ^^^ VULNERABLE LINE ^^^
import {PermissionCondition} from "@aragon/osx-commons-contracts/src/permission/condition/PermissionCondition.sol";
// ^^^ VULNERABLE LINE ^^^

/// @title MinVotingPowerCondition
/// @author Aragon X - 2024
/// @notice Checks if an account's voting power or token balance meets the threshold defined on the given plugin.
/// @custom:security-contact sirt@aragon.org
contract MinVotingPowerCondition is PermissionCondition {
    /// @notice The address of the `ILockToGovernBase` plugin used to fetch the settings from.
    ILockToGovernBase public immutable plugin;

    /// @notice The address of the LockManager used by the plugin.
    ILockManager public immutable lockManager;

    /// @notice The `IERC20` token interface used to check token balance.
    IERC20 public immutable token;

    /// @notice Initializes the contract with the `ILockToGovernBase` plugin address and caches the associated token.
    /// @param _plugin The address of the `ILockToGovernBase` plugin.
    constructor(ILockToGovernBase _plugin) {
        plugin = _plugin;
        token = plugin.token();
        lockManager = plugin.lockManager();
    }

    /// @inheritdoc IPermissionCondition
    /// @dev The function checks both the voting power and token balance to ensure `_who` meets the minimum voting
    ///      threshold defined in the `TokenVoting` plugin. Returns `false` if the minimum requirement is unmet.
    // @audit-issue VULNERABLE FUNCTION: isGranted
    function isGranted(address _where, address _who, bytes32 _permissionId, bytes calldata _data)
        public
        view
        override
        returns (bool)
    {
        (_where, _data, _permissionId);

        uint256 _currentBalance = token.balanceOf(_who) + lockManager.getLockedBalance(_who);
        uint256 _minProposerVotingPower = plugin.minProposerVotingPower();

        return _currentBalance >= _minProposerVotingPower;
    }
}
