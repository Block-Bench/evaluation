/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ contract ConcentratedPool {
/*LN-4*/ 
/*LN-5*/     address public token0;
/*LN-6*/     address public token1;
/*LN-7*/ 
/*LN-8*/ 
/*LN-9*/     uint160 public sqrtPriceX96;
/*LN-10*/     int24 public currentTick;
/*LN-11*/     uint128 public liquidity;
/*LN-12*/ 
/*LN-13*/ 
/*LN-14*/     mapping(int24 => int128) public liquidityNet;
/*LN-15*/ 
/*LN-16*/ 
/*LN-17*/     struct Position {
/*LN-18*/         uint128 liquidity;
/*LN-19*/         int24 tickLower;
/*LN-20*/         int24 tickUpper;
/*LN-21*/     }
/*LN-22*/ 
/*LN-23*/     mapping(bytes32 => Position) public positions;
/*LN-24*/ 
/*LN-25*/     event Swap(
/*LN-26*/         address indexed sender,
/*LN-27*/         uint256 amount0In,
/*LN-28*/         uint256 amount1In,
/*LN-29*/         uint256 amount0Out,
/*LN-30*/         uint256 amount1Out
/*LN-31*/     );
/*LN-32*/ 
/*LN-33*/     event LiquidityAdded(
/*LN-34*/         address indexed provider,
/*LN-35*/         int24 tickLower,
/*LN-36*/         int24 tickUpper,
/*LN-37*/         uint128 liquidity
/*LN-38*/     );
/*LN-39*/ 
/*LN-40*/ 
/*LN-41*/     function addLiquidity(
/*LN-42*/         int24 tickLower,
/*LN-43*/         int24 tickUpper,
/*LN-44*/         uint128 liquidityDelta
/*LN-45*/     ) external returns (uint256 amount0, uint256 amount1) {
/*LN-46*/         require(tickLower < tickUpper, "Invalid ticks");
/*LN-47*/         require(liquidityDelta > 0, "Zero liquidity");
/*LN-48*/ 
/*LN-49*/ 
/*LN-50*/         bytes32 positionKey = keccak256(
/*LN-51*/             abi.encodePacked(msg.sender, tickLower, tickUpper)
/*LN-52*/         );
/*LN-53*/ 
/*LN-54*/ 
/*LN-55*/         Position storage position = positions[positionKey];
/*LN-56*/         position.liquidity += liquidityDelta;
/*LN-57*/         position.tickLower = tickLower;
/*LN-58*/         position.tickUpper = tickUpper;
/*LN-59*/ 
/*LN-60*/ 
/*LN-61*/         liquidityNet[tickLower] += int128(liquidityDelta);
/*LN-62*/         liquidityNet[tickUpper] -= int128(liquidityDelta);
/*LN-63*/ 
/*LN-64*/ 
/*LN-65*/         if (currentTick >= tickLower && currentTick < tickUpper) {
/*LN-66*/             liquidity += liquidityDelta;
/*LN-67*/         }
/*LN-68*/ 
/*LN-69*/ 
/*LN-70*/         (amount0, amount1) = _calculateAmounts(
/*LN-71*/             sqrtPriceX96,
/*LN-72*/             tickLower,
/*LN-73*/             tickUpper,
/*LN-74*/             int128(liquidityDelta)
/*LN-75*/         );
/*LN-76*/ 
/*LN-77*/         emit LiquidityAdded(msg.sender, tickLower, tickUpper, liquidityDelta);
/*LN-78*/     }
/*LN-79*/ 
/*LN-80*/     function swap(
/*LN-81*/         bool zeroForOne,
/*LN-82*/         int256 amountSpecified,
/*LN-83*/         uint160 sqrtPriceLimitX96
/*LN-84*/     ) external returns (int256 amount0, int256 amount1) {
/*LN-85*/         require(amountSpecified != 0, "Zero amount");
/*LN-86*/ 
/*LN-87*/ 
/*LN-88*/         uint160 sqrtPriceX96Next = sqrtPriceX96;
/*LN-89*/         uint128 liquidityNext = liquidity;
/*LN-90*/         int24 tickNext = currentTick;
/*LN-91*/ 
/*LN-92*/ 
/*LN-93*/         while (amountSpecified != 0) {
/*LN-94*/ 
/*LN-95*/             (
/*LN-96*/                 uint256 amountIn,
/*LN-97*/                 uint256 amountOut,
/*LN-98*/                 uint160 sqrtPriceX96Target
/*LN-99*/             ) = _computeSwapStep(
/*LN-100*/                     sqrtPriceX96Next,
/*LN-101*/                     sqrtPriceLimitX96,
/*LN-102*/                     liquidityNext,
/*LN-103*/                     amountSpecified
/*LN-104*/                 );
/*LN-105*/ 
/*LN-106*/ 
/*LN-107*/             sqrtPriceX96Next = sqrtPriceX96Target;
/*LN-108*/ 
/*LN-109*/ 
/*LN-110*/             int24 tickCrossed = _getTickAtSqrtRatio(sqrtPriceX96Next);
/*LN-111*/             if (tickCrossed != tickNext) {
/*LN-112*/ 
/*LN-113*/                 int128 liquidityNetAtTick = liquidityNet[tickCrossed];
/*LN-114*/ 
/*LN-115*/                 if (zeroForOne) {
/*LN-116*/                     liquidityNetAtTick = -liquidityNetAtTick;
/*LN-117*/                 }
/*LN-118*/ 
/*LN-119*/                 liquidityNext = _addLiquidity(
/*LN-120*/                     liquidityNext,
/*LN-121*/                     liquidityNetAtTick
/*LN-122*/                 );
/*LN-123*/ 
/*LN-124*/                 tickNext = tickCrossed;
/*LN-125*/             }
/*LN-126*/ 
/*LN-127*/ 
/*LN-128*/             if (amountSpecified > 0) {
/*LN-129*/                 amountSpecified -= int256(amountIn);
/*LN-130*/             } else {
/*LN-131*/                 amountSpecified += int256(amountOut);
/*LN-132*/             }
/*LN-133*/         }
/*LN-134*/ 
/*LN-135*/ 
/*LN-136*/         sqrtPriceX96 = sqrtPriceX96Next;
/*LN-137*/         liquidity = liquidityNext;
/*LN-138*/         currentTick = tickNext;
/*LN-139*/ 
/*LN-140*/         return (amount0, amount1);
/*LN-141*/     }
/*LN-142*/ 
/*LN-143*/     function _addLiquidity(
/*LN-144*/         uint128 x,
/*LN-145*/         int128 y
/*LN-146*/     ) internal pure returns (uint128 z) {
/*LN-147*/         if (y < 0) {
/*LN-148*/             z = x - uint128(-y);
/*LN-149*/         } else {
/*LN-150*/             z = x + uint128(y);
/*LN-151*/         }
/*LN-152*/ 
/*LN-153*/     }
/*LN-154*/ 
/*LN-155*/ 
/*LN-156*/     function _calculateAmounts(
/*LN-157*/         uint160 sqrtPrice,
/*LN-158*/         int24 tickLower,
/*LN-159*/         int24 tickUpper,
/*LN-160*/         int128 liquidityDelta
/*LN-161*/     ) internal pure returns (uint256 amount0, uint256 amount1) {
/*LN-162*/ 
/*LN-163*/ 
/*LN-164*/         amount0 = uint256(uint128(liquidityDelta)) / 2;
/*LN-165*/         amount1 = uint256(uint128(liquidityDelta)) / 2;
/*LN-166*/     }
/*LN-167*/ 
/*LN-168*/ 
/*LN-169*/     function _computeSwapStep(
/*LN-170*/         uint160 sqrtPriceCurrentX96,
/*LN-171*/         uint160 sqrtPriceTargetX96,
/*LN-172*/         uint128 liquidityCurrent,
/*LN-173*/         int256 amountRemaining
/*LN-174*/     )
/*LN-175*/         internal
/*LN-176*/         pure
/*LN-177*/         returns (uint256 amountIn, uint256 amountOut, uint160 sqrtPriceNextX96)
/*LN-178*/     {
/*LN-179*/ 
/*LN-180*/         amountIn =
/*LN-181*/             uint256(amountRemaining > 0 ? amountRemaining : -amountRemaining) /
/*LN-182*/             2;
/*LN-183*/         amountOut = amountIn;
/*LN-184*/         sqrtPriceNextX96 = sqrtPriceCurrentX96;
/*LN-185*/     }
/*LN-186*/ 
/*LN-187*/ 
/*LN-188*/     function _getTickAtSqrtRatio(
/*LN-189*/         uint160 sqrtPriceX96
/*LN-190*/     ) internal pure returns (int24 tick) {
/*LN-191*/ 
/*LN-192*/         return int24(int256(uint256(sqrtPriceX96 >> 96)));
/*LN-193*/     }
/*LN-194*/ }