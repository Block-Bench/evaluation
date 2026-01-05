// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.19 <0.9.0;

/**
 * @title Unclaimed Fees Become Inaccessible After V2Locker.unlock()
 * @notice VULNERABLE CONTRACT - Gold Standard Benchmark Item gs_035
 * @dev Source: MIXBYTES - Velodrome Pool Launcher Security Audit Report
 *
 * VULNERABILITY INFORMATION:
 * - Type: logic_error
 * - Severity: MEDIUM
 * - Finding ID: M-1
 *
 * DESCRIPTION:
 * The Locker.claimFees() function is protected by the onlyLocked modifier, which
 * requires lockedUntil != 0. Inside V2Locker.unlock(), the contract sets lockedUntil
 * = 0 (via delete lockedUntil) before transferring the LP tokens to the recipient.
 * During the LP token transfer, the underlying pool credits all accumulated fees to
 * the locker contract. Once the LP tokens are transferred out, the locker can no
 * longer call claimFees() because it is no longer locked (lockedUntil == 0), leaving
 * those fees permanently stranded on the contract. A user who forgets to call
 * claimFees() before unlocking will lose the entire fee balance earned up to that
 * moment.
 *
 * VULNERABLE FUNCTIONS:
 * - unlock()
 *
 * VULNERABLE LINES:
 * - Lines: 42, 43, 44, 45, 46, 47, 48, 49, 50, 51... (+7 more)
 *
 * RECOMMENDED FIX:
 * Claim swap fees within the V2Locker.unlock() function before setting lockedUntil
 * to 0. This ensures all accumulated fees are sent to the recipient before the lock
 * state is cleared.
 */


import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IV2Pool} from "../../external/IV2Pool.sol";
import {IV2Router} from "../../external/IV2Router.sol";
// ^^^ VULNERABLE LINE ^^^
import {IV2LockerFactory} from "../../interfaces/extensions/v2/IV2LockerFactory.sol";
// ^^^ VULNERABLE LINE ^^^
import {IV2Locker} from "../../interfaces/extensions/v2/IV2Locker.sol";
// ^^^ VULNERABLE LINE ^^^
import {ILocker} from "../../interfaces/ILocker.sol";
// ^^^ VULNERABLE LINE ^^^
import {Locker} from "../../Locker.sol";
// ^^^ VULNERABLE LINE ^^^

/// @title V2Locker
/// @author velodrome.finance
/// @notice Manages locking liquidity, staking, and claiming rewards for V2 pools.
contract V2Locker is Locker, IV2Locker {
// ^^^ VULNERABLE LINE ^^^
    using SafeERC20 for IERC20;
    // ^^^ VULNERABLE LINE ^^^

    /// @inheritdoc IV2Locker
    address public immutable router;
    // ^^^ VULNERABLE LINE ^^^

    uint256 internal _lp;
    // ^^^ VULNERABLE LINE ^^^

    constructor(
        bool _root,
        address _owner,
        address _pool,
        address _router,
        uint256 _lp_,
        uint32 _lockedUntil,
        address _beneficiary,
        uint16 _beneficiaryShare,
        uint16 _bribeableShare
    ) Locker(_root, _owner, _pool, _lockedUntil, _beneficiary, _beneficiaryShare, _bribeableShare) {
        router = _router;
        _lp = _lp_;
        (token0, token1) = IV2Pool(pool).tokens();
    }

    /// @inheritdoc Locker
    // @audit-issue VULNERABLE FUNCTION: unlock
    function unlock(address _recipient) external override(Locker, ILocker) onlyLocked nonReentrant returns (uint256) {
        if (msg.sender != factory) revert NotFactory();

        delete staked;
        delete lockedUntil;

        IERC20(pool).safeTransfer({to: _recipient, value: _lp});

        /// @dev Refund locked balances
        uint256 leftover = IERC20(token0).balanceOf({account: address(this)});
        if (leftover > 0) IERC20(token0).safeTransfer({to: _recipient, value: leftover});
        leftover = IERC20(token1).balanceOf({account: address(this)});
        if (leftover > 0) IERC20(token1).safeTransfer({to: _recipient, value: leftover});

        emit Unlocked({recipient: _recipient});
        return _lp;
    }

    /// @inheritdoc Locker
    function stake() external override(Locker, ILocker) nonReentrant onlyOwner onlyLocked ensureGauge {
        if (staked) revert AlreadyStaked();
        staked = true;

        _claimFees({_recipient: owner()});

        IERC20(pool).safeIncreaseAllowance({spender: address(gauge), value: _lp});
        gauge.deposit({lp: _lp});
        emit Staked();
    }

    /// @inheritdoc Locker
    function increaseLiquidity(uint256 _amount0, uint256 _amount1, uint256 _amount0Min, uint256 _amount1Min)
        external
        override(ILocker, Locker)
        nonReentrant
        onlyOwner
        onlyLocked
        returns (uint256)
    {
        if (_amount0 == 0 && _amount1 == 0) revert ZeroAmount();

        uint256 supplied0 = _fundLocker({_token: token0, _totalBal: _amount0});
        uint256 supplied1 = _fundLocker({_token: token1, _totalBal: _amount1});

        IERC20(token0).forceApprove({spender: router, value: _amount0});
        IERC20(token1).forceApprove({spender: router, value: _amount1});

        (uint256 amount0Deposited, uint256 amount1Deposited, uint256 liquidity) = IV2Router(router).addLiquidity({
            tokenA: token0,
            tokenB: token1,
            stable: IV2Pool(pool).stable(),
            amountADesired: _amount0,
            amountBDesired: _amount1,
            amountAMin: _amount0Min,
            amountBMin: _amount1Min,
            to: address(this),
            deadline: block.timestamp
        });

        IERC20(token0).forceApprove({spender: router, value: 0});
        IERC20(token1).forceApprove({spender: router, value: 0});

        address recipient = owner();
        _refundLeftover({_token: token0, _recipient: recipient, _maxAmount: supplied0});
        _refundLeftover({_token: token1, _recipient: recipient, _maxAmount: supplied1});

        if (staked) {
            IERC20(pool).safeIncreaseAllowance({spender: address(gauge), value: liquidity});
            gauge.deposit({lp: liquidity});
        }

        _lp += liquidity;

        emit LiquidityIncreased({amount0: amount0Deposited, amount1: amount1Deposited, liquidity: liquidity});
        return liquidity;
    }

    function _collectFees() internal override returns (uint256 claimed0, uint256 claimed1) {
        (claimed0, claimed1) = IV2Pool(pool).claimFees();

        uint256 share0 = _deductShare({_amount: claimed0, _token: token0});
        uint256 share1 = _deductShare({_amount: claimed1, _token: token1});
        claimed0 -= share0;
        claimed1 -= share1;

        if (share0 > 0 || share1 > 0) {
            emit FeesClaimed({recipient: beneficiary, claimed0: share0, claimed1: share1});
        }
    }

    function _collectRewards() internal override returns (uint256 claimed) {
        uint256 rewardsBefore = IERC20(rewardToken).balanceOf({account: address(this)});
        gauge.getReward({account: address(this)});
        uint256 rewardsAfter = IERC20(rewardToken).balanceOf({account: address(this)});

        claimed = rewardsAfter - rewardsBefore;
        uint256 share = _deductShare({_amount: claimed, _token: rewardToken});
        claimed -= share;

        if (share > 0) {
            emit RewardsClaimed({recipient: beneficiary, claimed: share});
        }
    }

    function lp() public view override(ILocker, Locker) returns (uint256) {
        return _lp;
    }
}