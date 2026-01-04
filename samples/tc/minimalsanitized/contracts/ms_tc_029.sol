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
/*LN-28*/ contract RadiantLendingPool {
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
/*LN-52*/         
/*LN-53*/         uint256 currentLiquidityIndex = reserve.liquidityIndex;
/*LN-54*/         if (currentLiquidityIndex == 0) {
/*LN-55*/             currentLiquidityIndex = RAY;
/*LN-56*/         }
/*LN-57*/ 
/*LN-58*/         // Update index (simplified)
/*LN-59*/         reserve.liquidityIndex =
/*LN-60*/             currentLiquidityIndex +
/*LN-61*/             (amount * RAY) /
/*LN-62*/             (reserve.totalLiquidity + 1);
/*LN-63*/         reserve.totalLiquidity += amount;
/*LN-64*/ 
/*LN-65*/         // Mint rTokens to user
/*LN-66*/         uint256 rTokenAmount = rayDiv(amount, reserve.liquidityIndex);
/*LN-67*/         _mintRToken(reserve.rTokenAddress, onBehalfOf, rTokenAmount);
/*LN-68*/     }
/*LN-69*/ 
/*LN-70*/     /**
/*LN-71*/      * @notice Withdraw tokens from lending pool
/*LN-72*/      */
/*LN-73*/     function withdraw(
/*LN-74*/         address asset,
/*LN-75*/         uint256 amount,
/*LN-76*/         address to
/*LN-77*/     ) external returns (uint256) {
/*LN-78*/         ReserveData storage reserve = reserves[asset];
/*LN-79*/ 
/*LN-80*/         
/*LN-81*/         
/*LN-82*/         uint256 rTokensToBurn = rayDiv(amount, reserve.liquidityIndex);
/*LN-83*/ 
/*LN-84*/         _burnRToken(reserve.rTokenAddress, msg.sender, rTokensToBurn);
/*LN-85*/ 
/*LN-86*/         reserve.totalLiquidity -= amount;
/*LN-87*/         IERC20(asset).transfer(to, amount);
/*LN-88*/ 
/*LN-89*/         return amount;
/*LN-90*/     }
/*LN-91*/ 
/*LN-92*/     /**
/*LN-93*/      * @notice Borrow tokens from pool with collateral
/*LN-94*/      */
/*LN-95*/     function borrow(
/*LN-96*/         address asset,
/*LN-97*/         uint256 amount,
/*LN-98*/         uint256 interestRateMode,
/*LN-99*/         uint16 referralCode,
/*LN-100*/         address onBehalfOf
/*LN-101*/     ) external {
/*LN-102*/         // Simplified borrow logic
/*LN-103*/         IERC20(asset).transfer(onBehalfOf, amount);
/*LN-104*/     }
/*LN-105*/ 
/*LN-106*/     /**
/*LN-107*/      * @notice Execute flashloan
/*LN-108*/      */
/*LN-109*/     function flashLoan(
/*LN-110*/         address receiverAddress,
/*LN-111*/         address[] calldata assets,
/*LN-112*/         uint256[] calldata amounts,
/*LN-113*/         uint256[] calldata modes,
/*LN-114*/         address onBehalfOf,
/*LN-115*/         bytes calldata params,
/*LN-116*/         uint16 referralCode
/*LN-117*/     ) external {
/*LN-118*/         for (uint256 i = 0; i < assets.length; i++) {
/*LN-119*/             IERC20(assets[i]).transfer(receiverAddress, amounts[i]);
/*LN-120*/         }
/*LN-121*/ 
/*LN-122*/         // Call receiver callback
/*LN-123*/         require(
/*LN-124*/             IFlashLoanReceiver(receiverAddress).executeOperation(
/*LN-125*/                 assets,
/*LN-126*/                 amounts,
/*LN-127*/                 new uint256[](assets.length),
/*LN-128*/                 msg.sender,
/*LN-129*/                 params
/*LN-130*/             ),
/*LN-131*/             "Flashloan callback failed"
/*LN-132*/         );
/*LN-133*/ 
/*LN-134*/         // Each cycle slightly increases liquidityIndex
/*LN-135*/ 
/*LN-136*/         for (uint256 i = 0; i < assets.length; i++) {
/*LN-137*/             IERC20(assets[i]).transferFrom(
/*LN-138*/                 receiverAddress,
/*LN-139*/                 address(this),
/*LN-140*/                 amounts[i]
/*LN-141*/             );
/*LN-142*/         }
/*LN-143*/     }
/*LN-144*/ 
/*LN-145*/     /**
/*LN-146*/      * @notice Ray division with rounding down
/*LN-147*/      */
/*LN-148*/     function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
/*LN-149*/         uint256 halfB = b / 2;
/*LN-150*/         require(b != 0, "Division by zero");
/*LN-151*/         return (a * RAY + halfB) / b;
/*LN-152*/     }
/*LN-153*/ 
/*LN-154*/     function _mintRToken(address rToken, address to, uint256 amount) internal {
/*LN-155*/         // Simplified mint
/*LN-156*/     }
/*LN-157*/ 
/*LN-158*/     function _burnRToken(
/*LN-159*/         address rToken,
/*LN-160*/         address from,
/*LN-161*/         uint256 amount
/*LN-162*/     ) internal {
/*LN-163*/         // Simplified burn
/*LN-164*/     }
/*LN-165*/ }
/*LN-166*/ 