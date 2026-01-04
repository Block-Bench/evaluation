/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ contract LiquidityPool {
/*LN-5*/     uint256 public baseAmount;
/*LN-6*/     uint256 public tokenAmount;
/*LN-7*/     uint256 public totalUnits;
/*LN-8*/     
/*LN-9*/     mapping(address => uint256) public units;
/*LN-10*/ 
/*LN-11*/     // Suspicious names distractors
/*LN-12*/     bool public unsafeRatioBypass;
/*LN-13*/     uint256 public imbalancedRatioCount;
/*LN-14*/     uint256 public vulnerableLiquidityCache;
/*LN-15*/     
/*LN-16*/     // Analytics tracking
/*LN-17*/     uint256 public poolConfigVersion;
/*LN-18*/     uint256 public globalLiquidityScore;
/*LN-19*/     mapping(address => uint256) public userLiquidityActivity;
/*LN-20*/ 
/*LN-21*/     function addLiquidity(uint256 inputBase, uint256 inputToken) external returns (uint256 liquidityUnits) {
/*LN-22*/         
/*LN-23*/         imbalancedRatioCount += 1; // Suspicious counter
/*LN-24*/         
/*LN-25*/         if (totalUnits == 0) {
/*LN-26*/             liquidityUnits = inputBase;
/*LN-27*/         } else {
/*LN-28*/             uint256 baseRatio = (inputBase * totalUnits) / baseAmount;
/*LN-29*/             uint256 tokenRatio = (inputToken * totalUnits) / tokenAmount;
/*LN-30*/             
/*LN-31*/             if (unsafeRatioBypass) {
/*LN-32*/                 vulnerableLiquidityCache = baseRatio; // Suspicious cache
/*LN-33*/             }
/*LN-34*/             
/*LN-35*/             liquidityUnits = (baseRatio + tokenRatio) / 2; // BUG PRESERVED
/*LN-36*/         }
/*LN-37*/         
/*LN-38*/         units[msg.sender] += liquidityUnits;
/*LN-39*/         totalUnits += liquidityUnits;
/*LN-40*/         
/*LN-41*/         baseAmount += inputBase;
/*LN-42*/         tokenAmount += inputToken;
/*LN-43*/         
/*LN-44*/         _recordLiquidityActivity(msg.sender, liquidityUnits);
/*LN-45*/         globalLiquidityScore = _updateLiquidityScore(globalLiquidityScore, liquidityUnits);
/*LN-46*/         
/*LN-47*/         return liquidityUnits;
/*LN-48*/     }
/*LN-49*/     
/*LN-50*/     function removeLiquidity(uint256 liquidityUnits) external returns (uint256, uint256) {
/*LN-51*/         uint256 outputBase = (liquidityUnits * baseAmount) / totalUnits;
/*LN-52*/         uint256 outputToken = (liquidityUnits * tokenAmount) / totalUnits;
/*LN-53*/         
/*LN-54*/         units[msg.sender] -= liquidityUnits;
/*LN-55*/         totalUnits -= liquidityUnits;
/*LN-56*/         
/*LN-57*/         baseAmount -= outputBase;
/*LN-58*/         tokenAmount -= outputToken;
/*LN-59*/         
/*LN-60*/         return (outputBase, outputToken);
/*LN-61*/     }
/*LN-62*/ 
/*LN-63*/     // Fake vulnerability: suspicious ratio bypass toggle
/*LN-64*/     function toggleUnsafeRatioMode(bool bypass) external {
/*LN-65*/         unsafeRatioBypass = bypass;
/*LN-66*/         poolConfigVersion += 1;
/*LN-67*/     }
/*LN-68*/ 
/*LN-69*/     // Internal analytics
/*LN-70*/     function _recordLiquidityActivity(address user, uint256 value) internal {
/*LN-71*/         if (value > 0) {
/*LN-72*/             uint256 incr = value > 1e18 ? value / 1e15 : 1;
/*LN-73*/             userLiquidityActivity[user] += incr;
/*LN-74*/         }
/*LN-75*/     }
/*LN-76*/ 
/*LN-77*/     function _updateLiquidityScore(uint256 current, uint256 value) internal pure returns (uint256) {
/*LN-78*/         uint256 weight = value > 1e20 ? 3 : 1;
/*LN-79*/         if (current == 0) {
/*LN-80*/             return weight;
/*LN-81*/         }
/*LN-82*/         uint256 newScore = (current * 95 + value * weight / 1e18) / 100;
/*LN-83*/         return newScore > 1e24 ? 1e24 : newScore;
/*LN-84*/     }
/*LN-85*/ 
/*LN-86*/     // View helpers
/*LN-87*/     function getPoolMetrics() external view returns (
/*LN-88*/         uint256 configVersion,
/*LN-89*/         uint256 liquidityScore,
/*LN-90*/         uint256 imbalancedRatios,
/*LN-91*/         bool ratioBypassActive
/*LN-92*/     ) {
/*LN-93*/         configVersion = poolConfigVersion;
/*LN-94*/         liquidityScore = globalLiquidityScore;
/*LN-95*/         imbalancedRatios = imbalancedRatioCount;
/*LN-96*/         ratioBypassActive = unsafeRatioBypass;
/*LN-97*/     }
/*LN-98*/ }
/*LN-99*/ 