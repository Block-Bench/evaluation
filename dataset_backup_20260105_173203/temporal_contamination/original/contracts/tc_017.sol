/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * WARP FINANCE EXPLOIT (December 2020)
/*LN-6*/  *
/*LN-7*/  * Attack Vector: Flash Loan LP Token Price Manipulation
/*LN-8*/  * Loss: $7.7 million
/*LN-9*/  *
/*LN-10*/  * VULNERABILITY:
/*LN-11*/  * Warp Finance allowed users to deposit Uniswap LP tokens as collateral and
/*LN-12*/  * borrow stablecoins. The vulnerability was in how the protocol calculated
/*LN-13*/  * the value of LP tokens - it used the current reserve balances directly
/*LN-14*/  * without any protection against flash loan manipulation.
/*LN-15*/  *
/*LN-16*/  * By using flash loans to massively imbalance a Uniswap pool, the attacker
/*LN-17*/  * could inflate the calculated value of their LP tokens, allowing them to
/*LN-18*/  * borrow more than the true value of their collateral.
/*LN-19*/  *
/*LN-20*/  * Attack Steps:
/*LN-21*/  * 1. Flash loan large amounts of DAI
/*LN-22*/  * 2. Swap DAI for ETH in Uniswap pool, heavily imbalancing it
/*LN-23*/  * 3. LP token price calculation now shows inflated ETH value
/*LN-24*/  * 4. Deposit LP tokens as collateral (now overvalued)
/*LN-25*/  * 5. Borrow maximum DAI based on inflated collateral value
/*LN-26*/  * 6. Swap back to rebalance pool
/*LN-27*/  * 7. Repay flash loan
/*LN-28*/  * 8. Profit from overborrowing
/*LN-29*/  */
/*LN-30*/ 
/*LN-31*/ interface IUniswapV2Pair {
/*LN-32*/     function getReserves()
/*LN-33*/         external
/*LN-34*/         view
/*LN-35*/         returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
/*LN-36*/ 
/*LN-37*/     function totalSupply() external view returns (uint256);
/*LN-38*/ }
/*LN-39*/ 
/*LN-40*/ interface IERC20 {
/*LN-41*/     function balanceOf(address account) external view returns (uint256);
/*LN-42*/ 
/*LN-43*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-44*/ 
/*LN-45*/     function transferFrom(
/*LN-46*/         address from,
/*LN-47*/         address to,
/*LN-48*/         uint256 amount
/*LN-49*/     ) external returns (bool);
/*LN-50*/ }
/*LN-51*/ 
/*LN-52*/ contract WarpVault {
/*LN-53*/     struct Position {
/*LN-54*/         uint256 lpTokenAmount;
/*LN-55*/         uint256 borrowed;
/*LN-56*/     }
/*LN-57*/ 
/*LN-58*/     mapping(address => Position) public positions;
/*LN-59*/ 
/*LN-60*/     address public lpToken;
/*LN-61*/     address public stablecoin;
/*LN-62*/     uint256 public constant COLLATERAL_RATIO = 150; // 150% collateralization
/*LN-63*/ 
/*LN-64*/     constructor(address _lpToken, address _stablecoin) {
/*LN-65*/         lpToken = _lpToken;
/*LN-66*/         stablecoin = _stablecoin;
/*LN-67*/     }
/*LN-68*/ 
/*LN-69*/     /**
/*LN-70*/      * @notice Deposit LP tokens as collateral
/*LN-71*/      */
/*LN-72*/     function deposit(uint256 amount) external {
/*LN-73*/         IERC20(lpToken).transferFrom(msg.sender, address(this), amount);
/*LN-74*/         positions[msg.sender].lpTokenAmount += amount;
/*LN-75*/     }
/*LN-76*/ 
/*LN-77*/     /**
/*LN-78*/      * @notice Borrow stablecoins against LP token collateral
/*LN-79*/      * @dev VULNERABLE: Uses current LP token value which can be manipulated
/*LN-80*/      */
/*LN-81*/     function borrow(uint256 amount) external {
/*LN-82*/         uint256 collateralValue = getLPTokenValue(
/*LN-83*/             positions[msg.sender].lpTokenAmount
/*LN-84*/         );
/*LN-85*/         uint256 maxBorrow = (collateralValue * 100) / COLLATERAL_RATIO;
/*LN-86*/ 
/*LN-87*/         require(
/*LN-88*/             positions[msg.sender].borrowed + amount <= maxBorrow,
/*LN-89*/             "Insufficient collateral"
/*LN-90*/         );
/*LN-91*/ 
/*LN-92*/         positions[msg.sender].borrowed += amount;
/*LN-93*/         IERC20(stablecoin).transfer(msg.sender, amount);
/*LN-94*/     }
/*LN-95*/ 
/*LN-96*/     /**
/*LN-97*/      * @notice VULNERABLE FUNCTION: Calculate LP token value
/*LN-98*/      * @dev Uses instantaneous reserve values, vulnerable to flash loan manipulation
/*LN-99*/      *
/*LN-100*/      * The vulnerability: LP token value is calculated as:
/*LN-101*/      * value = (reserve0 * price0 + reserve1 * price1) * lpAmount / totalSupply
/*LN-102*/      *
/*LN-103*/      * If an attacker uses flash loans to manipulate reserve0 and reserve1,
/*LN-104*/      * they can inflate the calculated value of their LP tokens.
/*LN-105*/      */
/*LN-106*/     function getLPTokenValue(uint256 lpAmount) public view returns (uint256) {
/*LN-107*/         if (lpAmount == 0) return 0;
/*LN-108*/ 
/*LN-109*/         IUniswapV2Pair pair = IUniswapV2Pair(lpToken);
/*LN-110*/ 
/*LN-111*/         // Get current reserves - VULNERABLE to flash loan manipulation
/*LN-112*/         (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
/*LN-113*/         uint256 totalSupply = pair.totalSupply();
/*LN-114*/ 
/*LN-115*/         // Calculate share of reserves owned by these LP tokens
/*LN-116*/         // This assumes reserves are fairly priced, but flash loans can manipulate this
/*LN-117*/         uint256 amount0 = (uint256(reserve0) * lpAmount) / totalSupply;
/*LN-118*/         uint256 amount1 = (uint256(reserve1) * lpAmount) / totalSupply;
/*LN-119*/ 
/*LN-120*/         // For simplicity, assume token0 is stablecoin ($1) and token1 is ETH
/*LN-121*/         // In reality, would need oracle for ETH price
/*LN-122*/         // VULNERABILITY: Using current reserves directly without TWAP or oracle
/*LN-123*/         uint256 value0 = amount0; // amount0 is stablecoin, worth face value
/*LN-124*/ 
/*LN-125*/         // This simplified version just adds both reserves
/*LN-126*/         // Real exploit would use inflated ETH reserves
/*LN-127*/         uint256 totalValue = amount0 + amount1;
/*LN-128*/ 
/*LN-129*/         return totalValue;
/*LN-130*/     }
/*LN-131*/ 
/*LN-132*/     /**
/*LN-133*/      * @notice Repay borrowed amount
/*LN-134*/      */
/*LN-135*/     function repay(uint256 amount) external {
/*LN-136*/         require(positions[msg.sender].borrowed >= amount, "Repay exceeds debt");
/*LN-137*/ 
/*LN-138*/         IERC20(stablecoin).transferFrom(msg.sender, address(this), amount);
/*LN-139*/         positions[msg.sender].borrowed -= amount;
/*LN-140*/     }
/*LN-141*/ 
/*LN-142*/     /**
/*LN-143*/      * @notice Withdraw LP tokens
/*LN-144*/      */
/*LN-145*/     function withdraw(uint256 amount) external {
/*LN-146*/         require(
/*LN-147*/             positions[msg.sender].lpTokenAmount >= amount,
/*LN-148*/             "Insufficient balance"
/*LN-149*/         );
/*LN-150*/ 
/*LN-151*/         // Check that position remains healthy after withdrawal
/*LN-152*/         uint256 remainingLP = positions[msg.sender].lpTokenAmount - amount;
/*LN-153*/         uint256 remainingValue = getLPTokenValue(remainingLP);
/*LN-154*/         uint256 maxBorrow = (remainingValue * 100) / COLLATERAL_RATIO;
/*LN-155*/ 
/*LN-156*/         require(
/*LN-157*/             positions[msg.sender].borrowed <= maxBorrow,
/*LN-158*/             "Withdrawal would liquidate position"
/*LN-159*/         );
/*LN-160*/ 
/*LN-161*/         positions[msg.sender].lpTokenAmount -= amount;
/*LN-162*/         IERC20(lpToken).transfer(msg.sender, amount);
/*LN-163*/     }
/*LN-164*/ }
/*LN-165*/ 
/*LN-166*/ /**
/*LN-167*/  * EXPLOIT SCENARIO:
/*LN-168*/  *
/*LN-169*/  * Initial State:
/*LN-170*/  * - Uniswap DAI/ETH pool: 1M DAI, 500 ETH (ETH price = $2000)
/*LN-171*/  * - LP tokens represent balanced liquidity
/*LN-172*/  * - Attacker holds some LP tokens
/*LN-173*/  *
/*LN-174*/  * Attack:
/*LN-175*/  * 1. Flash loan 5M DAI from dYdX/Aave
/*LN-176*/  *
/*LN-177*/  * 2. Swap 5M DAI -> ETH in Uniswap pool
/*LN-178*/  *    - Pool becomes: 6M DAI, 100 ETH (heavily imbalanced)
/*LN-179*/  *    - Constant product maintained but prices skewed
/*LN-180*/  *
/*LN-181*/  * 3. LP token value calculation now sees:
/*LN-182*/  *    - reserve0 (DAI): 6M
/*LN-183*/  *    - reserve1 (ETH): 100 (but each LP token's share looks valuable due to high DAI reserve)
/*LN-184*/  *    - Due to calculation method, LP tokens appear more valuable
/*LN-185*/  *
/*LN-186*/  * 4. Deposit LP tokens to Warp Finance
/*LN-187*/  *    - getLPTokenValue() returns inflated value due to manipulated reserves
/*LN-188*/  *
/*LN-189*/  * 5. Borrow maximum stablecoins based on inflated collateral value
/*LN-190*/  *    - Can borrow ~2-3x more than LP tokens are truly worth
/*LN-191*/  *
/*LN-192*/  * 6. Swap ETH back to DAI to rebalance pool
/*LN-193*/  *
/*LN-194*/  * 7. Repay flash loan
/*LN-195*/  *
/*LN-196*/  * 8. Keep overborrowed funds
/*LN-197*/  *    - Profit: $7.7M
/*LN-198*/  *    - Warp Finance left with undercollateralized debt
/*LN-199*/  *
/*LN-200*/  * Root Cause:
/*LN-201*/  * - Using instantaneous reserve values to calculate LP token worth
/*LN-202*/  * - No protection against within-block price manipulation
/*LN-203*/  * - No use of TWAP (Time-Weighted Average Price)
/*LN-204*/  *
/*LN-205*/  * Fix:
/*LN-206*/  * - Use Uniswap TWAP oracle for price feeds
/*LN-207*/  * - Don't calculate LP token value from instantaneous reserves
/*LN-208*/  * - Use external price oracles (Chainlink, etc.)
/*LN-209*/  * - Implement manipulation-resistant LP valuation (e.g., Alpha Homora's formula)
/*LN-210*/  */
/*LN-211*/ 