/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title Concentrated Liquidity AMM Pool
/*LN-6*/  * @notice Automated market maker with concentrated liquidity positions
/*LN-7*/  * @dev Allows liquidity providers to concentrate capital at specific price ranges
/*LN-8*/  */
/*LN-9*/ contract ConcentratedLiquidityPool {
/*LN-10*/     // Token addresses
/*LN-11*/     address public token0;
/*LN-12*/     address public token1;
/*LN-13*/ 
/*LN-14*/     // Current state
/*LN-15*/     uint160 public sqrtPriceX96;
/*LN-16*/     int24 public currentTick;
/*LN-17*/     uint128 public liquidity;
/*LN-18*/ 
/*LN-19*/     // Liquidity at each tick
/*LN-20*/     mapping(int24 => int128) public liquidityNet;
/*LN-21*/ 
/*LN-22*/     // Position tracking
/*LN-23*/     struct Position {
/*LN-24*/         uint128 liquidity;
/*LN-25*/         int24 tickLower;
/*LN-26*/         int24 tickUpper;
/*LN-27*/     }
/*LN-28*/ 
/*LN-29*/     mapping(bytes32 => Position) public positions;
/*LN-30*/ 
/*LN-31*/     // Additional configuration and analytics
/*LN-32*/     uint256 public poolConfigVersion;
/*LN-33*/     uint256 public lastRebalanceTimestamp;
/*LN-34*/     uint256 public globalActivityScore;
/*LN-35*/     mapping(address => uint256) public userActivityScore;
/*LN-36*/     mapping(int24 => uint256) public tickUsageCount;
/*LN-37*/ 
/*LN-38*/     event Swap(
/*LN-39*/         address index sender,
/*LN-40*/         uint256 amount0In,
/*LN-41*/         uint256 amount1In,
/*LN-42*/         uint256 amount0Out,
/*LN-43*/         uint256 amount1Out
/*LN-44*/     );
/*LN-45*/ 
/*LN-46*/     event LiquidityAdded(
/*LN-47*/         address index provider,
/*LN-48*/         int24 tickLower,
/*LN-49*/         int24 tickUpper,
/*LN-50*/         uint128 liquidity
/*LN-51*/     );
/*LN-52*/ 
/*LN-53*/     event PoolConfigUpdated(uint256 index version, uint256 timestamp);
/*LN-54*/     event PoolActivity(address index user, uint256 value);
/*LN-55*/ 
/*LN-56*/     /**
/*LN-57*/      * @notice Add liquidity to a price range
/*LN-58*/      * @param tickLower Lower tick of range
/*LN-59*/      * @param tickUpper Upper tick of range
/*LN-60*/      * @param liquidityDelta Amount of liquidity to add
/*LN-61*/      */
/*LN-62*/     function addLiquidity(
/*LN-63*/         int24 tickLower,
/*LN-64*/         int24 tickUpper,
/*LN-65*/         uint128 liquidityDelta
/*LN-66*/     ) external returns (uint256 amount0, uint256 amount1) {
/*LN-67*/         require(tickLower < tickUpper, "Invalid ticks");
/*LN-68*/         require(liquidityDelta > 0, "Zero liquidity");
/*LN-69*/ 
/*LN-70*/         bytes32 positionKey = keccak256(
/*LN-71*/             abi.encodePacked(msg.sender, tickLower, tickUpper)
/*LN-72*/         );
/*LN-73*/ 
/*LN-74*/         Position storage position = positions[positionKey];
/*LN-75*/         position.liquidity += liquidityDelta;
/*LN-76*/         position.tickLower = tickLower;
/*LN-77*/         position.tickUpper = tickUpper;
/*LN-78*/ 
/*LN-79*/         liquidityNet[tickLower] += int128(liquidityDelta);
/*LN-80*/         liquidityNet[tickUpper] -= int128(liquidityDelta);
/*LN-81*/ 
/*LN-82*/         if (currentTick >= tickLower && currentTick < tickUpper) {
/*LN-83*/             liquidity += liquidityDelta;
/*LN-84*/         }
/*LN-85*/ 
/*LN-86*/         (amount0, amount1) = _calculateAmounts(
/*LN-87*/             sqrtPriceX96,
/*LN-88*/             tickLower,
/*LN-89*/             tickUpper,
/*LN-90*/             int128(liquidityDelta)
/*LN-91*/         );
/*LN-92*/ 
/*LN-93*/         _recordPoolActivity(msg.sender, liquidityDelta);
/*LN-94*/         _recordTickUsage(tickLower);
/*LN-95*/         _recordTickUsage(tickUpper);
/*LN-96*/ 
/*LN-97*/         emit LiquidityAdded(msg.sender, tickLower, tickUpper, liquidityDelta);
/*LN-98*/     }
/*LN-99*/ 
/*LN-100*/     /**
/*LN-101*/      * @notice Execute a swap
/*LN-102*/      * @param zeroForOne Direction of swap
/*LN-103*/      * @param amountSpecified Amount to swap
/*LN-104*/      * @param sqrtPriceLimitX96 Price limit for the swap
/*LN-105*/      */
/*LN-106*/     function swap(
/*LN-107*/         bool zeroForOne,
/*LN-108*/         int256 amountSpecified,
/*LN-109*/         uint160 sqrtPriceLimitX96
/*LN-110*/     ) external returns (int256 amount0, int256 amount1) {
/*LN-111*/         require(amountSpecified != 0, "Zero amount");
/*LN-112*/ 
/*LN-113*/         uint160 sqrtPriceX96Next = sqrtPriceX96;
/*LN-114*/         uint128 liquidityNext = liquidity;
/*LN-115*/         int24 tickNext = currentTick;
/*LN-116*/ 
/*LN-117*/         while (amountSpecified != 0) {
/*LN-118*/             (
/*LN-119*/                 uint256 amountIn,
/*LN-120*/                 uint256 amountOut,
/*LN-121*/                 uint160 sqrtPriceX96Target
/*LN-122*/             ) = _computeSwapStep(
/*LN-123*/                     sqrtPriceX96Next,
/*LN-124*/                     sqrtPriceLimitX96,
/*LN-125*/                     liquidityNext,
/*LN-126*/                     amountSpecified
/*LN-127*/                 );
/*LN-128*/ 
/*LN-129*/             sqrtPriceX96Next = sqrtPriceX96Target;
/*LN-130*/ 
/*LN-131*/             int24 tickCrossed = _getTickAtSqrtRatio(sqrtPriceX96Next);
/*LN-132*/             if (tickCrossed != tickNext) {
/*LN-133*/                 int128 liquidityNetAtTick = liquidityNet[tickCrossed];
/*LN-134*/ 
/*LN-135*/                 if (zeroForOne) {
/*LN-136*/                     liquidityNetAtTick = -liquidityNetAtTick;
/*LN-137*/                 }
/*LN-138*/ 
/*LN-139*/                 liquidityNext = _addLiquidity(
/*LN-140*/                     liquidityNext,
/*LN-141*/                     liquidityNetAtTick
/*LN-142*/                 );
/*LN-143*/ 
/*LN-144*/                 tickNext = tickCrossed;
/*LN-145*/                 _recordTickUsage(tickCrossed);
/*LN-146*/             }
/*LN-147*/ 
/*LN-148*/             if (amountSpecified > 0) {
/*LN-149*/                 amountSpecified -= int256(amountIn);
/*LN-150*/             } else {
/*LN-151*/                 amountSpecified += int256(amountOut);
/*LN-152*/             }
/*LN-153*/ 
/*LN-154*/             _recordPoolActivity(msg.sender, amountIn + amountOut);
/*LN-155*/         }
/*LN-156*/ 
/*LN-157*/         sqrtPriceX96 = sqrtPriceX96Next;
/*LN-158*/         liquidity = liquidityNext;
/*LN-159*/         currentTick = tickNext;
/*LN-160*/ 
/*LN-161*/         return (amount0, amount1);
/*LN-162*/     }
/*LN-163*/ 
/*LN-164*/     /**
/*LN-165*/      * @notice Add signed liquidity value
/*LN-166*/      */
/*LN-167*/     function _addLiquidity(
/*LN-168*/         uint128 x,
/*LN-169*/         int128 y
/*LN-170*/     ) internal pure returns (uint128 z) {
/*LN-171*/         if (y < 0) {
/*LN-172*/             z = x - uint128(-y);
/*LN-173*/         } else {
/*LN-174*/             z = x + uint128(y);
/*LN-175*/         }
/*LN-176*/     }
/*LN-177*/ 
/*LN-178*/     /**
/*LN-179*/      * @notice Calculate amounts for liquidity
/*LN-180*/      */
/*LN-181*/     function _calculateAmounts(
/*LN-182*/         uint160 sqrtPrice,
/*LN-183*/         int24 tickLower,
/*LN-184*/         int24 tickUpper,
/*LN-185*/         int128 liquidityDelta
/*LN-186*/     ) internal pure returns (uint256 amount0, uint256 amount1) {
/*LN-187*/         sqrtPrice;
/*LN-188*/         tickLower;
/*LN-189*/         tickUpper;
/*LN-190*/         amount0 = uint256(uint128(liquidityDelta)) / 2;
/*LN-191*/         amount1 = uint256(uint128(liquidityDelta)) / 2;
/*LN-192*/     }
/*LN-193*/ 
/*LN-194*/     /**
/*LN-195*/      * @notice Compute single swap step
/*LN-196*/      */
/*LN-197*/     function _computeSwapStep(
/*LN-198*/         uint160 sqrtPriceCurrentX96,
/*LN-199*/         uint160 sqrtPriceTargetX96,
/*LN-200*/         uint128 liquidityCurrent,
/*LN-201*/         int256 amountRemaining
/*LN-202*/     )
/*LN-203*/         internal
/*LN-204*/         pure
/*LN-205*/         returns (uint256 amountIn, uint256 amountOut, uint160 sqrtPriceNextX96)
/*LN-206*/     {
/*LN-207*/         sqrtPriceTargetX96;
/*LN-208*/         liquidityCurrent;
/*LN-209*/         amountIn =
/*LN-210*/             uint256(amountRemaining > 0 ? amountRemaining : -amountRemaining) /
/*LN-211*/             2;
/*LN-212*/         amountOut = amountIn;
/*LN-213*/         sqrtPriceNextX96 = sqrtPriceCurrentX96;
/*LN-214*/     }
/*LN-215*/ 
/*LN-216*/     /**
/*LN-217*/      * @notice Get tick at sqrt ratio
/*LN-218*/      */
/*LN-219*/     function _getTickAtSqrtRatio(
/*LN-220*/         uint160 sqrtPriceX96_
/*LN-221*/     ) internal pure returns (int24 tick) {
/*LN-222*/         return int24(int256(uint256(sqrtPriceX96_ >> 96)));
/*LN-223*/     }
/*LN-224*/ 
/*LN-225*/     // Configuration-like helper
/*LN-226*/ 
/*LN-227*/     function setPoolConfigVersion(uint256 version) external {
/*LN-228*/         poolConfigVersion = version;
/*LN-229*/         lastRebalanceTimestamp = block.timestamp;
/*LN-230*/         emit PoolConfigUpdated(version, lastRebalanceTimestamp);
/*LN-231*/     }
/*LN-232*/ 
/*LN-233*/     // Internal analytics
/*LN-234*/ 
/*LN-235*/     function _recordPoolActivity(address user, uint256 value) internal {
/*LN-236*/         if (value > 0) {
/*LN-237*/             uint256 incr = value;
/*LN-238*/             if (incr > 1e24) {
/*LN-239*/                 incr = 1e24;
/*LN-240*/             }
/*LN-241*/ 
/*LN-242*/             userActivityScore[user] = _updateScore(userActivityScore[user], incr);
/*LN-243*/             globalActivityScore = _updateScore(globalActivityScore, incr);
/*LN-244*/         }
/*LN-245*/ 
/*LN-246*/         emit PoolActivity(user, value);
/*LN-247*/     }
/*LN-248*/ 
/*LN-249*/     function _recordTickUsage(int24 tick) internal {
/*LN-250*/         tickUsageCount[tick] += 1;
/*LN-251*/     }
/*LN-252*/ 
/*LN-253*/     function _updateScore(
/*LN-254*/         uint256 current,
/*LN-255*/         uint256 value
/*LN-256*/     ) internal pure returns (uint256) {
/*LN-257*/         uint256 updated;
/*LN-258*/         if (current == 0) {
/*LN-259*/             updated = value;
/*LN-260*/         } else {
/*LN-261*/             updated = (current * 9 + value) / 10;
/*LN-262*/         }
/*LN-263*/ 
/*LN-264*/         if (updated > 1e27) {
/*LN-265*/             updated = 1e27;
/*LN-266*/         }
/*LN-267*/ 
/*LN-268*/         return updated;
/*LN-269*/     }
/*LN-270*/ 
/*LN-271*/     // View helpers
/*LN-272*/ 
/*LN-273*/     function getUserMetrics(
/*LN-274*/         address user
/*LN-275*/     ) external view returns (uint256 activityScore) {
/*LN-276*/         activityScore = userActivityScore[user];
/*LN-277*/     }
/*LN-278*/ 
/*LN-279*/     function getPoolMetrics()
/*LN-280*/         external
/*LN-281*/         view
/*LN-282*/         returns (
/*LN-283*/             uint256 configVersion,
/*LN-284*/             uint256 lastRebalance,
/*LN-285*/             uint256 activity
/*LN-286*/         )
/*LN-287*/     {
/*LN-288*/         configVersion = poolConfigVersion;
/*LN-289*/         lastRebalance = lastRebalanceTimestamp;
/*LN-290*/         activity = globalActivityScore;
/*LN-291*/     }
/*LN-292*/ 
/*LN-293*/     function getTickMetrics(
/*LN-294*/         int24 tick
/*LN-295*/     ) external view returns (uint256 usageCount) {
/*LN-296*/         usageCount = tickUsageCount[tick];
/*LN-297*/     }
/*LN-298*/ }
/*LN-299*/ 