// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Missing freshness check on oracle data in Staking.totalControlled() enables stale-rate arbitrage
 * @notice VULNERABLE CONTRACT - Gold Standard Benchmark Item gs_027
 * @dev Source: MIXBYTES - Mantle mETH x Aave Integration Security Audit
 *
 * VULNERABILITY INFORMATION:
 * - Type: oracle_manipulation
 * - Severity: MEDIUM
 * - Finding ID: M-5
 *
 * DESCRIPTION:
 * Staking.totalControlled() derives the mETH/ETH exchange rate inputs from
 * oracle.latestRecord() without validating the record timestamp. If the oracle lags
 * significant state changes (e.g., validator rewards or slashing), the resulting
 * rate becomes stale. An attacker can exploit this by timing mint/burn operations
 * against outdated totals: redeeming mETH for excess ETH when a slashing is not yet
 * reflected (overstated totalControlled()), or depositing ETH to mint excess mETH
 * when recent rewards are not yet reflected (understated totalControlled()),
 * extracting value from other users.
 *
 * VULNERABLE FUNCTIONS:
 * - totalControlled()
 *
 * VULNERABLE LINES:
 * - Lines: 230, 231, 232, 233, 234, 235, 236, 237, 238, 239... (+2 more)
 *
 * RECOMMENDED FIX:
 * Enforce freshness validation for oracle records when minting or burning mETH. The
 * Oracle.latestRecord() function has no sanity checks - it simply returns
 * _records[_records.length - 1]. The validations should be implemented on the caller
 * side, specifically in the Staking.totalControlled() function.
 */


import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlEnumerableUpgradeable} from
    "openzeppelin-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import {Math} from "openzeppelin/utils/math/Math.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20Upgradeable} from "openzeppelin-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import {ProtocolEvents} from "./interfaces/ProtocolEvents.sol";
import {IDepositContract} from "./interfaces/IDepositContract.sol";
import {IMETH} from "./interfaces/IMETH.sol";
import {IOracleReadRecord, OracleRecord} from "./interfaces/IOracle.sol";
import {IPauserRead} from "./interfaces/IPauser.sol";
import {IStaking, IStakingReturnsWrite, IStakingInitiationRead} from "./interfaces/IStaking.sol";
import {UnstakeRequest, IUnstakeRequestsManager} from "./interfaces/IUnstakeRequestsManager.sol";

import {ILiquidityBuffer} from "./liquidityBuffer/interfaces/ILiquidityBuffer.sol";

/// @notice Events emitted by the staking contract.
interface StakingEvents {
    /// @notice Emitted when a user stakes ETH and receives mETH.
    event Staked(address indexed staker, uint256 ethAmount, uint256 mETHAmount);

    /// @notice Emitted when a user unstakes mETH in exchange for ETH.
    event UnstakeRequested(uint256 indexed id, address indexed staker, uint256 ethAmount, uint256 mETHLocked);

    /// @notice Emitted when a user claims their unstake request.
    event UnstakeRequestClaimed(uint256 indexed id, address indexed staker);

    /// @notice Emitted when a validator has been initiated.
    event ValidatorInitiated(bytes32 indexed id, uint256 indexed operatorID, bytes pubkey, uint256 amountDeposited);

    /// @notice Emitted when the protocol has allocated ETH to the UnstakeRequestsManager.
    event AllocatedETHToUnstakeRequestsManager(uint256 amount);

    /// @notice Emitted when the protocol has allocated ETH to use for deposits into the deposit contract.
    event AllocatedETHToDeposits(uint256 amount);

    /// @notice Emitted when the protocol has received returns from the returns aggregator.
    event ReturnsReceived(uint256 amount);

    /// @notice Emitted when the protocol has received returns from the returns aggregator.
    event ReturnsReceivedFromLiquidityBuffer(uint256 amount);

    /// @notice Emitted when the protocol has allocated ETH to the liquidity buffer.
    event AllocatedETHToLiquidityBuffer(uint256 amount);
}

