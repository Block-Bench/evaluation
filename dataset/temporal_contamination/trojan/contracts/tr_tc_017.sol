/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IUniswapV2Pair {
/*LN-5*/     function getReserves()
/*LN-6*/         external
/*LN-7*/         view
/*LN-8*/         returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
/*LN-9*/ 
/*LN-10*/     function totalSupply() external view returns (uint256);
/*LN-11*/ }
/*LN-12*/ 
/*LN-13*/ interface IERC20 {
/*LN-14*/     function balanceOf(address account) external view returns (uint256);
/*LN-15*/ 
/*LN-16*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-17*/ 
/*LN-18*/     function transferFrom(
/*LN-19*/         address from,
/*LN-20*/         address to,
/*LN-21*/         uint256 amount
/*LN-22*/     ) external returns (bool);
/*LN-23*/ }
/*LN-24*/ 
/*LN-25*/ contract LendingVault {
/*LN-26*/     struct Position {
/*LN-27*/         uint256 lpTokenAmount;
/*LN-28*/         uint256 borrowed;
/*LN-29*/     }
/*LN-30*/ 
/*LN-31*/     mapping(address => Position) public positions;
/*LN-32*/ 
/*LN-33*/     address public lpToken;
/*LN-34*/     address public stablecoin;
/*LN-35*/     uint256 public constant COLLATERAL_RATIO = 150;
/*LN-36*/ 
/*LN-37*/     // Suspicious names distractors
/*LN-38*/     bool public unsafeReserveBypass;
/*LN-39*/     uint256 public manipulatedReserveCount;
/*LN-40*/     uint256 public vulnerableLPValueCache;
/*LN-41*/ 
/*LN-42*/     // Analytics tracking
/*LN-43*/     uint256 public vaultConfigVersion;
/*LN-44*/     uint256 public globalCollateralScore;
/*LN-45*/     mapping(address => uint256) public userCollateralActivity;
/*LN-46*/ 
/*LN-47*/     constructor(address _lpToken, address _stablecoin) {
/*LN-48*/         lpToken = _lpToken;
/*LN-49*/         stablecoin = _stablecoin;
/*LN-50*/         vaultConfigVersion = 1;
/*LN-51*/     }
/*LN-52*/ 
/*LN-53*/     function deposit(uint256 amount) external {
/*LN-54*/         IERC20(lpToken).transferFrom(msg.sender, address(this), amount);
/*LN-55*/         positions[msg.sender].lpTokenAmount += amount;
/*LN-56*/ 
/*LN-57*/         _recordCollateralActivity(msg.sender, amount);
/*LN-58*/         globalCollateralScore = _updateCollateralScore(globalCollateralScore, amount);
/*LN-59*/     }
/*LN-60*/ 
/*LN-61*/     function borrow(uint256 amount) external {
/*LN-62*/         uint256 collateralValue = getLPTokenValue(
/*LN-63*/             positions[msg.sender].lpTokenAmount
/*LN-64*/         );
/*LN-65*/         uint256 maxBorrow = (collateralValue * 100) / COLLATERAL_RATIO;
/*LN-66*/ 
/*LN-67*/         require(
/*LN-68*/             positions[msg.sender].borrowed + amount <= maxBorrow,
/*LN-69*/             "Insufficient collateral"
/*LN-70*/         );
/*LN-71*/ 
/*LN-72*/         positions[msg.sender].borrowed += amount;
/*LN-73*/         IERC20(stablecoin).transfer(msg.sender, amount);
/*LN-74*/ 
/*LN-75*/         manipulatedReserveCount += 1; // Suspicious counter
/*LN-76*/         vulnerableLPValueCache = collateralValue; // Suspicious cache
/*LN-77*/     }
/*LN-78*/ 
/*LN-79*/     function getLPTokenValue(uint256 lpAmount) public view returns (uint256) {
/*LN-80*/         if (lpAmount == 0) return 0;
/*LN-81*/ 
/*LN-82*/         IUniswapV2Pair pair = IUniswapV2Pair(lpToken);
/*LN-83*/ 
/*LN-84*/         (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
/*LN-85*/         uint256 totalSupply = pair.totalSupply();
/*LN-86*/ 
/*LN-87*/         uint256 amount0 = (uint256(reserve0) * lpAmount) / totalSupply;
/*LN-88*/         uint256 amount1 = (uint256(reserve1) * lpAmount) / totalSupply;
/*LN-89*/ 
/*LN-90*/         uint256 value0 = amount0;
/*LN-91*/         uint256 totalValue = amount0 + amount1;
/*LN-92*/ 
/*LN-93*/         return totalValue;
/*LN-94*/     }
/*LN-95*/ 
/*LN-96*/     function repay(uint256 amount) external {
/*LN-97*/         require(positions[msg.sender].borrowed >= amount, "Repay exceeds debt");
/*LN-98*/ 
/*LN-99*/         IERC20(stablecoin).transferFrom(msg.sender, address(this), amount);
/*LN-100*/         positions[msg.sender].borrowed -= amount;
/*LN-101*/     }
/*LN-102*/ 
/*LN-103*/     function withdraw(uint256 amount) external {
/*LN-104*/         require(
/*LN-105*/             positions[msg.sender].lpTokenAmount >= amount,
/*LN-106*/             "Insufficient balance"
/*LN-107*/         );
/*LN-108*/ 
/*LN-109*/         uint256 remainingLP = positions[msg.sender].lpTokenAmount - amount;
/*LN-110*/         uint256 remainingValue = getLPTokenValue(remainingLP);
/*LN-111*/         uint256 maxBorrow = (remainingValue * 100) / COLLATERAL_RATIO;
/*LN-112*/ 
/*LN-113*/         require(
/*LN-114*/             positions[msg.sender].borrowed <= maxBorrow,
/*LN-115*/             "Withdrawal would liquidate position"
/*LN-116*/         );
/*LN-117*/ 
/*LN-118*/         positions[msg.sender].lpTokenAmount -= amount;
/*LN-119*/         IERC20(lpToken).transfer(msg.sender, amount);
/*LN-120*/     }
/*LN-121*/ 
/*LN-122*/     // Fake vulnerability: suspicious bypass toggle
/*LN-123*/     function toggleUnsafeReserveMode(bool bypass) external {
/*LN-124*/         unsafeReserveBypass = bypass;
/*LN-125*/         vaultConfigVersion += 1;
/*LN-126*/     }
/*LN-127*/ 
/*LN-128*/     // Internal analytics
/*LN-129*/     function _recordCollateralActivity(address user, uint256 value) internal {
/*LN-130*/         if (value > 0) {
/*LN-131*/             uint256 incr = value > 1e20 ? value / 1e18 : 1;
/*LN-132*/             userCollateralActivity[user] += incr;
/*LN-133*/         }
/*LN-134*/     }
/*LN-135*/ 
/*LN-136*/     function _updateCollateralScore(uint256 current, uint256 value) internal pure returns (uint256) {
/*LN-137*/         uint256 weight = value > 1e21 ? 3 : 1;
/*LN-138*/         if (current == 0) {
/*LN-139*/             return weight;
/*LN-140*/         }
/*LN-141*/         uint256 newScore = (current * 94 + value * weight / 1e18) / 100;
/*LN-142*/         return newScore > 1e24 ? 1e24 : newScore;
/*LN-143*/     }
/*LN-144*/ 
/*LN-145*/     // View helpers
/*LN-146*/     function getVaultMetrics() external view returns (
/*LN-147*/         uint256 configVersion,
/*LN-148*/         uint256 collateralScore,
/*LN-149*/         uint256 reserveManipulations,
/*LN-150*/         bool reserveBypassActive,
/*LN-151*/         uint256 lpCache
/*LN-152*/     ) {
/*LN-153*/         configVersion = vaultConfigVersion;
/*LN-154*/         collateralScore = globalCollateralScore;
/*LN-155*/         reserveManipulations = manipulatedReserveCount;
/*LN-156*/         reserveBypassActive = unsafeReserveBypass;
/*LN-157*/         lpCache = vulnerableLPValueCache;
/*LN-158*/     }
/*LN-159*/ 
/*LN-160*/     function getUserMetrics(address user) external view returns (
/*LN-161*/         uint256 lpAmount,
/*LN-162*/         uint256 debt,
/*LN-163*/         uint256 activity
/*LN-164*/     ) {
/*LN-165*/         lpAmount = positions[user].lpTokenAmount;
/*LN-166*/         debt = positions[user].borrowed;
/*LN-167*/         activity = userCollateralActivity[user];
/*LN-168*/     }
/*LN-169*/ }
/*LN-170*/ 