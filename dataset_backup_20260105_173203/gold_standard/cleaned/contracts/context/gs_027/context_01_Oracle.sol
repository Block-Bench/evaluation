// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlEnumerableUpgradeable} from
    "openzeppelin-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import {Math} from "openzeppelin/utils/math/Math.sol";

import {ProtocolEvents} from "./interfaces/ProtocolEvents.sol";
import {
    IOracle,
    IOracleReadRecord,
    IOracleReadPending,
    IOracleWrite,
    IOracleManager,
    OracleRecord
} from "./interfaces/IOracle.sol";
import {IStakingInitiationRead} from "./interfaces/IStaking.sol";
import {IReturnsAggregatorWrite} from "./interfaces/IReturnsAggregator.sol";
import {IPauser} from "./interfaces/IPauser.sol";

/// @notice Events emitted by the oracle contract.
interface OracleEvents {
    event OracleRecordAdded(uint256 indexed index, OracleRecord record);
    event OracleRecordModified(uint256 indexed index, OracleRecord record);
    event OraclePendingUpdateRejected(OracleRecord pendingUpdate);
    event OracleRecordFailedSanityCheck(
        bytes32 indexed reasonHash, string reason, OracleRecord record, uint256 value, uint256 bound
    );
}

/// @title Oracle
/// @notice The oracle contract stores records which are snapshots of consensus layer state.
contract Oracle is Initializable, AccessControlEnumerableUpgradeable, IOracle, OracleEvents, ProtocolEvents {
    error CannotUpdateWhileUpdatePending();
    error CannotModifyInitialRecord();
    error InvalidConfiguration();
    error InvalidRecordModification();
    error InvalidUpdateStartBlock(uint256 wantUpdateStartBlock, uint256 gotUpdateStartBlock);
    error InvalidUpdateEndBeforeStartBlock(uint256 end, uint256 start);
    error InvalidUpdateMoreDepositsProcessedThanSent(uint256 processed, uint256 sent);
    error InvalidUpdateMoreValidatorsThanInitiated(uint256 numValidatorsOnRecord, uint256 numInitiatedValidators);
    error NoUpdatePending();
    error Paused();
    error RecordDoesNotExist(uint256 idx);
    error UnauthorizedOracleUpdater(address sender, address oracleUpdater);
    error UpdateEndBlockNumberNotFinal(uint256 updateFinalizingBlock);
    error ZeroAddress();

    bytes32 public constant ORACLE_MANAGER_ROLE = keccak256("ORACLE_MANAGER_ROLE");
    bytes32 public constant ORACLE_MODIFIER_ROLE = keccak256("ORACLE_MODIFIER_ROLE");
    bytes32 public constant ORACLE_PENDING_UPDATE_RESOLVER_ROLE = keccak256("ORACLE_PENDING_UPDATE_RESOLVER_ROLE");

    uint256 internal constant _FINALIZATION_BLOCK_NUMBER_DELTA_UPPER_BOUND = 2048;

    OracleRecord[] internal _records;
    bool public hasPendingUpdate;
    OracleRecord internal _pendingUpdate;
    uint256 public finalizationBlockNumberDelta;
    address public oracleUpdater;
    IPauser public pauser;
    IStakingInitiationRead public staking;
    IReturnsAggregatorWrite public aggregator;

    uint256 public minDepositPerValidator;
    uint256 public maxDepositPerValidator;
    uint40 public minConsensusLayerGainPerBlockPPT;
    uint40 public maxConsensusLayerGainPerBlockPPT;
    uint24 public maxConsensusLayerLossPPM;
    uint16 public minReportSizeBlocks;

    uint24 internal constant _PPM_DENOMINATOR = 1e6;
    uint40 internal constant _PPT_DENOMINATOR = 1e12;

    struct Init {
        address admin;
        address manager;
        address oracleUpdater;
        address pendingResolver;
        IReturnsAggregatorWrite aggregator;
        IPauser pauser;
        IStakingInitiationRead staking;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(Init memory init) external initializer {
        __AccessControlEnumerable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, init.admin);
        _grantRole(ORACLE_MANAGER_ROLE, init.manager);
        _grantRole(ORACLE_PENDING_UPDATE_RESOLVER_ROLE, init.pendingResolver);

        aggregator = init.aggregator;
        oracleUpdater = init.oracleUpdater;
        pauser = init.pauser;
        staking = init.staking;
    }

    /// @inheritdoc IOracleReadRecord
    function latestRecord() public view returns (OracleRecord memory) {
        return _records[_records.length - 1];
    }

    /// @inheritdoc IOracleReadPending
    function pendingUpdate() external view returns (OracleRecord memory) {
        if (!hasPendingUpdate) {
            revert NoUpdatePending();
        }
        return _pendingUpdate;
    }

    /// @inheritdoc IOracleReadRecord
    function recordAt(uint256 idx) external view returns (OracleRecord memory) {
        return _records[idx];
    }

    /// @inheritdoc IOracleReadRecord
    function numRecords() external view returns (uint256) {
        return _records.length;
    }

    modifier notZeroAddress(address addr) {
        if (addr == address(0)) {
            revert ZeroAddress();
        }
        _;
    }
}