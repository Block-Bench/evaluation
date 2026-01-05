// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

/**
 * @title Proposals created with voting mode EarlyExecution are vulnerable to flashloan attacks
 * @notice VULNERABLE CONTRACT - Gold Standard Benchmark Item gs_012
 * @dev Source: SPEARBIT - Aragon DAO Gov Plugin Security Review
 *
 * VULNERABILITY INFORMATION:
 * - Type: flash_loan
 * - Severity: HIGH
 * - Finding ID: H-02
 *
 * DESCRIPTION:
 * If the token used by the LockManager can be flashloaned (or flashminted) and a
 * proposal is created with the voting mode EarlyExecution, anyone could be able to
 * 'early execute' it by flashloaning tokens, locking them, casting a YES vote to
 * trigger early execution, unlocking tokens, and repaying the flashloan - all in one
 * transaction. The vulnerable code is in LockToVotePlugin.vote() at lines 205-207
 * which calls _attemptEarlyExecution() when VotingMode.EarlyExecution is set.
 *
 * VULNERABLE FUNCTIONS:
 * - vote()
 * - _attemptEarlyExecution()
 *
 * VULNERABLE LINES:
 * - Lines: 145, 146, 147, 148, 149, 150, 151, 152, 153, 154... (+63 more)
 *
 * ATTACK SCENARIO:
 * 1. Flashloan the needed amount.
 * 2. Lock the flashloaned amount via LockManager.lock().
 * 3. Cast a 'YES' vote via LockManager.vote() which triggers LockToVotePlugin._att
 * 4. Proposal executes immediately in same transaction.
 * 5. Unlock the tokens via LockManager.unlock().
 *
 * RECOMMENDED FIX:
 * Avoid allowing the early execution in the very same block that the vote has been
 * made. This would require tracking the 'success' of a proposal in a separate flag,
 * stored in the proposal struct. Alternatively, remove the EarlyExecution voting
 * mode entirely.
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
        VotingSettings calldata _votingSettings,
        IPlugin.TargetConfig calldata _targetConfig,
        bytes calldata _pluginMetadata
    ) external onlyCallAtInitialization reinitializer(1) {
        __MajorityVotingBase_init(_dao, _votingSettings, _targetConfig, _pluginMetadata);
        __LockToGovernBase_init(_lockManager);

        emit MembershipContractAnnounced({definingContract: address(_lockManager.token())});
    }

    /// @notice Checks if this or the parent contract supports an interface by its ID.
    /// @param _interfaceId The ID of the interface.
    /// @return Returns `true` if the interface is supported.
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(MajorityVotingBase, LockToGovernBase)
        returns (bool)
    {
        return _interfaceId == LOCK_TO_VOTE_INTERFACE_ID || _interfaceId == type(ILockToVote).interfaceId
            || super.supportsInterface(_interfaceId);
    }

    /// @inheritdoc IProposal
    function customProposalParamsABI() external pure override returns (string memory) {
        return "(uint256 allowFailureMap)";
    }

    /// @inheritdoc IProposal
    /// @dev Requires the `CREATE_PROPOSAL_PERMISSION_ID` permission.
    function createProposal(
        bytes calldata _metadata,
        Action[] memory _actions,
        uint64 _startDate,
        uint64 _endDate,
        bytes memory _data
    ) external auth(CREATE_PROPOSAL_PERMISSION_ID) returns (uint256 proposalId) {
        uint256 _allowFailureMap;

        if (_data.length != 0) {
            (_allowFailureMap) = abi.decode(_data, (uint256));
        }

        if (currentTokenSupply() == 0) {
            revert NoVotingPower();
        }

        /// @dev `minProposerVotingPower` is checked at the the permission condition behind auth(CREATE_PROPOSAL_PERMISSION_ID)

        (_startDate, _endDate) = _validateProposalDates(_startDate, _endDate);

        proposalId = _createProposalId(keccak256(abi.encode(_actions, _metadata)));

        if (_proposalExists(proposalId)) {
            revert ProposalAlreadyExists(proposalId);
        }

        // Store proposal related information
        Proposal storage proposal_ = proposals[proposalId];
        // ^^^ VULNERABLE LINE ^^^

        proposal_.parameters.votingMode = votingMode();
        // ^^^ VULNERABLE LINE ^^^
        proposal_.parameters.supportThresholdRatio = supportThresholdRatio();
        // ^^^ VULNERABLE LINE ^^^
        proposal_.parameters.startDate = _startDate;
        // ^^^ VULNERABLE LINE ^^^
        proposal_.parameters.endDate = _endDate;
        // ^^^ VULNERABLE LINE ^^^
        proposal_.parameters.minParticipationRatio = minParticipationRatio();
        // ^^^ VULNERABLE LINE ^^^
        proposal_.parameters.minApprovalRatio = minApprovalRatio();
        // ^^^ VULNERABLE LINE ^^^

        proposal_.targetConfig = getTargetConfig();
        // ^^^ VULNERABLE LINE ^^^

        // Reduce costs
        if (_allowFailureMap != 0) {
        // ^^^ VULNERABLE LINE ^^^
            proposal_.allowFailureMap = _allowFailureMap;
            // ^^^ VULNERABLE LINE ^^^
        }
        // ^^^ VULNERABLE LINE ^^^

        for (uint256 i; i < _actions.length;) {
        // ^^^ VULNERABLE LINE ^^^
            proposal_.actions.push(_actions[i]);
            // ^^^ VULNERABLE LINE ^^^
            unchecked {
            // ^^^ VULNERABLE LINE ^^^
                ++i;
                // ^^^ VULNERABLE LINE ^^^
            }
            // ^^^ VULNERABLE LINE ^^^
        }
        // ^^^ VULNERABLE LINE ^^^

        emit ProposalCreated(proposalId, _msgSender(), _startDate, _endDate, _metadata, _actions, _allowFailureMap);
        // ^^^ VULNERABLE LINE ^^^

        lockManager.proposalCreated(proposalId);
        // ^^^ VULNERABLE LINE ^^^
    }
    // ^^^ VULNERABLE LINE ^^^

    /// @inheritdoc ILockToVote
    /// @dev Reverts if the proposal with the given `_proposalId` does not exist.
    function canVote(uint256 _proposalId, address _voter, VoteOption _voteOption) public view returns (bool) {
    // ^^^ VULNERABLE LINE ^^^
        if (!_proposalExists(_proposalId)) {
        // ^^^ VULNERABLE LINE ^^^
            revert NonexistentProposal(_proposalId);
            // ^^^ VULNERABLE LINE ^^^
        }
        // ^^^ VULNERABLE LINE ^^^

        Proposal storage proposal_ = proposals[_proposalId];
        // ^^^ VULNERABLE LINE ^^^
        return _canVote(proposal_, _voter, _voteOption, lockManager.getLockedBalance(_voter));
        // ^^^ VULNERABLE LINE ^^^
    }
    // ^^^ VULNERABLE LINE ^^^

    /// @inheritdoc ILockToVote
    // @audit-issue VULNERABLE FUNCTION: vote
    function vote(uint256 _proposalId, address _voter, VoteOption _voteOption, uint256 _newVotingPower)
    // ^^^ VULNERABLE LINE ^^^
        public
        // ^^^ VULNERABLE LINE ^^^
        override
        // ^^^ VULNERABLE LINE ^^^
        auth(LOCK_MANAGER_PERMISSION_ID)
        // ^^^ VULNERABLE LINE ^^^
    {
    // ^^^ VULNERABLE LINE ^^^
        Proposal storage proposal_ = proposals[_proposalId];
        // ^^^ VULNERABLE LINE ^^^

        if (!_canVote(proposal_, _voter, _voteOption, _newVotingPower)) {
        // ^^^ VULNERABLE LINE ^^^
            revert VoteCastForbidden(_proposalId, _voter);
            // ^^^ VULNERABLE LINE ^^^
        }
        // ^^^ VULNERABLE LINE ^^^

        // Same vote
        if (_voteOption == proposal_.votes[_voter].voteOption) {
        // ^^^ VULNERABLE LINE ^^^
            // Same value, nothing to do
            if (_newVotingPower == proposal_.votes[_voter].votingPower) return;
            // ^^^ VULNERABLE LINE ^^^

            // More balance
            /// @dev diff > 0 is guaranteed, as _canVote() above will return false and revert otherwise
            uint256 diff = _newVotingPower - proposal_.votes[_voter].votingPower;
            // ^^^ VULNERABLE LINE ^^^
            proposal_.votes[_voter].votingPower = _newVotingPower;
            // ^^^ VULNERABLE LINE ^^^

            if (proposal_.votes[_voter].voteOption == VoteOption.Yes) {
            // ^^^ VULNERABLE LINE ^^^
                proposal_.tally.yes += diff;
                // ^^^ VULNERABLE LINE ^^^
            } else if (proposal_.votes[_voter].voteOption == VoteOption.No) {
            // ^^^ VULNERABLE LINE ^^^
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
        // ^^^ VULNERABLE LINE ^^^
        returns (bool)
        // ^^^ VULNERABLE LINE ^^^
    {
    // ^^^ VULNERABLE LINE ^^^
        uint256 _currentVotingPower = proposal_.votes[_voter].votingPower;
        // ^^^ VULNERABLE LINE ^^^

        // The proposal vote hasn't started or has already ended.
        if (!_isProposalOpen(proposal_)) {
        // ^^^ VULNERABLE LINE ^^^
            return false;
            // ^^^ VULNERABLE LINE ^^^
        } else if (_voteOption == VoteOption.None) {
        // ^^^ VULNERABLE LINE ^^^
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

    // @audit-issue VULNERABLE FUNCTION: _attemptEarlyExecution
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
