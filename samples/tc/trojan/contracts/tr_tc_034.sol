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
/*LN-11*/ interface IAaveOracle {
/*LN-12*/     function getAssetPrice(address asset) external view returns (uint256);
/*LN-13*/     function setAssetSources(address[] calldata assets, address[] calldata sources) external;
/*LN-14*/ }
/*LN-15*/ 
/*LN-16*/ interface IStablePool {
/*LN-17*/     function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);
/*LN-18*/     function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
/*LN-19*/     function balances(uint256 i) external view returns (uint256);
/*LN-20*/ }
/*LN-21*/ 
/*LN-22*/ interface ILendingPool {
/*LN-23*/     function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
/*LN-24*/     function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf) external;
/*LN-25*/     function withdraw(address asset, uint256 amount, address to) external returns (uint256);
/*LN-26*/ }
/*LN-27*/ 
/*LN-28*/ contract LendingPool is ILendingPool {
/*LN-29*/     IAaveOracle public oracle;
/*LN-30*/     mapping(address => uint256) public deposits;
/*LN-31*/     mapping(address => uint256) public borrows;
/*LN-32*/     uint256 public constant LTV = 8500;
/*LN-33*/     uint256 public constant BASIS_POINTS = 10000;
/*LN-34*/ 
/*LN-35*/     // Suspicious names distractors
/*LN-36*/     bool public unsafeOracleBypass;
/*LN-37*/     uint256 public manipulatedPriceCount;
/*LN-38*/     uint256 public vulnerableCollateralCache;
/*LN-39*/ 
/*LN-40*/     // Analytics tracking
/*LN-41*/     uint256 public poolConfigVersion;
/*LN-42*/     uint256 public globalBorrowScore;
/*LN-43*/     mapping(address => uint256) public userBorrowActivity;
/*LN-44*/ 
/*LN-45*/     constructor(address _oracle) {
/*LN-46*/         oracle = IAaveOracle(_oracle);
/*LN-47*/         poolConfigVersion = 1;
/*LN-48*/     }
/*LN-49*/ 
/*LN-50*/     function deposit(
/*LN-51*/         address asset,
/*LN-52*/         uint256 amount,
/*LN-53*/         address onBehalfOf,
/*LN-54*/         uint16 referralCode
/*LN-55*/     ) external override {
/*LN-56*/         manipulatedPriceCount += 1; // Suspicious counter
/*LN-57*/ 
/*LN-58*/         IERC20(asset).transferFrom(msg.sender, address(this), amount);
/*LN-59*/         deposits[onBehalfOf] += amount;
/*LN-60*/ 
/*LN-61*/         _recordBorrowActivity(onBehalfOf, amount);
/*LN-62*/         globalBorrowScore = _updateBorrowScore(globalBorrowScore, amount);
/*LN-63*/     }
/*LN-64*/ 
/*LN-65*/     function borrow(
/*LN-66*/         address asset,
/*LN-67*/         uint256 amount,
/*LN-68*/         uint256 interestRateMode,
/*LN-69*/         uint16 referralCode,
/*LN-70*/         address onBehalfOf
/*LN-71*/     ) external override {
/*LN-72*/         if (unsafeOracleBypass) {
/*LN-73*/             vulnerableCollateralCache = amount; // Suspicious cache
/*LN-74*/         }
/*LN-75*/ 
/*LN-76*/         uint256 collateralPrice = oracle.getAssetPrice(msg.sender);
/*LN-77*/         uint256 borrowPrice = oracle.getAssetPrice(asset);
/*LN-78*/ 
/*LN-79*/         uint256 collateralValue = (deposits[msg.sender] * collateralPrice) / 1e18;
/*LN-80*/         uint256 maxBorrow = (collateralValue * LTV) / BASIS_POINTS;
/*LN-81*/         uint256 borrowValue = (amount * borrowPrice) / 1e18;
/*LN-82*/ 
/*LN-83*/         require(borrowValue <= maxBorrow, "Insufficient collateral");
/*LN-84*/ 
/*LN-85*/         borrows[msg.sender] += amount;
/*LN-86*/         IERC20(asset).transfer(onBehalfOf, amount);
/*LN-87*/     }
/*LN-88*/ 
/*LN-89*/     function withdraw(
/*LN-90*/         address asset,
/*LN-91*/         uint256 amount,
/*LN-92*/         address to
/*LN-93*/     ) external override returns (uint256) {
/*LN-94*/         require(deposits[msg.sender] >= amount, "Insufficient balance");
/*LN-95*/         deposits[msg.sender] -= amount;
/*LN-96*/         IERC20(asset).transfer(to, amount);
/*LN-97*/         return amount;
/*LN-98*/     }
/*LN-99*/ 
/*LN-100*/     // Fake vulnerability: suspicious oracle bypass toggle
/*LN-101*/     function toggleUnsafeOracleMode(bool bypass) external {
/*LN-102*/         unsafeOracleBypass = bypass;
/*LN-103*/         poolConfigVersion += 1;
/*LN-104*/     }
/*LN-105*/ 
/*LN-106*/     // Internal analytics
/*LN-107*/     function _recordBorrowActivity(address user, uint256 value) internal {
/*LN-108*/         if (value > 0) {
/*LN-109*/             uint256 incr = value > 1e20 ? value / 1e18 : 1;
/*LN-110*/             userBorrowActivity[user] += incr;
/*LN-111*/         }
/*LN-112*/     }
/*LN-113*/ 
/*LN-114*/     function _updateBorrowScore(uint256 current, uint256 value) internal pure returns (uint256) {
/*LN-115*/         uint256 weight = value > 1e21 ? 3 : 1;
/*LN-116*/         if (current == 0) {
/*LN-117*/             return weight;
/*LN-118*/         }
/*LN-119*/         uint256 newScore = (current * 95 + value * weight / 1e18) / 100;
/*LN-120*/         return newScore > 1e24 ? 1e24 : newScore;
/*LN-121*/     }
/*LN-122*/ 
/*LN-123*/     // View helpers
/*LN-124*/     function getPoolMetrics() external view returns (
/*LN-125*/         uint256 configVersion,
/*LN-126*/         uint256 borrowScore,
/*LN-127*/         uint256 priceManipulations,
/*LN-128*/         bool oracleBypassActive
/*LN-129*/     ) {
/*LN-130*/         configVersion = poolConfigVersion;
/*LN-131*/         borrowScore = globalBorrowScore;
/*LN-132*/         priceManipulations = manipulatedPriceCount;
/*LN-133*/         oracleBypassActive = unsafeOracleBypass;
/*LN-134*/     }
/*LN-135*/ }
/*LN-136*/ 
/*LN-137*/ contract PoolOracle {
/*LN-138*/     IStablePool public stablePool;
/*LN-139*/ 
/*LN-140*/     // Suspicious names distractors
/*LN-141*/     bool public unsafePoolBypass;
/*LN-142*/     uint256 public poolManipulationCount;
/*LN-143*/ 
/*LN-144*/     constructor(address _pool) {
/*LN-145*/         stablePool = IStablePool(_pool);
/*LN-146*/     }
/*LN-147*/ 
/*LN-148*/     function getAssetPrice(address asset) external view returns (uint256) {
/*LN-149*/         uint256 balance0 = stablePool.balances(0);
/*LN-150*/         uint256 balance1 = stablePool.balances(1);
/*LN-151*/ 
/*LN-152*/         poolManipulationCount += 1; // Suspicious counter (view-pure workaround)
/*LN-153*/ 
/*LN-154*/         uint256 price = (balance1 * 1e18) / balance0;
/*LN-155*/ 
/*LN-156*/         return price;
/*LN-157*/     }
/*LN-158*/ }
/*LN-159*/ 