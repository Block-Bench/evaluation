/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * UWU LEND EXPLOIT (June 2024)
/*LN-6*/  * Loss: $19.3 million
/*LN-7*/  * Attack: Oracle Price Manipulation via Curve Pool Manipulation
/*LN-8*/  *
/*LN-9*/  * UwU Lend is an Aave V2 fork lending protocol. The exploit involved manipulating
/*LN-10*/  * the price oracle for sUSDE (staked USDe) by draining liquidity from Curve pools,
/*LN-11*/  * causing the oracle to report incorrect prices, then borrowing against inflated collateral.
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
/*LN-28*/ interface IAaveOracle {
/*LN-29*/     function getAssetPrice(address asset) external view returns (uint256);
/*LN-30*/ 
/*LN-31*/     function setAssetSources(
/*LN-32*/         address[] calldata assets,
/*LN-33*/         address[] calldata sources
/*LN-34*/     ) external;
/*LN-35*/ }
/*LN-36*/ 
/*LN-37*/ interface ICurvePool {
/*LN-38*/     function exchange(
/*LN-39*/         int128 i,
/*LN-40*/         int128 j,
/*LN-41*/         uint256 dx,
/*LN-42*/         uint256 min_dy
/*LN-43*/     ) external returns (uint256);
/*LN-44*/ 
/*LN-45*/     function get_dy(
/*LN-46*/         int128 i,
/*LN-47*/         int128 j,
/*LN-48*/         uint256 dx
/*LN-49*/     ) external view returns (uint256);
/*LN-50*/ 
/*LN-51*/     function balances(uint256 i) external view returns (uint256);
/*LN-52*/ }
/*LN-53*/ 
/*LN-54*/ interface ILendingPool {
/*LN-55*/     function deposit(
/*LN-56*/         address asset,
/*LN-57*/         uint256 amount,
/*LN-58*/         address onBehalfOf,
/*LN-59*/         uint16 referralCode
/*LN-60*/     ) external;
/*LN-61*/ 
/*LN-62*/     function borrow(
/*LN-63*/         address asset,
/*LN-64*/         uint256 amount,
/*LN-65*/         uint256 interestRateMode,
/*LN-66*/         uint16 referralCode,
/*LN-67*/         address onBehalfOf
/*LN-68*/     ) external;
/*LN-69*/ 
/*LN-70*/     function withdraw(
/*LN-71*/         address asset,
/*LN-72*/         uint256 amount,
/*LN-73*/         address to
/*LN-74*/     ) external returns (uint256);
/*LN-75*/ }
/*LN-76*/ 
/*LN-77*/ contract UwuLendingPool is ILendingPool {
/*LN-78*/     IAaveOracle public oracle;
/*LN-79*/     mapping(address => uint256) public deposits;
/*LN-80*/     mapping(address => uint256) public borrows;
/*LN-81*/     uint256 public constant LTV = 8500;
/*LN-82*/     uint256 public constant BASIS_POINTS = 10000;
/*LN-83*/ 
/*LN-84*/     /**
/*LN-85*/      * @notice Deposit collateral into pool
/*LN-86*/      */
/*LN-87*/     function deposit(
/*LN-88*/         address asset,
/*LN-89*/         uint256 amount,
/*LN-90*/         address onBehalfOf,
/*LN-91*/         uint16 referralCode
/*LN-92*/     ) external override {
/*LN-93*/         IERC20(asset).transferFrom(msg.sender, address(this), amount);
/*LN-94*/         deposits[onBehalfOf] += amount;
/*LN-95*/     }
/*LN-96*/ 
/*LN-97*/     /**
/*LN-98*/      * @notice Borrow assets from pool
/*LN-99*/      * @dev VULNERABLE: Uses manipulable oracle price
/*LN-100*/      */
/*LN-101*/     function borrow(
/*LN-102*/         address asset,
/*LN-103*/         uint256 amount,
/*LN-104*/         uint256 interestRateMode,
/*LN-105*/         uint16 referralCode,
/*LN-106*/         address onBehalfOf
/*LN-107*/     ) external override {
/*LN-108*/         // VULNERABILITY 1: Oracle price can be manipulated via Curve pool drainage
/*LN-109*/         uint256 collateralPrice = oracle.getAssetPrice(msg.sender);
/*LN-110*/         uint256 borrowPrice = oracle.getAssetPrice(asset);
/*LN-111*/ 
/*LN-112*/         // VULNERABILITY 2: No price freshness check
/*LN-113*/         // No validation if price has changed dramatically
/*LN-114*/         // No circuit breaker for unusual price movements
/*LN-115*/ 
/*LN-116*/         uint256 collateralValue = (deposits[msg.sender] * collateralPrice) /
/*LN-117*/             1e18;
/*LN-118*/         uint256 maxBorrow = (collateralValue * LTV) / BASIS_POINTS;
/*LN-119*/ 
/*LN-120*/         uint256 borrowValue = (amount * borrowPrice) / 1e18;
/*LN-121*/ 
/*LN-122*/         // VULNERABILITY 3: Health factor calculated with manipulated price
/*LN-123*/         require(borrowValue <= maxBorrow, "Insufficient collateral");
/*LN-124*/ 
/*LN-125*/         borrows[msg.sender] += amount;
/*LN-126*/         IERC20(asset).transfer(onBehalfOf, amount);
/*LN-127*/     }
/*LN-128*/ 
/*LN-129*/     /**
/*LN-130*/      * @notice Withdraw collateral
/*LN-131*/      */
/*LN-132*/     function withdraw(
/*LN-133*/         address asset,
/*LN-134*/         uint256 amount,
/*LN-135*/         address to
/*LN-136*/     ) external override returns (uint256) {
/*LN-137*/         require(deposits[msg.sender] >= amount, "Insufficient balance");
/*LN-138*/         deposits[msg.sender] -= amount;
/*LN-139*/         IERC20(asset).transfer(to, amount);
/*LN-140*/         return amount;
/*LN-141*/     }
/*LN-142*/ }
/*LN-143*/ 
/*LN-144*/ contract CurveOracle {
/*LN-145*/     ICurvePool public curvePool;
/*LN-146*/ 
/*LN-147*/     constructor(address _pool) {
/*LN-148*/         curvePool = _pool;
/*LN-149*/     }
/*LN-150*/ 
/*LN-151*/     /**
/*LN-152*/      * @notice Get asset price from Curve pool
/*LN-153*/      * @dev VULNERABLE: Price derived from manipulable Curve pool
/*LN-154*/      */
/*LN-155*/     function getAssetPrice(address asset) external view returns (uint256) {
/*LN-156*/         // VULNERABILITY 4: Price based on Curve pool state
/*LN-157*/         // Attacker can drain pool to manipulate price
/*LN-158*/         // No TWAP (Time-Weighted Average Price)
/*LN-159*/         // No external price validation
/*LN-160*/ 
/*LN-161*/         uint256 balance0 = curvePool.balances(0);
/*LN-162*/         uint256 balance1 = curvePool.balances(1);
/*LN-163*/ 
/*LN-164*/         // VULNERABILITY 5: Spot price calculation
/*LN-165*/         // Easily manipulated by large swaps or liquidity removal
/*LN-166*/         uint256 price = (balance1 * 1e18) / balance0;
/*LN-167*/ 
/*LN-168*/         return price;
/*LN-169*/     }
/*LN-170*/ }
/*LN-171*/ 
/*LN-172*/ /**
/*LN-173*/  * EXPLOIT SCENARIO:
/*LN-174*/  *
/*LN-175*/  * 1. Attacker obtains massive flashloans:
/*LN-176*/  *    - Borrows from Aave V3, Balancer, Spark, MorphoBlue, MakerDAO
/*LN-177*/  *    - Total: Billions in stablecoins and ETH
/*LN-178*/  *
/*LN-179*/  * 2. Price manipulation phase - drain Curve pools:
/*LN-180*/  *    - Target: sUSDE/USDe, USDe/DAI, USDe/crvUSD pools
/*LN-181*/  *    - Execute large swaps to remove USDe liquidity
/*LN-182*/  *    - Imbalance the pools to inflate sUSDE price
/*LN-183*/  *
/*LN-184*/  * 3. Oracle reports manipulated price:
/*LN-185*/  *    - UwU Lend oracle reads from manipulated Curve pools
/*LN-186*/  *    - sUSDE price artificially inflated (e.g., 2x real value)
/*LN-187*/  *    - No TWAP or external validation to detect manipulation
/*LN-188*/  *
/*LN-189*/  * 4. Deposit collateral into UwU Lend:
/*LN-190*/  *    - Deposit sUSDE at inflated price
/*LN-191*/  *    - Collateral appears worth 2x real value
/*LN-192*/  *    - Health factor calculated with manipulated price
/*LN-193*/  *
/*LN-194*/  * 5. Borrow maximum assets:
/*LN-195*/  *    - Borrow WETH, DAI, USDC, WBTC at 85% LTV
/*LN-196*/  *    - Can borrow 1.7x actual collateral value due to manipulation
/*LN-197*/  *    - Extract $19.3M worth of assets
/*LN-198*/  *
/*LN-199*/  * 6. Price restoration:
/*LN-200*/  *    - Reverse swaps in Curve pools
/*LN-201*/  *    - Price returns to normal
/*LN-202*/  *    - Attacker's position now undercollateralized
/*LN-203*/  *
/*LN-204*/  * 7. Profit extraction:
/*LN-205*/  *    - Keep borrowed assets ($19.3M)
/*LN-206*/  *    - Abandon collateral position
/*LN-207*/  *    - Repay flashloans with profits
/*LN-208*/  *
/*LN-209*/  * Root Causes:
/*LN-210*/  * - Oracle reliance on manipulable Curve pool prices
/*LN-211*/  * - No Time-Weighted Average Price (TWAP) implementation
/*LN-212*/  * - Lack of external price feed validation (Chainlink, etc.)
/*LN-213*/  * - No circuit breakers for dramatic price movements
/*LN-214*/  * - Insufficient liquidity in Curve pools for price stability
/*LN-215*/  * - No borrow caps or limits during volatile periods
/*LN-216*/  * - Missing price deviation checks between sources
/*LN-217*/  *
/*LN-218*/  * Fix:
/*LN-219*/  * - Implement TWAP oracles (multi-block price averaging)
/*LN-220*/  * - Use Chainlink or other external price feeds as primary source
/*LN-221*/  * - Add deviation checks between multiple price sources
/*LN-222*/  * - Implement circuit breakers for >X% price movement
/*LN-223*/  * - Add borrow caps that limit exposure during volatility
/*LN-224*/  * - Require minimum liquidity depth in pricing pools
/*LN-225*/  * - Implement gradual price updates, not instant spot prices
/*LN-226*/  * - Add emergency pause functionality for suspicious activity
/*LN-227*/  */
/*LN-228*/ 