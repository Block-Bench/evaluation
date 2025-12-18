pragma solidity ^0.8.0;


interface IDiamondCut {
    struct FacetCut {
        address facetAddress;
        uint8 action;
        bytes4[] functionSelectors;
    }
}

contract VulnerableBeanstalkGovernance {
    mapping(address => uint256) public depositedBalance;
    mapping(address => uint256) public votingPower;

    struct Proposal {
        address proposer;
        address target;
        bytes data;
        uint256 forVotes;
        uint256 startTime;
        bool executed;
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    uint256 public proposalCount;

    uint256 public totalVotingPower;

    uint256 constant EMERGENCY_THRESHOLD = 66;

    event ProposalCreated(
        uint256 indexed proposalId,
        address proposer,
        address target
    );
    event Voted(uint256 indexed proposalId, address voter, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId);

    function deposit(uint256 amount) external {
        depositedBalance[msg.sender] += amount;
        votingPower[msg.sender] += amount;
        totalVotingPower += amount;
    }

    function propose(
        IDiamondCut.FacetCut[] calldata,
        address _target,
        bytes calldata _calldata,
        uint8
    ) external returns (uint256) {
        proposalCount++;

        Proposal storage prop = proposals[proposalCount];
        prop.proposer = msg.sender;
        prop.target = _target;
        prop.data = _calldata;
        prop.startTime = block.timestamp;
        prop.executed = false;

        prop.forVotes = votingPower[msg.sender];
        hasVoted[proposalCount][msg.sender] = true;

        emit ProposalCreated(proposalCount, msg.sender, _target);
        return proposalCount;
    }

    function vote(uint256 proposalId) external {
        require(!hasVoted[proposalId][msg.sender], "Already voted");
        require(!proposals[proposalId].executed, "Already executed");

        proposals[proposalId].forVotes += votingPower[msg.sender];
        hasVoted[proposalId][msg.sender] = true;

        emit Voted(proposalId, msg.sender, votingPower[msg.sender]);
    }

    function emergencyCommit(uint256 proposalId) external {
        Proposal storage prop = proposals[proposalId];
        require(!prop.executed, "Already executed");

        uint256 votePercentage = (prop.forVotes * 100) / totalVotingPower;
        require(votePercentage >= EMERGENCY_THRESHOLD, "Insufficient votes");

        prop.executed = true;

        (bool success, ) = prop.target.call(prop.data);
        require(success, "Execution failed");

        emit ProposalExecuted(proposalId);
    }
}
