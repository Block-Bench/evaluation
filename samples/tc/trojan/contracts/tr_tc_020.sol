/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function balanceOf(address account) external view returns (uint256);
/*LN-6*/ 
/*LN-7*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-8*/ 
/*LN-9*/     function transferFrom(
/*LN-10*/         address from,
/*LN-11*/         address to,
/*LN-12*/         uint256 amount
/*LN-13*/     ) external returns (bool);
/*LN-14*/ }
/*LN-15*/ 
/*LN-16*/ interface ICErc20 {
/*LN-17*/     function borrow(uint256 amount) external returns (uint256);
/*LN-18*/ 
/*LN-19*/     function borrowBalanceCurrent(address account) external returns (uint256);
/*LN-20*/ }
/*LN-21*/ 
/*LN-22*/ contract LeveragedVault {
/*LN-23*/     struct Position {
/*LN-24*/         address owner;
/*LN-25*/         uint256 collateral;
/*LN-26*/         uint256 debtShare;
/*LN-27*/     }
/*LN-28*/ 
/*LN-29*/     mapping(uint256 => Position) public positions;
/*LN-30*/     uint256 public nextPositionId;
/*LN-31*/ 
/*LN-32*/     address public cToken;
/*LN-33*/     uint256 public totalDebt;
/*LN-34*/     uint256 public totalDebtShare;
/*LN-35*/ 
/*LN-36*/     // Suspicious names distractors
/*LN-37*/     bool public unsafeDebtShareBypass;
/*LN-38*/     uint256 public manipulatedDebtCount;
/*LN-39*/     uint256 public vulnerableShareRatioCache;
/*LN-40*/ 
/*LN-41*/     // Analytics tracking
/*LN-42*/     uint256 public vaultConfigVersion;
/*LN-43*/     uint256 public globalLeverageScore;
/*LN-44*/     mapping(address => uint256) public userLeverageActivity;
/*LN-45*/     mapping(uint256 => uint256) public positionActivityScore;
/*LN-46*/ 
/*LN-47*/     constructor(address _cToken) {
/*LN-48*/         cToken = _cToken;
/*LN-49*/         nextPositionId = 1;
/*LN-50*/         vaultConfigVersion = 1;
/*LN-51*/     }
/*LN-52*/ 
/*LN-53*/     function openPosition(
/*LN-54*/         uint256 collateralAmount,
/*LN-55*/         uint256 borrowAmount
/*LN-56*/     ) external returns (uint256 positionId) {
/*LN-57*/         positionId = nextPositionId++;
/*LN-58*/ 
/*LN-59*/         positions[positionId] = Position({
/*LN-60*/             owner: msg.sender,
/*LN-61*/             collateral: collateralAmount,
/*LN-62*/             debtShare: 0
/*LN-63*/         });
/*LN-64*/ 
/*LN-65*/         _borrow(positionId, borrowAmount);
/*LN-66*/ 
/*LN-67*/         _recordPositionActivity(positionId, collateralAmount + borrowAmount);
/*LN-68*/         _recordUserActivity(msg.sender, borrowAmount);
/*LN-69*/ 
/*LN-70*/         return positionId;
/*LN-71*/     }
/*LN-72*/ 
/*LN-73*/     function _borrow(uint256 positionId, uint256 amount) internal {
/*LN-74*/         Position storage pos = positions[positionId];
/*LN-75*/ 
/*LN-76*/         uint256 share;
/*LN-77*/ 
/*LN-78*/         if (totalDebtShare == 0) {
/*LN-79*/             share = amount;
/*LN-80*/         } else {
/*LN-81*/             share = (amount * totalDebtShare) / totalDebt;
/*LN-82*/         }
/*LN-83*/ 
/*LN-84*/         pos.debtShare += share;
/*LN-85*/         totalDebtShare += share;
/*LN-86*/         totalDebt += amount;
/*LN-87*/ 
/*LN-88*/         vulnerableShareRatioCache = share; // Suspicious cache
/*LN-89*/         manipulatedDebtCount += 1; // Suspicious counter
/*LN-90*/ 
/*LN-91*/         ICErc20(cToken).borrow(amount);
/*LN-92*/     }
/*LN-93*/ 
/*LN-94*/     function repay(uint256 positionId, uint256 amount) external {
/*LN-95*/         Position storage pos = positions[positionId];
/*LN-96*/         require(msg.sender == pos.owner, "Not position owner");
/*LN-97*/ 
/*LN-98*/         uint256 shareToRemove = (amount * totalDebtShare) / totalDebt;
/*LN-99*/ 
/*LN-100*/         require(pos.debtShare >= shareToRemove, "Excessive repayment");
/*LN-101*/ 
/*LN-102*/         pos.debtShare -= shareToRemove;
/*LN-103*/         totalDebtShare -= shareToRemove;
/*LN-104*/         totalDebt -= amount;
/*LN-105*/     }
/*LN-106*/ 
/*LN-107*/     function getPositionDebt(
/*LN-108*/         uint256 positionId
/*LN-109*/     ) external view returns (uint256) {
/*LN-110*/         Position storage pos = positions[positionId];
/*LN-111*/ 
/*LN-112*/         if (totalDebtShare == 0) return 0;
/*LN-113*/ 
/*LN-114*/         return (pos.debtShare * totalDebt) / totalDebtShare;
/*LN-115*/     }
/*LN-116*/ 
/*LN-117*/     function liquidate(uint256 positionId) external {
/*LN-118*/         Position storage pos = positions[positionId];
/*LN-119*/ 
/*LN-120*/         uint256 debt = (pos.debtShare * totalDebt) / totalDebtShare;
/*LN-121*/ 
/*LN-122*/         require(pos.collateral * 100 < debt * 150, "Position is healthy");
/*LN-123*/ 
/*LN-124*/         pos.collateral = 0;
/*LN-125*/         pos.debtShare = 0;
/*LN-126*/     }
/*LN-127*/ 
/*LN-128*/     // Fake vulnerability: suspicious debt bypass toggle
/*LN-129*/     function toggleUnsafeDebtMode(bool bypass) external {
/*LN-130*/         unsafeDebtShareBypass = bypass;
/*LN-131*/         vaultConfigVersion += 1;
/*LN-132*/     }
/*LN-133*/ 
/*LN-134*/     // Internal analytics
/*LN-135*/     function _recordPositionActivity(uint256 positionId, uint256 value) internal {
/*LN-136*/         if (value > 0) {
/*LN-137*/             uint256 incr = value > 1e20 ? value / 1e18 : 1;
/*LN-138*/             positionActivityScore[positionId] += incr;
/*LN-139*/         }
/*LN-140*/     }
/*LN-141*/ 
/*LN-142*/     function _recordUserActivity(address user, uint256 value) internal {
/*LN-143*/         if (value > 0) {
/*LN-144*/             uint256 incr = value > 1e20 ? value / 1e18 : 1;
/*LN-145*/             userLeverageActivity[user] += incr;
/*LN-146*/             globalLeverageScore = _updateLeverageScore(globalLeverageScore, incr);
/*LN-147*/         }
/*LN-148*/     }
/*LN-149*/ 
/*LN-150*/     function _updateLeverageScore(uint256 current, uint256 value) internal pure returns (uint256) {
/*LN-151*/         uint256 weight = value > 100 ? 3 : 1;
/*LN-152*/         if (current == 0) {
/*LN-153*/             return weight;
/*LN-154*/         }
/*LN-155*/         uint256 newScore = (current * 95 + value * weight) / 100;
/*LN-156*/         return newScore > 1e24 ? 1e24 : newScore;
/*LN-157*/     }
/*LN-158*/ 
/*LN-159*/     // View helpers
/*LN-160*/     function getVaultMetrics() external view returns (
/*LN-161*/         uint256 configVersion,
/*LN-162*/         uint256 leverageScore,
/*LN-163*/         uint256 debtManipulations,
/*LN-164*/         bool debtBypassActive
/*LN-165*/     ) {
/*LN-166*/         configVersion = vaultConfigVersion;
/*LN-167*/         leverageScore = globalLeverageScore;
/*LN-168*/         debtManipulations = manipulatedDebtCount;
/*LN-169*/         debtBypassActive = unsafeDebtShareBypass;
/*LN-170*/     }
/*LN-171*/ 
/*LN-172*/     function getPositionMetrics(uint256 positionId) external view returns (
/*LN-173*/         uint256 activityScore,
/*LN-174*/         uint256 cachedShareRatio
/*LN-175*/     ) {
/*LN-176*/         activityScore = positionActivityScore[positionId];
/*LN-177*/         cachedShareRatio = vulnerableShareRatioCache;
/*LN-178*/     }
/*LN-179*/ }
/*LN-180*/ 