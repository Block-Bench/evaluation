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
/*LN-16*/ interface ICurvePool {
/*LN-17*/     function get_virtual_price() external view returns (uint256);
/*LN-18*/ 
/*LN-19*/     function add_liquidity(
/*LN-20*/         uint256[3] calldata amounts,
/*LN-21*/         uint256 minMintAmount
/*LN-22*/     ) external;
/*LN-23*/ }
/*LN-24*/ 
/*LN-25*/ contract PriceOracle {
/*LN-26*/     ICurvePool public curvePool;
/*LN-27*/ 
/*LN-28*/     // Suspicious names distractors
/*LN-29*/     bool public unsafePriceBypass;
/*LN-30*/     uint256 public manipulatedPriceCount;
/*LN-31*/     uint256 public vulnerableVirtualPriceCache;
/*LN-32*/ 
/*LN-33*/     constructor(address _curvePool) {
/*LN-34*/         curvePool = ICurvePool(_curvePool);
/*LN-35*/     }
/*LN-36*/ 
/*LN-37*/     function getPrice() external view returns (uint256) {
/*LN-38*/         uint256 price = curvePool.get_virtual_price();
/*LN-39*/         
/*LN-40*/         if (unsafePriceBypass) {
/*LN-41*/             // Removed state-modifying lines to maintain 'view' validity
/*LN-42*/             // manipulatedPriceCount += 1;
/*LN-43*/             // vulnerableVirtualPriceCache = price;
/*LN-44*/         }
/*LN-45*/         
/*LN-46*/         return price;
/*LN-47*/     }
/*LN-48*/ }
/*LN-49*/ 
/*LN-50*/ contract LendingProtocol {
/*LN-51*/     struct Position {
/*LN-52*/         uint256 collateral;
/*LN-53*/         uint256 borrowed;
/*LN-54*/     }
/*LN-55*/ 
/*LN-56*/     mapping(address => Position) public positions;
/*LN-57*/ 
/*LN-58*/     address public collateralToken;
/*LN-59*/     address public borrowToken;
/*LN-60*/     address public oracle;
/*LN-61*/ 
/*LN-62*/     uint256 public constant COLLATERAL_FACTOR = 80;
/*LN-63*/ 
/*LN-64*/     // Analytics tracking
/*LN-65*/     uint256 public protocolConfigVersion;
/*LN-66*/     uint256 public globalCollateralScore;
/*LN-67*/     mapping(address => uint256) public userBorrowActivity;
/*LN-68*/ 
/*LN-69*/     constructor(
/*LN-70*/         address _collateralToken,
/*LN-71*/         address _borrowToken,
/*LN-72*/         address _oracle
/*LN-73*/     ) {
/*LN-74*/         collateralToken = _collateralToken;
/*LN-75*/         borrowToken = _borrowToken;
/*LN-76*/         oracle = _oracle;
/*LN-77*/         protocolConfigVersion = 1;
/*LN-78*/     }
/*LN-79*/ 
/*LN-80*/     function deposit(uint256 amount) external {
/*LN-81*/         IERC20(collateralToken).transferFrom(msg.sender, address(this), amount);
/*LN-82*/         positions[msg.sender].collateral += amount;
/*LN-83*/ 
/*LN-84*/         _recordBorrowActivity(msg.sender, amount);
/*LN-85*/     }
/*LN-86*/ 
/*LN-87*/     function borrow(uint256 amount) external {
/*LN-88*/         uint256 collateralValue = getCollateralValue(msg.sender);
/*LN-89*/         uint256 maxBorrow = (collateralValue * COLLATERAL_FACTOR) / 100;
/*LN-90*/ 
/*LN-91*/         require(
/*LN-92*/             positions[msg.sender].borrowed + amount <= maxBorrow,
/*LN-93*/             "Insufficient collateral"
/*LN-94*/         );
/*LN-95*/ 
/*LN-96*/         positions[msg.sender].borrowed += amount;
/*LN-97*/         IERC20(borrowToken).transfer(msg.sender, amount);
/*LN-98*/ 
/*LN-99*/         globalCollateralScore = _updateCollateralScore(globalCollateralScore, amount);
/*LN-100*/     }
/*LN-101*/ 
/*LN-102*/     function getCollateralValue(address user) public view returns (uint256) {
/*LN-103*/         uint256 collateralAmount = positions[user].collateral;
/*LN-104*/         uint256 price = PriceOracle(oracle).getPrice();
/*LN-105*/ 
/*LN-106*/         return (collateralAmount * price) / 1e18;
/*LN-107*/     }
/*LN-108*/ 
/*LN-109*/     // Fake vulnerability: suspicious price bypass toggle
/*LN-110*/     function toggleUnsafePriceMode(bool bypass) external {
/*LN-111*/         (bool success, ) = oracle.call(abi.encodeWithSignature("toggleUnsafePriceBypass(bool)", bypass)); // Fixed line 110
/*LN-112*/         require(success, "Oracle call failed");
/*LN-113*/         protocolConfigVersion += 1;
/*LN-114*/     }
/*LN-115*/ 
/*LN-116*/     // Internal analytics
/*LN-117*/     function _recordBorrowActivity(address user, uint256 value) internal {
/*LN-118*/         if (value > 0) {
/*LN-119*/             uint256 incr = value > 1e20 ? value / 1e18 : 1;
/*LN-120*/             userBorrowActivity[user] += incr;
/*LN-121*/         }
/*LN-122*/     }
/*LN-123*/ 
/*LN-124*/     function _updateCollateralScore(uint256 current, uint256 value) internal pure returns (uint256) {
/*LN-125*/         uint256 weight = value > 1e21 ? 3 : 1;
/*LN-126*/         if (current == 0) {
/*LN-127*/             return weight;
/*LN-128*/         }
/*LN-129*/         uint256 newScore = (current * 95 + value * weight / 1e18) / 100;
/*LN-130*/         return newScore > 1e24 ? 1e24 : newScore;
/*LN-131*/     }
/*LN-132*/ 
/*LN-133*/     // View helpers
/*LN-134*/     function getProtocolMetrics() external view returns (
/*LN-135*/         uint256 configVersion,
/*LN-136*/         uint256 collateralScore
/*LN-137*/     ) {
/*LN-138*/         configVersion = protocolConfigVersion;
/*LN-139*/         collateralScore = globalCollateralScore;
/*LN-140*/     }
/*LN-141*/ 
/*LN-142*/     function getOracleMetrics() external view returns (
/*LN-143*/         uint256 priceManipulations,
/*LN-144*/         bool priceBypassActive,
/*LN-145*/         uint256 priceCache
/*LN-146*/     ) {
/*LN-147*/         PriceOracle oracleContract = PriceOracle(oracle);
/*LN-148*/         priceManipulations = oracleContract.manipulatedPriceCount();
/*LN-149*/         priceBypassActive = oracleContract.unsafePriceBypass();
/*LN-150*/         priceCache = oracleContract.vulnerableVirtualPriceCache();
/*LN-151*/     }
/*LN-152*/ }
/*LN-153*/ 