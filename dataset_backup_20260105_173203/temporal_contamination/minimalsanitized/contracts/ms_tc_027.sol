/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ contract SpartanPool {
/*LN-5*/     uint256 public baseAmount;
/*LN-6*/     uint256 public tokenAmount;
/*LN-7*/     uint256 public totalUnits;
/*LN-8*/     
/*LN-9*/     mapping(address => uint256) public units;
/*LN-10*/     
/*LN-11*/     function addLiquidity(uint256 inputBase, uint256 inputToken) external returns (uint256 liquidityUnits) {
/*LN-12*/         
/*LN-13*/         if (totalUnits == 0) {
/*LN-14*/             liquidityUnits = inputBase;
/*LN-15*/         } else {
/*LN-16*/             
/*LN-17*/             
/*LN-18*/             
/*LN-19*/             uint256 baseRatio = (inputBase * totalUnits) / baseAmount;
/*LN-20*/             uint256 tokenRatio = (inputToken * totalUnits) / tokenAmount;
/*LN-21*/             
/*LN-22*/             
/*LN-23*/             liquidityUnits = (baseRatio + tokenRatio) / 2;
/*LN-24*/         }
/*LN-25*/         
/*LN-26*/         units[msg.sender] += liquidityUnits;
/*LN-27*/         totalUnits += liquidityUnits;
/*LN-28*/         
/*LN-29*/         baseAmount += inputBase;
/*LN-30*/         tokenAmount += inputToken;
/*LN-31*/         
/*LN-32*/         return liquidityUnits;
/*LN-33*/     }
/*LN-34*/     
/*LN-35*/     function removeLiquidity(uint256 liquidityUnits) external returns (uint256, uint256) {
/*LN-36*/         uint256 outputBase = (liquidityUnits * baseAmount) / totalUnits;
/*LN-37*/         uint256 outputToken = (liquidityUnits * tokenAmount) / totalUnits;
/*LN-38*/         
/*LN-39*/         units[msg.sender] -= liquidityUnits;
/*LN-40*/         totalUnits -= liquidityUnits;
/*LN-41*/         
/*LN-42*/         baseAmount -= outputBase;
/*LN-43*/         tokenAmount -= outputToken;
/*LN-44*/         
/*LN-45*/         return (outputBase, outputToken);
/*LN-46*/     }
/*LN-47*/ }
/*LN-48*/ 