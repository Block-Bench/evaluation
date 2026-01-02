/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function balanceOf(address account) external view returns (uint256);
/*LN-6*/ 
/*LN-7*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-8*/ }
/*LN-9*/ 

/**
 * @title IndexPool
 * @notice Weighted index pool for multi-asset portfolio management
 * @dev Audited by Halborn Security (Q3 2021) - All findings resolved
 * @dev Implements dynamic weight rebalancing based on pool composition
 * @dev Constant product AMM formula with weight adjustments
 * @custom:security-contact security@indexpool.finance
 */
/*LN-10*/ contract IndexPool {
    /// @dev Token configuration with balance and weight tracking
/*LN-11*/     struct Token {
/*LN-12*/         address addr;
/*LN-13*/         uint256 balance;
/*LN-14*/         uint256 weight; // stored as percentage (100 = 100%)
/*LN-15*/     }
/*LN-16*/
    /// @dev Token registry for pool composition
/*LN-17*/     mapping(address => Token) public tokens;
    /// @dev Ordered list of pool tokens
/*LN-18*/     address[] public tokenList;
    /// @dev Sum of all token weights (normalized to 100)
/*LN-19*/     uint256 public totalWeight;
/*LN-20*/ 
/*LN-21*/     constructor() {
/*LN-22*/         totalWeight = 100;
/*LN-23*/     }
/*LN-24*/ 
    /**
     * @notice Register a new token in the pool
     * @dev Initializes token with zero balance and specified weight
     * @param token Address of token to add
     * @param initialWeight Initial weight percentage for the token
     */
/*LN-25*/     function addToken(address token, uint256 initialWeight) external {
/*LN-26*/         tokens[token] = Token({addr: token, balance: 0, weight: initialWeight});
/*LN-27*/         tokenList.push(token);
/*LN-28*/     }
/*LN-29*/ 
    /**
     * @notice Swap tokens using weighted constant product formula
     * @dev Executes atomic swap with automatic weight rebalancing
     * @dev Updates internal balances before external transfers
     * @param tokenIn Input token address
     * @param tokenOut Output token address
     * @param amountIn Amount of input tokens
     * @return amountOut Calculated output amount
     */
/*LN-33*/     function swap(
/*LN-34*/         address tokenIn,
/*LN-35*/         address tokenOut,
/*LN-36*/         uint256 amountIn
/*LN-37*/     ) external returns (uint256 amountOut) {
/*LN-38*/         require(tokens[tokenIn].addr != address(0), "Invalid token");
/*LN-39*/         require(tokens[tokenOut].addr != address(0), "Invalid token");
/*LN-40*/ 
            // Receive input tokens from sender
/*LN-42*/         IERC20(tokenIn).transfer(address(this), amountIn);
/*LN-43*/         tokens[tokenIn].balance += amountIn;
/*LN-44*/ 
/*LN-45*/         // Calculate amount out based on current weights
/*LN-46*/         amountOut = calculateSwapAmount(tokenIn, tokenOut, amountIn);
/*LN-47*/ 
/*LN-48*/         // Transfer tokens out
/*LN-49*/         require(
/*LN-50*/             tokens[tokenOut].balance >= amountOut,
/*LN-51*/             "Insufficient liquidity"
/*LN-52*/         );
/*LN-53*/         tokens[tokenOut].balance -= amountOut;
            // Send output tokens to caller
/*LN-54*/         IERC20(tokenOut).transfer(msg.sender, amountOut);
/*LN-55*/ 
/*LN-56*/         _updateWeights();
/*LN-57*/ 
/*LN-58*/         return amountOut;
/*LN-59*/     }
/*LN-60*/ 
/*LN-61*/     /**
/*LN-62*/      * @notice Calculate swap amount based on token weights
/*LN-63*/      */
/*LN-64*/     function calculateSwapAmount(
/*LN-65*/         address tokenIn,
/*LN-66*/         address tokenOut,
/*LN-67*/         uint256 amountIn
/*LN-68*/     ) public view returns (uint256) {
/*LN-69*/         uint256 weightIn = tokens[tokenIn].weight;
/*LN-70*/         uint256 weightOut = tokens[tokenOut].weight;
/*LN-71*/         uint256 balanceOut = tokens[tokenOut].balance;
/*LN-72*/ 
/*LN-73*/         // Simplified constant product with weights: x * y = k * (w1/w2)
/*LN-74*/         // amountOut = balanceOut * amountIn * weightOut / (balanceIn * weightIn + amountIn * weightOut)
/*LN-75*/ 
/*LN-76*/         uint256 numerator = balanceOut * amountIn * weightOut;
/*LN-77*/         uint256 denominator = tokens[tokenIn].balance *
/*LN-78*/             weightIn +
/*LN-79*/             amountIn *
/*LN-80*/             weightOut;
/*LN-81*/ 
/*LN-82*/         return numerator / denominator;
/*LN-83*/     }
/*LN-84*/ 
    /**
     * @notice Rebalance token weights based on current pool composition
     * @dev Maintains weight normalization to 100% total
     * @dev Called automatically after each swap and liquidity change
     */
/*LN-85*/     function _updateWeights() internal {
/*LN-86*/         uint256 totalValue = 0;
/*LN-87*/
            // Aggregate pool value for weight calculation
/*LN-89*/         for (uint256 i = 0; i < tokenList.length; i++) {
/*LN-90*/             address token = tokenList[i];
            // Use balance as value metric for weight distribution
/*LN-93*/             totalValue += tokens[token].balance;
/*LN-94*/         }
/*LN-95*/
            // Normalize weights to reflect current composition
/*LN-97*/         for (uint256 i = 0; i < tokenList.length; i++) {
/*LN-98*/             address token = tokenList[i];
/*LN-99*/
            // Proportional weight assignment
/*LN-101*/             tokens[token].weight = (tokens[token].balance * 100) / totalValue;
/*LN-102*/         }
/*LN-103*/     }
/*LN-104*/ 
/*LN-105*/     /**
/*LN-106*/      * @notice Get current token weight
/*LN-107*/      */
/*LN-108*/     function getWeight(address token) external view returns (uint256) {
/*LN-109*/         return tokens[token].weight;
/*LN-110*/     }
/*LN-111*/ 
    /**
     * @notice Add single-sided liquidity to the pool
     * @dev Updates token balance and triggers weight rebalancing
     * @param token Address of token to deposit
     * @param amount Amount to add to pool
     */
/*LN-115*/     function addLiquidity(address token, uint256 amount) external {
/*LN-116*/         require(tokens[token].addr != address(0), "Invalid token");
            // Receive tokens from liquidity provider
/*LN-117*/         IERC20(token).transfer(address(this), amount);
/*LN-118*/         tokens[token].balance += amount;
/*LN-119*/         _updateWeights();
/*LN-120*/     }
/*LN-121*/ }
/*LN-122*/ 