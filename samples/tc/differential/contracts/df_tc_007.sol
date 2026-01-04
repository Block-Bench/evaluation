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
/*LN-31*/     event Swap(
/*LN-32*/         address indexed sender,
/*LN-33*/         uint256 amount0In,
/*LN-34*/         uint256 amount1In,
/*LN-35*/         uint256 amount0Out,
/*LN-36*/         uint256 amount1Out
/*LN-37*/     );
/*LN-38*/ 
/*LN-39*/     event LiquidityAdded(
/*LN-40*/         address indexed provider,
/*LN-41*/         int24 tickLower,
/*LN-42*/         int24 tickUpper,
/*LN-43*/         uint128 liquidity
/*LN-44*/     );
/*LN-45*/ 
/*LN-46*/     /**
/*LN-47*/      * @notice Add liquidity to a price range
/*LN-48*/      * @param tickLower Lower tick of range
/*LN-49*/      * @param tickUpper Upper tick of range
/*LN-50*/      * @param liquidityDelta Amount of liquidity to add
/*LN-51*/      */
/*LN-52*/     function addLiquidity(
/*LN-53*/         int24 tickLower,
/*LN-54*/         int24 tickUpper,
/*LN-55*/         uint128 liquidityDelta
/*LN-56*/     ) external returns (uint256 amount0, uint256 amount1) {
/*LN-57*/         require(tickLower < tickUpper, "Invalid ticks");
/*LN-58*/         require(liquidityDelta > 0, "Zero liquidity");
/*LN-59*/ 
/*LN-60*/         // Create position ID
/*LN-61*/         bytes32 positionKey = keccak256(
/*LN-62*/             abi.encodePacked(msg.sender, tickLower, tickUpper)
/*LN-63*/         );
/*LN-64*/ 
/*LN-65*/         // Update position
/*LN-66*/         Position storage position = positions[positionKey];
/*LN-67*/         position.liquidity += liquidityDelta;
/*LN-68*/         position.tickLower = tickLower;
/*LN-69*/         position.tickUpper = tickUpper;
/*LN-70*/ 
/*LN-71*/         // Update tick liquidity
/*LN-72*/         liquidityNet[tickLower] += int128(liquidityDelta);
/*LN-73*/         liquidityNet[tickUpper] -= int128(liquidityDelta);
/*LN-74*/ 
/*LN-75*/         // If current price is in range, update active liquidity
/*LN-76*/         if (currentTick >= tickLower && currentTick < tickUpper) {
/*LN-77*/             liquidity += liquidityDelta;
/*LN-78*/         }
/*LN-79*/ 
/*LN-80*/         // Calculate required amounts
/*LN-81*/         (amount0, amount1) = _calculateAmounts(
/*LN-82*/             sqrtPriceX96,
/*LN-83*/             tickLower,
/*LN-84*/             tickUpper,
/*LN-85*/             int128(liquidityDelta)
/*LN-86*/         );
/*LN-87*/ 
/*LN-88*/         emit LiquidityAdded(msg.sender, tickLower, tickUpper, liquidityDelta);
/*LN-89*/     }
/*LN-90*/ 
/*LN-91*/     /**
/*LN-92*/      * @notice Execute a swap
/*LN-93*/      * @param zeroForOne Direction of swap
/*LN-94*/      * @param amountSpecified Amount to swap
/*LN-95*/      * @param sqrtPriceLimitX96 Price limit for the swap
/*LN-96*/      */
/*LN-97*/     function swap(
/*LN-98*/         bool zeroForOne,
/*LN-99*/         int256 amountSpecified,
/*LN-100*/         uint160 sqrtPriceLimitX96
/*LN-101*/     ) external returns (int256 amount0, int256 amount1) {
/*LN-102*/         require(amountSpecified != 0, "Zero amount");
/*LN-103*/ 
/*LN-104*/         // Swap state
/*LN-105*/         uint160 sqrtPriceX96Next = sqrtPriceX96;
/*LN-106*/         uint128 liquidityNext = liquidity;
/*LN-107*/         int24 tickNext = currentTick;
/*LN-108*/ 
/*LN-109*/         // Simulate swap steps
/*LN-110*/         while (amountSpecified != 0) {
/*LN-111*/             // Calculate how much can be swapped in current tick
/*LN-112*/             (
/*LN-113*/                 uint256 amountIn,
/*LN-114*/                 uint256 amountOut,
/*LN-115*/                 uint160 sqrtPriceX96Target
/*LN-116*/             ) = _computeSwapStep(
/*LN-117*/                     sqrtPriceX96Next,
/*LN-118*/                     sqrtPriceLimitX96,
/*LN-119*/                     liquidityNext,
/*LN-120*/                     amountSpecified
/*LN-121*/                 );
/*LN-122*/ 
/*LN-123*/             // Update price
/*LN-124*/             sqrtPriceX96Next = sqrtPriceX96Target;
/*LN-125*/ 
/*LN-126*/             // Check if we crossed a tick
/*LN-127*/             int24 tickCrossed = _getTickAtSqrtRatio(sqrtPriceX96Next);
/*LN-128*/             if (tickCrossed != tickNext) {
/*LN-129*/                 // Tick crossing involves liquidity updates
/*LN-130*/                 int128 liquidityNetAtTick = liquidityNet[tickCrossed];
/*LN-131*/ 
/*LN-132*/                 if (zeroForOne) {
/*LN-133*/                     liquidityNetAtTick = -liquidityNetAtTick;
/*LN-134*/                 }
/*LN-135*/ 
/*LN-136*/                 liquidityNext = _addLiquidity(
/*LN-137*/                     liquidityNext,
/*LN-138*/                     liquidityNetAtTick
/*LN-139*/                 );
/*LN-140*/ 
/*LN-141*/                 tickNext = tickCrossed;
/*LN-142*/             }
/*LN-143*/ 
/*LN-144*/             // Update remaining amount
/*LN-145*/             if (amountSpecified > 0) {
/*LN-146*/                 amountSpecified -= int256(amountIn);
/*LN-147*/             } else {
/*LN-148*/                 amountSpecified += int256(amountOut);
/*LN-149*/             }
/*LN-150*/         }
/*LN-151*/ 
/*LN-152*/         // Update state
/*LN-153*/         sqrtPriceX96 = sqrtPriceX96Next;
/*LN-154*/         liquidity = liquidityNext;
/*LN-155*/         currentTick = tickNext;
/*LN-156*/ 
/*LN-157*/         return (amount0, amount1);
/*LN-158*/     }
/*LN-159*/ 
/*LN-160*/     /**
/*LN-161*/      * @notice Add signed liquidity value
/*LN-162*/      */
/*LN-163*/     function _addLiquidity(
/*LN-164*/         uint128 x,
/*LN-165*/         int128 y
/*LN-166*/     ) internal pure returns (uint128 z) {
/*LN-167*/         if (y < 0) {
/*LN-168*/             require(x >= uint128(-y), "Underflow");
/*LN-169*/             z = x - uint128(-y);
/*LN-170*/         } else {
/*LN-171*/             require(x + uint128(y) >= x, "Overflow");
/*LN-172*/             z = x + uint128(y);
/*LN-173*/         }
/*LN-174*/     }
/*LN-175*/ 
/*LN-176*/     /**
/*LN-177*/      * @notice Calculate amounts for liquidity
/*LN-178*/      */
/*LN-179*/     function _calculateAmounts(
/*LN-180*/         uint160 sqrtPrice,
/*LN-181*/         int24 tickLower,
/*LN-182*/         int24 tickUpper,
/*LN-183*/         int128 liquidityDelta
/*LN-184*/     ) internal pure returns (uint256 amount0, uint256 amount1) {
/*LN-185*/         amount0 = uint256(uint128(liquidityDelta)) / 2;
/*LN-186*/         amount1 = uint256(uint128(liquidityDelta)) / 2;
/*LN-187*/     }
/*LN-188*/ 
/*LN-189*/     /**
/*LN-190*/      * @notice Compute single swap step
/*LN-191*/      */
/*LN-192*/     function _computeSwapStep(
/*LN-193*/         uint160 sqrtPriceCurrentX96,
/*LN-194*/         uint160 sqrtPriceTargetX96,
/*LN-195*/         uint128 liquidityCurrent,
/*LN-196*/         int256 amountRemaining
/*LN-197*/     )
/*LN-198*/         internal
/*LN-199*/         pure
/*LN-200*/         returns (uint256 amountIn, uint256 amountOut, uint160 sqrtPriceNextX96)
/*LN-201*/     {
/*LN-202*/         amountIn =
/*LN-203*/             uint256(amountRemaining > 0 ? amountRemaining : -amountRemaining) / 2;
/*LN-204*/         amountOut = amountIn;
/*LN-205*/         sqrtPriceNextX96 = sqrtPriceCurrentX96;
/*LN-206*/     }
/*LN-207*/ 
/*LN-208*/     /**
/*LN-209*/      * @notice Get tick at sqrt ratio
/*LN-210*/      */
/*LN-211*/     function _getTickAtSqrtRatio(
/*LN-212*/         uint160 sqrtPriceX96
/*LN-213*/     ) internal pure returns (int24 tick) {
/*LN-214*/         return int24(int256(uint256(sqrtPriceX96 >> 96)));
/*LN-215*/     }
/*LN-216*/ }
/*LN-217*/ 