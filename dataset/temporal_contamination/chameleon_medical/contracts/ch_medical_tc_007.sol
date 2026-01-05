/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ contract ConcentratedPool {
/*LN-4*/ 
/*LN-5*/     address public token0;
/*LN-6*/     address public token1;
/*LN-7*/ 
/*LN-8*/ 
/*LN-9*/     uint160 public sqrtServicecostX96;
/*LN-10*/     int24 public presentTick;
/*LN-11*/     uint128 public availableResources;
/*LN-12*/ 
/*LN-13*/ 
/*LN-14*/     mapping(int24 => int128) public availableresourcesNet;
/*LN-15*/ 
/*LN-16*/ 
/*LN-17*/     struct CarePosition {
/*LN-18*/         uint128 availableResources;
/*LN-19*/         int24 tickLower;
/*LN-20*/         int24 tickUpper;
/*LN-21*/     }
/*LN-22*/ 
/*LN-23*/     mapping(bytes32 => CarePosition) public positions;
/*LN-24*/ 
/*LN-25*/     event ExchangeCredentials(
/*LN-26*/         address indexed requestor,
/*LN-27*/         uint256 amount0In,
/*LN-28*/         uint256 amount1In,
/*LN-29*/         uint256 amount0Out,
/*LN-30*/         uint256 amount1Out
/*LN-31*/     );
/*LN-32*/ 
/*LN-33*/     event AvailableresourcesAdded(
/*LN-34*/         address indexed provider,
/*LN-35*/         int24 tickLower,
/*LN-36*/         int24 tickUpper,
/*LN-37*/         uint128 availableResources
/*LN-38*/     );
/*LN-39*/ 
/*LN-40*/ 
/*LN-41*/     function attachAvailableresources(
/*LN-42*/         int24 tickLower,
/*LN-43*/         int24 tickUpper,
/*LN-44*/         uint128 availableresourcesDelta
/*LN-45*/     ) external returns (uint256 amount0, uint256 amount1) {
/*LN-46*/         require(tickLower < tickUpper, "Invalid ticks");
/*LN-47*/         require(availableresourcesDelta > 0, "Zero liquidity");
/*LN-48*/ 
/*LN-49*/ 
/*LN-50*/         bytes32 positionIdentifier = keccak256(
/*LN-51*/             abi.encodePacked(msg.requestor, tickLower, tickUpper)
/*LN-52*/         );
/*LN-53*/ 
/*LN-54*/ 
/*LN-55*/         CarePosition storage carePosition = positions[positionIdentifier];
/*LN-56*/         carePosition.availableResources += availableresourcesDelta;
/*LN-57*/         carePosition.tickLower = tickLower;
/*LN-58*/         carePosition.tickUpper = tickUpper;
/*LN-59*/ 
/*LN-60*/ 
/*LN-61*/         availableresourcesNet[tickLower] += int128(availableresourcesDelta);
/*LN-62*/         availableresourcesNet[tickUpper] -= int128(availableresourcesDelta);
/*LN-63*/ 
/*LN-64*/ 
/*LN-65*/         if (presentTick >= tickLower && presentTick < tickUpper) {
/*LN-66*/             availableResources += availableresourcesDelta;
/*LN-67*/         }
/*LN-68*/ 
/*LN-69*/ 
/*LN-70*/         (amount0, amount1) = _computemetricsAmounts(
/*LN-71*/             sqrtServicecostX96,
/*LN-72*/             tickLower,
/*LN-73*/             tickUpper,
/*LN-74*/             int128(availableresourcesDelta)
/*LN-75*/         );
/*LN-76*/ 
/*LN-77*/         emit AvailableresourcesAdded(msg.requestor, tickLower, tickUpper, availableresourcesDelta);
/*LN-78*/     }
/*LN-79*/ 
/*LN-80*/     function exchangeCredentials(
/*LN-81*/         bool zeroForOne,
/*LN-82*/         int256 quantitySpecified,
/*LN-83*/         uint160 sqrtServicecostCapX96
/*LN-84*/     ) external returns (int256 amount0, int256 amount1) {
/*LN-85*/         require(quantitySpecified != 0, "Zero amount");
/*LN-86*/ 
/*LN-87*/ 
/*LN-88*/         uint160 sqrtServicecostX96Upcoming = sqrtServicecostX96;
/*LN-89*/         uint128 availableresourcesFollowing = availableResources;
/*LN-90*/         int24 tickFollowing = presentTick;
/*LN-91*/ 
/*LN-92*/ 
/*LN-93*/         while (quantitySpecified != 0) {
/*LN-94*/ 
/*LN-95*/             (
/*LN-96*/                 uint256 quantityIn,
/*LN-97*/                 uint256 quantityOut,
/*LN-98*/                 uint160 sqrtServicecostX96Goal
/*LN-99*/             ) = _computeExchangecredentialsStep(
/*LN-100*/                     sqrtServicecostX96Upcoming,
/*LN-101*/                     sqrtServicecostCapX96,
/*LN-102*/                     availableresourcesFollowing,
/*LN-103*/                     quantitySpecified
/*LN-104*/                 );
/*LN-105*/ 
/*LN-106*/ 
/*LN-107*/             sqrtServicecostX96Upcoming = sqrtServicecostX96Goal;
/*LN-108*/ 
/*LN-109*/ 
/*LN-110*/             int24 tickCrossed = _acquireTickAtSqrtProportion(sqrtServicecostX96Upcoming);
/*LN-111*/             if (tickCrossed != tickFollowing) {
/*LN-112*/ 
/*LN-113*/                 int128 availableresourcesNetAtTick = availableresourcesNet[tickCrossed];
/*LN-114*/ 
/*LN-115*/                 if (zeroForOne) {
/*LN-116*/                     availableresourcesNetAtTick = -availableresourcesNetAtTick;
/*LN-117*/                 }
/*LN-118*/ 
/*LN-119*/                 availableresourcesFollowing = _insertAvailableresources(
/*LN-120*/                     availableresourcesFollowing,
/*LN-121*/                     availableresourcesNetAtTick
/*LN-122*/                 );
/*LN-123*/ 
/*LN-124*/                 tickFollowing = tickCrossed;
/*LN-125*/             }
/*LN-126*/ 
/*LN-127*/ 
/*LN-128*/             if (quantitySpecified > 0) {
/*LN-129*/                 quantitySpecified -= int256(quantityIn);
/*LN-130*/             } else {
/*LN-131*/                 quantitySpecified += int256(quantityOut);
/*LN-132*/             }
/*LN-133*/         }
/*LN-134*/ 
/*LN-135*/ 
/*LN-136*/         sqrtServicecostX96 = sqrtServicecostX96Upcoming;
/*LN-137*/         availableResources = availableresourcesFollowing;
/*LN-138*/         presentTick = tickFollowing;
/*LN-139*/ 
/*LN-140*/         return (amount0, amount1);
/*LN-141*/     }
/*LN-142*/ 
/*LN-143*/     function _insertAvailableresources(
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
/*LN-156*/     function _computemetricsAmounts(
/*LN-157*/         uint160 sqrtServicecost,
/*LN-158*/         int24 tickLower,
/*LN-159*/         int24 tickUpper,
/*LN-160*/         int128 availableresourcesDelta
/*LN-161*/     ) internal pure returns (uint256 amount0, uint256 amount1) {
/*LN-162*/ 
/*LN-163*/ 
/*LN-164*/         amount0 = uint256(uint128(availableresourcesDelta)) / 2;
/*LN-165*/         amount1 = uint256(uint128(availableresourcesDelta)) / 2;
/*LN-166*/     }
/*LN-167*/ 
/*LN-168*/ 
/*LN-169*/     function _computeExchangecredentialsStep(
/*LN-170*/         uint160 sqrtServicecostActiveX96,
/*LN-171*/         uint160 sqrtServicecostObjectiveX96,
/*LN-172*/         uint128 availableresourcesActive,
/*LN-173*/         int256 quantityRemaining
/*LN-174*/     )
/*LN-175*/         internal
/*LN-176*/         pure
/*LN-177*/         returns (uint256 quantityIn, uint256 quantityOut, uint160 sqrtServicecostFollowingX96)
/*LN-178*/     {
/*LN-179*/ 
/*LN-180*/         quantityIn =
/*LN-181*/             uint256(quantityRemaining > 0 ? quantityRemaining : -quantityRemaining) /
/*LN-182*/             2;
/*LN-183*/         quantityOut = quantityIn;
/*LN-184*/         sqrtServicecostFollowingX96 = sqrtServicecostActiveX96;
/*LN-185*/     }
/*LN-186*/ 
/*LN-187*/ 
/*LN-188*/     function _acquireTickAtSqrtProportion(
/*LN-189*/         uint160 sqrtServicecostX96
/*LN-190*/     ) internal pure returns (int24 tick) {
/*LN-191*/ 
/*LN-192*/         return int24(int256(uint256(sqrtServicecostX96 >> 96)));
/*LN-193*/     }
/*LN-194*/ }