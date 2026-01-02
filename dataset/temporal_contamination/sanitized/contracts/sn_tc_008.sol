/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IOracle {
/*LN-5*/     function getUnderlyingPrice(address cToken) external view returns (uint256);
/*LN-6*/ }
/*LN-7*/ 
/*LN-8*/ interface ICToken {
/*LN-9*/     function mint(uint256 mintAmount) external;
/*LN-10*/ 
/*LN-11*/     function borrow(uint256 borrowAmount) external;
/*LN-12*/ 
/*LN-13*/     function redeem(uint256 redeemTokens) external;
/*LN-14*/ 
/*LN-15*/     function underlying() external view returns (address);
/*LN-16*/ }
/*LN-17*/ 
/*LN-18*/ contract ForkLending {
/*LN-19*/     // Oracle for getting asset prices
/*LN-20*/     IOracle public oracle;
/*LN-21*/ 
/*LN-22*/     // Collateral factors (how much can be borrowed against collateral)
/*LN-23*/     mapping(address => uint256) public collateralFactors; // e.g., 75% = 0.75e18
/*LN-24*/ 
/*LN-25*/     // User deposits (crToken balances)
/*LN-26*/     mapping(address => mapping(address => uint256)) public userDeposits;
/*LN-27*/ 
/*LN-28*/     // User borrows
/*LN-29*/     mapping(address => mapping(address => uint256)) public userBorrows;
/*LN-30*/ 
/*LN-31*/     // Supported markets
/*LN-32*/     mapping(address => bool) public supportedMarkets;
/*LN-33*/ 
/*LN-34*/     event Deposit(address indexed user, address indexed cToken, uint256 amount);
/*LN-35*/     event Borrow(address indexed user, address indexed cToken, uint256 amount);
/*LN-36*/ 
/*LN-37*/     constructor(address _oracle) {
/*LN-38*/         oracle = IOracle(_oracle);
/*LN-39*/     }
/*LN-40*/ 
/*LN-41*/     /**
/*LN-42*/      * @notice Mint crTokens by depositing underlying assets
/*LN-43*/      * @param cToken The crToken to mint
/*LN-44*/      * @param amount Amount of underlying to deposit
/*LN-45*/      *
/*LN-46*/      */
/*LN-47*/     function mint(address cToken, uint256 amount) external {
/*LN-48*/         require(supportedMarkets[cToken], "Market not supported");
/*LN-49*/ 
/*LN-50*/         // Transfer underlying from user (simplified)
/*LN-51*/         // address underlying = ICToken(cToken).underlying();
/*LN-52*/         // IERC20(underlying).transferFrom(msg.sender, address(this), amount);
/*LN-53*/ 
/*LN-54*/         // Mint crTokens to user
/*LN-55*/         userDeposits[msg.sender][cToken] += amount;
/*LN-56*/ 
/*LN-57*/         emit Deposit(msg.sender, cToken, amount);
/*LN-58*/     }
/*LN-59*/ 
/*LN-60*/     function borrow(address cToken, uint256 amount) external {
/*LN-61*/         require(supportedMarkets[cToken], "Market not supported");
/*LN-62*/ 
/*LN-63*/         // Calculate user's borrowing power
/*LN-64*/         uint256 borrowPower = calculateBorrowPower(msg.sender);
/*LN-65*/ 
/*LN-66*/         // Calculate current total borrows value
/*LN-67*/         uint256 currentBorrows = calculateTotalBorrows(msg.sender);
/*LN-68*/ 
/*LN-69*/         // Get value of new borrow
/*LN-70*/         uint256 borrowValue = (oracle.getUnderlyingPrice(cToken) * amount) /
/*LN-71*/             1e18;
/*LN-72*/ 
/*LN-73*/         // Check if user has enough collateral
/*LN-74*/         require(
/*LN-75*/             currentBorrows + borrowValue <= borrowPower,
/*LN-76*/             "Insufficient collateral"
/*LN-77*/         );
/*LN-78*/ 
/*LN-79*/         // Update borrow balance
/*LN-80*/         userBorrows[msg.sender][cToken] += amount;
/*LN-81*/ 
/*LN-82*/         // Transfer tokens to borrower (simplified)
/*LN-83*/         // address underlying = ICToken(cToken).underlying();
/*LN-84*/         // IERC20(underlying).transfer(msg.sender, amount);
/*LN-85*/ 
/*LN-86*/         emit Borrow(msg.sender, cToken, amount);
/*LN-87*/     }
/*LN-88*/ 
/*LN-89*/     function calculateBorrowPower(address user) public view returns (uint256) {
/*LN-90*/         uint256 totalPower = 0;
/*LN-91*/ 
/*LN-92*/         // Iterate through all supported markets (simplified)
/*LN-93*/         // In reality, would track user's entered markets
/*LN-94*/         address[] memory markets = new address[](2); // Placeholder
/*LN-95*/ 
/*LN-96*/         for (uint256 i = 0; i < markets.length; i++) {
/*LN-97*/             address cToken = markets[i];
/*LN-98*/             uint256 balance = userDeposits[user][cToken];
/*LN-99*/ 
/*LN-100*/             if (balance > 0) {
/*LN-101*/                 // Get price from oracle
/*LN-102*/                 uint256 price = oracle.getUnderlyingPrice(cToken);
/*LN-103*/ 
/*LN-104*/                 // Calculate value
/*LN-105*/                 uint256 value = (balance * price) / 1e18;
/*LN-106*/ 
/*LN-107*/                 // Apply collateral factor
/*LN-108*/                 uint256 power = (value * collateralFactors[cToken]) / 1e18;
/*LN-109*/ 
/*LN-110*/                 totalPower += power;
/*LN-111*/             }
/*LN-112*/         }
/*LN-113*/ 
/*LN-114*/         return totalPower;
/*LN-115*/     }
/*LN-116*/ 
/*LN-117*/     /**
/*LN-118*/      * @notice Calculate user's total borrow value
/*LN-119*/      * @param user The user address
/*LN-120*/      * @return Total borrow value in USD (scaled by 1e18)
/*LN-121*/      */
/*LN-122*/     function calculateTotalBorrows(address user) public view returns (uint256) {
/*LN-123*/         uint256 totalBorrows = 0;
/*LN-124*/ 
/*LN-125*/         // Iterate through all supported markets (simplified)
/*LN-126*/         address[] memory markets = new address[](2); // Placeholder
/*LN-127*/ 
/*LN-128*/         for (uint256 i = 0; i < markets.length; i++) {
/*LN-129*/             address cToken = markets[i];
/*LN-130*/             uint256 borrowed = userBorrows[user][cToken];
/*LN-131*/ 
/*LN-132*/             if (borrowed > 0) {
/*LN-133*/                 uint256 price = oracle.getUnderlyingPrice(cToken);
/*LN-134*/                 uint256 value = (borrowed * price) / 1e18;
/*LN-135*/                 totalBorrows += value;
/*LN-136*/             }
/*LN-137*/         }
/*LN-138*/ 
/*LN-139*/         return totalBorrows;
/*LN-140*/     }
/*LN-141*/ 
/*LN-142*/     /**
/*LN-143*/      * @notice Add a supported market
/*LN-144*/      * @param cToken The crToken to add
/*LN-145*/      * @param collateralFactor The collateral factor (e.g., 0.75e18 for 75%)
/*LN-146*/      */
/*LN-147*/     function addMarket(address cToken, uint256 collateralFactor) external {
/*LN-148*/         supportedMarkets[cToken] = true;
/*LN-149*/         collateralFactors[cToken] = collateralFactor;
/*LN-150*/     }
/*LN-151*/ }
/*LN-152*/ 