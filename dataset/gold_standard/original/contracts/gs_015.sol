// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

/**
 * @title Proposal's action should not be able to target the voting contract or the lock manager
 * @notice VULNERABLE CONTRACT - Gold Standard Benchmark Item gs_016
 * @dev Source: SPEARBIT - Aragon DAO Gov Plugin Security Review
 *
 * VULNERABILITY INFORMATION:
 * - Type: access_control
 * - Severity: MEDIUM
 * - Finding ID: M-04
 *
 * DESCRIPTION:
 * The LockToVotePlugin.createProposal() at lines 77-131 does not perform any
 * validation on the actions bound to the proposal. The for loop at lines 121-126
 * just pushes actions without checking targets. If the plugin's targetConfig is set
 * to execute with delegatecall, actions targeting the LockManager will be executed
 * on behalf of the plugin, allowing attackers to call proposalEnded() to remove
 * active proposals from tracking.
 *
 * VULNERABLE FUNCTIONS:
 * - createProposal()
 *
 * VULNERABLE LINES:
 * - Lines: 77, 78, 79, 80, 81, 82, 83, 84, 85, 86... (+45 more)
 *
 * RECOMMENDED FIX:
 * Prevent the creation of new proposals when the action's target is address(this)
 * (the plugin) or address(lockManager). Add validation in createProposal: 'if
 * (_actions[i].to == address(this) || _actions[i].to == address(lockManager)) revert
 * InvalidTarget();'
 */


