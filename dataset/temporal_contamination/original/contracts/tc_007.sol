/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title KyberSwap Elastic (Vulnerable Version)
/*LN-6*/  * @notice This contract demonstrates the vulnerability that led to the $47M KyberSwap hack
/*LN-7*/  * @dev November 22, 2023 - Liquidity calculation precision loss vulnerability
/*LN-8*/  *
/*LN-9*/  * VULNERABILITY: Precision loss in liquidity calculations + tick manipulation
/*LN-10*/  *
/*LN-11*/  * ROOT CAUSE:
/*LN-12*/  * KyberSwap Elastic (concentrated liquidity AMM similar to Uniswap V3) had a
/*LN-13*/  * vulnerability in how it calculated liquidity changes across price ticks.
/*LN-14*/  *
/*LN-15*/  * The protocol used a complex formula to track liquidity at different price points:
/*LN-16*/  * - Liquidity providers deposit at specific price ranges (ticks)
/*LN-17*/  * - When price crosses a tick, liquidity is activated/deactivated
/*LN-18*/  * - Protocol must precisely track these liquidity changes
/*LN-19*/  *
/*LN-20*/  * The vulnerability involved:
/*LN-21*/  * 1. Rounding errors in liquidity calculations
/*LN-22*/  * 2. Ability to manipulate these errors via specific swap patterns
/*LN-23*/  * 3. Creating positions that cause liquidity math overflow/underflow
/*LN-24*/  * 4. Draining liquidity from the pool
/*LN-25*/  *
/*LN-26*/  * ATTACK VECTOR:
/*LN-27*/  * 1. Flash loan large amount of tokens
/*LN-28*/  * 2. Create liquidity positions at strategic ticks
/*LN-29*/  * 3. Execute swaps that cause tick transitions
/*LN-30*/  * 4. Trigger rounding errors in liquidity calculations
/*LN-31*/  * 5. Exploit the errors to extract more tokens than deposited
/*LN-32*/  * 6. Repeat across multiple pools
/*LN-33*/  * 7. Repay flash loans with profit
/*LN-34*/  */
/*LN-35*/ 
/*LN-36*/ contract VulnerableKyberSwapPool {
/*LN-37*/     // Token addresses
/*LN-38*/     address public token0;
/*LN-39*/     address public token1;
/*LN-40*/ 
/*LN-41*/     // Current state
/*LN-42*/     uint160 public sqrtPriceX96; // Current price in sqrt(token1/token0) * 2^96
/*LN-43*/     int24 public currentTick; // Current tick (log base 1.0001 of price)
/*LN-44*/     uint128 public liquidity; // Active liquidity at current tick
/*LN-45*/ 
/*LN-46*/     // Liquidity at each tick
/*LN-47*/     mapping(int24 => int128) public liquidityNet; // Net liquidity change at tick
/*LN-48*/ 
/*LN-49*/     // Position tracking
/*LN-50*/     struct Position {
/*LN-51*/         uint128 liquidity;
/*LN-52*/         int24 tickLower;
/*LN-53*/         int24 tickUpper;
/*LN-54*/     }
/*LN-55*/ 
/*LN-56*/     mapping(bytes32 => Position) public positions;
/*LN-57*/ 
/*LN-58*/     event Swap(
/*LN-59*/         address indexed sender,
/*LN-60*/         uint256 amount0In,
/*LN-61*/         uint256 amount1In,
/*LN-62*/         uint256 amount0Out,
/*LN-63*/         uint256 amount1Out
/*LN-64*/     );
/*LN-65*/ 
/*LN-66*/     event LiquidityAdded(
/*LN-67*/         address indexed provider,
/*LN-68*/         int24 tickLower,
/*LN-69*/         int24 tickUpper,
/*LN-70*/         uint128 liquidity
/*LN-71*/     );
/*LN-72*/ 
/*LN-73*/     /**
/*LN-74*/      * @notice Add liquidity to a price range
/*LN-75*/      * @param tickLower Lower tick of range
/*LN-76*/      * @param tickUpper Upper tick of range
/*LN-77*/      * @param liquidityDelta Amount of liquidity to add
/*LN-78*/      *
/*LN-79*/      * This function is complex and has precision issues
/*LN-80*/      */
/*LN-81*/     function addLiquidity(
/*LN-82*/         int24 tickLower,
/*LN-83*/         int24 tickUpper,
/*LN-84*/         uint128 liquidityDelta
/*LN-85*/     ) external returns (uint256 amount0, uint256 amount1) {
/*LN-86*/         require(tickLower < tickUpper, "Invalid ticks");
/*LN-87*/         require(liquidityDelta > 0, "Zero liquidity");
/*LN-88*/ 
/*LN-89*/         // Create position ID
/*LN-90*/         bytes32 positionKey = keccak256(
/*LN-91*/             abi.encodePacked(msg.sender, tickLower, tickUpper)
/*LN-92*/         );
/*LN-93*/ 
/*LN-94*/         // Update position
/*LN-95*/         Position storage position = positions[positionKey];
/*LN-96*/         position.liquidity += liquidityDelta;
/*LN-97*/         position.tickLower = tickLower;
/*LN-98*/         position.tickUpper = tickUpper;
/*LN-99*/ 
/*LN-100*/         // Update tick liquidity
/*LN-101*/         // VULNERABILITY: These updates can have rounding errors
/*LN-102*/         liquidityNet[tickLower] += int128(liquidityDelta);
/*LN-103*/         liquidityNet[tickUpper] -= int128(liquidityDelta);
/*LN-104*/ 
/*LN-105*/         // If current price is in range, update active liquidity
/*LN-106*/         if (currentTick >= tickLower && currentTick < tickUpper) {
/*LN-107*/             liquidity += liquidityDelta;
/*LN-108*/         }
/*LN-109*/ 
/*LN-110*/         // Calculate required amounts (simplified)
/*LN-111*/         // VULNERABILITY: Precision loss in these calculations
/*LN-112*/         (amount0, amount1) = _calculateAmounts(
/*LN-113*/             sqrtPriceX96,
/*LN-114*/             tickLower,
/*LN-115*/             tickUpper,
/*LN-116*/             int128(liquidityDelta)
/*LN-117*/         );
/*LN-118*/ 
/*LN-119*/         emit LiquidityAdded(msg.sender, tickLower, tickUpper, liquidityDelta);
/*LN-120*/     }
/*LN-121*/ 
/*LN-122*/     /**
/*LN-123*/      * @notice Execute a swap
/*LN-124*/      * @param zeroForOne Direction of swap (token0 -> token1 or vice versa)
/*LN-125*/      * @param amountSpecified Amount to swap (positive for exact in, negative for exact out)
/*LN-126*/      * @param sqrtPriceLimitX96 Price limit for the swap
/*LN-127*/      *
/*LN-128*/      * VULNERABILITY:
/*LN-129*/      * The swap function crosses ticks and updates liquidity. The liquidity
/*LN-130*/      * updates involve complex math with potential for precision loss and
/*LN-131*/      * manipulation.
/*LN-132*/      */
/*LN-133*/     function swap(
/*LN-134*/         bool zeroForOne,
/*LN-135*/         int256 amountSpecified,
/*LN-136*/         uint160 sqrtPriceLimitX96
/*LN-137*/     ) external returns (int256 amount0, int256 amount1) {
/*LN-138*/         require(amountSpecified != 0, "Zero amount");
/*LN-139*/ 
/*LN-140*/         // Swap state
/*LN-141*/         uint160 sqrtPriceX96Next = sqrtPriceX96;
/*LN-142*/         uint128 liquidityNext = liquidity;
/*LN-143*/         int24 tickNext = currentTick;
/*LN-144*/ 
/*LN-145*/         // Simulate swap steps (simplified)
/*LN-146*/         // In reality, this loops through ticks
/*LN-147*/         while (amountSpecified != 0) {
/*LN-148*/             // Calculate how much can be swapped in current tick
/*LN-149*/             (
/*LN-150*/                 uint256 amountIn,
/*LN-151*/                 uint256 amountOut,
/*LN-152*/                 uint160 sqrtPriceX96Target
/*LN-153*/             ) = _computeSwapStep(
/*LN-154*/                     sqrtPriceX96Next,
/*LN-155*/                     sqrtPriceLimitX96,
/*LN-156*/                     liquidityNext,
/*LN-157*/                     amountSpecified
/*LN-158*/                 );
/*LN-159*/ 
/*LN-160*/             // Update price
/*LN-161*/             sqrtPriceX96Next = sqrtPriceX96Target;
/*LN-162*/ 
/*LN-163*/             // Check if we crossed a tick
/*LN-164*/             int24 tickCrossed = _getTickAtSqrtRatio(sqrtPriceX96Next);
/*LN-165*/             if (tickCrossed != tickNext) {
/*LN-166*/                 // VULNERABILITY: Tick crossing involves liquidity updates
/*LN-167*/                 // These updates can accumulate precision errors
/*LN-168*/                 int128 liquidityNetAtTick = liquidityNet[tickCrossed];
/*LN-169*/ 
/*LN-170*/                 if (zeroForOne) {
/*LN-171*/                     liquidityNetAtTick = -liquidityNetAtTick;
/*LN-172*/                 }
/*LN-173*/ 
/*LN-174*/                 // VULNERABILITY: This addition can overflow/underflow with manipulation
/*LN-175*/                 // The attacker can create positions that cause this calculation to be wrong
/*LN-176*/                 liquidityNext = _addLiquidity(
/*LN-177*/                     liquidityNext,
/*LN-178*/                     liquidityNetAtTick
/*LN-179*/                 );
/*LN-180*/ 
/*LN-181*/                 tickNext = tickCrossed;
/*LN-182*/             }
/*LN-183*/ 
/*LN-184*/             // Update remaining amount (simplified)
/*LN-185*/             if (amountSpecified > 0) {
/*LN-186*/                 amountSpecified -= int256(amountIn);
/*LN-187*/             } else {
/*LN-188*/                 amountSpecified += int256(amountOut);
/*LN-189*/             }
/*LN-190*/         }
/*LN-191*/ 
/*LN-192*/         // Update state
/*LN-193*/         sqrtPriceX96 = sqrtPriceX96Next;
/*LN-194*/         liquidity = liquidityNext;
/*LN-195*/         currentTick = tickNext;
/*LN-196*/ 
/*LN-197*/         return (amount0, amount1);
/*LN-198*/     }
/*LN-199*/ 
/*LN-200*/     /**
/*LN-201*/      * @notice Add signed liquidity value
/*LN-202*/      * @dev VULNERABILITY: This can overflow/underflow with specific inputs
/*LN-203*/      */
/*LN-204*/     function _addLiquidity(
/*LN-205*/         uint128 x,
/*LN-206*/         int128 y
/*LN-207*/     ) internal pure returns (uint128 z) {
/*LN-208*/         if (y < 0) {
/*LN-209*/             // VULNERABILITY: Subtraction can underflow
/*LN-210*/             z = x - uint128(-y);
/*LN-211*/         } else {
/*LN-212*/             // VULNERABILITY: Addition can overflow
/*LN-213*/             z = x + uint128(y);
/*LN-214*/         }
/*LN-215*/         // No overflow/underflow checks!
/*LN-216*/     }
/*LN-217*/ 
/*LN-218*/     /**
/*LN-219*/      * @notice Calculate amounts for liquidity (simplified)
/*LN-220*/      */
/*LN-221*/     function _calculateAmounts(
/*LN-222*/         uint160 sqrtPrice,
/*LN-223*/         int24 tickLower,
/*LN-224*/         int24 tickUpper,
/*LN-225*/         int128 liquidityDelta
/*LN-226*/     ) internal pure returns (uint256 amount0, uint256 amount1) {
/*LN-227*/         // Simplified calculation
/*LN-228*/         // Real implementation is much more complex and has precision issues
/*LN-229*/         amount0 = uint256(uint128(liquidityDelta)) / 2;
/*LN-230*/         amount1 = uint256(uint128(liquidityDelta)) / 2;
/*LN-231*/     }
/*LN-232*/ 
/*LN-233*/     /**
/*LN-234*/      * @notice Compute single swap step (simplified)
/*LN-235*/      */
/*LN-236*/     function _computeSwapStep(
/*LN-237*/         uint160 sqrtPriceCurrentX96,
/*LN-238*/         uint160 sqrtPriceTargetX96,
/*LN-239*/         uint128 liquidityCurrent,
/*LN-240*/         int256 amountRemaining
/*LN-241*/     )
/*LN-242*/         internal
/*LN-243*/         pure
/*LN-244*/         returns (uint256 amountIn, uint256 amountOut, uint160 sqrtPriceNextX96)
/*LN-245*/     {
/*LN-246*/         // Simplified - real math is extremely complex
/*LN-247*/         amountIn =
/*LN-248*/             uint256(amountRemaining > 0 ? amountRemaining : -amountRemaining) /
/*LN-249*/             2;
/*LN-250*/         amountOut = amountIn;
/*LN-251*/         sqrtPriceNextX96 = sqrtPriceCurrentX96;
/*LN-252*/     }
/*LN-253*/ 
/*LN-254*/     /**
/*LN-255*/      * @notice Get tick at sqrt ratio (simplified)
/*LN-256*/      */
/*LN-257*/     function _getTickAtSqrtRatio(
/*LN-258*/         uint160 sqrtPriceX96
/*LN-259*/     ) internal pure returns (int24 tick) {
/*LN-260*/         // Simplified - real calculation involves logarithms
/*LN-261*/         return int24(int256(uint256(sqrtPriceX96 >> 96)));
/*LN-262*/     }
/*LN-263*/ }
/*LN-264*/ 
/*LN-265*/ /**
/*LN-266*/  * REAL-WORLD IMPACT:
/*LN-267*/  * - $47M stolen on November 22, 2023
/*LN-268*/  * - Affected multiple chains (Ethereum, Polygon, BSC, Arbitrum)
/*LN-269*/  * - Complex attack requiring deep understanding of concentrated liquidity math
/*LN-270*/  * - Attacker left on-chain message negotiating for bounty
/*LN-271*/  *
/*LN-272*/  * ATTACK COMPLEXITY:
/*LN-273*/  * The KyberSwap attack was one of the most technically sophisticated DeFi hacks.
/*LN-274*/  * It required:
/*LN-275*/  * 1. Understanding of concentrated liquidity mechanics (Uniswap V3-style)
/*LN-276*/  * 2. Knowledge of precision loss in fixed-point arithmetic
/*LN-277*/  * 3. Ability to manipulate tick transitions to trigger specific calculation errors
/*LN-278*/  * 4. Coordinated execution across multiple pools and chains
/*LN-279*/  *
/*LN-280*/  * FIX:
/*LN-281*/  * The fix required:
/*LN-282*/  * 1. Add overflow/underflow checks in liquidity calculations
/*LN-283*/  * 2. Use SafeMath or Solidity 0.8+ checked arithmetic
/*LN-284*/  * 3. More precise rounding in liquidity delta calculations
/*LN-285*/  * 4. Validate liquidity values before and after tick crossings
/*LN-286*/  * 5. Add invariant checks to detect impossible states
/*LN-287*/  * 6. Implement emergency pause for anomalous behavior
/*LN-288*/  * 7. More rigorous testing of edge cases in tick math
/*LN-289*/  *
/*LN-290*/  * KEY LESSON:
/*LN-291*/  * Concentrated liquidity AMMs are extremely complex with intricate math.
/*LN-292*/  * Even subtle rounding errors or precision loss can be exploited.
/*LN-293*/  * The vulnerability required deep mathematical understanding to exploit,
/*LN-294*/  * making it one of the most sophisticated attacks in DeFi history.
/*LN-295*/  *
/*LN-296*/  *
/*LN-297*/  * AFTERMATH:
/*LN-298*/  * The attacker attempted to negotiate with the KyberSwap team, requesting
/*LN-299*/  * control of the company in exchange for returning funds. The team rejected
/*LN-300*/  * this demand. Most funds were not recovered.
/*LN-301*/  */
/*LN-302*/ 