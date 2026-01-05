/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/     function transferFrom(
/*LN-7*/         address from,
/*LN-8*/         address to,
/*LN-9*/         uint256 amount
/*LN-10*/     ) external returns (bool);
/*LN-11*/     function balanceOf(address account) external view returns (uint256);
/*LN-12*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-13*/ }
/*LN-14*/ 
/*LN-15*/ interface IFlashLoanReceiver {
/*LN-16*/     function executeOperation(
/*LN-17*/         address[] calldata assets,
/*LN-18*/         uint256[] calldata amounts,
/*LN-19*/         uint256[] calldata premiums,
/*LN-20*/         address initiator,
/*LN-21*/         bytes calldata params
/*LN-22*/     ) external returns (bool);
/*LN-23*/ }
/*LN-24*/ 
/*LN-25*/ contract RadiantLendingPool {
/*LN-26*/     uint256 public constant RAY = 1e27;
/*LN-27*/ 
/*LN-28*/     struct ReserveData {
/*LN-29*/         uint256 liquidityIndex;
/*LN-30*/         uint256 totalLiquidity;
/*LN-31*/         address rTokenAddress;
/*LN-32*/     }
/*LN-33*/ 
/*LN-34*/     mapping(address => ReserveData) public reserves;
/*LN-35*/ 
/*LN-36*/     function deposit(
/*LN-37*/         address asset,
/*LN-38*/         uint256 amount,
/*LN-39*/         address onBehalfOf,
/*LN-40*/         uint16 referralCode
/*LN-41*/     ) external {
/*LN-42*/         IERC20(asset).transferFrom(msg.sender, address(this), amount);
/*LN-43*/ 
/*LN-44*/         ReserveData storage reserve = reserves[asset];
/*LN-45*/ 
/*LN-46*/         uint256 currentLiquidityIndex = reserve.liquidityIndex;
/*LN-47*/         if (currentLiquidityIndex == 0) {
/*LN-48*/             currentLiquidityIndex = RAY;
/*LN-49*/         }
/*LN-50*/ 
/*LN-51*/         reserve.liquidityIndex =
/*LN-52*/             currentLiquidityIndex +
/*LN-53*/             (amount * RAY) /
/*LN-54*/             (reserve.totalLiquidity + 1);
/*LN-55*/         reserve.totalLiquidity += amount;
/*LN-56*/ 
/*LN-57*/         uint256 rTokenAmount = rayDiv(amount, reserve.liquidityIndex);
/*LN-58*/         _mintRToken(reserve.rTokenAddress, onBehalfOf, rTokenAmount);
/*LN-59*/     }
/*LN-60*/ 
/*LN-61*/     function withdraw(
/*LN-62*/         address asset,
/*LN-63*/         uint256 amount,
/*LN-64*/         address to
/*LN-65*/     ) external returns (uint256) {
/*LN-66*/         ReserveData storage reserve = reserves[asset];
/*LN-67*/ 
/*LN-68*/         uint256 rTokensToBurn = rayDiv(amount, reserve.liquidityIndex);
/*LN-69*/ 
/*LN-70*/         _burnRToken(reserve.rTokenAddress, msg.sender, rTokensToBurn);
/*LN-71*/ 
/*LN-72*/         reserve.totalLiquidity -= amount;
/*LN-73*/         IERC20(asset).transfer(to, amount);
/*LN-74*/ 
/*LN-75*/         return amount;
/*LN-76*/     }
/*LN-77*/ 
/*LN-78*/     function borrow(
/*LN-79*/         address asset,
/*LN-80*/         uint256 amount,
/*LN-81*/         uint256 interestRateMode,
/*LN-82*/         uint16 referralCode,
/*LN-83*/         address onBehalfOf
/*LN-84*/     ) external {
/*LN-85*/         IERC20(asset).transfer(onBehalfOf, amount);
/*LN-86*/     }
/*LN-87*/ 
/*LN-88*/     function flashLoan(
/*LN-89*/         address receiverAddress,
/*LN-90*/         address[] calldata assets,
/*LN-91*/         uint256[] calldata amounts,
/*LN-92*/         uint256[] calldata modes,
/*LN-93*/         address onBehalfOf,
/*LN-94*/         bytes calldata params,
/*LN-95*/         uint16 referralCode
/*LN-96*/     ) external {
/*LN-97*/         for (uint256 i = 0; i < assets.length; i++) {
/*LN-98*/             IERC20(assets[i]).transfer(receiverAddress, amounts[i]);
/*LN-99*/         }
/*LN-100*/ 
/*LN-101*/         require(
/*LN-102*/             IFlashLoanReceiver(receiverAddress).executeOperation(
/*LN-103*/                 assets,
/*LN-104*/                 amounts,
/*LN-105*/                 new uint256[](0),
/*LN-106*/                 msg.sender,
/*LN-107*/                 params
/*LN-108*/             ),
/*LN-109*/             "Flashloan callback failed"
/*LN-110*/         );
/*LN-111*/ 
/*LN-112*/         for (uint256 i = 0; i < assets.length; i++) {
/*LN-113*/             IERC20(assets[i]).transferFrom(
/*LN-114*/                 receiverAddress,
/*LN-115*/                 address(this),
/*LN-116*/                 amounts[i]
/*LN-117*/             );
/*LN-118*/         }
/*LN-119*/     }
/*LN-120*/ 
/*LN-121*/     function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
/*LN-122*/         uint256 halfB = b / 2;
/*LN-123*/         require(b != 0, "Division by zero");
/*LN-124*/         uint256 result = (a * RAY + halfB) / b;
/*LN-125*/         require(result < type(uint256).max / 2, "LiquidityIndex overflow");
/*LN-126*/         return result;
/*LN-127*/     }
/*LN-128*/ 
/*LN-129*/     function _mintRToken(address rToken, address to, uint256 amount) internal {}
/*LN-130*/ 
/*LN-131*/     function _burnRToken(
/*LN-132*/         address rToken,
/*LN-133*/         address from,
/*LN-134*/         uint256 amount
/*LN-135*/     ) internal {}
/*LN-136*/ }
/*LN-137*/ 