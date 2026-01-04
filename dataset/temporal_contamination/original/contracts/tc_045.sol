/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * EXACTLY PROTOCOL EXPLOIT (August 2024)
/*LN-6*/  * Loss: $12 million
/*LN-7*/  * Attack: Oracle Price Manipulation via DebtPreviewer Contract
/*LN-8*/  *
/*LN-9*/  * VULNERABILITY OVERVIEW:
/*LN-10*/  * Exactly Protocol, a decentralized lending market, was exploited through a vulnerability
/*LN-11*/  * in its DebtPreviewer helper contract. The previewer incorrectly calculated debt positions,
/*LN-12*/  * allowing attackers to manipulate their perceived debt and borrow more than collateralized.
/*LN-13*/  *
/*LN-14*/  * ROOT CAUSE:
/*LN-15*/  * 1. DebtPreviewer used incorrect accounting for debt calculations
/*LN-16*/  * 2. Malicious market contract could return false data
/*LN-17*/  * 3. Protocol trusted previewer's calculations without validation
/*LN-18*/  * 4. Missing sanity checks on borrow limits
/*LN-19*/  *
/*LN-20*/  * ATTACK FLOW:
/*LN-21*/  * 1. Attacker deposited collateral into Exactly Protocol
/*LN-22*/  * 2. Created malicious market contract with fake asset
/*LN-23*/  * 3. DebtPreviewer queried malicious market for debt calculations
/*LN-24*/  * 4. Malicious market returned manipulated data showing low/zero debt
/*LN-25*/  * 5. Protocol allowed over-borrowing based on false debt figures
/*LN-26*/  * 6. Attacker borrowed $12M against minimal actual collateral
/*LN-27*/  * 7. Withdrew borrowed assets and abandoned position
/*LN-28*/  */
/*LN-29*/ 
/*LN-30*/ interface IERC20 {
/*LN-31*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-32*/ 
/*LN-33*/     function transferFrom(
/*LN-34*/         address from,
/*LN-35*/         address to,
/*LN-36*/         uint256 amount
/*LN-37*/     ) external returns (bool);
/*LN-38*/ 
/*LN-39*/     function balanceOf(address account) external view returns (uint256);
/*LN-40*/ }
/*LN-41*/ 
/*LN-42*/ interface IMarket {
/*LN-43*/     function getAccountSnapshot(
/*LN-44*/         address account
/*LN-45*/     )
/*LN-46*/         external
/*LN-47*/         view
/*LN-48*/         returns (uint256 collateral, uint256 borrows, uint256 exchangeRate);
/*LN-49*/ }
/*LN-50*/ 
/*LN-51*/ /**
/*LN-52*/  * DebtPreviewer - Helper contract for calculating account health
/*LN-53*/  * VULNERABILITY: Trusts arbitrary market contracts without validation
/*LN-54*/  */
/*LN-55*/ contract DebtPreviewer {
/*LN-56*/     /**
/*LN-57*/      * @dev VULNERABILITY: Accepts any address as market parameter
/*LN-58*/      * @dev Allows attacker to provide malicious market contract
/*LN-59*/      */
/*LN-60*/     function previewDebt(
/*LN-61*/         address market,
/*LN-62*/         address account
/*LN-63*/     )
/*LN-64*/         external
/*LN-65*/         view
/*LN-66*/         returns (
/*LN-67*/             uint256 collateralValue,
/*LN-68*/             uint256 debtValue,
/*LN-69*/             uint256 healthFactor
/*LN-70*/         )
/*LN-71*/     {
/*LN-72*/         // VULNERABILITY 1: No validation that 'market' is legitimate
/*LN-73*/         // VULNERABILITY 2: Trusts data from user-provided address
/*LN-74*/ 
/*LN-75*/         // Query market for account snapshot
/*LN-76*/         // VULNERABILITY 3: Malicious market can return false data
/*LN-77*/         (uint256 collateral, uint256 borrows, uint256 exchangeRate) = IMarket(
/*LN-78*/             market
/*LN-79*/         ).getAccountSnapshot(account);
/*LN-80*/ 
/*LN-81*/         // VULNERABILITY 4: Uses manipulated data for critical calculations
/*LN-82*/         collateralValue = (collateral * exchangeRate) / 1e18;
/*LN-83*/         debtValue = borrows;
/*LN-84*/ 
/*LN-85*/         // VULNERABILITY 5: Health factor calculated from fake data
/*LN-86*/         if (debtValue == 0) {
/*LN-87*/             healthFactor = type(uint256).max;
/*LN-88*/         } else {
/*LN-89*/             healthFactor = (collateralValue * 1e18) / debtValue;
/*LN-90*/         }
/*LN-91*/ 
/*LN-92*/         return (collateralValue, debtValue, healthFactor);
/*LN-93*/     }
/*LN-94*/ 
/*LN-95*/     /**
/*LN-96*/      * @dev VULNERABILITY 6: Batch preview allows mixing real and fake markets
/*LN-97*/      */
/*LN-98*/     function previewMultipleMarkets(
/*LN-99*/         address[] calldata markets,
/*LN-100*/         address account
/*LN-101*/     )
/*LN-102*/         external
/*LN-103*/         view
/*LN-104*/         returns (
/*LN-105*/             uint256 totalCollateral,
/*LN-106*/             uint256 totalDebt,
/*LN-107*/             uint256 overallHealth
/*LN-108*/         )
/*LN-109*/     {
/*LN-110*/         for (uint256 i = 0; i < markets.length; i++) {
/*LN-111*/             // VULNERABILITY 7: Each market address unvalidated
/*LN-112*/             (uint256 collateral, uint256 debt, ) = this.previewDebt(
/*LN-113*/                 markets[i],
/*LN-114*/                 account
/*LN-115*/             );
/*LN-116*/ 
/*LN-117*/             totalCollateral += collateral;
/*LN-118*/             totalDebt += debt;
/*LN-119*/         }
/*LN-120*/ 
/*LN-121*/         if (totalDebt == 0) {
/*LN-122*/             overallHealth = type(uint256).max;
/*LN-123*/         } else {
/*LN-124*/             overallHealth = (totalCollateral * 1e18) / totalDebt;
/*LN-125*/         }
/*LN-126*/ 
/*LN-127*/         return (totalCollateral, totalDebt, overallHealth);
/*LN-128*/     }
/*LN-129*/ }
/*LN-130*/ 
/*LN-131*/ /**
/*LN-132*/  * Exactly Protocol Lending Market
/*LN-133*/  */
/*LN-134*/ contract ExactlyMarket {
/*LN-135*/     IERC20 public asset;
/*LN-136*/     DebtPreviewer public previewer;
/*LN-137*/ 
/*LN-138*/     mapping(address => uint256) public deposits;
/*LN-139*/     mapping(address => uint256) public borrows;
/*LN-140*/ 
/*LN-141*/     uint256 public constant COLLATERAL_FACTOR = 80; // 80%
/*LN-142*/ 
/*LN-143*/     constructor(address _asset, address _previewer) {
/*LN-144*/         asset = IERC20(_asset);
/*LN-145*/         previewer = DebtPreviewer(_previewer);
/*LN-146*/     }
/*LN-147*/ 
/*LN-148*/     function deposit(uint256 amount) external {
/*LN-149*/         asset.transferFrom(msg.sender, address(this), amount);
/*LN-150*/         deposits[msg.sender] += amount;
/*LN-151*/     }
/*LN-152*/ 
/*LN-153*/     /**
/*LN-154*/      * @dev VULNERABILITY 8: Borrow limit check relies on DebtPreviewer
/*LN-155*/      * @dev DebtPreviewer can be manipulated to show false debt levels
/*LN-156*/      */
/*LN-157*/     function borrow(uint256 amount, address[] calldata markets) external {
/*LN-158*/         // VULNERABILITY 9: Uses previewer for health check
/*LN-159*/         // VULNERABILITY 10: User provides markets array (can include malicious markets)
/*LN-160*/         (uint256 totalCollateral, uint256 totalDebt, ) = previewer
/*LN-161*/             .previewMultipleMarkets(markets, msg.sender);
/*LN-162*/ 
/*LN-163*/         // Calculate new debt after this borrow
/*LN-164*/         uint256 newDebt = totalDebt + amount;
/*LN-165*/ 
/*LN-166*/         // VULNERABILITY 11: Check based on manipulated totalCollateral
/*LN-167*/         uint256 maxBorrow = (totalCollateral * COLLATERAL_FACTOR) / 100;
/*LN-168*/         require(newDebt <= maxBorrow, "Insufficient collateral");
/*LN-169*/ 
/*LN-170*/         borrows[msg.sender] += amount;
/*LN-171*/         asset.transfer(msg.sender, amount);
/*LN-172*/     }
/*LN-173*/ 
/*LN-174*/     function getAccountSnapshot(
/*LN-175*/         address account
/*LN-176*/     )
/*LN-177*/         external
/*LN-178*/         view
/*LN-179*/         returns (uint256 collateral, uint256 borrowed, uint256 exchangeRate)
/*LN-180*/     {
/*LN-181*/         return (deposits[account], borrows[account], 1e18);
/*LN-182*/     }
/*LN-183*/ }
/*LN-184*/ 
/*LN-185*/ /**
/*LN-186*/  * ATTACK SCENARIO:
/*LN-187*/  *
/*LN-188*/  * Setup Phase:
/*LN-189*/  * 1. Attacker deploys malicious market contract:
/*LN-190*/  *    contract MaliciousMarket {
/*LN-191*/  *        function getAccountSnapshot(address) external pure returns (
/*LN-192*/  *            uint256, uint256, uint256
/*LN-193*/  *        ) {
/*LN-194*/  *            // Return huge fake collateral, zero debt
/*LN-195*/  *            return (1000000 * 1e18, 0, 1e18);
/*LN-196*/  *        }
/*LN-197*/  *    }
/*LN-198*/  *
/*LN-199*/  * Deposit Phase:
/*LN-200*/  * 2. Attacker deposits small real collateral:
/*LN-201*/  *    exactlyMarket.deposit(10 ETH)  // ~$20K
/*LN-202*/  *
/*LN-203*/  * Manipulation Phase:
/*LN-204*/  * 3. Attacker calls borrow with mixed market array:
/*LN-205*/  *    address[] markets = [
/*LN-206*/  *        realMarketAddress,      // Shows: 10 ETH collateral, 0 debt
/*LN-207*/  *        maliciousMarketAddress  // Shows: 1M ETH fake collateral, 0 debt
/*LN-208*/  *    ];
/*LN-209*/  *
/*LN-210*/  * 4. DebtPreviewer.previewMultipleMarkets() calculates:
/*LN-211*/  *    totalCollateral = 10 ETH + 1M ETH = 1,000,010 ETH
/*LN-212*/  *    totalDebt = 0
/*LN-213*/  *    healthFactor = infinite
/*LN-214*/  *
/*LN-215*/  * 5. Borrow check passes:
/*LN-216*/  *    maxBorrow = 1,000,010 ETH * 80% = 800,008 ETH
/*LN-217*/  *    Attacker can borrow up to $1.6B worth!
/*LN-218*/  *
/*LN-219*/  * Exploitation Phase:
/*LN-220*/  * 6. Attacker borrows maximum available liquidity:
/*LN-221*/  *    borrow(USDC, 5M USDC)
/*LN-222*/  *    borrow(ETH, 3000 ETH)
/*LN-223*/  *    borrow(DAI, 4M DAI)
/*LN-224*/  *    Total: ~$12M
/*LN-225*/  *
/*LN-226*/  * 7. Attacker transfers borrowed assets out
/*LN-227*/  * 8. Abandons position with $20K collateral left
/*LN-228*/  *
/*LN-229*/  * MITIGATION STRATEGIES:
/*LN-230*/  *
/*LN-231*/  * 1. Whitelist Verified Markets:
/*LN-232*/  *    mapping(address => bool) public approvedMarkets;
/*LN-233*/  *    require(approvedMarkets[market], "Market not approved");
/*LN-234*/  *
/*LN-235*/  * 2. Direct Balance Queries:
/*LN-236*/  *    // Don't trust external previewer
/*LN-237*/  *    // Query markets directly from protocol
/*LN-238*/  *    function getCollateral(address user) internal view returns (uint256) {
/*LN-239*/  *        return deposits[user];
/*LN-240*/  *    }
/*LN-241*/  *
/*LN-242*/  * 3. Oracle Integration:
/*LN-243*/  *    // Use trusted price oracle instead of user-provided data
/*LN-244*/  *    uint256 collateralValue = oracle.getPrice(asset) * deposits[user];
/*LN-245*/  *
/*LN-246*/  * 4. Market Registry:
/*LN-247*/  *    // Maintain on-chain registry of legitimate markets
/*LN-248*/  *    address[] public registeredMarkets;
/*LN-249*/  *    mapping(address => bool) public isRegistered;
/*LN-250*/  *
/*LN-251*/  * 5. Sanity Checks:
/*LN-252*/  *    require(collateralValue < MAX_REASONABLE_VALUE, "Unrealistic collateral");
/*LN-253*/  *    require(healthFactor < 1000 * 1e18, "Suspiciously high");
/*LN-254*/  *
/*LN-255*/  * 6. Rate Limiting:
/*LN-256*/  *    // Limit borrow amount per transaction/timeperiod
/*LN-257*/  *    require(amount <= MAX_SINGLE_BORROW, "Amount too large");
/*LN-258*/  *
/*LN-259*/  * 7. Two-Step Verification:
/*LN-260*/  *    // Cross-verify debt calculations through multiple methods
/*LN-261*/  *    uint256 debt1 = calculateDebtMethod1();
/*LN-262*/  *    uint256 debt2 = calculateDebtMethod2();
/*LN-263*/  *    require(debt1 == debt2, "Debt calculation mismatch");
/*LN-264*/  *
/*LN-265*/  * 8. Isolated Market Queries:
/*LN-266*/  *    // Don't allow batch queries that mix markets
/*LN-267*/  *    // Query each approved market separately within protocol
/*LN-268*/  */
/*LN-269*/ 