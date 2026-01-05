// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

/**
 * @title Lock fails for unlimited approvals
 * @notice VULNERABLE CONTRACT - Gold Standard Benchmark Item gs_014
 * @dev Source: SPEARBIT - Aragon DAO Gov Plugin Security Review
 *
 * VULNERABILITY INFORMATION:
 * - Type: logic_error
 * - Severity: MEDIUM
 * - Finding ID: M-02
 *
 * DESCRIPTION:
 * The lock() function intends to lock the user's entire approved balance, but this
 * will fail for the most common case: Most users give contracts they interact with
 * an unlimited allowance by setting it to type(uint256).max. The
 * _incomingTokenBalance() function at line 32 returns just
 * 'erc20Token.allowance(msg.sender, address(this))' which would be type(uint256).max
 * for unlimited approvals. The lock() function then attempts to transfer this
 * impossible amount.
 *
 * VULNERABLE FUNCTIONS:
 * - _incomingTokenBalance()
 *
 * VULNERABLE LINES:
 * - Lines: 31, 32, 33
 *
 * ATTACK SCENARIO:
 * 1. User approves LockManager with unlimited allowance: approve(lockManager, type
 * 2. User calls lock() without specifying an amount.
 * 3. _incomingTokenBalance() returns type(uint256).max.
 * 4. _doLockTransfer attempts to transfer type(uint256).max tokens.
 * 5. Transaction reverts because user doesn't have that many tokens.
 *
 * RECOMMENDED FIX:
 * Have _incomingTokenBalance() return either the actual balance or the allowance
 * depending on whichever is smallest: 'return (allowance >= balance) ? balance :
 * allowance;'
 */


import {LockManagerBase} from "./base/LockManagerBase.sol";
import {ILockManager} from "./interfaces/ILockManager.sol";
import {LockManagerSettings} from "./interfaces/ILockManager.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title LockManagerERC20
/// @author Aragon X 2025
/// @notice Helper contract acting as the vault for locked tokens used to vote on multiple plugins and proposals.
contract LockManagerERC20 is ILockManager, LockManagerBase {
    /// @notice The address of the token contract used to determine the voting power
    IERC20 private immutable erc20Token;

    /// @param _settings The operation mode of the contract (plugin mode)
    /// @param _token The address of the token contract that users can lock
    constructor(LockManagerSettings memory _settings, IERC20 _token) LockManagerBase(_settings) {
        erc20Token = _token;
    }

    /// @inheritdoc ILockManager
    /// @dev Not having `token` as a public variable because the return types would differ (address vs IERC20)
    function token() public view virtual returns (address _token) {
        return address(erc20Token);
    }

    // Overrides

    /// @inheritdoc LockManagerBase
    // @audit-issue VULNERABLE FUNCTION: _incomingTokenBalance
    function _incomingTokenBalance() internal view virtual override returns (uint256) {
        return erc20Token.allowance(msg.sender, address(this));
    }

    /// @inheritdoc LockManagerBase
    function _doLockTransfer(uint256 _amount) internal virtual override {
        erc20Token.transferFrom(msg.sender, address(this), _amount);
    }

    /// @inheritdoc LockManagerBase
    function _doUnlockTransfer(address _recipient, uint256 _amount) internal virtual override {
        erc20Token.transfer(_recipient, _amount);
    }
}
