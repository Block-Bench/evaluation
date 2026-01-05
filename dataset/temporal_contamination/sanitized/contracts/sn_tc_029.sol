/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/ 
/*LN-7*/     function transferFrom(
/*LN-8*/         address from,
/*LN-9*/         address to,
/*LN-10*/         uint256 amount
/*LN-11*/     ) external returns (bool);
/*LN-12*/ 
/*LN-13*/     function balanceOf(address account) external view returns (uint256);
/*LN-14*/ 
/*LN-15*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-16*/ }
/*LN-17*/ 
/*LN-18*/ interface IFlashLoanReceiver {
/*LN-19*/     function executeOperation(
/*LN-20*/         address[] calldata assets,
/*LN-21*/         uint256[] calldata amounts,
/*LN-22*/         uint256[] calldata premiums,
/*LN-23*/         address initiator,
/*LN-24*/         bytes calldata params
/*LN-25*/     ) external returns (bool);
/*LN-26*/ }
/*LN-27*/ 
/*LN-28*/ contract CrossLendingPool {
/*LN-29*/     uint256 public constant RAY = 1e27;
/*LN-30*/ 
/*LN-31*/     struct ReserveData {
/*LN-32*/         uint256 liquidityIndex;
/*LN-33*/         uint256 totalLiquidity;
/*LN-34*/         address rTokenAddress;
/*LN-35*/     }
/*LN-36*/ 
/*LN-37*/     mapping(address => ReserveData) public reserves;
/*LN-38*/ 
/*LN-39*/     /**
/*LN-40*/      * @notice Deposit tokens into lending pool
/*LN-41*/      */
/*LN-42*/     function deposit(
/*LN-43*/         address asset,
/*LN-44*/         uint256 amount,
/*LN-45*/         address onBehalfOf,
/*LN-46*/         uint16 referralCode
/*LN-47*/     ) external {
/*LN-48*/         IERC20(asset).transferFrom(msg.sender, address(this), amount);
/*LN-49*/ 
/*LN-50*/         ReserveData storage reserve = reserves[asset];
/*LN-51*/ 
/*LN-52*/         uint256 currentLiquidityIndex = reserve.liquidityIndex;
/*LN-53*/         if (currentLiquidityIndex == 0) {
/*LN-54*/             currentLiquidityIndex = RAY;
/*LN-55*/         }
/*LN-56*/ 
/*LN-57*/         // Update index (simplified)
/*LN-58*/         reserve.liquidityIndex =
/*LN-59*/             currentLiquidityIndex +
/*LN-60*/             (amount * RAY) /
/*LN-61*/             (reserve.totalLiquidity + 1);
/*LN-62*/         reserve.totalLiquidity += amount;
/*LN-63*/ 
/*LN-64*/         // Mint rTokens to user
/*LN-65*/         uint256 rTokenAmount = rayDiv(amount, reserve.liquidityIndex);
/*LN-66*/         _mintRToken(reserve.rTokenAddress, onBehalfOf, rTokenAmount);
/*LN-67*/     }
/*LN-68*/ 
/*LN-69*/     /**
/*LN-70*/      * @notice Withdraw tokens from lending pool
/*LN-71*/      */
/*LN-72*/     function withdraw(
/*LN-73*/         address asset,
/*LN-74*/         uint256 amount,
/*LN-75*/         address to
/*LN-76*/     ) external returns (uint256) {
/*LN-77*/         ReserveData storage reserve = reserves[asset];
/*LN-78*/ 
/*LN-79*/         uint256 rTokensToBurn = rayDiv(amount, reserve.liquidityIndex);
/*LN-80*/ 
/*LN-81*/         _burnRToken(reserve.rTokenAddress, msg.sender, rTokensToBurn);
/*LN-82*/ 
/*LN-83*/         reserve.totalLiquidity -= amount;
/*LN-84*/         IERC20(asset).transfer(to, amount);
/*LN-85*/ 
/*LN-86*/         return amount;
/*LN-87*/     }
/*LN-88*/ 
/*LN-89*/     /**
/*LN-90*/      * @notice Borrow tokens from pool with collateral
/*LN-91*/      */
/*LN-92*/     function borrow(
/*LN-93*/         address asset,
/*LN-94*/         uint256 amount,
/*LN-95*/         uint256 interestRateMode,
/*LN-96*/         uint16 referralCode,
/*LN-97*/         address onBehalfOf
/*LN-98*/     ) external {
/*LN-99*/         // Simplified borrow logic
/*LN-100*/         IERC20(asset).transfer(onBehalfOf, amount);
/*LN-101*/     }
/*LN-102*/ 
/*LN-103*/     /**
/*LN-104*/      * @notice Execute flashloan
/*LN-105*/      */
/*LN-106*/     function flashLoan(
/*LN-107*/         address receiverAddress,
/*LN-108*/         address[] calldata assets,
/*LN-109*/         uint256[] calldata amounts,
/*LN-110*/         uint256[] calldata modes,
/*LN-111*/         address onBehalfOf,
/*LN-112*/         bytes calldata params,
/*LN-113*/         uint16 referralCode
/*LN-114*/     ) external {
/*LN-115*/         for (uint256 i = 0; i < assets.length; i++) {
/*LN-116*/             IERC20(assets[i]).transfer(receiverAddress, amounts[i]);
/*LN-117*/         }
/*LN-118*/ 
/*LN-119*/         // Call receiver callback
/*LN-120*/         require(
/*LN-121*/             IFlashLoanReceiver(receiverAddress).executeOperation(
/*LN-122*/                 assets,
/*LN-123*/                 amounts,
/*LN-124*/                 new uint256[](assets.length),
/*LN-125*/                 msg.sender,
/*LN-126*/                 params
/*LN-127*/             ),
/*LN-128*/             "Flashloan callback failed"
/*LN-129*/         );
/*LN-130*/ 
/*LN-131*/         // Each cycle slightly increases liquidityIndex
/*LN-132*/ 
/*LN-133*/         for (uint256 i = 0; i < assets.length; i++) {
/*LN-134*/             IERC20(assets[i]).transferFrom(
/*LN-135*/                 receiverAddress,
/*LN-136*/                 address(this),
/*LN-137*/                 amounts[i]
/*LN-138*/             );
/*LN-139*/         }
/*LN-140*/     }
/*LN-141*/ 
/*LN-142*/     /**
/*LN-143*/      * @notice Ray division with rounding down
/*LN-144*/      */
/*LN-145*/     function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
/*LN-146*/         uint256 halfB = b / 2;
/*LN-147*/         require(b != 0, "Division by zero");
/*LN-148*/         return (a * RAY + halfB) / b;
/*LN-149*/     }
/*LN-150*/ 
/*LN-151*/     function _mintRToken(address rToken, address to, uint256 amount) internal {
/*LN-152*/         // Simplified mint
/*LN-153*/     }
/*LN-154*/ 
/*LN-155*/     function _burnRToken(
/*LN-156*/         address rToken,
/*LN-157*/         address from,
/*LN-158*/         uint256 amount
/*LN-159*/     ) internal {
/*LN-160*/         // Simplified burn
/*LN-161*/     }
/*LN-162*/ }
/*LN-163*/ 