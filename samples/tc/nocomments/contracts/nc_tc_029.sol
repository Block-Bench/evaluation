/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-5*/ 
/*LN-6*/     function transferFrom(
/*LN-7*/         address from,
/*LN-8*/         address to,
/*LN-9*/         uint256 amount
/*LN-10*/     ) external returns (bool);
/*LN-11*/ 
/*LN-12*/     function balanceOf(address account) external view returns (uint256);
/*LN-13*/ 
/*LN-14*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-15*/ }
/*LN-16*/ 
/*LN-17*/ interface IFlashLoanReceiver {
/*LN-18*/     function executeOperation(
/*LN-19*/         address[] calldata assets,
/*LN-20*/         uint256[] calldata amounts,
/*LN-21*/         uint256[] calldata premiums,
/*LN-22*/         address initiator,
/*LN-23*/         bytes calldata params
/*LN-24*/     ) external returns (bool);
/*LN-25*/ }
/*LN-26*/ 
/*LN-27*/ contract CrossLendingPool {
/*LN-28*/     uint256 public constant RAY = 1e27;
/*LN-29*/ 
/*LN-30*/     struct ReserveData {
/*LN-31*/         uint256 liquidityIndex;
/*LN-32*/         uint256 totalLiquidity;
/*LN-33*/         address rTokenAddress;
/*LN-34*/     }
/*LN-35*/ 
/*LN-36*/     mapping(address => ReserveData) public reserves;
/*LN-37*/ 
/*LN-38*/ 
/*LN-39*/     function deposit(
/*LN-40*/         address asset,
/*LN-41*/         uint256 amount,
/*LN-42*/         address onBehalfOf,
/*LN-43*/         uint16 referralCode
/*LN-44*/     ) external {
/*LN-45*/         IERC20(asset).transferFrom(msg.sender, address(this), amount);
/*LN-46*/ 
/*LN-47*/         ReserveData storage reserve = reserves[asset];
/*LN-48*/ 
/*LN-49*/         uint256 currentLiquidityIndex = reserve.liquidityIndex;
/*LN-50*/         if (currentLiquidityIndex == 0) {
/*LN-51*/             currentLiquidityIndex = RAY;
/*LN-52*/         }
/*LN-53*/ 
/*LN-54*/ 
/*LN-55*/         reserve.liquidityIndex =
/*LN-56*/             currentLiquidityIndex +
/*LN-57*/             (amount * RAY) /
/*LN-58*/             (reserve.totalLiquidity + 1);
/*LN-59*/         reserve.totalLiquidity += amount;
/*LN-60*/ 
/*LN-61*/ 
/*LN-62*/         uint256 rTokenAmount = rayDiv(amount, reserve.liquidityIndex);
/*LN-63*/         _mintRToken(reserve.rTokenAddress, onBehalfOf, rTokenAmount);
/*LN-64*/     }
/*LN-65*/ 
/*LN-66*/ 
/*LN-67*/     function withdraw(
/*LN-68*/         address asset,
/*LN-69*/         uint256 amount,
/*LN-70*/         address to
/*LN-71*/     ) external returns (uint256) {
/*LN-72*/         ReserveData storage reserve = reserves[asset];
/*LN-73*/ 
/*LN-74*/         uint256 rTokensToBurn = rayDiv(amount, reserve.liquidityIndex);
/*LN-75*/ 
/*LN-76*/         _burnRToken(reserve.rTokenAddress, msg.sender, rTokensToBurn);
/*LN-77*/ 
/*LN-78*/         reserve.totalLiquidity -= amount;
/*LN-79*/         IERC20(asset).transfer(to, amount);
/*LN-80*/ 
/*LN-81*/         return amount;
/*LN-82*/     }
/*LN-83*/ 
/*LN-84*/ 
/*LN-85*/     function borrow(
/*LN-86*/         address asset,
/*LN-87*/         uint256 amount,
/*LN-88*/         uint256 interestRateMode,
/*LN-89*/         uint16 referralCode,
/*LN-90*/         address onBehalfOf
/*LN-91*/     ) external {
/*LN-92*/ 
/*LN-93*/         IERC20(asset).transfer(onBehalfOf, amount);
/*LN-94*/     }
/*LN-95*/ 
/*LN-96*/ 
/*LN-97*/     function flashLoan(
/*LN-98*/         address receiverAddress,
/*LN-99*/         address[] calldata assets,
/*LN-100*/         uint256[] calldata amounts,
/*LN-101*/         uint256[] calldata modes,
/*LN-102*/         address onBehalfOf,
/*LN-103*/         bytes calldata params,
/*LN-104*/         uint16 referralCode
/*LN-105*/     ) external {
/*LN-106*/         for (uint256 i = 0; i < assets.length; i++) {
/*LN-107*/             IERC20(assets[i]).transfer(receiverAddress, amounts[i]);
/*LN-108*/         }
/*LN-109*/ 
/*LN-110*/ 
/*LN-111*/         require(
/*LN-112*/             IFlashLoanReceiver(receiverAddress).executeOperation(
/*LN-113*/                 assets,
/*LN-114*/                 amounts,
/*LN-115*/                 new uint256[](assets.length),
/*LN-116*/                 msg.sender,
/*LN-117*/                 params
/*LN-118*/             ),
/*LN-119*/             "Flashloan callback failed"
/*LN-120*/         );
/*LN-121*/ 
/*LN-122*/ 
/*LN-123*/         for (uint256 i = 0; i < assets.length; i++) {
/*LN-124*/             IERC20(assets[i]).transferFrom(
/*LN-125*/                 receiverAddress,
/*LN-126*/                 address(this),
/*LN-127*/                 amounts[i]
/*LN-128*/             );
/*LN-129*/         }
/*LN-130*/     }
/*LN-131*/ 
/*LN-132*/ 
/*LN-133*/     function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
/*LN-134*/         uint256 halfB = b / 2;
/*LN-135*/         require(b != 0, "Division by zero");
/*LN-136*/         return (a * RAY + halfB) / b;
/*LN-137*/     }
/*LN-138*/ 
/*LN-139*/     function _mintRToken(address rToken, address to, uint256 amount) internal {
/*LN-140*/ 
/*LN-141*/     }
/*LN-142*/ 
/*LN-143*/     function _burnRToken(
/*LN-144*/         address rToken,
/*LN-145*/         address from,
/*LN-146*/         uint256 amount
/*LN-147*/     ) internal {
/*LN-148*/ 
/*LN-149*/     }
/*LN-150*/ }