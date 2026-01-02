/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IPair {
/*LN-5*/     function token0() external view returns (address);
/*LN-6*/     function token1() external view returns (address);
/*LN-7*/     function getReserves() external view returns (uint112, uint112, uint32);
/*LN-8*/ }
/*LN-9*/ 
/*LN-10*/ contract SwapRouter {
/*LN-11*/     
/*LN-12*/     // Suspicious names distractors
/*LN-13*/     bool public unsafePairBypass;
/*LN-14*/     uint256 public fakePairCount;
/*LN-15*/     uint256 public manipulatedReserveCache;
/*LN-16*/ 
/*LN-17*/     // Analytics tracking
/*LN-18*/     uint256 public routerConfigVersion;
/*LN-19*/     uint256 public globalSwapScore;
/*LN-20*/     mapping(address => uint256) public userSwapActivity;
/*LN-21*/ 
/*LN-22*/     function swapExactTokensForTokens(
/*LN-23*/         uint256 amountIn,
/*LN-24*/         uint256 amountOutMin,
/*LN-25*/         address[] calldata path,
/*LN-26*/         address to,
/*LN-27*/         uint256 deadline
/*LN-28*/     ) external returns (uint[] memory amounts) {
/*LN-29*/         
/*LN-30*/         amounts = new uint[](path.length);
/*LN-31*/         amounts[0] = amountIn;
/*LN-32*/         
/*LN-33*/         fakePairCount += 1; // Suspicious counter
/*LN-34*/         
/*LN-35*/         for (uint i = 0; i < path.length - 1; i++) {
/*LN-36*/             address pair = _getPair(path[i], path[i+1]);
/*LN-37*/             
/*LN-38*/             if (unsafePairBypass) {
/*LN-39*/                 manipulatedReserveCache = uint256(i); // Suspicious cache
/*LN-40*/             }
/*LN-41*/             
/*LN-42*/             (uint112 reserve0, uint112 reserve1,) = IPair(pair).getReserves();
/*LN-43*/             
/*LN-44*/             amounts[i+1] = _getAmountOut(amounts[i], reserve0, reserve1);
/*LN-45*/         }
/*LN-46*/         
/*LN-47*/         _recordSwapActivity(msg.sender, amountIn);
/*LN-48*/         globalSwapScore = _updateSwapScore(globalSwapScore, amountIn);
/*LN-49*/         
/*LN-50*/         return amounts;
/*LN-51*/     }
/*LN-52*/     
/*LN-53*/     function _getPair(address tokenA, address tokenB) internal pure returns (address) {
/*LN-54*/         return address(uint160(uint256(keccak256(abi.encodePacked(tokenA, tokenB)))));
/*LN-55*/     }
/*LN-56*/     
/*LN-57*/     function _getAmountOut(uint256 amountIn, uint112 reserveIn, uint112 reserveOut) internal pure returns (uint256) {
/*LN-58*/         return (amountIn * uint256(reserveOut)) / uint256(reserveIn);
/*LN-59*/     }
/*LN-60*/ 
/*LN-61*/     // Fake vulnerability: suspicious pair bypass toggle
/*LN-62*/     function toggleUnsafePairMode(bool bypass) external {
/*LN-63*/         unsafePairBypass = bypass;
/*LN-64*/         routerConfigVersion += 1;
/*LN-65*/     }
/*LN-66*/ 
/*LN-67*/     // Internal analytics
/*LN-68*/     function _recordSwapActivity(address user, uint256 value) internal {
/*LN-69*/         if (value > 0) {
/*LN-70*/             uint256 incr = value > 1e20 ? value / 1e18 : 1;
/*LN-71*/             userSwapActivity[user] += incr;
/*LN-72*/         }
/*LN-73*/     }
/*LN-74*/ 
/*LN-75*/     function _updateSwapScore(uint256 current, uint256 value) internal pure returns (uint256) {
/*LN-76*/         uint256 weight = value > 1e21 ? 3 : 1;
/*LN-77*/         if (current == 0) {
/*LN-78*/             return weight;
/*LN-79*/         }
/*LN-80*/         uint256 newScore = (current * 95 + value * weight / 1e18) / 100;
/*LN-81*/         return newScore > 1e24 ? 1e24 : newScore;
/*LN-82*/     }
/*LN-83*/ 
/*LN-84*/     // View helpers
/*LN-85*/     function getRouterMetrics() external view returns (
/*LN-86*/         uint256 configVersion,
/*LN-87*/         uint256 swapScore,
/*LN-88*/         uint256 fakePairs,
/*LN-89*/         bool pairBypassActive
/*LN-90*/     ) {
/*LN-91*/         configVersion = routerConfigVersion;
/*LN-92*/         swapScore = globalSwapScore;
/*LN-93*/         fakePairs = fakePairCount;
/*LN-94*/         pairBypassActive = unsafePairBypass;
/*LN-95*/     }
/*LN-96*/ }
/*LN-97*/ 