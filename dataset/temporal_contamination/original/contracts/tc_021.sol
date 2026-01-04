/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * INVERSE FINANCE EXPLOIT (April 2022)
/*LN-6*/  *
/*LN-7*/  * Attack Vector: Oracle Price Manipulation via Curve Pool
/*LN-8*/  * Loss: $15.6 million
/*LN-9*/  *
/*LN-10*/  * VULNERABILITY:
/*LN-11*/  * Inverse Finance used a Curve LP token as collateral (anYvCrv3Crypto).
/*LN-12*/  * The oracle for pricing this token relied on Curve pool reserves which
/*LN-13*/  * could be manipulated via flash loans within a single transaction.
/*LN-14*/  *
/*LN-15*/  * By adding massive liquidity to the Curve pool, the attacker inflated
/*LN-16*/  * the LP token price reported by the oracle, then borrowed against the
/*LN-17*/  * overvalued collateral.
/*LN-18*/  *
/*LN-19*/  * Attack Steps:
/*LN-20*/  * 1. Flash loan WBTC from Aave
/*LN-21*/  * 2. Add liquidity to Curve 3crypto pool (USDT/WBTC/WETH)
/*LN-22*/  * 3. Deposit Curve LP tokens to Yearn vault
/*LN-23*/  * 4. Deposit Yearn tokens as collateral in Inverse Finance
/*LN-24*/  * 5. Oracle reads inflated LP token price from manipulated pool
/*LN-25*/  * 6. Borrow maximum DOLA against inflated collateral
/*LN-26*/  * 7. Remove liquidity, repay flash loan
/*LN-27*/  * 8. Keep overborrowed DOLA
/*LN-28*/  */
/*LN-29*/ 
/*LN-30*/ interface IERC20 {
/*LN-31*/     function balanceOf(address account) external view returns (uint256);
/*LN-32*/ 
/*LN-33*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-34*/ 
/*LN-35*/     function transferFrom(
/*LN-36*/         address from,
/*LN-37*/         address to,
/*LN-38*/         uint256 amount
/*LN-39*/     ) external returns (bool);
/*LN-40*/ }
/*LN-41*/ 
/*LN-42*/ interface ICurvePool {
/*LN-43*/     function get_virtual_price() external view returns (uint256);
/*LN-44*/ 
/*LN-45*/     function add_liquidity(
/*LN-46*/         uint256[3] calldata amounts,
/*LN-47*/         uint256 minMintAmount
/*LN-48*/     ) external;
/*LN-49*/ }
/*LN-50*/ 
/*LN-51*/ contract SimplifiedOracle {
/*LN-52*/     ICurvePool public curvePool;
/*LN-53*/ 
/*LN-54*/     constructor(address _curvePool) {
/*LN-55*/         curvePool = ICurvePool(_curvePool);
/*LN-56*/     }
/*LN-57*/ 
/*LN-58*/     /**
/*LN-59*/      * @notice VULNERABLE: Gets price directly from Curve pool
/*LN-60*/      * @dev This price can be manipulated via flash loan attacks
/*LN-61*/      */
/*LN-62*/     function getPrice() external view returns (uint256) {
/*LN-63*/         return curvePool.get_virtual_price();
/*LN-64*/     }
/*LN-65*/ }
/*LN-66*/ 
/*LN-67*/ contract InverseLending {
/*LN-68*/     struct Position {
/*LN-69*/         uint256 collateral;
/*LN-70*/         uint256 borrowed;
/*LN-71*/     }
/*LN-72*/ 
/*LN-73*/     mapping(address => Position) public positions;
/*LN-74*/ 
/*LN-75*/     address public collateralToken;
/*LN-76*/     address public borrowToken;
/*LN-77*/     address public oracle;
/*LN-78*/ 
/*LN-79*/     uint256 public constant COLLATERAL_FACTOR = 80;
/*LN-80*/ 
/*LN-81*/     constructor(
/*LN-82*/         address _collateralToken,
/*LN-83*/         address _borrowToken,
/*LN-84*/         address _oracle
/*LN-85*/     ) {
/*LN-86*/         collateralToken = _collateralToken;
/*LN-87*/         borrowToken = _borrowToken;
/*LN-88*/         oracle = _oracle;
/*LN-89*/     }
/*LN-90*/ 
/*LN-91*/     /**
/*LN-92*/      * @notice Deposit collateral
/*LN-93*/      */
/*LN-94*/     function deposit(uint256 amount) external {
/*LN-95*/         IERC20(collateralToken).transferFrom(msg.sender, address(this), amount);
/*LN-96*/         positions[msg.sender].collateral += amount;
/*LN-97*/     }
/*LN-98*/ 
/*LN-99*/     /**
/*LN-100*/      * @notice VULNERABLE: Borrow against collateral using manipulatable oracle
/*LN-101*/      */
/*LN-102*/     function borrow(uint256 amount) external {
/*LN-103*/         uint256 collateralValue = getCollateralValue(msg.sender);
/*LN-104*/         uint256 maxBorrow = (collateralValue * COLLATERAL_FACTOR) / 100;
/*LN-105*/ 
/*LN-106*/         require(
/*LN-107*/             positions[msg.sender].borrowed + amount <= maxBorrow,
/*LN-108*/             "Insufficient collateral"
/*LN-109*/         );
/*LN-110*/ 
/*LN-111*/         positions[msg.sender].borrowed += amount;
/*LN-112*/         IERC20(borrowToken).transfer(msg.sender, amount);
/*LN-113*/     }
/*LN-114*/ 
/*LN-115*/     /**
/*LN-116*/      * @notice Calculate collateral value using oracle price
/*LN-117*/      * @dev VULNERABLE: Oracle price can be manipulated
/*LN-118*/      */
/*LN-119*/     function getCollateralValue(address user) public view returns (uint256) {
/*LN-120*/         uint256 collateralAmount = positions[user].collateral;
/*LN-121*/         uint256 price = SimplifiedOracle(oracle).getPrice();
/*LN-122*/ 
/*LN-123*/         return (collateralAmount * price) / 1e18;
/*LN-124*/     }
/*LN-125*/ }
/*LN-126*/ 
/*LN-127*/ /**
/*LN-128*/  * EXPLOIT SCENARIO:
/*LN-129*/  *
/*LN-130*/  * Initial State:
/*LN-131*/  * - Curve 3crypto pool: 10M USDT, 500 WBTC, 5000 WETH (balanced)
/*LN-132*/  * - LP token virtual price: $1.00
/*LN-133*/  * - Attacker has 1000 yvCrv3Crypto tokens
/*LN-134*/  *
/*LN-135*/  * Attack:
/*LN-136*/  * 1. Flash loan 2700 WBTC from Aave
/*LN-137*/  *
/*LN-138*/  * 2. Add massive liquidity to Curve pool:
/*LN-139*/  *    - Deposit 2677.5 WBTC and 22,500 USDT
/*LN-140*/  *    - Pool now heavily imbalanced: 3177 WBTC, 10M USDT, 5000 WETH
/*LN-141*/  *
/*LN-142*/  * 3. Curve virtual_price calculation:
/*LN-143*/  *    - virtual_price = D / totalSupply
/*LN-144*/  *    - D (invariant) increases due to added liquidity
/*LN-145*/  *    - virtual_price inflates from $1.00 to ~$1.50
/*LN-146*/  *
/*LN-147*/  * 4. Deposit yvCrv3Crypto as collateral:
/*LN-148*/  *    - Oracle reads inflated virtual_price ($1.50)
/*LN-149*/  *    - 1000 tokens * $1.50 = $1,500 collateral value
/*LN-150*/  *    - True value should be $1,000
/*LN-151*/  *
/*LN-152*/  * 5. Borrow maximum DOLA:
/*LN-153*/  *    - maxBorrow = $1,500 * 80% = $1,200
/*LN-154*/  *    - Should only be able to borrow $800
/*LN-155*/  *    - Overborrowed $400 per 1000 tokens
/*LN-156*/  *
/*LN-157*/  * 6. Swap borrowed DOLA to stablecoins
/*LN-158*/  *
/*LN-159*/  * 7. Remove liquidity from Curve:
/*LN-160*/  *    - Pool rebalances
/*LN-161*/  *    - virtual_price returns to normal
/*LN-162*/  *    - But borrowing already completed!
/*LN-163*/  *
/*LN-164*/  * 8. Repay flash loan
/*LN-165*/  *
/*LN-166*/  * 9. Profit: $15.6M in overborrowed funds
/*LN-167*/  *
/*LN-168*/  * Root Cause:
/*LN-169*/  * - Oracle relied on Curve's get_virtual_price()
/*LN-170*/  * - virtual_price is based on current pool state
/*LN-171*/  * - Adding liquidity inflates the virtual price within one transaction
/*LN-172*/  * - No TWAP or manipulation resistance
/*LN-173*/  *
/*LN-174*/  * Fix:
/*LN-175*/  * - Use time-weighted average oracle prices
/*LN-176*/  * - Implement EMA (Exponential Moving Average) for price feeds
/*LN-177*/  * - Add minimum time delays between price updates
/*LN-178*/  * - Use multiple oracle sources (Chainlink + internal)
/*LN-179*/  * - Implement manipulation-resistant LP token valuation
/*LN-180*/  */
/*LN-181*/ 