// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.8;

/**
 * @title MinVotingPowerCondition logic can be bypassed via flashloans
 * @notice VULNERABLE CONTRACT - Gold Standard Benchmark Item gs_011
 * @dev Source: SPEARBIT - Aragon DAO Gov Plugin Security Review
 *
 * VULNERABILITY INFORMATION:
 * - Type: flash_loan
 * - Severity: HIGH
 * - Finding ID: H-01
 *
 * DESCRIPTION:
 * The MinVotingPowerCondition contract allows any users who hold at least
 * plugin.minProposerVotingPower() amount of tokens (locked in the LockManager or in
 * their token balance) to create a proposal and execute LockToVote.createProposal.
 * This logic can be easily bypassed if the token allows flashloan or flashmint.
 * Given that isGranted checks the user's token balance (line 45:
 * token.balanceOf(_who) + lockManager.getLockedBalance(_who)), the user does not
 * even need to lock the flashloaned amount into the LockManager to be able to create
 * and spam proposals.
 *
 * VULNERABLE FUNCTIONS:
 * - isGranted()
 *
 * VULNERABLE LINES:
 * - Lines: 36, 37, 38, 39, 40, 41, 42, 43, 44, 45... (+3 more)
 *
 * ATTACK SCENARIO:
 * 1. Flashloan the token.
 * 2. Create the proposal (isGranted passes because token.balanceOf includes flashl
 * 3. Lock + vote the proposal and auto-execute it (EarlyExecution).
 * 4. Unlock the tokens.
 * 5. Repay the flashloan.
 *
 * RECOMMENDED FIX:
 * Avoid using the token's balance and require the user to only use the locked
 * amount. Change line 45 from 'token.balanceOf(_who) +
 * lockManager.getLockedBalance(_who)' to just 'lockManager.getLockedBalance(_who)'.
 * Store the proposal's creator in the proposal struct and require that the locked
 * amount required to create the proposal won't be unlockable until the proposal
 * ...
 */


import {ILockToGovernBase} from "../interfaces/ILockToGovernBase.sol";
// ^^^ VULNERABLE LINE ^^^
import {ILockManager} from "../interfaces/ILockManager.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPermissionCondition} from "@aragon/osx-commons-contracts/src/permission/condition/IPermissionCondition.sol";
import {PermissionCondition} from "@aragon/osx-commons-contracts/src/permission/condition/PermissionCondition.sol";

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
