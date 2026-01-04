/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * BLUEBERRY PROTOCOL EXPLOIT (February 2024)
/*LN-6*/  * Loss: $1.4 million
/*LN-7*/  * Attack: Price Oracle Manipulation + Liquidation Bypass
/*LN-8*/  *
/*LN-9*/  * Blueberry Protocol is a leveraged yield farming platform. The exploit involved
/*LN-10*/  * manipulating collateral valuation through inflated token prices and then draining
/*LN-11*/  * lending pools by borrowing against the manipulated collateral.
/*LN-12*/  */
/*LN-13*/ 
/*LN-14*/ interface IERC20 {
/*LN-15*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-16*/ 
/*LN-17*/     function transferFrom(
/*LN-18*/         address from,
/*LN-19*/         address to,
/*LN-20*/         uint256 amount
/*LN-21*/     ) external returns (bool);
/*LN-22*/ 
/*LN-23*/     function balanceOf(address account) external view returns (uint256);
/*LN-24*/ 
/*LN-25*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-26*/ }
/*LN-27*/ 
/*LN-28*/ interface IPriceOracle {
/*LN-29*/     function getPrice(address token) external view returns (uint256);
/*LN-30*/ }
/*LN-31*/ 
/*LN-32*/ contract BlueberryLending {
/*LN-33*/     struct Market {
/*LN-34*/         bool isListed;
/*LN-35*/         uint256 collateralFactor;
/*LN-36*/         mapping(address => uint256) accountCollateral;
/*LN-37*/         mapping(address => uint256) accountBorrows;
/*LN-38*/     }
/*LN-39*/ 
/*LN-40*/     mapping(address => Market) public markets;
/*LN-41*/     IPriceOracle public oracle;
/*LN-42*/ 
/*LN-43*/     uint256 public constant COLLATERAL_FACTOR = 75;
/*LN-44*/     uint256 public constant BASIS_POINTS = 100;
/*LN-45*/ 
/*LN-46*/     /**
/*LN-47*/      * @notice Enter markets to use as collateral
/*LN-48*/      */
/*LN-49*/     function enterMarkets(
/*LN-50*/         address[] calldata vTokens
/*LN-51*/     ) external returns (uint256[] memory) {
/*LN-52*/         uint256[] memory results = new uint256[](vTokens.length);
/*LN-53*/         for (uint256 i = 0; i < vTokens.length; i++) {
/*LN-54*/             markets[vTokens[i]].isListed = true;
/*LN-55*/             results[i] = 0;
/*LN-56*/         }
/*LN-57*/         return results;
/*LN-58*/     }
/*LN-59*/ 
/*LN-60*/     /**
/*LN-61*/      * @notice Mint collateral tokens
/*LN-62*/      * @dev VULNERABLE: Relies on manipulable oracle price
/*LN-63*/      */
/*LN-64*/     function mint(address token, uint256 amount) external returns (uint256) {
/*LN-65*/         IERC20(token).transferFrom(msg.sender, address(this), amount);
/*LN-66*/ 
/*LN-67*/         // VULNERABILITY 1: Price from potentially manipulable oracle
/*LN-68*/         uint256 price = oracle.getPrice(token);
/*LN-69*/ 
/*LN-70*/         // VULNERABILITY 2: No validation of price reasonableness
/*LN-71*/         // No checks for dramatic price changes
/*LN-72*/         // No TWAP or external price validation
/*LN-73*/ 
/*LN-74*/         markets[token].accountCollateral[msg.sender] += amount;
/*LN-75*/         return 0;
/*LN-76*/     }
/*LN-77*/ 
/*LN-78*/     /**
/*LN-79*/      * @notice Borrow tokens against collateral
/*LN-80*/      * @dev VULNERABLE: Borrow calculation uses manipulated collateral values
/*LN-81*/      */
/*LN-82*/     function borrow(
/*LN-83*/         address borrowToken,
/*LN-84*/         uint256 borrowAmount
/*LN-85*/     ) external returns (uint256) {
/*LN-86*/         // VULNERABILITY 3: Calculate collateral value using manipulated prices
/*LN-87*/         uint256 totalCollateralValue = 0;
/*LN-88*/ 
/*LN-89*/         // Sum up all collateral value (would iterate through user's collateral)
/*LN-90*/         // Using manipulated oracle prices
/*LN-91*/ 
/*LN-92*/         uint256 borrowPrice = oracle.getPrice(borrowToken);
/*LN-93*/         uint256 borrowValue = (borrowAmount * borrowPrice) / 1e18;
/*LN-94*/ 
/*LN-95*/         uint256 maxBorrowValue = (totalCollateralValue * COLLATERAL_FACTOR) /
/*LN-96*/             BASIS_POINTS;
/*LN-97*/ 
/*LN-98*/         // VULNERABILITY 4: Allows over-borrowing due to inflated collateral values
/*LN-99*/         require(borrowValue <= maxBorrowValue, "Insufficient collateral");
/*LN-100*/ 
/*LN-101*/         markets[borrowToken].accountBorrows[msg.sender] += borrowAmount;
/*LN-102*/         IERC20(borrowToken).transfer(msg.sender, borrowAmount);
/*LN-103*/ 
/*LN-104*/         return 0;
/*LN-105*/     }
/*LN-106*/ 
/*LN-107*/     /**
/*LN-108*/      * @notice Liquidate undercollateralized position
/*LN-109*/      */
/*LN-110*/     function liquidate(
/*LN-111*/         address borrower,
/*LN-112*/         address repayToken,
/*LN-113*/         uint256 repayAmount,
/*LN-114*/         address collateralToken
/*LN-115*/     ) external {
/*LN-116*/         // Liquidation logic (simplified)
/*LN-117*/         // Would check if borrower is undercollateralized
/*LN-118*/         // But vulnerable to same price manipulation issues
/*LN-119*/     }
/*LN-120*/ }
/*LN-121*/ 
/*LN-122*/ contract ManipulableOracle is IPriceOracle {
/*LN-123*/     mapping(address => uint256) public prices;
/*LN-124*/ 
/*LN-125*/     /**
/*LN-126*/      * @notice Get token price
/*LN-127*/      * @dev VULNERABLE: Price can be manipulated via DEX trades
/*LN-128*/      */
/*LN-129*/     function getPrice(address token) external view override returns (uint256) {
/*LN-130*/         // VULNERABILITY 5: Price derived from low-liquidity DEX pools
/*LN-131*/         // Attacker can use flashloans to manipulate DEX price
/*LN-132*/         // Then oracle reads manipulated price
/*LN-133*/         // No circuit breakers or sanity checks
/*LN-134*/ 
/*LN-135*/         return prices[token];
/*LN-136*/     }
/*LN-137*/ 
/*LN-138*/     function setPrice(address token, uint256 price) external {
/*LN-139*/         prices[token] = price;
/*LN-140*/     }
/*LN-141*/ }
/*LN-142*/ 
/*LN-143*/ /**
/*LN-144*/  * EXPLOIT SCENARIO:
/*LN-145*/  *
/*LN-146*/  * 1. Attacker obtains flashloan from Balancer:
/*LN-147*/  *    - Borrows 1000 WETH
/*LN-148*/  *
/*LN-149*/  * 2. Price manipulation phase:
/*LN-150*/  *    - Target low-liquidity token pairs (e.g., OHM/WETH)
/*LN-151*/  *    - Execute large buy of OHM using flashloaned WETH
/*LN-152*/  *    - OHM price artificially inflated on DEX
/*LN-153*/  *
/*LN-154*/  * 3. Oracle reads manipulated price:
/*LN-155*/  *    - Blueberry oracle queries DEX for OHM price
/*LN-156*/  *    - Reports inflated price (e.g., 2-3x normal)
/*LN-157*/  *    - No TWAP or external validation
/*LN-158*/  *
/*LN-159*/  * 4. Deposit collateral at inflated price:
/*LN-160*/  *    - Attacker mints bOHM (Blueberry OHM) tokens
/*LN-161*/  *    - Small amount of OHM now worth much more due to manipulation
/*LN-162*/  *    - Enter markets to use as collateral
/*LN-163*/  *
/*LN-164*/  * 5. Borrow maximum assets:
/*LN-165*/  *    - Borrow WETH, USDC, WBTC against inflated collateral
/*LN-166*/  *    - Can borrow far more than real collateral value
/*LN-167*/  *    - Extract $1.4M worth of assets from lending pools
/*LN-168*/  *
/*LN-169*/  * 6. Price restoration:
/*LN-170*/  *    - Sell OHM back for WETH to restore price
/*LN-171*/  *    - Repay Balancer flashloan
/*LN-172*/  *    - Price returns to normal
/*LN-173*/  *
/*LN-174*/  * 7. Profit extraction:
/*LN-175*/  *    - Keep borrowed assets ($1.4M)
/*LN-176*/  *    - Abandon inflated collateral position
/*LN-177*/  *    - Position now severely undercollateralized but attacker already extracted value
/*LN-178*/  *
/*LN-179*/  * Root Causes:
/*LN-180*/  * - Oracle reliance on manipulable DEX spot prices
/*LN-181*/  * - Insufficient liquidity in pricing DEX pools
/*LN-182*/  * - No Time-Weighted Average Price (TWAP) implementation
/*LN-183*/  * - Missing external price feed validation (Chainlink)
/*LN-184*/  * - No circuit breakers for rapid price movements
/*LN-185*/  * - Lack of price deviation checks between sources
/*LN-186*/  * - Missing borrow limits during volatile periods
/*LN-187*/  * - Insufficient collateral liquidation protection
/*LN-188*/  *
/*LN-189*/  * Fix:
/*LN-190*/  * - Implement TWAP oracles with multi-block averaging
/*LN-191*/  * - Use Chainlink or other external price feeds as primary source
/*LN-192*/  * - Add minimum liquidity requirements for pricing sources
/*LN-193*/  * - Implement circuit breakers for >X% price deviation
/*LN-194*/  * - Add price staleness checks and update frequency limits
/*LN-195*/  * - Require multiple independent price sources with deviation checks
/*LN-196*/  * - Implement gradual collateral factor adjustments
/*LN-197*/  * - Add borrow caps per asset to limit exposure
/*LN-198*/  * - Implement emergency pause for suspicious price movements
/*LN-199*/  * - Add liquidation buffer zones and time delays
/*LN-200*/  */
/*LN-201*/ 