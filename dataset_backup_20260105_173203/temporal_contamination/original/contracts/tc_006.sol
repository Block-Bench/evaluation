/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title Cream Finance Lending Pool (Vulnerable Version)
/*LN-6*/  * @notice This contract demonstrates the vulnerability that led to the $130M Cream Finance hack
/*LN-7*/  * @dev October 27, 2021 - Complex flash loan + price oracle manipulation
/*LN-8*/  *
/*LN-9*/  * VULNERABILITY: Price oracle manipulation + flash loan + reentrancy
/*LN-10*/  *
/*LN-11*/  * ROOT CAUSE:
/*LN-12*/  * Cream Finance was a fork of Compound Finance with similar mechanics:
/*LN-13*/  * - Users deposit collateral to mint crTokens
/*LN-14*/  * - crTokens can be used as collateral to borrow other assets
/*LN-15*/  * - Borrowing power based on collateral value (from price oracles)
/*LN-16*/  *
/*LN-17*/  * The attack exploited:
/*LN-18*/  * 1. Cream used yUSD token as collateral
/*LN-19*/  * 2. yUSD price was calculated from its underlying assets (via Curve pool)
/*LN-20*/  * 3. Attacker could manipulate yUSD price by draining Curve pool
/*LN-21*/  * 4. With inflated yUSD value, attacker could borrow massive amounts
/*LN-22*/  *
/*LN-23*/  * ATTACK VECTOR:
/*LN-24*/  * 1. Flash loan $500M DAI from MakerDAO
/*LN-25*/  * 2. Convert DAI to yUSD (via Curve), mint crYUSD as collateral ($500M value)
/*LN-26*/  * 3. Flash loan 524,000 ETH from Aave
/*LN-27*/  * 4. Mint crETH as additional collateral ($2B value)
/*LN-28*/  * 5. Borrow yUSD multiple times against ETH collateral
/*LN-29*/  * 6. Withdraw yUSD from Curve to underlying tokens, doubling crYUSD price
/*LN-30*/  * 7. Now crYUSD collateral is valued at $1.5B (was $500M)
/*LN-31*/  * 8. Borrow massive amounts against inflated collateral
/*LN-32*/  * 9. Repay flash loans, keep profit
/*LN-33*/  */
/*LN-34*/ 
/*LN-35*/ interface IOracle {
/*LN-36*/     function getUnderlyingPrice(address cToken) external view returns (uint256);
/*LN-37*/ }
/*LN-38*/ 
/*LN-39*/ interface ICToken {
/*LN-40*/     function mint(uint256 mintAmount) external;
/*LN-41*/ 
/*LN-42*/     function borrow(uint256 borrowAmount) external;
/*LN-43*/ 
/*LN-44*/     function redeem(uint256 redeemTokens) external;
/*LN-45*/ 
/*LN-46*/     function underlying() external view returns (address);
/*LN-47*/ }
/*LN-48*/ 
/*LN-49*/ contract VulnerableCreamLending {
/*LN-50*/     // Oracle for getting asset prices
/*LN-51*/     IOracle public oracle;
/*LN-52*/ 
/*LN-53*/     // Collateral factors (how much can be borrowed against collateral)
/*LN-54*/     mapping(address => uint256) public collateralFactors; // e.g., 75% = 0.75e18
/*LN-55*/ 
/*LN-56*/     // User deposits (crToken balances)
/*LN-57*/     mapping(address => mapping(address => uint256)) public userDeposits;
/*LN-58*/ 
/*LN-59*/     // User borrows
/*LN-60*/     mapping(address => mapping(address => uint256)) public userBorrows;
/*LN-61*/ 
/*LN-62*/     // Supported markets
/*LN-63*/     mapping(address => bool) public supportedMarkets;
/*LN-64*/ 
/*LN-65*/     event Deposit(address indexed user, address indexed cToken, uint256 amount);
/*LN-66*/     event Borrow(address indexed user, address indexed cToken, uint256 amount);
/*LN-67*/ 
/*LN-68*/     constructor(address _oracle) {
/*LN-69*/         oracle = IOracle(_oracle);
/*LN-70*/     }
/*LN-71*/ 
/*LN-72*/     /**
/*LN-73*/      * @notice Mint crTokens by depositing underlying assets
/*LN-74*/      * @param cToken The crToken to mint
/*LN-75*/      * @param amount Amount of underlying to deposit
/*LN-76*/      *
/*LN-77*/      * This function is safe, but sets up the collateral that enables the attack
/*LN-78*/      */
/*LN-79*/     function mint(address cToken, uint256 amount) external {
/*LN-80*/         require(supportedMarkets[cToken], "Market not supported");
/*LN-81*/ 
/*LN-82*/         // Transfer underlying from user (simplified)
/*LN-83*/         // address underlying = ICToken(cToken).underlying();
/*LN-84*/         // IERC20(underlying).transferFrom(msg.sender, address(this), amount);
/*LN-85*/ 
/*LN-86*/         // Mint crTokens to user
/*LN-87*/         userDeposits[msg.sender][cToken] += amount;
/*LN-88*/ 
/*LN-89*/         emit Deposit(msg.sender, cToken, amount);
/*LN-90*/     }
/*LN-91*/ 
/*LN-92*/     /**
/*LN-93*/      * @notice Borrow assets against collateral
/*LN-94*/      * @param cToken The crToken to borrow
/*LN-95*/      * @param amount Amount to borrow
/*LN-96*/      *
/*LN-97*/      * VULNERABILITY:
/*LN-98*/      * The borrowing limit is calculated based on oracle prices.
/*LN-99*/      * If the oracle price can be manipulated (as with yUSD via Curve),
/*LN-100*/      * attackers can borrow far more than their actual collateral is worth.
/*LN-101*/      */
/*LN-102*/     function borrow(address cToken, uint256 amount) external {
/*LN-103*/         require(supportedMarkets[cToken], "Market not supported");
/*LN-104*/ 
/*LN-105*/         // Calculate user's borrowing power
/*LN-106*/         uint256 borrowPower = calculateBorrowPower(msg.sender);
/*LN-107*/ 
/*LN-108*/         // Calculate current total borrows value
/*LN-109*/         uint256 currentBorrows = calculateTotalBorrows(msg.sender);
/*LN-110*/ 
/*LN-111*/         // Get value of new borrow
/*LN-112*/         // VULNERABILITY: Uses oracle price which can be manipulated!
/*LN-113*/         uint256 borrowValue = (oracle.getUnderlyingPrice(cToken) * amount) /
/*LN-114*/             1e18;
/*LN-115*/ 
/*LN-116*/         // Check if user has enough collateral
/*LN-117*/         require(
/*LN-118*/             currentBorrows + borrowValue <= borrowPower,
/*LN-119*/             "Insufficient collateral"
/*LN-120*/         );
/*LN-121*/ 
/*LN-122*/         // Update borrow balance
/*LN-123*/         userBorrows[msg.sender][cToken] += amount;
/*LN-124*/ 
/*LN-125*/         // Transfer tokens to borrower (simplified)
/*LN-126*/         // address underlying = ICToken(cToken).underlying();
/*LN-127*/         // IERC20(underlying).transfer(msg.sender, amount);
/*LN-128*/ 
/*LN-129*/         emit Borrow(msg.sender, cToken, amount);
/*LN-130*/     }
/*LN-131*/ 
/*LN-132*/     /**
/*LN-133*/      * @notice Calculate user's total borrowing power
/*LN-134*/      * @param user The user address
/*LN-135*/      * @return Total borrowing power in USD (scaled by 1e18)
/*LN-136*/      *
/*LN-137*/      * VULNERABILITY:
/*LN-138*/      * This function uses oracle.getUnderlyingPrice() which can return
/*LN-139*/      * manipulated prices for tokens like yUSD.
/*LN-140*/      *
/*LN-141*/      * In the Cream hack:
/*LN-142*/      * 1. Attacker deposited crYUSD (backed by Curve pool)
/*LN-143*/      * 2. Oracle valued yUSD based on its underlying assets
/*LN-144*/      * 3. Attacker manipulated Curve pool by withdrawing all yUSD
/*LN-145*/      * 4. This made remaining yUSD appear more valuable
/*LN-146*/      * 5. Oracle reported inflated price
/*LN-147*/      * 6. Attacker could borrow huge amounts
/*LN-148*/      */
/*LN-149*/     function calculateBorrowPower(address user) public view returns (uint256) {
/*LN-150*/         uint256 totalPower = 0;
/*LN-151*/ 
/*LN-152*/         // Iterate through all supported markets (simplified)
/*LN-153*/         // In reality, would track user's entered markets
/*LN-154*/         address[] memory markets = new address[](2); // Placeholder
/*LN-155*/ 
/*LN-156*/         for (uint256 i = 0; i < markets.length; i++) {
/*LN-157*/             address cToken = markets[i];
/*LN-158*/             uint256 balance = userDeposits[user][cToken];
/*LN-159*/ 
/*LN-160*/             if (balance > 0) {
/*LN-161*/                 // Get price from oracle
/*LN-162*/                 // VULNERABILITY: This price can be manipulated!
/*LN-163*/                 uint256 price = oracle.getUnderlyingPrice(cToken);
/*LN-164*/ 
/*LN-165*/                 // Calculate value
/*LN-166*/                 uint256 value = (balance * price) / 1e18;
/*LN-167*/ 
/*LN-168*/                 // Apply collateral factor
/*LN-169*/                 uint256 power = (value * collateralFactors[cToken]) / 1e18;
/*LN-170*/ 
/*LN-171*/                 totalPower += power;
/*LN-172*/             }
/*LN-173*/         }
/*LN-174*/ 
/*LN-175*/         return totalPower;
/*LN-176*/     }
/*LN-177*/ 
/*LN-178*/     /**
/*LN-179*/      * @notice Calculate user's total borrow value
/*LN-180*/      * @param user The user address
/*LN-181*/      * @return Total borrow value in USD (scaled by 1e18)
/*LN-182*/      */
/*LN-183*/     function calculateTotalBorrows(address user) public view returns (uint256) {
/*LN-184*/         uint256 totalBorrows = 0;
/*LN-185*/ 
/*LN-186*/         // Iterate through all supported markets (simplified)
/*LN-187*/         address[] memory markets = new address[](2); // Placeholder
/*LN-188*/ 
/*LN-189*/         for (uint256 i = 0; i < markets.length; i++) {
/*LN-190*/             address cToken = markets[i];
/*LN-191*/             uint256 borrowed = userBorrows[user][cToken];
/*LN-192*/ 
/*LN-193*/             if (borrowed > 0) {
/*LN-194*/                 uint256 price = oracle.getUnderlyingPrice(cToken);
/*LN-195*/                 uint256 value = (borrowed * price) / 1e18;
/*LN-196*/                 totalBorrows += value;
/*LN-197*/             }
/*LN-198*/         }
/*LN-199*/ 
/*LN-200*/         return totalBorrows;
/*LN-201*/     }
/*LN-202*/ 
/*LN-203*/     /**
/*LN-204*/      * @notice Add a supported market
/*LN-205*/      * @param cToken The crToken to add
/*LN-206*/      * @param collateralFactor The collateral factor (e.g., 0.75e18 for 75%)
/*LN-207*/      */
/*LN-208*/     function addMarket(address cToken, uint256 collateralFactor) external {
/*LN-209*/         supportedMarkets[cToken] = true;
/*LN-210*/         collateralFactors[cToken] = collateralFactor;
/*LN-211*/     }
/*LN-212*/ }
/*LN-213*/ 
/*LN-214*/ /**
/*LN-215*/  * REAL-WORLD IMPACT:
/*LN-216*/  * - $130M stolen on October 27, 2021
/*LN-217*/  * - Complex multi-step attack using two flash loans
/*LN-218*/  * - Exploited price oracle manipulation via Curve pool
/*LN-219*/  * - One of Cream's multiple hacks (they were exploited several times)
/*LN-220*/  *
/*LN-221*/  * ATTACK FLOW (Simplified):
/*LN-222*/  * 1. Flash loan $500M DAI from MakerDAO
/*LN-223*/  * 2. Swap DAI -> yUSD, deposit to Cream, get crYUSD collateral
/*LN-224*/  * 3. Flash loan 524,000 ETH from Aave
/*LN-225*/  * 4. Deposit ETH to Cream, get crETH collateral
/*LN-226*/  * 5. Borrow yUSD against ETH collateral (multiple times)
/*LN-227*/  * 6. Withdraw yUSD from Curve to underlying tokens
/*LN-228*/  * 7. This manipulation doubles the price of remaining yUSD
/*LN-229*/  * 8. Oracle reports inflated yUSD price
/*LN-230*/  * 9. Attacker's crYUSD collateral is now valued at $1.5B (was $500M)
/*LN-231*/  * 10. Borrow massive amounts against inflated collateral
/*LN-232*/  * 11. Repay flash loans with profit
/*LN-233*/  *
/*LN-234*/  * FIX:
/*LN-235*/  * The fix requires:
/*LN-236*/  * 1. Use Time-Weighted Average Price (TWAP) oracles
/*LN-237*/  * 2. Use Chainlink or other manipulation-resistant oracles
/*LN-238*/  * 3. Don't use LP token prices directly from AMM pools
/*LN-239*/  * 4. Implement price sanity checks and circuit breakers
/*LN-240*/  * 5. Add borrow caps per market
/*LN-241*/  * 6. Implement gradual price updates, not instant changes
/*LN-242*/  * 7. Use multiple oracle sources and take median
/*LN-243*/  * 8. Add flash loan attack detection
/*LN-244*/  *
/*LN-245*/  * KEY LESSON:
/*LN-246*/  * Oracle manipulation is one of the most dangerous vulnerabilities in DeFi.
/*LN-247*/  * Using spot prices from AMM pools is especially risky because:
/*LN-248*/  * - Pools can be manipulated via flash loans
/*LN-249*/  * - Especially dangerous for low-liquidity assets
/*LN-250*/  * - Can lead to cascading liquidations and protocol insolvency
/*LN-251*/  *
/*LN-252*/  * Cream was particularly vulnerable because:
/*LN-253*/  * - It listed many low-liquidity tokens
/*LN-254*/  * - Used Curve pool prices without sufficient safeguards
/*LN-255*/  * - Allowed recursive borrowing that amplified the attack
/*LN-256*/  *
/*LN-257*/  *
/*LN-258*/  * The vulnerability is in the ORACLE, not this contract's logic.
/*LN-259*/  * But the contract should have protected against oracle manipulation.
/*LN-260*/  */
/*LN-261*/ 