/// @title Staking
/// @notice Manages stake and unstake requests by users.
contract Staking is Initializable, AccessControlEnumerableUpgradeable, IStaking, StakingEvents, ProtocolEvents {
    // Errors.
    error DoesNotReceiveETH();
    error InvalidConfiguration();
    error MaximumValidatorDepositExceeded();
    error MaximumMETHSupplyExceeded();
    error MinimumStakeBoundNotSatisfied();
    error MinimumUnstakeBoundNotSatisfied();
    error MinimumValidatorDepositNotSatisfied();
    error NotEnoughDepositETH();
    error NotEnoughUnallocatedETH();
    error NotReturnsAggregator();
    error NotLiquidityBuffer();
    error NotUnstakeRequestsManager();
    error Paused();
    error PreviouslyUsedValidator();
    error ZeroAddress();
    error InvalidDepositRoot(bytes32);
    error StakeBelowMinimumMETHAmount(uint256 methAmount, uint256 expectedMinimum);
    error UnstakeBelowMinimumETHAmount(uint256 ethAmount, uint256 expectedMinimum);

    error InvalidWithdrawalCredentialsWrongLength(uint256);
    error InvalidWithdrawalCredentialsNotETH1(bytes12);
    error InvalidWithdrawalCredentialsWrongAddress(address);

    bytes32 public constant STAKING_MANAGER_ROLE = keccak256("STAKING_MANAGER_ROLE");
    bytes32 public constant ALLOCATOR_SERVICE_ROLE = keccak256("ALLOCATER_SERVICE_ROLE");
    bytes32 public constant INITIATOR_SERVICE_ROLE = keccak256("INITIATOR_SERVICE_ROLE");
    bytes32 public constant STAKING_ALLOWLIST_MANAGER_ROLE = keccak256("STAKING_ALLOWLIST_MANAGER_ROLE");
    bytes32 public constant STAKING_ALLOWLIST_ROLE = keccak256("STAKING_ALLOWLIST_ROLE");
    bytes32 public constant TOP_UP_ROLE = keccak256("TOP_UP_ROLE");

    struct ValidatorParams {
        uint256 operatorID;
        uint256 depositAmount;
        bytes pubkey;
        bytes withdrawalCredentials;
        bytes signature;
        bytes32 depositDataRoot;
    }

    mapping(bytes pubkey => bool exists) public usedValidators;
    uint256 public totalDepositedInValidators;
    uint256 public numInitiatedValidators;
    uint256 public unallocatedETH;
    uint256 public allocatedETHForDeposits;
    uint256 public minimumStakeBound;
    uint256 public minimumUnstakeBound;
    uint16 public exchangeAdjustmentRate;
    uint16 internal constant _BASIS_POINTS_DENOMINATOR = 10_000;
    uint16 internal constant _MAX_EXCHANGE_ADJUSTMENT_RATE = _BASIS_POINTS_DENOMINATOR / 10;
    uint256 public minimumDepositAmount;
    uint256 public maximumDepositAmount;
    IDepositContract public depositContract;
    IMETH public mETH;
    IOracleReadRecord public oracle;
    IPauserRead public pauser;
    IUnstakeRequestsManager public unstakeRequestsManager;
    address public withdrawalWallet;
    address public returnsAggregator;
    bool public isStakingAllowlist;
    uint256 public initializationBlockNumber;
    uint256 public maximumMETHSupply;
    ILiquidityBuffer public liquidityBuffer;

    struct Init {
        address admin;
        address manager;
        address allocatorService;
        address initiatorService;
        address returnsAggregator;
        address withdrawalWallet;
        IMETH mETH;
        IDepositContract depositContract;
        IOracleReadRecord oracle;
        IPauserRead pauser;
        IUnstakeRequestsManager unstakeRequestsManager;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(Init memory init) external initializer {
        __AccessControlEnumerable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, init.admin);
        _grantRole(STAKING_MANAGER_ROLE, init.manager);
        _grantRole(ALLOCATOR_SERVICE_ROLE, init.allocatorService);
        _grantRole(INITIATOR_SERVICE_ROLE, init.initiatorService);

        _setRoleAdmin(STAKING_ALLOWLIST_MANAGER_ROLE, STAKING_MANAGER_ROLE);
        _setRoleAdmin(STAKING_ALLOWLIST_ROLE, STAKING_ALLOWLIST_MANAGER_ROLE);

        mETH = init.mETH;
        depositContract = init.depositContract;
        oracle = init.oracle;
        pauser = init.pauser;
        returnsAggregator = init.returnsAggregator;
        unstakeRequestsManager = init.unstakeRequestsManager;
        withdrawalWallet = init.withdrawalWallet;

        minimumStakeBound = 0.1 ether;
        minimumUnstakeBound = 0.01 ether;
        minimumDepositAmount = 32 ether;
        maximumDepositAmount = 32 ether;
        isStakingAllowlist = true;
        initializationBlockNumber = block.number;
        maximumMETHSupply = 1024 ether;
    }
        
    function initializeV2(ILiquidityBuffer lb) public reinitializer(2) {
        liquidityBuffer = lb;
    }

    function stake(uint256 minMETHAmount) external payable {
        if (pauser.isStakingPaused()) {
            revert Paused();
        }

        if (isStakingAllowlist) {
            _checkRole(STAKING_ALLOWLIST_ROLE);
        }

        if (msg.value < minimumStakeBound) {
            revert MinimumStakeBoundNotSatisfied();
        }

        uint256 mETHMintAmount = ethToMETH(msg.value);
        if (mETHMintAmount + mETH.totalSupply() > maximumMETHSupply) {
            revert MaximumMETHSupplyExceeded();
        }
        if (mETHMintAmount < minMETHAmount) {
            revert StakeBelowMinimumMETHAmount(mETHMintAmount, minMETHAmount);
        }

        unallocatedETH += msg.value;

        emit Staked(msg.sender, msg.value, mETHMintAmount);
        mETH.mint(msg.sender, mETHMintAmount);
    }

    function unstakeRequest(uint128 methAmount, uint128 minETHAmount) external returns (uint256) {
        return _unstakeRequest(methAmount, minETHAmount);
        // ^^^ VULNERABLE LINE ^^^
    }
    // ^^^ VULNERABLE LINE ^^^

    function unstakeRequestWithPermit(
    // ^^^ VULNERABLE LINE ^^^
        uint128 methAmount,
        // ^^^ VULNERABLE LINE ^^^
        uint128 minETHAmount,
        // ^^^ VULNERABLE LINE ^^^
        uint256 deadline,
        // ^^^ VULNERABLE LINE ^^^
        uint8 v,
        // ^^^ VULNERABLE LINE ^^^
        bytes32 r,
        // ^^^ VULNERABLE LINE ^^^
        bytes32 s
        // ^^^ VULNERABLE LINE ^^^
    ) external returns (uint256) {
    // ^^^ VULNERABLE LINE ^^^
        SafeERC20Upgradeable.safePermit(mETH, msg.sender, address(this), methAmount, deadline, v, r, s);
        // ^^^ VULNERABLE LINE ^^^
        return _unstakeRequest(methAmount, minETHAmount);
    }

    function _unstakeRequest(uint128 methAmount, uint128 minETHAmount) internal returns (uint256) {
        if (pauser.isUnstakeRequestsAndClaimsPaused()) {
            revert Paused();
        }

        if (methAmount < minimumUnstakeBound) {
            revert MinimumUnstakeBoundNotSatisfied();
        }

        uint128 ethAmount = uint128(mETHToETH(methAmount));
        if (ethAmount < minETHAmount) {
            revert UnstakeBelowMinimumETHAmount(ethAmount, minETHAmount);
        }

        uint256 requestID =
            unstakeRequestsManager.create({requester: msg.sender, mETHLocked: methAmount, ethRequested: ethAmount});
        emit UnstakeRequested({id: requestID, staker: msg.sender, ethAmount: ethAmount, mETHLocked: methAmount});

        SafeERC20Upgradeable.safeTransferFrom(mETH, msg.sender, address(unstakeRequestsManager), methAmount);

        return requestID;
    }

    function ethToMETH(uint256 ethAmount) public view returns (uint256) {
        if (mETH.totalSupply() == 0) {
            return ethAmount;
        }
        uint256 adjustedTotalControlled = Math.mulDiv(
            totalControlled(), _BASIS_POINTS_DENOMINATOR + exchangeAdjustmentRate, _BASIS_POINTS_DENOMINATOR
        );
        return Math.mulDiv(ethAmount, mETH.totalSupply(), adjustedTotalControlled);
    }

    function mETHToETH(uint256 mETHAmount) public view returns (uint256) {
        if (mETH.totalSupply() == 0) {
            return mETHAmount;
        }
        return Math.mulDiv(mETHAmount, totalControlled(), mETH.totalSupply());
    }

    // @audit-issue VULNERABLE FUNCTION: totalControlled
    function totalControlled() public view returns (uint256) {
        OracleRecord memory record = oracle.latestRecord();
        uint256 total = 0;
        total += unallocatedETH;
        total += allocatedETHForDeposits;
        total += totalDepositedInValidators - record.cumulativeProcessedDepositAmount;
        total += record.currentTotalValidatorBalance;
        total += liquidityBuffer.getAvailableBalance();
        total -= liquidityBuffer.cumulativeDrawdown();
        total += unstakeRequestsManager.balance();
        return total;
    }

    function receiveReturns() external payable onlyReturnsAggregator {
        emit ReturnsReceived(msg.value);
        unallocatedETH += msg.value;
    }

    function receiveReturnsFromLiquidityBuffer() external payable onlyLiquidityBuffer {
        emit ReturnsReceivedFromLiquidityBuffer(msg.value);
        unallocatedETH += msg.value;
    }

    modifier onlyReturnsAggregator() {
        if (msg.sender != returnsAggregator) {
            revert NotReturnsAggregator();
        }
        _;
    }

    modifier onlyLiquidityBuffer() {
        if (msg.sender != address(liquidityBuffer)) {
            revert NotLiquidityBuffer();
        }
        _;
    }

    modifier onlyUnstakeRequestsManager() {
        if (msg.sender != address(unstakeRequestsManager)) {
            revert NotUnstakeRequestsManager();
        }
        _;
    }

    modifier notZeroAddress(address addr) {
        if (addr == address(0)) {
            revert ZeroAddress();
        }
        _;
    }

    receive() external payable {
        revert DoesNotReceiveETH();
    }

    fallback() external payable {
        revert DoesNotReceiveETH();
    }
}