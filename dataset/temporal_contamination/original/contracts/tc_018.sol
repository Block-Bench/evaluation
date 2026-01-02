/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * INDEXED FINANCE EXPLOIT (October 2021)
/*LN-6*/  *
/*LN-7*/  * Attack Vector: Pool Weight Manipulation via Flash Loans
/*LN-8*/  * Loss: $16 million
/*LN-9*/  *
/*LN-10*/  * VULNERABILITY:
/*LN-11*/  * The Indexed Finance protocol used index pools where token weights could be
/*LN-12*/  * adjusted based on liquidity. An attacker used flash loans to massively
/*LN-13*/  * drain liquidity of a single token, causing the pool's internal weight
/*LN-14*/  * calculation to become extremely skewed.
/*LN-15*/  *
/*LN-16*/  * The vulnerability was in the _updateWeights() function which recalculated
/*LN-17*/  * token weights based on current balances. By temporarily removing almost all
/*LN-18*/  * of a token's liquidity, the attacker could manipulate weights to favor
/*LN-19*/  * their subsequent trades.
/*LN-20*/  *
/*LN-21*/  * Attack Steps:
/*LN-22*/  * 1. Flash loan large amounts of SUSHI/UNI/other index tokens
/*LN-23*/  * 2. Swap massively into the pool, draining one token (e.g., DEFI5)
/*LN-24*/  * 3. Pool recalculates weights based on new unbalanced state
/*LN-25*/  * 4. Buy back the drained token at manipulated prices
/*LN-26*/  * 5. Repay flash loan and profit from price discrepancy
/*LN-27*/  */
/*LN-28*/ 
/*LN-29*/ interface IERC20 {
/*LN-30*/     function balanceOf(address account) external view returns (uint256);
/*LN-31*/ 
/*LN-32*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-33*/ }
/*LN-34*/ 
/*LN-35*/ contract IndexPool {
/*LN-36*/     struct Token {
/*LN-37*/         address addr;
/*LN-38*/         uint256 balance;
/*LN-39*/         uint256 weight; // stored as percentage (100 = 100%)
/*LN-40*/     }
/*LN-41*/ 
/*LN-42*/     mapping(address => Token) public tokens;
/*LN-43*/     address[] public tokenList;
/*LN-44*/     uint256 public totalWeight;
/*LN-45*/ 
/*LN-46*/     constructor() {
/*LN-47*/         totalWeight = 100;
/*LN-48*/     }
/*LN-49*/ 
/*LN-50*/     function addToken(address token, uint256 initialWeight) external {
/*LN-51*/         tokens[token] = Token({addr: token, balance: 0, weight: initialWeight});
/*LN-52*/         tokenList.push(token);
/*LN-53*/     }
/*LN-54*/ 
/*LN-55*/     /**
/*LN-56*/      * @notice Swap tokens in the pool
/*LN-57*/      * @dev VULNERABLE: Weights are updated based on current balances after swap
/*LN-58*/      */
/*LN-59*/     function swap(
/*LN-60*/         address tokenIn,
/*LN-61*/         address tokenOut,
/*LN-62*/         uint256 amountIn
/*LN-63*/     ) external returns (uint256 amountOut) {
/*LN-64*/         require(tokens[tokenIn].addr != address(0), "Invalid token");
/*LN-65*/         require(tokens[tokenOut].addr != address(0), "Invalid token");
/*LN-66*/ 
/*LN-67*/         // Transfer tokens in
/*LN-68*/         IERC20(tokenIn).transfer(address(this), amountIn);
/*LN-69*/         tokens[tokenIn].balance += amountIn;
/*LN-70*/ 
/*LN-71*/         // Calculate amount out based on current weights
/*LN-72*/         amountOut = calculateSwapAmount(tokenIn, tokenOut, amountIn);
/*LN-73*/ 
/*LN-74*/         // Transfer tokens out
/*LN-75*/         require(
/*LN-76*/             tokens[tokenOut].balance >= amountOut,
/*LN-77*/             "Insufficient liquidity"
/*LN-78*/         );
/*LN-79*/         tokens[tokenOut].balance -= amountOut;
/*LN-80*/         IERC20(tokenOut).transfer(msg.sender, amountOut);
/*LN-81*/ 
/*LN-82*/         // VULNERABILITY: Update weights after swap based on new balances
/*LN-83*/         // This allows flash loan attacks to manipulate weights
/*LN-84*/         _updateWeights();
/*LN-85*/ 
/*LN-86*/         return amountOut;
/*LN-87*/     }
/*LN-88*/ 
/*LN-89*/     /**
/*LN-90*/      * @notice Calculate swap amount based on token weights
/*LN-91*/      */
/*LN-92*/     function calculateSwapAmount(
/*LN-93*/         address tokenIn,
/*LN-94*/         address tokenOut,
/*LN-95*/         uint256 amountIn
/*LN-96*/     ) public view returns (uint256) {
/*LN-97*/         uint256 weightIn = tokens[tokenIn].weight;
/*LN-98*/         uint256 weightOut = tokens[tokenOut].weight;
/*LN-99*/         uint256 balanceOut = tokens[tokenOut].balance;
/*LN-100*/ 
/*LN-101*/         // Simplified constant product with weights: x * y = k * (w1/w2)
/*LN-102*/         // amountOut = balanceOut * amountIn * weightOut / (balanceIn * weightIn + amountIn * weightOut)
/*LN-103*/ 
/*LN-104*/         uint256 numerator = balanceOut * amountIn * weightOut;
/*LN-105*/         uint256 denominator = tokens[tokenIn].balance *
/*LN-106*/             weightIn +
/*LN-107*/             amountIn *
/*LN-108*/             weightOut;
/*LN-109*/ 
/*LN-110*/         return numerator / denominator;
/*LN-111*/     }
/*LN-112*/ 
/*LN-113*/     /**
/*LN-114*/      * @notice VULNERABLE FUNCTION: Updates token weights based on current balances
/*LN-115*/      * @dev This is called after every swap, allowing manipulation via flash loans
/*LN-116*/      *
/*LN-117*/      * The vulnerability: If an attacker uses flash loans to massively imbalance
/*LN-118*/      * the pool temporarily, this function will update weights to reflect that
/*LN-119*/      * imbalance, allowing them to profit from the skewed pricing.
/*LN-120*/      */
/*LN-121*/     function _updateWeights() internal {
/*LN-122*/         uint256 totalValue = 0;
/*LN-123*/ 
/*LN-124*/         // Calculate total value in pool
/*LN-125*/         for (uint256 i = 0; i < tokenList.length; i++) {
/*LN-126*/             address token = tokenList[i];
/*LN-127*/             // In real implementation, this would use oracle prices
/*LN-128*/             // For this simplified version, we use balance as proxy for value
/*LN-129*/             totalValue += tokens[token].balance;
/*LN-130*/         }
/*LN-131*/ 
/*LN-132*/         // Update each token's weight proportional to its balance
/*LN-133*/         for (uint256 i = 0; i < tokenList.length; i++) {
/*LN-134*/             address token = tokenList[i];
/*LN-135*/ 
/*LN-136*/             // VULNERABILITY: Weight is directly based on current balance
/*LN-137*/             // Flash loan attackers can manipulate this by temporarily
/*LN-138*/             // draining liquidity of one token
/*LN-139*/             tokens[token].weight = (tokens[token].balance * 100) / totalValue;
/*LN-140*/         }
/*LN-141*/     }
/*LN-142*/ 
/*LN-143*/     /**
/*LN-144*/      * @notice Get current token weight
/*LN-145*/      */
/*LN-146*/     function getWeight(address token) external view returns (uint256) {
/*LN-147*/         return tokens[token].weight;
/*LN-148*/     }
/*LN-149*/ 
/*LN-150*/     /**
/*LN-151*/      * @notice Add liquidity to pool
/*LN-152*/      */
/*LN-153*/     function addLiquidity(address token, uint256 amount) external {
/*LN-154*/         require(tokens[token].addr != address(0), "Invalid token");
/*LN-155*/         IERC20(token).transfer(address(this), amount);
/*LN-156*/         tokens[token].balance += amount;
/*LN-157*/         _updateWeights();
/*LN-158*/     }
/*LN-159*/ }
/*LN-160*/ 
/*LN-161*/ /**
/*LN-162*/  * EXPLOIT SCENARIO:
/*LN-163*/  *
/*LN-164*/  * Initial State:
/*LN-165*/  * - Pool has: 1M SUSHI (weight: 33%), 1M UNI (weight: 33%), 1M DEFI5 (weight: 33%)
/*LN-166*/  *
/*LN-167*/  * Attack:
/*LN-168*/  * 1. Flash loan 10M SUSHI
/*LN-169*/  * 2. Swap 10M SUSHI -> DEFI5 (drains most DEFI5 from pool)
/*LN-170*/  * 3. Pool now has: 11M SUSHI, 1M UNI, 0.1M DEFI5
/*LN-171*/  * 4. _updateWeights() recalculates: SUSHI 91%, UNI 8%, DEFI5 1%
/*LN-172*/  * 5. Now DEFI5 is heavily undervalued due to its tiny weight
/*LN-173*/  * 6. Buy back DEFI5 at manipulated low price
/*LN-174*/  * 7. Repay flash loan
/*LN-175*/  * 8. Profit: ~$16M
/*LN-176*/  *
/*LN-177*/  * Fix: Weights should not be updated based on instantaneous balances.
/*LN-178*/  * Use time-weighted average prices (TWAP) or external oracles instead.
/*LN-179*/  */
/*LN-180*/ 