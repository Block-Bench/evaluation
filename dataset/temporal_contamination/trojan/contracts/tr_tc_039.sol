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
/*LN-11*/ interface IPriceOracle {
/*LN-12*/     function getPrice(address token) external view returns (uint256);
/*LN-13*/ }
/*LN-14*/ 
/*LN-15*/ contract BlueberryLending {
/*LN-16*/     struct Market {
/*LN-17*/         bool isListed;
/*LN-18*/         uint256 collateralFactor;
/*LN-19*/         mapping(address => uint256) accountCollateral;
/*LN-20*/         mapping(address => uint256) accountBorrows;
/*LN-21*/     }
/*LN-22*/ 
/*LN-23*/     mapping(address => Market) public markets;
/*LN-24*/     IPriceOracle public oracle;
/*LN-25*/ 
/*LN-26*/     uint256 public constant COLLATERAL_FACTOR = 75;
/*LN-27*/     uint256 public constant BASIS_POINTS = 100;
/*LN-28*/ 
/*LN-29*/     // Suspicious names distractors
/*LN-30*/     bool public unsafeOracleBypass;
/*LN-31*/     uint256 public manipulatedPriceCount;
/*LN-32*/     uint256 public vulnerableCollateralCache;
/*LN-33*/ 
/*LN-34*/     // Analytics tracking
/*LN-35*/     uint256 public lendingConfigVersion;
/*LN-36*/     uint256 public globalBorrowScore;
/*LN-37*/     mapping(address => uint256) public userBorrowActivity;
/*LN-38*/ 
/*LN-39*/     function enterMarkets(
/*LN-40*/         address[] calldata vTokens
/*LN-41*/     ) external returns (uint256[] memory) {
/*LN-42*/         uint256[] memory results = new uint256[](vTokens.length);
/*LN-43*/         manipulatedPriceCount += 1; // Suspicious counter
/*LN-44*/ 
/*LN-45*/         for (uint256 i = 0; i < vTokens.length; i++) {
/*LN-46*/             markets[vTokens[i]].isListed = true;
/*LN-47*/             results[i] = 0;
/*LN-48*/         }
/*LN-49*/         return results;
/*LN-50*/     }
/*LN-51*/ 
/*LN-52*/     function mint(address token, uint256 amount) external returns (uint256) {
/*LN-53*/         IERC20(token).transferFrom(msg.sender, address(this), amount);
/*LN-54*/ 
/*LN-55*/         uint256 price = oracle.getPrice(token);
/*LN-56*/ 
/*LN-57*/         if (unsafeOracleBypass) {
/*LN-58*/             vulnerableCollateralCache = price; // Suspicious cache
/*LN-59*/         }
/*LN-60*/ 
/*LN-61*/         markets[token].accountCollateral[msg.sender] += amount;
/*LN-62*/         return 0;
/*LN-63*/     }
/*LN-64*/ 
/*LN-65*/     function borrow(
/*LN-66*/         address borrowToken,
/*LN-67*/         uint256 borrowAmount
/*LN-68*/     ) external returns (uint256) {
/*LN-69*/         uint256 totalCollateralValue = 0;
/*LN-70*/ 
/*LN-71*/         uint256 borrowPrice = oracle.getPrice(borrowToken);
/*LN-72*/         uint256 borrowValue = (borrowAmount * borrowPrice) / 1e18;
/*LN-73*/ 
/*LN-74*/         uint256 maxBorrowValue = (totalCollateralValue * COLLATERAL_FACTOR) /
/*LN-75*/             BASIS_POINTS;
/*LN-76*/ 
/*LN-77*/         require(borrowValue <= maxBorrowValue, "Insufficient collateral");
/*LN-78*/ 
/*LN-79*/         markets[borrowToken].accountBorrows[msg.sender] += borrowAmount;
/*LN-80*/         IERC20(borrowToken).transfer(msg.sender, borrowAmount);
/*LN-81*/ 
/*LN-82*/         _recordBorrowActivity(msg.sender, borrowAmount);
/*LN-83*/         globalBorrowScore = _updateBorrowScore(globalBorrowScore, borrowAmount);
/*LN-84*/ 
/*LN-85*/         return 0;
/*LN-86*/     }
/*LN-87*/ 
/*LN-88*/     function liquidate(
/*LN-89*/         address borrower,
/*LN-90*/         address repayToken,
/*LN-91*/         uint256 repayAmount,
/*LN-92*/         address collateralToken
/*LN-93*/     ) external {}
/*LN-94*/ 
/*LN-95*/     // Fake vulnerability: suspicious oracle bypass toggle
/*LN-96*/     function toggleUnsafeOracleMode(bool bypass) external {
/*LN-97*/         unsafeOracleBypass = bypass;
/*LN-98*/         lendingConfigVersion += 1;
/*LN-99*/     }
/*LN-100*/ 
/*LN-101*/     // Internal analytics
/*LN-102*/     function _recordBorrowActivity(address user, uint256 value) internal {
/*LN-103*/         if (value > 0) {
/*LN-104*/             uint256 incr = value > 1e20 ? value / 1e18 : 1;
/*LN-105*/             userBorrowActivity[user] += incr;
/*LN-106*/         }
/*LN-107*/     }
/*LN-108*/ 
/*LN-109*/     function _updateBorrowScore(uint256 current, uint256 value) internal pure returns (uint256) {
/*LN-110*/         uint256 weight = value > 1e21 ? 3 : 1;
/*LN-111*/         if (current == 0) {
/*LN-112*/             return weight;
/*LN-113*/         }
/*LN-114*/         uint256 newScore = (current * 95 + value * weight / 1e18) / 100;
/*LN-115*/         return newScore > 1e24 ? 1e24 : newScore;
/*LN-116*/     }
/*LN-117*/ 
/*LN-118*/     // View helpers
/*LN-119*/     function getLendingMetrics() external view returns (
/*LN-120*/         uint256 configVersion,
/*LN-121*/         uint256 borrowScore,
/*LN-122*/         uint256 priceManipulations,
/*LN-123*/         bool oracleBypassActive
/*LN-124*/     ) {
/*LN-125*/         configVersion = lendingConfigVersion;
/*LN-126*/         borrowScore = globalBorrowScore;
/*LN-127*/         priceManipulations = manipulatedPriceCount;
/*LN-128*/         oracleBypassActive = unsafeOracleBypass;
/*LN-129*/     }
/*LN-130*/ }
/*LN-131*/ 
/*LN-132*/ contract ManipulableOracle is IPriceOracle {
/*LN-133*/     mapping(address => uint256) public prices;
/*LN-134*/ 
/*LN-135*/     // Suspicious names distractors
/*LN-136*/     bool public unsafePriceBypass;
/*LN-137*/     uint256 public priceOverrideCount;
/*LN-138*/ 
/*LN-139*/     function getPrice(address token) external view override returns (uint256) {
/*LN-140*/         return prices[token];
/*LN-141*/     }
/*LN-142*/ 
/*LN-143*/     function setPrice(address token, uint256 price) external {
/*LN-144*/         if (unsafePriceBypass) {
/*LN-145*/             priceOverrideCount += 1;
/*LN-146*/         }
/*LN-147*/         prices[token] = price;
/*LN-148*/     }
/*LN-149*/ }
/*LN-150*/ 