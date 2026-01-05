/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IDiamondCut {
/*LN-4*/     struct FacetCut {
/*LN-5*/         address facetAddress;
/*LN-6*/         uint8 action;
/*LN-7*/         bytes4[] functionSelectors;
/*LN-8*/     }
/*LN-9*/ }
/*LN-10*/ 
/*LN-11*/ contract Governance {
/*LN-12*/ 
/*LN-13*/     mapping(address => uint256) public depositedBalance;
/*LN-14*/     mapping(address => uint256) public votingPower;
/*LN-15*/ 
/*LN-16*/ 
/*LN-17*/     struct Proposal {
/*LN-18*/         address proposer;
/*LN-19*/         address target;
/*LN-20*/         bytes data;
/*LN-21*/         uint256 forVotes;
/*LN-22*/         uint256 startTime;
/*LN-23*/         bool executed;
/*LN-24*/     }
/*LN-25*/ 
/*LN-26*/     mapping(uint256 => Proposal) public proposals;
/*LN-27*/     mapping(uint256 => mapping(address => bool)) public hasVoted;
/*LN-28*/     uint256 public proposalCount;
/*LN-29*/ 
/*LN-30*/     uint256 public totalVotingPower;
/*LN-31*/ 
/*LN-32*/ 
/*LN-33*/     uint256 constant EMERGENCY_THRESHOLD = 66;
/*LN-34*/ 
/*LN-35*/     event ProposalCreated(
/*LN-36*/         uint256 indexed proposalId,
/*LN-37*/         address proposer,
/*LN-38*/         address target
/*LN-39*/     );
/*LN-40*/     event Voted(uint256 indexed proposalId, address voter, uint256 votes);
/*LN-41*/     event ProposalExecuted(uint256 indexed proposalId);
/*LN-42*/ 
/*LN-43*/ 
/*LN-44*/     function deposit(uint256 amount) external {
/*LN-45*/ 
/*LN-46*/ 
/*LN-47*/         depositedBalance[msg.sender] += amount;
/*LN-48*/         votingPower[msg.sender] += amount;
/*LN-49*/         totalVotingPower += amount;
/*LN-50*/     }
/*LN-51*/ 
/*LN-52*/     function propose(
/*LN-53*/         IDiamondCut.FacetCut[] calldata,
/*LN-54*/         address _target,
/*LN-55*/         bytes calldata _calldata,
/*LN-56*/         uint8
/*LN-57*/     ) external returns (uint256) {
/*LN-58*/         proposalCount++;
/*LN-59*/ 
/*LN-60*/         Proposal storage prop = proposals[proposalCount];
/*LN-61*/         prop.proposer = msg.sender;
/*LN-62*/         prop.target = _target;
/*LN-63*/         prop.data = _calldata;
/*LN-64*/         prop.startTime = block.timestamp;
/*LN-65*/         prop.executed = false;
/*LN-66*/ 
/*LN-67*/ 
/*LN-68*/         prop.forVotes = votingPower[msg.sender];
/*LN-69*/         hasVoted[proposalCount][msg.sender] = true;
/*LN-70*/ 
/*LN-71*/         emit ProposalCreated(proposalCount, msg.sender, _target);
/*LN-72*/         return proposalCount;
/*LN-73*/     }
/*LN-74*/ 
/*LN-75*/ 
/*LN-76*/     function vote(uint256 proposalId) external {
/*LN-77*/         require(!hasVoted[proposalId][msg.sender], "Already voted");
/*LN-78*/         require(!proposals[proposalId].executed, "Already executed");
/*LN-79*/ 
/*LN-80*/         proposals[proposalId].forVotes += votingPower[msg.sender];
/*LN-81*/         hasVoted[proposalId][msg.sender] = true;
/*LN-82*/ 
/*LN-83*/         emit Voted(proposalId, msg.sender, votingPower[msg.sender]);
/*LN-84*/     }
/*LN-85*/ 
/*LN-86*/     function emergencyCommit(uint256 proposalId) external {
/*LN-87*/         Proposal storage prop = proposals[proposalId];
/*LN-88*/         require(!prop.executed, "Already executed");
/*LN-89*/ 
/*LN-90*/ 
/*LN-91*/         uint256 votePercentage = (prop.forVotes * 100) / totalVotingPower;
/*LN-92*/         require(votePercentage >= EMERGENCY_THRESHOLD, "Insufficient votes");
/*LN-93*/ 
/*LN-94*/         prop.executed = true;
/*LN-95*/ 
/*LN-96*/ 
/*LN-97*/         (bool success, ) = prop.target.call(prop.data);
/*LN-98*/         require(success, "Execution failed");
/*LN-99*/ 
/*LN-100*/         emit ProposalExecuted(proposalId);
/*LN-101*/     }
/*LN-102*/ }