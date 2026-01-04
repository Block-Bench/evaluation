/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title Beanstalk Governance (Vulnerable Version)
/*LN-6*/  * @notice This contract demonstrates the vulnerability that led to the $182M Beanstalk hack
/*LN-7*/  * @dev April 17, 2022 - Governance attack via flash loan
/*LN-8*/  *
/*LN-9*/  * VULNERABILITY: Flash loan governance attack
/*LN-10*/  *
/*LN-11*/  * ROOT CAUSE:
/*LN-12*/  * The Beanstalk protocol used a governance system where voting power was based on
/*LN-13*/  * deposited assets (BEAN tokens and LP tokens) in the Silo. The governance system
/*LN-14*/  * allowed proposals to be executed immediately via emergencyCommit() if they received
/*LN-15*/  * enough votes, with no time delay for users to react.
/*LN-16*/  *
/*LN-17*/  * The attacker could:
/*LN-18*/  * 1. Take a massive flash loan
/*LN-19*/  * 2. Deposit funds into Silo to gain voting power
/*LN-20*/  * 3. Propose and vote on a malicious proposal
/*LN-21*/  * 4. Execute the proposal immediately via emergencyCommit()
/*LN-22*/  * 5. Drain funds and repay flash loan
/*LN-23*/  *
/*LN-24*/  * ATTACK VECTOR:
/*LN-25*/  * 1. Attacker takes $1B flash loan (DAI, USDC, USDT from Aave)
/*LN-26*/  * 2. Swaps stablecoins for Curve 3pool LP tokens
/*LN-27*/  * 3. Deposits LP tokens into Beanstalk Silo, gaining majority voting power
/*LN-28*/  * 4. Creates malicious proposal to transfer all funds to attacker
/*LN-29*/  * 5. Votes on the proposal with flash-loan-funded voting power
/*LN-30*/  * 6. Immediately executes via emergencyCommit()
/*LN-31*/  * 7. Proposal calls sweep() function transferring all assets to attacker
/*LN-32*/  * 8. Repays flash loan, keeps profit
/*LN-33*/  */
/*LN-34*/ 
/*LN-35*/ interface IDiamondCut {
/*LN-36*/     struct FacetCut {
/*LN-37*/         address facetAddress;
/*LN-38*/         uint8 action;
/*LN-39*/         bytes4[] functionSelectors;
/*LN-40*/     }
/*LN-41*/ }
/*LN-42*/ 
/*LN-43*/ contract VulnerableBeanstalkGovernance {
/*LN-44*/     // Voting power based on deposits
/*LN-45*/     mapping(address => uint256) public depositedBalance;
/*LN-46*/     mapping(address => uint256) public votingPower;
/*LN-47*/ 
/*LN-48*/     // Proposal structure
/*LN-49*/     struct Proposal {
/*LN-50*/         address proposer;
/*LN-51*/         address target; // Contract to call
/*LN-52*/         bytes data; // Calldata to execute
/*LN-53*/         uint256 forVotes;
/*LN-54*/         uint256 startTime;
/*LN-55*/         bool executed;
/*LN-56*/     }
/*LN-57*/ 
/*LN-58*/     mapping(uint256 => Proposal) public proposals;
/*LN-59*/     mapping(uint256 => mapping(address => bool)) public hasVoted;
/*LN-60*/     uint256 public proposalCount;
/*LN-61*/ 
/*LN-62*/     uint256 public totalVotingPower;
/*LN-63*/ 
/*LN-64*/     // Constants
/*LN-65*/     uint256 constant EMERGENCY_THRESHOLD = 66; // 66% threshold for emergency commit
/*LN-66*/ 
/*LN-67*/     event ProposalCreated(
/*LN-68*/         uint256 indexed proposalId,
/*LN-69*/         address proposer,
/*LN-70*/         address target
/*LN-71*/     );
/*LN-72*/     event Voted(uint256 indexed proposalId, address voter, uint256 votes);
/*LN-73*/     event ProposalExecuted(uint256 indexed proposalId);
/*LN-74*/ 
/*LN-75*/     /**
/*LN-76*/      * @notice Deposit tokens to gain voting power
/*LN-77*/      * @param amount Amount to deposit
/*LN-78*/      *
/*LN-79*/      * VULNERABILITY ENABLER:
/*LN-80*/      * This function allows anyone to gain voting power by depositing,
/*LN-81*/      * including via flash-loaned funds with no time delay.
/*LN-82*/      */
/*LN-83*/     function deposit(uint256 amount) external {
/*LN-84*/         // In real Beanstalk, this accepts BEAN3CRV LP tokens
/*LN-85*/         // Simplified for demonstration
/*LN-86*/         depositedBalance[msg.sender] += amount;
/*LN-87*/         votingPower[msg.sender] += amount;
/*LN-88*/         totalVotingPower += amount;
/*LN-89*/     }
/*LN-90*/ 
/*LN-91*/     /**
/*LN-92*/      * @notice Create a governance proposal
/*LN-93*/      * @param _target The contract to call
/*LN-94*/      * @param _calldata The calldata to execute
/*LN-95*/      *
/*LN-96*/      * VULNERABILITY: No minimum deposit time required before proposing
/*LN-97*/      */
/*LN-98*/     function propose(
/*LN-99*/         IDiamondCut.FacetCut[] calldata, // Diamond cut (unused in this simplified version)
/*LN-100*/         address _target,
/*LN-101*/         bytes calldata _calldata,
/*LN-102*/         uint8 /* _pauseOrUnpause */
/*LN-103*/     ) external returns (uint256) {
/*LN-104*/         proposalCount++;
/*LN-105*/ 
/*LN-106*/         Proposal storage prop = proposals[proposalCount];
/*LN-107*/         prop.proposer = msg.sender;
/*LN-108*/         prop.target = _target;
/*LN-109*/         prop.data = _calldata;
/*LN-110*/         prop.startTime = block.timestamp;
/*LN-111*/         prop.executed = false;
/*LN-112*/ 
/*LN-113*/         // Auto-vote with proposer's voting power
/*LN-114*/         prop.forVotes = votingPower[msg.sender];
/*LN-115*/         hasVoted[proposalCount][msg.sender] = true;
/*LN-116*/ 
/*LN-117*/         emit ProposalCreated(proposalCount, msg.sender, _target);
/*LN-118*/         return proposalCount;
/*LN-119*/     }
/*LN-120*/ 
/*LN-121*/     /**
/*LN-122*/      * @notice Vote on a proposal
/*LN-123*/      * @param proposalId The ID of the proposal
/*LN-124*/      */
/*LN-125*/     function vote(uint256 proposalId) external {
/*LN-126*/         require(!hasVoted[proposalId][msg.sender], "Already voted");
/*LN-127*/         require(!proposals[proposalId].executed, "Already executed");
/*LN-128*/ 
/*LN-129*/         proposals[proposalId].forVotes += votingPower[msg.sender];
/*LN-130*/         hasVoted[proposalId][msg.sender] = true;
/*LN-131*/ 
/*LN-132*/         emit Voted(proposalId, msg.sender, votingPower[msg.sender]);
/*LN-133*/     }
/*LN-134*/ 
/*LN-135*/     /**
/*LN-136*/      * @notice Emergency commit - execute proposal immediately
/*LN-137*/      * @param proposalId The ID of the proposal to execute
/*LN-138*/      *
/*LN-139*/      * CRITICAL VULNERABILITY:
/*LN-140*/      * This function allows immediate execution of proposals if they reach
/*LN-141*/      * the emergency threshold (66%). Combined with flash-loan-funded voting power,
/*LN-142*/      * an attacker can:
/*LN-143*/      * 1. Deposit flash-loaned assets to gain >66% voting power
/*LN-144*/      * 2. Propose malicious action
/*LN-145*/      * 3. Immediately execute via emergencyCommit()
/*LN-146*/      * 4. No time delay for legitimate users to react
/*LN-147*/      */
/*LN-148*/     function emergencyCommit(uint256 proposalId) external {
/*LN-149*/         Proposal storage prop = proposals[proposalId];
/*LN-150*/         require(!prop.executed, "Already executed");
/*LN-151*/ 
/*LN-152*/         // VULNERABILITY: Only checks voting percentage, not time-weighted votes
/*LN-153*/         // or minimum holding period
/*LN-154*/         uint256 votePercentage = (prop.forVotes * 100) / totalVotingPower;
/*LN-155*/         require(votePercentage >= EMERGENCY_THRESHOLD, "Insufficient votes");
/*LN-156*/ 
/*LN-157*/         prop.executed = true;
/*LN-158*/ 
/*LN-159*/         // Execute the proposal
/*LN-160*/         // VULNERABILITY: Executes arbitrary call to target with attacker-controlled data
/*LN-161*/         (bool success, ) = prop.target.call(prop.data);
/*LN-162*/         require(success, "Execution failed");
/*LN-163*/ 
/*LN-164*/         emit ProposalExecuted(proposalId);
/*LN-165*/     }
/*LN-166*/ }
/*LN-167*/ 
/*LN-168*/ /**
/*LN-169*/  * REAL-WORLD IMPACT:
/*LN-170*/  * - $182M stolen on April 17, 2022
/*LN-171*/  * - Attacker used $1B flash loan from Aave
/*LN-172*/  * - Entire Beanstalk treasury drained
/*LN-173*/  * - One of the largest DeFi governance attacks
/*LN-174*/  *
/*LN-175*/  * FIX:
/*LN-176*/  * The fix requires:
/*LN-177*/  * 1. Implement time-weighted voting (voting power increases with time held)
/*LN-178*/  * 2. Add minimum deposit duration before gaining voting rights
/*LN-179*/  * 3. Implement time delay between proposal and execution (timelock)
/*LN-180*/  * 4. Remove or restrict emergencyCommit() function
/*LN-181*/  * 5. Add multi-sig or guardian role for emergency functions
/*LN-182*/  * 6. Implement snapshot-based voting to prevent same-block deposit + vote
/*LN-183*/  *
/*LN-184*/  * KEY LESSON:
/*LN-185*/  * Governance systems must protect against flash loan attacks by requiring
/*LN-186*/  * time-weighted votes or minimum holding periods. Instant execution of
/*LN-187*/  * proposals is extremely dangerous, even with high vote thresholds.
/*LN-188*/  *
/*LN-189*/  */
/*LN-190*/ 