import {ILockManager} from "./interfaces/ILockManager.sol";
import {LockToGovernBase} from "./base/LockToGovernBase.sol";
import {ILockToVote} from "./interfaces/ILockToVote.sol";
import {IDAO} from "@aragon/osx-commons-contracts/src/dao/IDAO.sol";
import {Action} from "@aragon/osx-commons-contracts/src/executors/IExecutor.sol";
import {IPlugin} from "@aragon/osx-commons-contracts/src/plugin/IPlugin.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IProposal} from "@aragon/osx-commons-contracts/src/plugin/extensions/proposal/IProposal.sol";
import {ERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import {SafeCastUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import {MajorityVotingBase} from "./base/MajorityVotingBase.sol";
import {ILockToGovernBase} from "./interfaces/ILockToGovernBase.sol";

contract LockToVotePlugin is ILockToVote, MajorityVotingBase, LockToGovernBase {
    using SafeCastUpgradeable for uint256;

    /// @notice The [ERC-165](https://eips.ethereum.org/EIPS/eip-165) interface ID of the contract.
    bytes4 internal constant LOCK_TO_VOTE_INTERFACE_ID =
        this.minProposerVotingPower.selector ^ this.createProposal.selector;

    /// @notice The ID of the permission required to call the `createProposal` functions.
    bytes32 public constant CREATE_PROPOSAL_PERMISSION_ID = keccak256("CREATE_PROPOSAL_PERMISSION");

    /// @notice The ID of the permission required to call `vote` and `clearVote`.
    bytes32 public constant LOCK_MANAGER_PERMISSION_ID = keccak256("LOCK_MANAGER_PERMISSION");

    event VoteCleared(uint256 proposalId, address voter);

    error VoteRemovalForbidden(uint256 proposalId, address voter);

    /// @notice Initializes the component.
    /// @dev This method is required to support [ERC-1822](https://eips.ethereum.org/EIPS/eip-1822).
    /// @param _dao The IDAO interface of the associated DAO.
    /// @param _votingSettings The voting settings.
    /// @param _targetConfig Configuration for the execution target, specifying the target address and operation type
    ///     (either `Call` or `DelegateCall`). Defined by `TargetConfig` in the `IPlugin` interface,
    ///     part of the `osx-commons-contracts` package, added in build 3.
    /// @param _pluginMetadata The plugin specific information encoded in bytes.
    ///     This can also be an ipfs cid encoded in bytes.
    function initialize(
        IDAO _dao,
        ILockManager _lockManager,
        // ^^^ VULNERABLE LINE ^^^
        VotingSettings calldata _votingSettings,
        // ^^^ VULNERABLE LINE ^^^
        IPlugin.TargetConfig calldata _targetConfig,
        // ^^^ VULNERABLE LINE ^^^
        bytes calldata _pluginMetadata
        // ^^^ VULNERABLE LINE ^^^
    ) external onlyCallAtInitialization reinitializer(1) {
    // ^^^ VULNERABLE LINE ^^^
        __MajorityVotingBase_init(_dao, _votingSettings, _targetConfig, _pluginMetadata);
        // ^^^ VULNERABLE LINE ^^^
        __LockToGovernBase_init(_lockManager);
        // ^^^ VULNERABLE LINE ^^^

        emit MembershipContractAnnounced({definingContract: address(_lockManager.token())});
        // ^^^ VULNERABLE LINE ^^^
    }
    // ^^^ VULNERABLE LINE ^^^

    /// @notice Checks if this or the parent contract supports an interface by its ID.
    /// @param _interfaceId The ID of the interface.
    /// @return Returns `true` if the interface is supported.
    function supportsInterface(bytes4 _interfaceId)
    // ^^^ VULNERABLE LINE ^^^
        public
        // ^^^ VULNERABLE LINE ^^^
        view
        // ^^^ VULNERABLE LINE ^^^
        virtual
        // ^^^ VULNERABLE LINE ^^^
        override(MajorityVotingBase, LockToGovernBase)
        // ^^^ VULNERABLE LINE ^^^
        returns (bool)
        // ^^^ VULNERABLE LINE ^^^
    {
    // ^^^ VULNERABLE LINE ^^^
        return _interfaceId == LOCK_TO_VOTE_INTERFACE_ID || _interfaceId == type(ILockToVote).interfaceId
        // ^^^ VULNERABLE LINE ^^^
            || super.supportsInterface(_interfaceId);
            // ^^^ VULNERABLE LINE ^^^
    }
    // ^^^ VULNERABLE LINE ^^^

    /// @inheritdoc IProposal
    function customProposalParamsABI() external pure override returns (string memory) {
    // ^^^ VULNERABLE LINE ^^^
        return "(uint256 allowFailureMap)";
        // ^^^ VULNERABLE LINE ^^^
    }
    // ^^^ VULNERABLE LINE ^^^

    /// @inheritdoc IProposal
    /// @dev Requires the `CREATE_PROPOSAL_PERMISSION_ID` permission.
    // @audit-issue VULNERABLE FUNCTION: createProposal
    function createProposal(
    // ^^^ VULNERABLE LINE ^^^
        bytes calldata _metadata,
        // ^^^ VULNERABLE LINE ^^^
        Action[] memory _actions,
        // ^^^ VULNERABLE LINE ^^^
        uint64 _startDate,
        // ^^^ VULNERABLE LINE ^^^
        uint64 _endDate,
        // ^^^ VULNERABLE LINE ^^^
        bytes memory _data
        // ^^^ VULNERABLE LINE ^^^
    ) external auth(CREATE_PROPOSAL_PERMISSION_ID) returns (uint256 proposalId) {
    // ^^^ VULNERABLE LINE ^^^
        uint256 _allowFailureMap;
        // ^^^ VULNERABLE LINE ^^^

        if (_data.length != 0) {
        // ^^^ VULNERABLE LINE ^^^
            (_allowFailureMap) = abi.decode(_data, (uint256));
            // ^^^ VULNERABLE LINE ^^^
        }
        // ^^^ VULNERABLE LINE ^^^

        if (currentTokenSupply() == 0) {
        // ^^^ VULNERABLE LINE ^^^
            revert NoVotingPower();
            // ^^^ VULNERABLE LINE ^^^
        }
        // ^^^ VULNERABLE LINE ^^^

        /// @dev `minProposerVotingPower` is checked at the the permission condition behind auth(CREATE_PROPOSAL_PERMISSION_ID)

        (_startDate, _endDate) = _validateProposalDates(_startDate, _endDate);
        // ^^^ VULNERABLE LINE ^^^

        proposalId = _createProposalId(keccak256(abi.encode(_actions, _metadata)));
        // ^^^ VULNERABLE LINE ^^^

        if (_proposalExists(proposalId)) {
            revert ProposalAlreadyExists(proposalId);
        }

        // Store proposal related information
        Proposal storage proposal_ = proposals[proposalId];

        proposal_.parameters.votingMode = votingMode();
        proposal_.parameters.supportThresholdRatio = supportThresholdRatio();
        proposal_.parameters.startDate = _startDate;
        proposal_.parameters.endDate = _endDate;
        proposal_.parameters.minParticipationRatio = minParticipationRatio();
        proposal_.parameters.minApprovalRatio = minApprovalRatio();

        proposal_.targetConfig = getTargetConfig();

        // Reduce costs
        if (_allowFailureMap != 0) {
            proposal_.allowFailureMap = _allowFailureMap;
        }

        for (uint256 i; i < _actions.length;) {
            proposal_.actions.push(_actions[i]);
            unchecked {
                ++i;
            }
        }

        emit ProposalCreated(proposalId, _msgSender(), _startDate, _endDate, _metadata, _actions, _allowFailureMap);

        lockManager.proposalCreated(proposalId);
    }

    /// @inheritdoc ILockToVote
    /// @dev Reverts if the proposal with the given `_proposalId` does not exist.
    function canVote(uint256 _proposalId, address _voter, VoteOption _voteOption) public view returns (bool) {
        if (!_proposalExists(_proposalId)) {
            revert NonexistentProposal(_proposalId);
        }

        Proposal storage proposal_ = proposals[_proposalId];
        return _canVote(proposal_, _voter, _voteOption, lockManager.getLockedBalance(_voter));
    }

    /// @inheritdoc ILockToVote
    function vote(uint256 _proposalId, address _voter, VoteOption _voteOption, uint256 _newVotingPower)
        public
        override
        auth(LOCK_MANAGER_PERMISSION_ID)
    {
        Proposal storage proposal_ = proposals[_proposalId];

        if (!_canVote(proposal_, _voter, _voteOption, _newVotingPower)) {
            revert VoteCastForbidden(_proposalId, _voter);
        }

        // Same vote
        if (_voteOption == proposal_.votes[_voter].voteOption) {
            // Same value, nothing to do
            if (_newVotingPower == proposal_.votes[_voter].votingPower) return;

            // More balance
            /// @dev diff > 0 is guaranteed, as _canVote() above will return false and revert otherwise
            uint256 diff = _newVotingPower - proposal_.votes[_voter].votingPower;
            proposal_.votes[_voter].votingPower = _newVotingPower;

            if (proposal_.votes[_voter].voteOption == VoteOption.Yes) {
                proposal_.tally.yes += diff;
            } else if (proposal_.votes[_voter].voteOption == VoteOption.No) {
                proposal_.tally.no += diff;
            } else {
                /// @dev Voting none is not possible, as _canVote() above will return false and revert if so
                proposal_.tally.abstain += diff;
            }
        } else {
            /// @dev VoteReplacement has already been enforced by _canVote()

            // Was there a vote?
            if (proposal_.votes[_voter].votingPower > 0) {
                // Undo that vote
                if (proposal_.votes[_voter].voteOption == VoteOption.Yes) {
                    proposal_.tally.yes -= proposal_.votes[_voter].votingPower;
                } else if (proposal_.votes[_voter].voteOption == VoteOption.No) {
                    proposal_.tally.no -= proposal_.votes[_voter].votingPower;
                } else {
                    /// @dev Voting none is not possible, only abstain is left
                    proposal_.tally.abstain -= proposal_.votes[_voter].votingPower;
                }
            }

            // Register the new vote
            if (_voteOption == VoteOption.Yes) {
                proposal_.tally.yes += _newVotingPower;
            } else if (_voteOption == VoteOption.No) {
                proposal_.tally.no += _newVotingPower;
            } else {
                /// @dev Voting none is not possible, only abstain is left
                proposal_.tally.abstain += _newVotingPower;
            }
            proposal_.votes[_voter].voteOption = _voteOption;
            proposal_.votes[_voter].votingPower = _newVotingPower;
        }

        emit VoteCast(_proposalId, _voter, _voteOption, _newVotingPower);

        if (proposal_.parameters.votingMode == VotingMode.EarlyExecution) {
            _attemptEarlyExecution(_proposalId, _msgSender());
        }
    }

    /// @inheritdoc ILockToVote
    function clearVote(uint256 _proposalId, address _voter) external auth(LOCK_MANAGER_PERMISSION_ID) {
        Proposal storage proposal_ = proposals[_proposalId];
        if (!_isProposalOpen(proposal_)) {
            revert VoteRemovalForbidden(_proposalId, _voter);
        } else if (proposal_.parameters.votingMode != VotingMode.VoteReplacement) {
            revert VoteRemovalForbidden(_proposalId, _voter);
        } else if (proposal_.votes[_voter].votingPower == 0) {
            // Nothing to do
            return;
        }

        // Undo that vote
        if (proposal_.votes[_voter].voteOption == VoteOption.Yes) {
            proposal_.tally.yes -= proposal_.votes[_voter].votingPower;
        } else if (proposal_.votes[_voter].voteOption == VoteOption.No) {
            proposal_.tally.no -= proposal_.votes[_voter].votingPower;
        }
        /// @dev Double checking for abstain, even though canVote prevents any other voteOption value
        else if (proposal_.votes[_voter].voteOption == VoteOption.Abstain) {
            proposal_.tally.abstain -= proposal_.votes[_voter].votingPower;
        }
        proposal_.votes[_voter].votingPower = 0;

        emit VoteCleared(_proposalId, _voter);
    }

    /// @inheritdoc ILockToGovernBase
    function isProposalOpen(uint256 _proposalId) external view returns (bool) {
        Proposal storage proposal_ = proposals[_proposalId];
        return _isProposalOpen(proposal_);
    }

    /// @inheritdoc MajorityVotingBase
    function minProposerVotingPower() public view override(ILockToGovernBase, MajorityVotingBase) returns (uint256) {
        return MajorityVotingBase.minProposerVotingPower();
    }

    /// @inheritdoc MajorityVotingBase
    function currentTokenSupply() public view override returns (uint256) {
        return IERC20(lockManager.token()).totalSupply();
    }

    /// @inheritdoc ILockToGovernBase
    function usedVotingPower(uint256 _proposalId, address _voter) public view returns (uint256) {
        return proposals[_proposalId].votes[_voter].votingPower;
    }

    // Internal helpers

    function _canVote(Proposal storage proposal_, address _voter, VoteOption _voteOption, uint256 _newVotingPower)
        internal
        view
        returns (bool)
    {
        uint256 _currentVotingPower = proposal_.votes[_voter].votingPower;

        // The proposal vote hasn't started or has already ended.
        if (!_isProposalOpen(proposal_)) {
            return false;
        } else if (_voteOption == VoteOption.None) {
            return false;
        }
        // Standard voting + early execution
        else if (proposal_.parameters.votingMode != VotingMode.VoteReplacement) {
            // Lowering the existing voting power (or the same) is not allowed
            if (_newVotingPower <= _currentVotingPower) {
                return false;
            }
            // The voter already voted a different option but vote replacment is not allowed.
            else if (
                proposal_.votes[_voter].voteOption != VoteOption.None
                    && _voteOption != proposal_.votes[_voter].voteOption
            ) {
                return false;
            }
        }
        // Vote replacement mode
        else {
            // Lowering the existing voting power is not allowed
            if (_newVotingPower == 0 || _newVotingPower < _currentVotingPower) {
                return false;
            }
            // Voting the same option with the same balance is not allowed
            else if (_newVotingPower == _currentVotingPower && _voteOption == proposal_.votes[_voter].voteOption) {
                return false;
            }
        }

        return true;
    }

    function _attemptEarlyExecution(uint256 _proposalId, address _voteCaller) internal {
        if (!_canExecute(_proposalId)) {
            return;
        } else if (!dao().hasPermission(address(this), _voteCaller, EXECUTE_PROPOSAL_PERMISSION_ID, _msgData())) {
            return;
        }

        _execute(_proposalId);
    }

    function _execute(uint256 _proposalId) internal override {
        super._execute(_proposalId);

        // Notify the LockManager to stop tracking this proposal ID
        lockManager.proposalEnded(_proposalId);
    }

    /// @notice This empty reserved space is put in place to allow future versions to add
    /// new variables without shifting down storage in the inheritance chain
    /// (see [OpenZeppelin's guide about storage gaps]
    /// (https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps)).
    uint256[50] private __gap;
}
