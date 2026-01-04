/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * SPARTAN PROTOCOL EXPLOIT (May 2021)
/*LN-6*/  * Attack: Liquidity Calculation Error in AMM
/*LN-7*/  * Loss: $30 million
/*LN-8*/  * 
/*LN-9*/  * Spartan's AMM had a critical error in calculating liquidity units
/*LN-10*/  * during addLiquidity, allowing attackers to mint excessive LP tokens.
/*LN-11*/  */
/*LN-12*/ 
/*LN-13*/ contract SpartanPool {
/*LN-14*/     uint256 public baseAmount;
/*LN-15*/     uint256 public tokenAmount;
/*LN-16*/     uint256 public totalUnits;
/*LN-17*/     
/*LN-18*/     mapping(address => uint256) public units;
/*LN-19*/     
/*LN-20*/     function addLiquidity(uint256 inputBase, uint256 inputToken) external returns (uint256 liquidityUnits) {
/*LN-21*/         
/*LN-22*/         if (totalUnits == 0) {
/*LN-23*/             liquidityUnits = inputBase;
/*LN-24*/         } else {
/*LN-25*/             // VULNERABLE: Incorrect formula
/*LN-26*/             // Should be: min(inputBase/baseAmount, inputToken/tokenAmount) * totalUnits
/*LN-27*/             // Instead uses: (inputBase + inputToken) / 2
/*LN-28*/             
/*LN-29*/             uint256 baseRatio = (inputBase * totalUnits) / baseAmount;
/*LN-30*/             uint256 tokenRatio = (inputToken * totalUnits) / tokenAmount;
/*LN-31*/             
/*LN-32*/             // BUG: Takes average instead of minimum!
/*LN-33*/             liquidityUnits = (baseRatio + tokenRatio) / 2;
/*LN-34*/         }
/*LN-35*/         
/*LN-36*/         units[msg.sender] += liquidityUnits;
/*LN-37*/         totalUnits += liquidityUnits;
/*LN-38*/         
/*LN-39*/         baseAmount += inputBase;
/*LN-40*/         tokenAmount += inputToken;
/*LN-41*/         
/*LN-42*/         return liquidityUnits;
/*LN-43*/     }
/*LN-44*/     
/*LN-45*/     function removeLiquidity(uint256 liquidityUnits) external returns (uint256, uint256) {
/*LN-46*/         uint256 outputBase = (liquidityUnits * baseAmount) / totalUnits;
/*LN-47*/         uint256 outputToken = (liquidityUnits * tokenAmount) / totalUnits;
/*LN-48*/         
/*LN-49*/         units[msg.sender] -= liquidityUnits;
/*LN-50*/         totalUnits -= liquidityUnits;
/*LN-51*/         
/*LN-52*/         baseAmount -= outputBase;
/*LN-53*/         tokenAmount -= outputToken;
/*LN-54*/         
/*LN-55*/         return (outputBase, outputToken);
/*LN-56*/     }
/*LN-57*/ }
/*LN-58*/ 
/*LN-59*/ /**
/*LN-60*/  * EXPLOIT:
/*LN-61*/  * 1. Pool has 100 BASE, 100 TOKEN, 100 totalUnits
/*LN-62*/  * 2. Attacker adds 1 BASE, 99 TOKEN
/*LN-63*/  * 3. baseRatio = 1*100/100 = 1
/*LN-64*/  * 4. tokenRatio = 99*100/100 = 99  
/*LN-65*/  * 5. liquidityUnits = (1+99)/2 = 50 (WRONG! Should be 1)
/*LN-66*/  * 6. Attacker got 50 units for only 1 BASE worth of value
/*LN-67*/  * 7. Remove liquidity: gets back proportional share = 33 BASE + 33 TOKEN
/*LN-68*/  * 8. Profit: Started with 1 BASE + 99 TOKEN, ended with 33 BASE + 33 TOKEN
/*LN-69*/  * 9. Repeat to drain $30M
/*LN-70*/  * 
/*LN-71*/  * Fix: Use minimum ratio, not average: liquidityUnits = min(baseRatio, tokenRatio)
/*LN-72*/  */
/*LN-73*/ 