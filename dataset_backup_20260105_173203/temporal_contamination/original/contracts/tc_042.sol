/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * PENPIE EXPLOIT (September 2024)
/*LN-6*/  * Loss: $27 million
/*LN-7*/  * Attack: Reentrancy + Market Manipulation via Fake Pendle Market
/*LN-8*/  *
/*LN-9*/  * Penpie is a yield optimization protocol for Pendle markets. The exploit
/*LN-10*/  * involved creating a fake Pendle market, registering it in Penpie, then
/*LN-11*/  * exploiting reentrancy in reward claiming to manipulate balances and drain
/*LN-12*/  * real assets from the protocol.
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
/*LN-29*/ interface IPendleMarket {
/*LN-30*/     function getRewardTokens() external view returns (address[] memory);
/*LN-31*/ 
/*LN-32*/     function rewardIndexesCurrent() external returns (uint256[] memory);
/*LN-33*/ 
/*LN-34*/     function claimRewards(address user) external returns (uint256[] memory);
/*LN-35*/ }
/*LN-36*/ 
/*LN-37*/ contract PenpieStaking {
/*LN-38*/     mapping(address => mapping(address => uint256)) public userBalances;
/*LN-39*/     mapping(address => uint256) public totalStaked;
/*LN-40*/ 
/*LN-41*/     /**
/*LN-42*/      * @notice Deposit tokens into Penpie staking
/*LN-43*/      */
/*LN-44*/     function deposit(address market, uint256 amount) external {
/*LN-45*/         IERC20(market).transferFrom(msg.sender, address(this), amount);
/*LN-46*/         userBalances[market][msg.sender] += amount;
/*LN-47*/         totalStaked[market] += amount;
/*LN-48*/     }
/*LN-49*/ 
/*LN-50*/     /**
/*LN-51*/      * @notice Claim rewards from Pendle market
/*LN-52*/      * @dev VULNERABILITY: Reentrancy allows balance manipulation
/*LN-53*/      */
/*LN-54*/     function claimRewards(address market, address user) external {
/*LN-55*/         // VULNERABILITY 1: No reentrancy guard
/*LN-56*/         // Allows reentrant calls during reward claiming
/*LN-57*/ 
/*LN-58*/         // VULNERABILITY 2: External call before state updates
/*LN-59*/         // Classic reentrancy pattern (checks-effects-interactions violated)
/*LN-60*/ 
/*LN-61*/         // Get pending rewards
/*LN-62*/         uint256[] memory rewards = IPendleMarket(market).claimRewards(user);
/*LN-63*/ 
/*LN-64*/         // VULNERABILITY 3: Balance updates happen after external call
/*LN-65*/         // Reentrant call can manipulate state before this executes
/*LN-66*/ 
/*LN-67*/         // Update user's reward balance (should happen before external call)
/*LN-68*/         for (uint256 i = 0; i < rewards.length; i++) {
/*LN-69*/             // Process rewards
/*LN-70*/         }
/*LN-71*/     }
/*LN-72*/ 
/*LN-73*/     /**
/*LN-74*/      * @notice Withdraw staked tokens
/*LN-75*/      * @dev VULNERABLE: Can be called during reentrancy with manipulated balance
/*LN-76*/      */
/*LN-77*/     function withdraw(address market, uint256 amount) external {
/*LN-78*/         // VULNERABILITY 4: No checks if currently in reentrant call
/*LN-79*/         require(
/*LN-80*/             userBalances[market][msg.sender] >= amount,
/*LN-81*/             "Insufficient balance"
/*LN-82*/         );
/*LN-83*/ 
/*LN-84*/         userBalances[market][msg.sender] -= amount;
/*LN-85*/         totalStaked[market] -= amount;
/*LN-86*/ 
/*LN-87*/         // VULNERABILITY 5: Transfers real assets based on manipulated balance
/*LN-88*/         IERC20(market).transfer(msg.sender, amount);
/*LN-89*/     }
/*LN-90*/ }
/*LN-91*/ 
/*LN-92*/ contract PendleMarketRegister {
/*LN-93*/     mapping(address => bool) public registeredMarkets;
/*LN-94*/ 
/*LN-95*/     /**
/*LN-96*/      * @notice Register a new Pendle market
/*LN-97*/      * @dev VULNERABILITY: Insufficient validation of market contracts
/*LN-98*/      */
/*LN-99*/     function registerMarket(address market) external {
/*LN-100*/         // VULNERABILITY 6: No validation that market is legitimate Pendle market
/*LN-101*/         // Attacker can register fake market contracts
/*LN-102*/ 
/*LN-103*/         // VULNERABILITY 7: No verification of market factory
/*LN-104*/         // Should check: market was created by official Pendle factory
/*LN-105*/ 
/*LN-106*/         // VULNERABILITY 8: No checks for malicious contract code
/*LN-107*/         // Fake market can have reentrancy exploits
/*LN-108*/ 
/*LN-109*/         registeredMarkets[market] = true;
/*LN-110*/     }
/*LN-111*/ }
/*LN-112*/ 
/*LN-113*/ /**
/*LN-114*/  * EXPLOIT SCENARIO:
/*LN-115*/  *
/*LN-116*/  * 1. Attacker creates fake Pendle market contract:
/*LN-117*/  *    - Implements IPendleMarket interface
/*LN-118*/  *    - getRewardTokens() returns real Pendle LPTs
/*LN-119*/  *    - claimRewards() triggers reentrancy attack
/*LN-120*/  *    - Contract pretends to be legitimate market
/*LN-121*/  *
/*LN-122*/  * 2. Attacker registers fake market:
/*LN-123*/  *    - Calls registerMarket(fakeMarketAddress)
/*LN-124*/  *    - Penpie accepts it without validation
/*LN-125*/  *    - No check that market came from Pendle factory
/*LN-126*/  *
/*LN-127*/  * 3. Attacker calls Penpie deposit():
/*LN-128*/  *    - Deposits small amount into fake market
/*LN-129*/  *    - Gets credited balance in Penpie
/*LN-130*/  *
/*LN-131*/  * 4. Attacker triggers reward claim:
/*LN-132*/  *    - Calls claimRewards(fakeMarket, attacker)
/*LN-133*/  *    - Penpie calls fakeMarket.claimRewards(attacker)
/*LN-134*/  *
/*LN-135*/  * 5. Fake market exploits reentrancy:
/*LN-136*/  *    - In claimRewards(), before returning:
/*LN-137*/  *      * Calls back to Penpie.deposit() with real Pendle LPTs
/*LN-138*/  *      * Or calls Penpie.claimRewards() again (reentrancy)
/*LN-139*/  *      * Manipulates internal state during execution
/*LN-140*/  *
/*LN-141*/  * 6. Reentrancy manipulates balances:
/*LN-142*/  *    - During reentrant call:
/*LN-143*/  *      * Inflates userBalances mapping
/*LN-144*/  *      * Credits attacker with large balance
/*LN-145*/  *      * But hasn't actually deposited equivalent value
/*LN-146*/  *
/*LN-147*/  * 7. Attacker withdraws inflated balance:
/*LN-148*/  *    - Calls withdraw() with inflated amount
/*LN-149*/  *    - Penpie transfers real Pendle LPTs
/*LN-150*/  *    - Gets far more value than deposited
/*LN-151*/  *
/*LN-152*/  * 8. Attacker swaps for liquid assets:
/*LN-153*/  *    - Converts Pendle LPTs to ETH via DEX
/*LN-154*/  *    - Total profit: $27M
/*LN-155*/  *
/*LN-156*/  * Fake Market Implementation:
/*LN-157*/  * ```solidity
/*LN-158*/  * contract FakePendleMarket {
/*LN-159*/  *     uint256 public callCount;
/*LN-160*/  *
/*LN-161*/  *     function getRewardTokens() external returns (address[] memory) {
/*LN-162*/  *         address[] memory tokens = new address[](2);
/*LN-163*/  *         tokens[0] = REAL_PENDLE_LPT_1;
/*LN-164*/  *         tokens[1] = REAL_PENDLE_LPT_2;
/*LN-165*/  *         return tokens;
/*LN-166*/  *     }
/*LN-167*/  *
/*LN-168*/  *     function claimRewards(address user) external returns (uint256[] memory) {
/*LN-169*/  *         if (callCount == 0) {
/*LN-170*/  *             callCount++;
/*LN-171*/  *             // Reentrant call to manipulate state
/*LN-172*/  *             Penpie(msg.sender).deposit(REAL_MARKET, LARGE_AMOUNT);
/*LN-173*/  *         }
/*LN-174*/  *         return new uint256[](2);
/*LN-175*/  *     }
/*LN-176*/  * }
/*LN-177*/  * ```
/*LN-178*/  *
/*LN-179*/  * Root Causes:
/*LN-180*/  * - Missing reentrancy guards on critical functions
/*LN-181*/  * - External calls before state updates (CEI pattern violated)
/*LN-182*/  * - Insufficient validation of registered markets
/*LN-183*/  * - No verification that markets came from official factory
/*LN-184*/  * - Trusting arbitrary market contracts
/*LN-185*/  * - No monitoring for unusual registration patterns
/*LN-186*/  * - Missing access controls on market registration
/*LN-187*/  * - Lack of contract code verification
/*LN-188*/  *
/*LN-189*/  * Fix:
/*LN-190*/  * - Add reentrancy guards (OpenZeppelin ReentrancyGuard)
/*LN-191*/  * - Follow checks-effects-interactions pattern strictly
/*LN-192*/  * - Update state before making external calls
/*LN-193*/  * - Verify markets were created by official Pendle factory
/*LN-194*/  * - Whitelist approved market contracts only
/*LN-195*/  * - Add market registration approval process
/*LN-196*/  * - Implement circuit breakers for unusual activity
/*LN-197*/  * - Monitor for suspicious reward claim patterns
/*LN-198*/  * - Add maximum withdrawal limits per transaction
/*LN-199*/  * - Require time delay between deposit and withdrawal
/*LN-200*/  */
/*LN-201*/ 