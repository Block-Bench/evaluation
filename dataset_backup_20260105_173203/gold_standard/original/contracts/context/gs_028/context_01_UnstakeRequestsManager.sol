// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlEnumerableUpgradeable} from
    "openzeppelin-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import {Address} from "openzeppelin/utils/Address.sol";
import {Math} from "openzeppelin/utils/math/Math.sol";
import {SafeERC20Upgradeable} from "openzeppelin-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import {ProtocolEvents} from "./interfaces/ProtocolEvents.sol";
import {IMETH} from "./interfaces/IMETH.sol";
import {IOracleReadRecord} from "./interfaces/IOracle.sol";
import {
    IUnstakeRequestsManager,
    IUnstakeRequestsManagerWrite,
    IUnstakeRequestsManagerRead,
    UnstakeRequest
} from "./interfaces/IUnstakeRequestsManager.sol";
import {IStakingReturnsWrite} from "./interfaces/IStaking.sol";

/// @notice Events emitted by the unstake requests manager.
interface UnstakeRequestsManagerEvents {
    event UnstakeRequestCreated(
        uint256 indexed id,
        address indexed requester,
        uint256 mETHLocked,
        uint256 ethRequested,
        uint256 cumulativeETHRequested,
        uint256 blockNumber
    );

    event UnstakeRequestClaimed(
        uint256 indexed id,
        address indexed requester,
        uint256 mETHLocked,
        uint256 ethRequested,
        uint256 cumulativeETHRequested,
        uint256 blockNumber
    );

    event UnstakeRequestCancelled(
        uint256 indexed id,
        address indexed requester,
        uint256 mETHLocked,
        uint256 ethRequested,
        uint256 cumulativeETHRequested,
        uint256 blockNumber
    );
}

/// @title UnstakeRequestsManager
/// @notice Manages unstake requests from the staking contract.
contract UnstakeRequestsManager is
    Initializable,
    AccessControlEnumerableUpgradeable,
    IUnstakeRequestsManager,
    UnstakeRequestsManagerEvents,
    ProtocolEvents
{
    error AlreadyClaimed();
    error DoesNotReceiveETH();
    error NotEnoughFunds(uint256 cumulativeETHOnRequest, uint256 allocatedETHForClaims);
    error NotFinalized();
    error NotRequester();
    error NotStakingContract();

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant REQUEST_CANCELLER_ROLE = keccak256("REQUEST_CANCELLER_ROLE");

    IStakingReturnsWrite public stakingContract;
    IOracleReadRecord public oracle;
    uint256 public allocatedETHForClaims;
    uint256 public totalClaimed;
    uint256 public numberOfBlocksToFinalize;
    IMETH public mETH;
    uint128 public latestCumulativeETHRequested;
    UnstakeRequest[] internal _unstakeRequests;

    struct Init {
        address admin;
        address manager;
        address requestCanceller;
        IMETH mETH;
        IStakingReturnsWrite stakingContract;
        IOracleReadRecord oracle;
        uint256 numberOfBlocksToFinalize;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(Init memory init) external initializer {
        __AccessControlEnumerable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, init.admin);
        numberOfBlocksToFinalize = init.numberOfBlocksToFinalize;
        stakingContract = init.stakingContract;
        oracle = init.oracle;
        mETH = init.mETH;

        _grantRole(MANAGER_ROLE, init.manager);
        _grantRole(REQUEST_CANCELLER_ROLE, init.requestCanceller);
    }

    function create(address requester, uint128 mETHLocked, uint128 ethRequested)
        external
        onlyStakingContract
        returns (uint256)
    {
        uint128 currentCumulativeETHRequested = latestCumulativeETHRequested + ethRequested;
        uint256 requestID = _unstakeRequests.length;
        UnstakeRequest memory unstakeRequest = UnstakeRequest({
            id: uint128(requestID),
            requester: requester,
            mETHLocked: mETHLocked,
            ethRequested: ethRequested,
            cumulativeETHRequested: currentCumulativeETHRequested,
            blockNumber: uint64(block.number)
        });
        _unstakeRequests.push(unstakeRequest);

        latestCumulativeETHRequested = currentCumulativeETHRequested;
        emit UnstakeRequestCreated(
            requestID, requester, mETHLocked, ethRequested, currentCumulativeETHRequested, block.number
        );
        return requestID;
    }

    function claim(uint256 requestID, address requester) external onlyStakingContract {
        UnstakeRequest memory request = _unstakeRequests[requestID];

        if (request.requester == address(0)) {
            revert AlreadyClaimed();
        }
        if (request.requester != requester) {
            revert NotRequester();
        }
        if (!_isFinalized(request)) {
            revert NotFinalized();
        }
        if (request.cumulativeETHRequested > allocatedETHForClaims) {
            revert NotEnoughFunds(request.cumulativeETHRequested, allocatedETHForClaims);
        }

        delete _unstakeRequests[requestID];

        totalClaimed += request.ethRequested;
        emit UnstakeRequestClaimed(
            request.id,
            request.requester,
            request.mETHLocked,
            request.ethRequested,
            request.cumulativeETHRequested,
            request.blockNumber
        );

        // Burn the mETH tokens that were locked in this contract
        mETH.burn(request.mETHLocked);

        Address.sendValue(payable(requester), request.ethRequested);
    }

    function allocateETH() external payable onlyStakingContract {
        allocatedETHForClaims += msg.value;
    }

    function balance() external view returns (uint256) {
        if (allocatedETHForClaims > totalClaimed) {
            return allocatedETHForClaims - totalClaimed;
        }
        return 0;
    }

    function _isFinalized(UnstakeRequest memory request) internal view returns (bool) {
        return (request.blockNumber + numberOfBlocksToFinalize) <= oracle.latestRecord().updateEndBlock;
    }

    modifier onlyStakingContract() {
        if (msg.sender != address(stakingContract)) {
            revert NotStakingContract();
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