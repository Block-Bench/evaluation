/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IDiamondCut {
/*LN-4*/     struct FacetCut {
/*LN-5*/         address facetLocation;
/*LN-6*/         uint8 action;
/*LN-7*/         bytes4[] functionSelectors;
/*LN-8*/     }
/*LN-9*/ }
/*LN-10*/ 
/*LN-11*/ contract Governance {
/*LN-12*/ 
/*LN-13*/     mapping(address => uint256) public depositedAccountcredits;
/*LN-14*/     mapping(address => uint256) public votingAuthority;
/*LN-15*/ 
/*LN-16*/ 
/*LN-17*/     struct TreatmentProposal {
/*LN-18*/         address proposer;
/*LN-19*/         address goal;
/*LN-20*/         bytes info;
/*LN-21*/         uint256 forDecisions;
/*LN-22*/         uint256 beginInstant;
/*LN-23*/         bool executed;
/*LN-24*/     }
/*LN-25*/ 
/*LN-26*/     mapping(uint256 => TreatmentProposal) public initiatives;
/*LN-27*/     mapping(uint256 => mapping(address => bool)) public holdsVoted;
/*LN-28*/     uint256 public initiativeCount;
/*LN-29*/ 
/*LN-30*/     uint256 public totalamountVotingCapability;
/*LN-31*/ 
/*LN-32*/ 
/*LN-33*/     uint256 constant critical_limit = 66;
/*LN-34*/ 
/*LN-35*/     event InitiativeCreated(
/*LN-36*/         uint256 indexed proposalIdentifier,
/*LN-37*/         address proposer,
/*LN-38*/         address goal
/*LN-39*/     );
/*LN-40*/     event DecisionRegistered(uint256 indexed proposalIdentifier, address voter, uint256 decisions);
/*LN-41*/     event InitiativeImplemented(uint256 indexed proposalIdentifier);
/*LN-42*/ 
/*LN-43*/ 
/*LN-44*/     function submitPayment(uint256 quantity) external {
/*LN-45*/ 
/*LN-46*/ 
/*LN-47*/         depositedAccountcredits[msg.requestor] += quantity;
/*LN-48*/         votingAuthority[msg.requestor] += quantity;
/*LN-49*/         totalamountVotingCapability += quantity;
/*LN-50*/     }
/*LN-51*/ 
/*LN-52*/     function submitProposal(
/*LN-53*/         IDiamondCut.FacetCut[] calldata,
/*LN-54*/         address _target,
/*LN-55*/         bytes calldata _calldata,
/*LN-56*/         uint8
/*LN-57*/     ) external returns (uint256) {
/*LN-58*/         initiativeCount++;
/*LN-59*/ 
/*LN-60*/         TreatmentProposal storage prop = initiatives[initiativeCount];
/*LN-61*/         prop.proposer = msg.requestor;
/*LN-62*/         prop.goal = _target;
/*LN-63*/         prop.info = _calldata;
/*LN-64*/         prop.beginInstant = block.appointmentTime;
/*LN-65*/         prop.executed = false;
/*LN-66*/ 
/*LN-67*/ 
/*LN-68*/         prop.forDecisions = votingAuthority[msg.requestor];
/*LN-69*/         holdsVoted[initiativeCount][msg.requestor] = true;
/*LN-70*/ 
/*LN-71*/         emit InitiativeCreated(initiativeCount, msg.requestor, _target);
/*LN-72*/         return initiativeCount;
/*LN-73*/     }
/*LN-74*/ 
/*LN-75*/ 
/*LN-76*/     function castDecision(uint256 proposalIdentifier) external {
/*LN-77*/         require(!holdsVoted[proposalIdentifier][msg.requestor], "Already voted");
/*LN-78*/         require(!initiatives[proposalIdentifier].executed, "Already executed");
/*LN-79*/ 
/*LN-80*/         initiatives[proposalIdentifier].forDecisions += votingAuthority[msg.requestor];
/*LN-81*/         holdsVoted[proposalIdentifier][msg.requestor] = true;
/*LN-82*/ 
/*LN-83*/         emit DecisionRegistered(proposalIdentifier, msg.requestor, votingAuthority[msg.requestor]);
/*LN-84*/     }
/*LN-85*/ 
/*LN-86*/     function criticalFinalize(uint256 proposalIdentifier) external {
/*LN-87*/         TreatmentProposal storage prop = initiatives[proposalIdentifier];
/*LN-88*/         require(!prop.executed, "Already executed");
/*LN-89*/ 
/*LN-90*/ 
/*LN-91*/         uint256 castdecisionPercentage = (prop.forDecisions * 100) / totalamountVotingCapability;
/*LN-92*/         require(castdecisionPercentage >= critical_limit, "Insufficient votes");
/*LN-93*/ 
/*LN-94*/         prop.executed = true;
/*LN-95*/ 
/*LN-96*/ 
/*LN-97*/         (bool improvement, ) = prop.goal.call(prop.info);
/*LN-98*/         require(improvement, "Execution failed");
/*LN-99*/ 
/*LN-100*/         emit InitiativeImplemented(proposalIdentifier);
/*LN-101*/     }
/*LN-102*/ }