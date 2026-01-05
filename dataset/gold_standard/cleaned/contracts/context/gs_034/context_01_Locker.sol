// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.19 <0.9.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IVoter} from "./external/IVoter.sol";
import {IVotingEscrow} from "./external/IVotingEscrow.sol";
import {IGauge} from "./external/IGauge.sol";
import {IBribeVotingReward} from "./external/IBribeVotingReward.sol";
import {ILockerFactory} from "./interfaces/ILockerFactory.sol";
import {ILocker} from "./interfaces/ILocker.sol";

/// @title Locker
/// @author velodrome.finance
/// @notice Manages locking liquidity, staking, and claiming rewards
abstract contract Locker is ILocker, Ownable, ReentrancyGuardTransient {
    using SafeERC20 for IERC20;

    /// @inheritdoc ILocker
    uint256 public constant MAX_BPS = 10_000;

    /// @inheritdoc ILocker
    uint256 public constant BASE_CHAIN_ID = 8453;

    /// @inheritdoc ILocker
    IVoter public immutable voter;
    /// @inheritdoc ILocker
    address public immutable factory;
    /// @inheritdoc ILocker
    ILockerFactory.PoolType public immutable poolType;

    /// @inheritdoc ILocker
    address public immutable pool;
    /// @inheritdoc ILocker
    address public immutable token0;
    /// @inheritdoc ILocker
    address public immutable token1;
    /// @inheritdoc ILocker
    address public immutable rewardToken;
    /// @inheritdoc ILocker
    address public immutable beneficiary;
    /// @inheritdoc ILocker
    uint16 public immutable beneficiaryShare;
    /// @inheritdoc ILocker
    bool public immutable root;

    /// @inheritdoc ILocker
    IGauge public gauge;
    /// @inheritdoc ILocker
    uint16 public bribeableShare;
    /// @inheritdoc ILocker
    uint32 public lockedUntil;
    /// @inheritdoc ILocker
    bool public staked;

    constructor(
        bool _root,
        address _owner,
        address _pool,
        uint32 _lockedUntil,
        address _beneficiary,
        uint16 _beneficiaryShare,
        uint16 _bribeableShare
    ) Ownable(_owner) {
        factory = msg.sender;
        voter = IVoter(ILockerFactory(factory).voter());
        rewardToken = IVotingEscrow(voter.ve()).token();
        poolType = ILockerFactory(factory).poolType();

        root = _root;
        pool = _pool;
        lockedUntil = _lockedUntil;

        beneficiary = _beneficiary;
        beneficiaryShare = _beneficiaryShare;
        bribeableShare = _bribeableShare;
    }

    modifier onlyLocked() {
        if (lockedUntil == 0) revert NotLocked();
        _;
    }

    modifier ensureGauge() {
        if (address(gauge) == address(0)) {
            address _gauge = voter.gauges({pool: pool});
            if (_gauge == address(0)) revert NoGauge();
            gauge = IGauge(_gauge);
        }
        _;
    }

    /// @inheritdoc ILocker
    function unlock(address _recipient) external virtual returns (uint256);

    /// @inheritdoc ILocker
    function stake() external virtual;

    /// @inheritdoc ILocker
    function unstake() external nonReentrant onlyOwner onlyLocked {
        if (!staked) revert NotStaked();
        delete staked;

        _claimRewards({_recipient: owner()});
        IGauge(gauge).withdraw({lp: lp()});
        emit Unstaked();
    }

    /// @inheritdoc ILocker
    function claimFees(address _recipient)
        public
        onlyOwner
        onlyLocked
        nonReentrant
        returns (uint256 claimed0, uint256 claimed1)
    {
        if (staked) revert LockerStaked();
        return _claimFees({_recipient: _recipient});
    }

    /// @inheritdoc ILocker
    function claimRewards(address _recipient) external onlyOwner onlyLocked nonReentrant returns (uint256 claimed) {
        if (!staked) revert NotStaked();

        return _claimRewards({_recipient: _recipient});
    }

    /// @inheritdoc ILocker
    function bribe(uint16 _percentage) external onlyOwner onlyLocked ensureGauge nonReentrant {
        if (_percentage > bribeableShare) revert InvalidPercentage();

        address briber = root || block.chainid == BASE_CHAIN_ID
            ? voter.gaugeToBribe({gauge: address(gauge)})
            : voter.gaugeToIncentive({gauge: address(gauge)});

        if (staked) {
            uint256 claimed = _collectRewards();
            uint256 bribeAmount = _calculatePercentage({_amount: claimed, _percentage: _percentage});

            _bribe({_briber: briber, _token: rewardToken, _amount: bribeAmount});
            /// @dev msg.sender is the owner
            IERC20(rewardToken).safeTransfer({to: msg.sender, value: claimed - bribeAmount});
        } else {
            (uint256 claimed0, uint256 claimed1) = _collectFees();
            uint256 bribeAmount0 = _calculatePercentage({_amount: claimed0, _percentage: _percentage});
            uint256 bribeAmount1 = _calculatePercentage({_amount: claimed1, _percentage: _percentage});

            if (bribeAmount0 > 0) {
                _bribe({_briber: briber, _token: token0, _amount: bribeAmount0});
                IERC20(token0).safeTransfer({to: msg.sender, value: claimed0 - bribeAmount0});
            }
            if (bribeAmount1 > 0) {
                _bribe({_briber: briber, _token: token1, _amount: bribeAmount1});
                IERC20(token1).safeTransfer({to: msg.sender, value: claimed1 - bribeAmount1});
            }
        }
    }

    /// @inheritdoc ILocker
    function increaseDuration(uint32 _duration) external onlyOwner nonReentrant {
        if (_duration == 0) revert ZeroDuration();
        uint32 _lockedUntil = lockedUntil;
        if (block.timestamp >= _lockedUntil) revert NotLocked();
        if (_lockedUntil == type(uint32).max) revert PermanentLock();

        _lockedUntil = _duration == type(uint32).max ? type(uint32).max : _lockedUntil + _duration;
        lockedUntil = _lockedUntil;
        emit UnlockTimestampIncreased({newUnlockTimestamp: _lockedUntil});
    }

    /// @inheritdoc ILocker
    function increaseLiquidity(uint256 _amount0, uint256 _amount1, uint256 _amount0Min, uint256 _amount1Min)
        external
        virtual
        returns (uint256);

    /// @inheritdoc ILocker
    function setBribeableShare(uint16 _bribeableShare) external onlyOwner nonReentrant {
        if (_bribeableShare > MAX_BPS) revert InvalidBribeableShare();
        bribeableShare = _bribeableShare;
        emit BribeableShareSet({newBribeableShare: _bribeableShare});
    }

    function _claimFees(address _recipient) internal returns (uint256 claimed0, uint256 claimed1) {
        (claimed0, claimed1) = _collectFees();

        IERC20(token0).safeTransfer({to: _recipient, value: claimed0});
        IERC20(token1).safeTransfer({to: _recipient, value: claimed1});

        emit FeesClaimed({recipient: _recipient, claimed0: claimed0, claimed1: claimed1});
    }

    function _collectFees() internal virtual returns (uint256 claimed0, uint256 claimed1);

    function _claimRewards(address _recipient) internal returns (uint256 claimed) {
        claimed = _collectRewards();

        if (claimed > 0) {
            IERC20(rewardToken).safeTransfer({to: _recipient, value: claimed});
            emit RewardsClaimed({recipient: _recipient, claimed: claimed});
        }
    }

    function _collectRewards() internal virtual returns (uint256 claimed);

    function _bribe(address _briber, address _token, uint256 _amount) private {
        IERC20(_token).safeIncreaseAllowance({spender: _briber, value: _amount});
        IBribeVotingReward(_briber).notifyRewardAmount({token: _token, amount: _amount});
        emit Bribed({pool: pool, token: _token, amount: _amount});
    }

    function _deductShare(uint256 _amount, address _token) internal returns (uint256 share) {
        if (beneficiary == address(0)) return 0;

        share = _calculatePercentage({_amount: _amount, _percentage: beneficiaryShare});

        if (share > 0) {
            IERC20(_token).safeTransfer({to: beneficiary, value: share});
        }
    }

    function _calculatePercentage(uint256 _amount, uint16 _percentage) private pure returns (uint256) {
        return (_amount * _percentage) / MAX_BPS;
    }

    /**
     * @notice Funds up to a specified balance
     * @dev Used to fund liquidity deposits
     * @param _token The address of the token to transfer
     * @param _totalBal The target balance this contract should be topped up to
     * @return The amount of tokens transferred
     */
    function _fundLocker(address _token, uint256 _totalBal) internal returns (uint256) {
        uint256 bal = IERC20(_token).balanceOf(address(this));
        //slither-disable-next-line uninitialized-local
        uint256 suppliedAmount;
        if (bal < _totalBal) {
            suppliedAmount = _totalBal - bal;
            IERC20(_token).safeTransferFrom({from: msg.sender, to: address(this), value: suppliedAmount});
        }
        return suppliedAmount;
    }

    /**
     * @notice Refunds any leftover tokens to a recipient, up to a max amount
     * @dev Should be used after increasing the liquidity of a position
     * @param _token The address of the token to refund
     * @param _recipient The recipient for the refund
     * @param _maxAmount The maximum amount of tokens that can be refunded
     */
    function _refundLeftover(address _token, address _recipient, uint256 _maxAmount) internal {
        if (_maxAmount > 0) {
            uint256 lockerBal = IERC20(_token).balanceOf(address(this));
            if (lockerBal > 0) {
                IERC20(_token).safeTransfer({to: _recipient, value: lockerBal < _maxAmount ? lockerBal : _maxAmount});
            }
        }
    }

    /// @inheritdoc ILocker
    function lp() public view virtual returns (uint256);

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`)
     * @dev Overrides Ownable._transferOwnership to update LockerFactory mappings
     * @param newOwner The address of the new owner
     */
    function _transferOwnership(address newOwner) internal override {
        /// @dev account for initial ownership transfer where owner() is address(0) and factory is not defined
        if (owner() != address(0)) {
            ILockerFactory(factory).transferLockerOwnership({_owner: owner(), _newOwner: newOwner, _pool: pool});
        }
        super._transferOwnership({newOwner: newOwner});
    }
}