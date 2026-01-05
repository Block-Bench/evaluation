/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title Lending Protocol
/*LN-6*/  * @notice Decentralized lending and borrowing platform
/*LN-7*/  * @dev Users can deposit collateral and borrow against it
/*LN-8*/  */
/*LN-9*/ 
/*LN-10*/ interface IOracle {
/*LN-11*/     function getUnderlyingPrice(address cToken) external view returns (uint256);
/*LN-12*/ }
/*LN-13*/ 
/*LN-14*/ interface ICToken {
/*LN-15*/     function mint(uint256 mintAmount) external;
/*LN-16*/ 
/*LN-17*/     function borrow(uint256 borrowAmount) external;
/*LN-18*/ 
/*LN-19*/     function redeem(uint256 redeemTokens) external;
/*LN-20*/ 
/*LN-21*/     function underlying() external view returns (address);
/*LN-22*/ }
/*LN-23*/ 
/*LN-24*/ contract LendingProtocol {
/*LN-25*/     // Oracle for getting asset prices
/*LN-26*/     IOracle public oracle;
/*LN-27*/ 
/*LN-28*/     // Collateral factors
/*LN-29*/     mapping(address => uint256) public collateralFactors;
/*LN-30*/ 
/*LN-31*/     // User deposits (cToken balances)
/*LN-32*/     mapping(address => mapping(address => uint256)) public userDeposits;
/*LN-33*/ 
/*LN-34*/     // User borrows
/*LN-35*/     mapping(address => mapping(address => uint256)) public userBorrows;
/*LN-36*/ 
/*LN-37*/     // Supported markets
/*LN-38*/     mapping(address => bool) public supportedMarkets;
/*LN-39*/ 
/*LN-40*/     // Price deviation protection
/*LN-41*/     mapping(address => uint256) public lastKnownPrice;
/*LN-42*/     mapping(address => uint256) public lastPriceUpdate;
/*LN-43*/     uint256 public constant MAX_PRICE_DEVIATION = 10; // 10%
/*LN-44*/     uint256 public constant MIN_PRICE_UPDATE_INTERVAL = 1 hours;
/*LN-45*/ 
/*LN-46*/     event Deposit(address indexed user, address indexed cToken, uint256 amount);
/*LN-47*/     event Borrow(address indexed user, address indexed cToken, uint256 amount);
/*LN-48*/ 
/*LN-49*/     constructor(address _oracle) {
/*LN-50*/         oracle = IOracle(_oracle);
/*LN-51*/     }
/*LN-52*/ 
/*LN-53*/     function _validatePrice(address cToken) internal view returns (uint256) {
/*LN-54*/         uint256 currentPrice = oracle.getUnderlyingPrice(cToken);
/*LN-55*/         uint256 lastPrice = lastKnownPrice[cToken];
/*LN-56*/ 
/*LN-57*/         if (lastPrice > 0 && block.timestamp < lastPriceUpdate[cToken] + MIN_PRICE_UPDATE_INTERVAL) {
/*LN-58*/             uint256 maxAllowed = lastPrice * (100 + MAX_PRICE_DEVIATION) / 100;
/*LN-59*/             uint256 minAllowed = lastPrice * (100 - MAX_PRICE_DEVIATION) / 100;
/*LN-60*/             require(currentPrice >= minAllowed && currentPrice <= maxAllowed, "Price deviation too high");
/*LN-61*/         }
/*LN-62*/ 
/*LN-63*/         return currentPrice;
/*LN-64*/     }
/*LN-65*/ 
/*LN-66*/     /**
/*LN-67*/      * @notice Mint cTokens by depositing underlying assets
/*LN-68*/      * @param cToken The cToken to mint
/*LN-69*/      * @param amount Amount of underlying to deposit
/*LN-70*/      */
/*LN-71*/     function mint(address cToken, uint256 amount) external {
/*LN-72*/         require(supportedMarkets[cToken], "Market not supported");
/*LN-73*/ 
/*LN-74*/         // Mint cTokens to user
/*LN-75*/         userDeposits[msg.sender][cToken] += amount;
/*LN-76*/ 
/*LN-77*/         emit Deposit(msg.sender, cToken, amount);
/*LN-78*/     }
/*LN-79*/ 
/*LN-80*/     /**
/*LN-81*/      * @notice Borrow assets against collateral
/*LN-82*/      * @param cToken The cToken to borrow
/*LN-83*/      * @param amount Amount to borrow
/*LN-84*/      */
/*LN-85*/     function borrow(address cToken, uint256 amount) external {
/*LN-86*/         require(supportedMarkets[cToken], "Market not supported");
/*LN-87*/ 
/*LN-88*/         // Calculate user's borrowing power
/*LN-89*/         uint256 borrowPower = calculateBorrowPower(msg.sender);
/*LN-90*/ 
/*LN-91*/         // Calculate current total borrows value
/*LN-92*/         uint256 currentBorrows = calculateTotalBorrows(msg.sender);
/*LN-93*/ 
/*LN-94*/         // Get validated price (with deviation check)
/*LN-95*/         uint256 price = _validatePrice(cToken);
/*LN-96*/         uint256 borrowValue = (price * amount) / 1e18;
/*LN-97*/ 
/*LN-98*/         // Check if user has enough collateral
/*LN-99*/         require(
/*LN-100*/             currentBorrows + borrowValue <= borrowPower,
/*LN-101*/             "Insufficient collateral"
/*LN-102*/         );
/*LN-103*/ 
/*LN-104*/         // Update borrow balance
/*LN-105*/         userBorrows[msg.sender][cToken] += amount;
/*LN-106*/ 
/*LN-107*/         emit Borrow(msg.sender, cToken, amount);
/*LN-108*/     }
/*LN-109*/ 
/*LN-110*/     /**
/*LN-111*/      * @notice Calculate user's total borrowing power
/*LN-112*/      * @param user The user address
/*LN-113*/      * @return Total borrowing power in USD
/*LN-114*/      */
/*LN-115*/     function calculateBorrowPower(address user) public view returns (uint256) {
/*LN-116*/         uint256 totalPower = 0;
/*LN-117*/ 
/*LN-118*/         address[] memory markets = new address[](2);
/*LN-119*/ 
/*LN-120*/         for (uint256 i = 0; i < markets.length; i++) {
/*LN-121*/             address cToken = markets[i];
/*LN-122*/             uint256 balance = userDeposits[user][cToken];
/*LN-123*/ 
/*LN-124*/             if (balance > 0) {
/*LN-125*/                 // Get price from oracle
/*LN-126*/                 uint256 price = oracle.getUnderlyingPrice(cToken);
/*LN-127*/ 
/*LN-128*/                 // Calculate value
/*LN-129*/                 uint256 value = (balance * price) / 1e18;
/*LN-130*/ 
/*LN-131*/                 // Apply collateral factor
/*LN-132*/                 uint256 power = (value * collateralFactors[cToken]) / 1e18;
/*LN-133*/ 
/*LN-134*/                 totalPower += power;
/*LN-135*/             }
/*LN-136*/         }
/*LN-137*/ 
/*LN-138*/         return totalPower;
/*LN-139*/     }
/*LN-140*/ 
/*LN-141*/     /**
/*LN-142*/      * @notice Calculate user's total borrow value
/*LN-143*/      * @param user The user address
/*LN-144*/      * @return Total borrow value in USD
/*LN-145*/      */
/*LN-146*/     function calculateTotalBorrows(address user) public view returns (uint256) {
/*LN-147*/         uint256 totalBorrows = 0;
/*LN-148*/ 
/*LN-149*/         address[] memory markets = new address[](2);
/*LN-150*/ 
/*LN-151*/         for (uint256 i = 0; i < markets.length; i++) {
/*LN-152*/             address cToken = markets[i];
/*LN-153*/             uint256 borrowed = userBorrows[user][cToken];
/*LN-154*/ 
/*LN-155*/             if (borrowed > 0) {
/*LN-156*/                 uint256 price = oracle.getUnderlyingPrice(cToken);
/*LN-157*/                 uint256 value = (borrowed * price) / 1e18;
/*LN-158*/                 totalBorrows += value;
/*LN-159*/             }
/*LN-160*/         }
/*LN-161*/ 
/*LN-162*/         return totalBorrows;
/*LN-163*/     }
/*LN-164*/ 
/*LN-165*/     /**
/*LN-166*/      * @notice Add a supported market
/*LN-167*/      * @param cToken The cToken to add
/*LN-168*/      * @param collateralFactor The collateral factor
/*LN-169*/      */
/*LN-170*/     function addMarket(address cToken, uint256 collateralFactor) external {
/*LN-171*/         supportedMarkets[cToken] = true;
/*LN-172*/         collateralFactors[cToken] = collateralFactor;
/*LN-173*/     }
/*LN-174*/ 
/*LN-175*/     /**
/*LN-176*/      * @notice Update cached price (admin function)
/*LN-177*/      */
/*LN-178*/     function updateCachedPrice(address cToken) external {
/*LN-179*/         lastKnownPrice[cToken] = oracle.getUnderlyingPrice(cToken);
/*LN-180*/         lastPriceUpdate[cToken] = block.timestamp;
/*LN-181*/     }
/*LN-182*/ }
/*LN-183*/ 