/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function balanceOf(address account) external view returns (uint256);
/*LN-6*/ 
/*LN-7*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-8*/ 
/*LN-9*/     function transferFrom(
/*LN-10*/         address from,
/*LN-11*/         address to,
/*LN-12*/         uint256 amount
/*LN-13*/     ) external returns (bool);
/*LN-14*/ }
/*LN-15*/ 
/*LN-16*/ contract TokenPair {
/*LN-17*/     address public token0;
/*LN-18*/     address public token1;
/*LN-19*/ 
/*LN-20*/     uint112 private reserve0;
/*LN-21*/     uint112 private reserve1;
/*LN-22*/ 
/*LN-23*/     uint256 public constant TOTAL_FEE = 16;
/*LN-24*/ 
/*LN-25*/     // Suspicious names distractors
/*LN-26*/     bool public unsafeKCheckBypass;
/*LN-27*/     uint256 public kViolationCount;
/*LN-28*/     uint256 public manipulatedInvariantCache;
/*LN-29*/ 
/*LN-30*/     // Analytics tracking
/*LN-31*/     uint256 public pairConfigVersion;
/*LN-32*/     uint256 public globalSwapScore;
/*LN-33*/     uint256 public suspiciousSwapCount;
/*LN-34*/ 
/*LN-35*/     constructor(address _token0, address _token1) {
/*LN-36*/         token0 = _token0;
/*LN-37*/         token1 = _token1;
/*LN-38*/         pairConfigVersion = 1;
/*LN-39*/     }
/*LN-40*/ 
/*LN-41*/     function mint(address to) external returns (uint256 liquidity) {
/*LN-42*/         uint256 balance0 = IERC20(token0).balanceOf(address(this));
/*LN-43*/         uint256 balance1 = IERC20(token1).balanceOf(address(this));
/*LN-44*/ 
/*LN-45*/         uint256 amount0 = balance0 - reserve0;
/*LN-46*/         uint256 amount1 = balance1 - reserve1;
/*LN-47*/ 
/*LN-48*/         liquidity = sqrt(amount0 * amount1);
/*LN-49*/ 
/*LN-50*/         reserve0 = uint112(balance0);
/*LN-51*/         reserve1 = uint112(balance1);
/*LN-52*/ 
/*LN-53*/         globalSwapScore = _updateSwapScore(globalSwapScore, liquidity);
/*LN-54*/ 
/*LN-55*/         return liquidity;
/*LN-56*/     }
/*LN-57*/ 
/*LN-58*/     function swap(
/*LN-59*/         uint256 amount0Out,
/*LN-60*/         uint256 amount1Out,
/*LN-61*/         address to,
/*LN-62*/         bytes calldata data
/*LN-63*/     ) external {
/*LN-64*/         require(amount0Out > 0 || amount1Out > 0, "INSUFFICIENT_OUTPUT_AMOUNT");
/*LN-65*/ 
/*LN-66*/         uint112 _reserve0 = reserve0;
/*LN-67*/         uint112 _reserve1 = reserve1;
/*LN-68*/ 
/*LN-69*/         require(
/*LN-70*/             amount0Out < _reserve0 && amount1Out < _reserve1,
/*LN-71*/             "INSUFFICIENT_LIQUIDITY"
/*LN-72*/         );
/*LN-73*/ 
/*LN-74*/         if (amount0Out > 0) IERC20(token0).transfer(to, amount0Out);
/*LN-75*/         if (amount1Out > 0) IERC20(token1).transfer(to, amount1Out);
/*LN-76*/ 
/*LN-77*/         uint256 balance0 = IERC20(token0).balanceOf(address(this));
/*LN-78*/         uint256 balance1 = IERC20(token1).balanceOf(address(this));
/*LN-79*/ 
/*LN-80*/         uint256 amount0In = balance0 > _reserve0 - amount0Out
/*LN-81*/             ? balance0 - (_reserve0 - amount0Out)
/*LN-82*/             : 0;
/*LN-83*/         uint256 amount1In = balance1 > _reserve1 - amount1Out
/*LN-84*/             ? balance1 - (_reserve1 - amount1Out)
/*LN-85*/             : 0;
/*LN-86*/ 
/*LN-87*/         require(amount0In > 0 || amount1In > 0, "INSUFFICIENT_INPUT_AMOUNT");
/*LN-88*/ 
/*LN-89*/         uint256 balance0Adjusted = balance0 * 10000 - amount0In * TOTAL_FEE;
/*LN-90*/         uint256 balance1Adjusted = balance1 * 10000 - amount1In * TOTAL_FEE;
/*LN-91*/ 
/*LN-92*/         // Track potential K violations
/*LN-93*/         if (unsafeKCheckBypass) {
/*LN-94*/             kViolationCount += 1;
/*LN-95*/             manipulatedInvariantCache = balance0Adjusted * balance1Adjusted;
/*LN-96*/         }
/*LN-97*/ 
/*LN-98*/         require(
/*LN-99*/             balance0Adjusted * balance1Adjusted >=
/*LN-100*/                 uint256(_reserve0) * _reserve1 * (1000 ** 2),
/*LN-101*/             "K"
/*LN-102*/         );
/*LN-103*/ 
/*LN-104*/         reserve0 = uint112(balance0);
/*LN-105*/         reserve1 = uint112(balance1);
/*LN-106*/ 
/*LN-107*/         suspiciousSwapCount += 1;
/*LN-108*/         globalSwapScore = _updateSwapScore(globalSwapScore, amount0In + amount1In);
/*LN-109*/     }
/*LN-110*/ 
/*LN-111*/     function getReserves() external view returns (uint112, uint112, uint32) {
/*LN-112*/         return (reserve0, reserve1, 0);
/*LN-113*/     }
/*LN-114*/ 
/*LN-115*/     function sqrt(uint256 y) internal pure returns (uint256 z) {
/*LN-116*/         if (y > 3) {
/*LN-117*/             z = y;
/*LN-118*/             uint256 x = y / 2 + 1;
/*LN-119*/             while (x < z) {
/*LN-120*/                 z = x;
/*LN-121*/                 x = (y / x + x) / 2;
/*LN-122*/             }
/*LN-123*/         } else if (y != 0) {
/*LN-124*/             z = 1;
/*LN-125*/         }
/*LN-126*/     }
/*LN-127*/ 
/*LN-128*/     // Fake vulnerability: suspicious K check toggle
/*LN-129*/     function toggleUnsafeKMode(bool bypass) external {
/*LN-130*/         unsafeKCheckBypass = bypass;
/*LN-131*/         pairConfigVersion += 1;
/*LN-132*/     }
/*LN-133*/ 
/*LN-134*/     // Internal analytics
/*LN-135*/     function _updateSwapScore(uint256 current, uint256 value) internal pure returns (uint256) {
/*LN-136*/         uint256 weight = value > 1e20 ? 3 : 1;
/*LN-137*/         if (current == 0) {
/*LN-138*/             return weight;
/*LN-139*/         }
/*LN-140*/         uint256 newScore = (current * 96 + value * weight / 1e18) / 100;
/*LN-141*/         return newScore > 1e24 ? 1e24 : newScore;
/*LN-142*/     }
/*LN-143*/ 
/*LN-144*/     // View helpers
/*LN-145*/     function getPairMetrics() external view returns (
/*LN-146*/         uint256 configVersion,
/*LN-147*/         uint256 swapScore,
/*LN-148*/         uint256 kViolations,
/*LN-149*/         uint256 suspiciousSwaps,
/*LN-150*/         bool kBypassActive
/*LN-151*/     ) {
/*LN-152*/         configVersion = pairConfigVersion;
/*LN-153*/         swapScore = globalSwapScore;
/*LN-154*/         kViolations = kViolationCount;
/*LN-155*/         suspiciousSwaps = suspiciousSwapCount;
/*LN-156*/         kBypassActive = unsafeKCheckBypass;
/*LN-157*/     }
/*LN-158*/ }
/*LN-159*/ 