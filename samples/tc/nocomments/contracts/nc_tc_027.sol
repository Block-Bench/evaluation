/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ contract LiquidityPool {
/*LN-4*/     uint256 public baseAmount;
/*LN-5*/     uint256 public tokenAmount;
/*LN-6*/     uint256 public totalUnits;
/*LN-7*/ 
/*LN-8*/     mapping(address => uint256) public units;
/*LN-9*/ 
/*LN-10*/     function addLiquidity(uint256 inputBase, uint256 inputToken) external returns (uint256 liquidityUnits) {
/*LN-11*/ 
/*LN-12*/         if (totalUnits == 0) {
/*LN-13*/             liquidityUnits = inputBase;
/*LN-14*/         } else {
/*LN-15*/ 
/*LN-16*/             uint256 baseRatio = (inputBase * totalUnits) / baseAmount;
/*LN-17*/             uint256 tokenRatio = (inputToken * totalUnits) / tokenAmount;
/*LN-18*/ 
/*LN-19*/             liquidityUnits = (baseRatio + tokenRatio) / 2;
/*LN-20*/         }
/*LN-21*/ 
/*LN-22*/         units[msg.sender] += liquidityUnits;
/*LN-23*/         totalUnits += liquidityUnits;
/*LN-24*/ 
/*LN-25*/         baseAmount += inputBase;
/*LN-26*/         tokenAmount += inputToken;
/*LN-27*/ 
/*LN-28*/         return liquidityUnits;
/*LN-29*/     }
/*LN-30*/ 
/*LN-31*/     function removeLiquidity(uint256 liquidityUnits) external returns (uint256, uint256) {
/*LN-32*/         uint256 outputBase = (liquidityUnits * baseAmount) / totalUnits;
/*LN-33*/         uint256 outputToken = (liquidityUnits * tokenAmount) / totalUnits;
/*LN-34*/ 
/*LN-35*/         units[msg.sender] -= liquidityUnits;
/*LN-36*/         totalUnits -= liquidityUnits;
/*LN-37*/ 
/*LN-38*/         baseAmount -= outputBase;
/*LN-39*/         tokenAmount -= outputToken;
/*LN-40*/ 
/*LN-41*/         return (outputBase, outputToken);
/*LN-42*/     }
/*LN-43*/ }