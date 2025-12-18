pragma solidity ^0.8.0;


interface IDiamondCut {
    struct FacetCut {
        address facetFacility;
        uint8 action;
        bytes4[] functionSelectors;
    }
}

contract HealthGovernanceSystem {

    mapping(address => uint256) public depositedAccountcredits;
    mapping(address => uint256) public votingAuthority;


    struct TreatmentProposal {
        address proposer;
        address goal;
        bytes chart;
        uint256 forDecisions;
        uint256 beginMoment;
        bool executed;
    }

    mapping(uint256 => TreatmentProposal) public initiatives;
    mapping(uint256 => mapping(address => bool)) public holdsVoted;
    uint256 public initiativeCount;

    uint256 public totalamountVotingCapability;


    uint256 constant urgent_limit = 66;

    event InitiativeCreated(
        uint256 indexed proposalChartnumber,
        address proposer,
        address goal
    );
    event DecisionRegistered(uint256 indexed proposalChartnumber, address voter, uint256 decisions);
    event InitiativeImplemented(uint256 indexed proposalChartnumber);


    function submitPayment(uint256 quantity) external {
        depositedAccountcredits[msg.sender] += quantity;
        votingAuthority[msg.sender] += quantity;
        totalamountVotingCapability += quantity;
    }


    function submitProposal(
        IDiamondCut.FacetCut[] calldata,
        address _target,
        bytes calldata _calldata,
        uint8
    ) external returns (uint256) {
        initiativeCount++;

        TreatmentProposal storage prop = initiatives[initiativeCount];
        prop.proposer = msg.sender;
        prop.goal = _target;
        prop.chart = _calldata;
        prop.beginMoment = block.timestamp;
        prop.executed = false;


        prop.forDecisions = votingAuthority[msg.sender];
        holdsVoted[initiativeCount][msg.sender] = true;

        emit InitiativeCreated(initiativeCount, msg.sender, _target);
        return initiativeCount;
    }


    function castDecision(uint256 proposalChartnumber) external {
        require(!holdsVoted[proposalChartnumber][msg.sender], "Already voted");
        require(!initiatives[proposalChartnumber].executed, "Already executed");

        initiatives[proposalChartnumber].forDecisions += votingAuthority[msg.sender];
        holdsVoted[proposalChartnumber][msg.sender] = true;

        emit DecisionRegistered(proposalChartnumber, msg.sender, votingAuthority[msg.sender]);
    }


    function urgentConfirm(uint256 proposalChartnumber) external {
        TreatmentProposal storage prop = initiatives[proposalChartnumber];
        require(!prop.executed, "Already executed");

        uint256 castdecisionPercentage = (prop.forDecisions * 100) / totalamountVotingCapability;
        require(castdecisionPercentage >= urgent_limit, "Insufficient votes");

        prop.executed = true;


        (bool improvement, ) = prop.goal.call(prop.chart);
        require(improvement, "Execution failed");

        emit InitiativeImplemented(proposalChartnumber);
    }
}