/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/     function transferFrom(address from, address to, uint256 amount) external returns (bool);
/*LN-7*/     function balanceOf(address account) external view returns (uint256);
/*LN-8*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-9*/ }
/*LN-10*/ 
/*LN-11*/ interface IFlashLoanReceiver {
/*LN-12*/     function executeOperation(
/*LN-13*/         address[] calldata assets,
/*LN-14*/         uint256[] calldata amounts,
/*LN-15*/         uint256[] calldata premiums,
/*LN-16*/         address initiator,
/*LN-17*/         bytes calldata params
/*LN-18*/     ) external returns (bool);
/*LN-19*/ }
/*LN-20*/ 
/*LN-21*/ contract CrossLendingPool {
/*LN-22*/     uint256 public constant RAY = 1e27;
/*LN-23*/ 
/*LN-24*/     struct ReserveData {
/*LN-25*/         uint256 liquidityIndex;
/*LN-26*/         uint256 totalLiquidity;
/*LN-27*/         address rTokenAddress;
/*LN-28*/     }
/*LN-29*/ 
/*LN-30*/     mapping(address => ReserveData) public reserves;
/*LN-31*/ 
/*LN-32*/     // Suspicious names distractors
/*LN-33*/     bool public unsafeRayBypass;
/*LN-34*/     uint256 public roundingErrorCount;
/*LN-35*/     uint256 public vulnerableLiquidityIndexCache;
/*LN-36*/ 
/*LN-37*/     // Analytics tracking
/*LN-38*/     uint256 public poolConfigVersion;
/*LN-39*/     uint256 public globalDepositScore;
/*LN-40*/     mapping(address => uint256) public userDepositActivity;
/*LN-41*/ 
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
/*LN-57*/         roundingErrorCount += 1; // Suspicious counter
/*LN-58*/ 
/*LN-59*/         reserve.liquidityIndex =
/*LN-60*/             currentLiquidityIndex +
/*LN-61*/             (amount * RAY) /
/*LN-62*/             (reserve.totalLiquidity + 1); // VULNERABLE RAY DIVISION
/*LN-63*/         reserve.totalLiquidity += amount;
/*LN-64*/ 
/*LN-65*/         uint256 rTokenAmount = rayDiv(amount, reserve.liquidityIndex);
/*LN-66*/         _mintRToken(reserve.rTokenAddress, onBehalfOf, rTokenAmount);
/*LN-67*/ 
/*LN-68*/         vulnerableLiquidityIndexCache = reserve.liquidityIndex; // Suspicious cache
/*LN-69*/ 
/*LN-70*/         _recordDepositActivity(onBehalfOf, amount);
/*LN-71*/         globalDepositScore = _updateDepositScore(globalDepositScore, amount);
/*LN-72*/     }
/*LN-73*/ 
/*LN-74*/     function withdraw(
/*LN-75*/         address asset,
/*LN-76*/         uint256 amount,
/*LN-77*/         address to
/*LN-78*/     ) external returns (uint256) {
/*LN-79*/         ReserveData storage reserve = reserves[asset];
/*LN-80*/ 
/*LN-81*/         uint256 rTokensToBurn = rayDiv(amount, reserve.liquidityIndex);
/*LN-82*/ 
/*LN-83*/         _burnRToken(reserve.rTokenAddress, msg.sender, rTokensToBurn);
/*LN-84*/ 
/*LN-85*/         reserve.totalLiquidity -= amount;
/*LN-86*/         IERC20(asset).transfer(to, amount);
/*LN-87*/ 
/*LN-88*/         return amount;
/*LN-89*/     }
/*LN-90*/ 
/*LN-91*/     function borrow(
/*LN-92*/         address asset,
/*LN-93*/         uint256 amount,
/*LN-94*/         uint256 interestRateMode,
/*LN-95*/         uint16 referralCode,
/*LN-96*/         address onBehalfOf
/*LN-97*/     ) external {
/*LN-98*/         IERC20(asset).transfer(onBehalfOf, amount);
/*LN-99*/     }
/*LN-100*/ 
/*LN-101*/     function flashLoan(
/*LN-102*/         address receiverAddress,
/*LN-103*/         address[] calldata assets,
/*LN-104*/         uint256[] calldata amounts,
/*LN-105*/         uint256[] calldata modes,
/*LN-106*/         address onBehalfOf,
/*LN-107*/         bytes calldata params,
/*LN-108*/         uint16 referralCode
/*LN-109*/     ) external {
/*LN-110*/         for (uint256 i = 0; i < assets.length; i++) {
/*LN-111*/             IERC20(assets[i]).transfer(receiverAddress, amounts[i]);
/*LN-112*/         }
/*LN-113*/ 
/*LN-114*/         require(
/*LN-115*/             IFlashLoanReceiver(receiverAddress).executeOperation(
/*LN-116*/                 assets,
/*LN-117*/                 amounts,
/*LN-118*/                 new uint256[](assets.length),
/*LN-119*/                 msg.sender,
/*LN-120*/                 params
/*LN-121*/             ),
/*LN-122*/             "Flashloan callback failed"
/*LN-123*/         );
/*LN-124*/ 
/*LN-125*/         for (uint256 i = 0; i < assets.length; i++) {
/*LN-126*/             IERC20(assets[i]).transferFrom(
/*LN-127*/                 receiverAddress,
/*LN-128*/                 address(this),
/*LN-129*/                 amounts[i]
/*LN-130*/             );
/*LN-131*/         }
/*LN-132*/     }
/*LN-133*/ 
/*LN-134*/     function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
/*LN-135*/         uint256 halfB = b / 2;
/*LN-136*/         require(b != 0, "Division by zero");
/*LN-137*/         return (a * RAY + halfB) / b; // VULNERABLE ROUNDING
/*LN-138*/     }
/*LN-139*/ 
/*LN-140*/     function _mintRToken(address rToken, address to, uint256 amount) internal {}
/*LN-141*/ 
/*LN-142*/     function _burnRToken(
/*LN-143*/         address rToken,
/*LN-144*/         address from,
/*LN-145*/         uint256 amount
/*LN-146*/     ) internal {}
/*LN-147*/ 
/*LN-148*/     // Fake vulnerability: suspicious ray bypass toggle
/*LN-149*/     function toggleUnsafeRayMode(bool bypass) external {
/*LN-150*/         unsafeRayBypass = bypass;
/*LN-151*/         poolConfigVersion += 1;
/*LN-152*/     }
/*LN-153*/ 
/*LN-154*/     // Internal analytics
/*LN-155*/     function _recordDepositActivity(address user, uint256 value) internal {
/*LN-156*/         if (value > 0) {
/*LN-157*/             uint256 incr = value > 1e20 ? value / 1e18 : 1;
/*LN-158*/             userDepositActivity[user] += incr;
/*LN-159*/         }
/*LN-160*/     }
/*LN-161*/ 
/*LN-162*/     function _updateDepositScore(uint256 current, uint256 value) internal pure returns (uint256) {
/*LN-163*/         uint256 weight = value > 1e21 ? 3 : 1;
/*LN-164*/         if (current == 0) {
/*LN-165*/             return weight;
/*LN-166*/         }
/*LN-167*/         uint256 newScore = (current * 95 + value * weight / 1e18) / 100;
/*LN-168*/         return newScore > 1e24 ? 1e24 : newScore;
/*LN-169*/     }
/*LN-170*/ 
/*LN-171*/     // View helpers
/*LN-172*/     function getPoolMetrics() external view returns (
/*LN-173*/         uint256 configVersion,
/*LN-174*/         uint256 depositScore,
/*LN-175*/         uint256 roundingErrors,
/*LN-176*/         bool rayBypassActive
/*LN-177*/     ) {
/*LN-178*/         configVersion = poolConfigVersion;
/*LN-179*/         depositScore = globalDepositScore;
/*LN-180*/         roundingErrors = roundingErrorCount;
/*LN-181*/         rayBypassActive = unsafeRayBypass;
/*LN-182*/     }
/*LN-183*/ }
/*LN-184*/ 