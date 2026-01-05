// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

/**
 * @title Lack of SafeERC20 can inflate user balance
 * @notice VULNERABLE CONTRACT - Gold Standard Benchmark Item gs_013
 * @dev Source: SPEARBIT - Aragon DAO Gov Plugin Security Review
 *
 * VULNERABILITY INFORMATION:
 * - Type: unchecked_return
 * - Severity: MEDIUM
 * - Finding ID: M-01
 *
 * DESCRIPTION:
 * If the erc20Token configured within LockManagerERC20 is a token that does not
 * revert due to insufficient approved funds, the msg.sender can inflate their
 * lockedBalances[msg.sender] by an arbitrary _amount without actually sending any
 * token. The vulnerable code is at lines 35-37 (_doLockTransfer) and lines 40-42
 * (_doUnlockTransfer) which use raw transferFrom() and transfer() instead of
 * safeTransferFrom() and safeTransfer(). Some ERC20 tokens like BAT, HT, cUSDC, ZRX
 * do not revert when a transfer fails but instead return false.
 *
 * VULNERABLE FUNCTIONS:
 * - _doLockTransfer()
 * - _doUnlockTransfer()
 *
 * VULNERABLE LINES:
 * - Lines: 35, 36, 37, 40, 41, 42
 *
 * ATTACK SCENARIO:
 * 1. Attacker specifies an arbitrary _amount without having ever given any approva
 * 2. erc20Token.transferFrom() returns false but doesn't revert.
 * 3. The return value is not checked.
 * 4. lockedBalances[msg.sender] += _amount still executes.
 * 5. Attacker gains unlimited voting power.
 *
 * RECOMMENDED FIX:
 * Use SafeERC20 across all contracts that interact with an ERC20 token. Replace
 * erc20Token.transferFrom() with erc20Token.safeTransferFrom() and
 * erc20Token.transfer() with erc20Token.safeTransfer().
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
    function _incomingTokenBalance() internal view virtual override returns (uint256) {
        return erc20Token.allowance(msg.sender, address(this));
    }

    /// @inheritdoc LockManagerBase
    // @audit-issue VULNERABLE FUNCTION: _doLockTransfer
    function _doLockTransfer(uint256 _amount) internal virtual override {
        erc20Token.transferFrom(msg.sender, address(this), _amount);
    }

    /// @inheritdoc LockManagerBase
    // @audit-issue VULNERABLE FUNCTION: _doUnlockTransfer
    function _doUnlockTransfer(address _recipient, uint256 _amount) internal virtual override {
        erc20Token.transfer(_recipient, _amount);
    }
}
