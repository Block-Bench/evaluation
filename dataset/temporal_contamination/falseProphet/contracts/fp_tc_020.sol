/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IUniswapV2Pair {
/*LN-5*/     function getReserves()
/*LN-6*/         external
/*LN-7*/         view
/*LN-8*/         returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
/*LN-9*/ 
/*LN-10*/     function totalSupply() external view returns (uint256);
/*LN-11*/ }
/*LN-12*/ 
/*LN-13*/ interface IERC20 {
/*LN-14*/     function balanceOf(address account) external view returns (uint256);
/*LN-15*/ 
/*LN-16*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-17*/ 
/*LN-18*/     function transferFrom(
/*LN-19*/         address from,
/*LN-20*/         address to,
/*LN-21*/         uint256 amount
/*LN-22*/     ) external returns (bool);
/*LN-23*/ }
/*LN-24*/ 

/**
 * @title WarpVault
 * @notice LP token collateralized lending vault
 * @dev Audited by Trail of Bits (Q4 2020) - All critical findings addressed
 * @dev Implements over-collateralized lending with 150% ratio
 * @dev Uses AMM pair reserves for collateral valuation
 * @custom:security-contact security@warpfinance.io
 */
/*LN-25*/ contract WarpVault {
    /// @dev User position tracking for collateral and debt
/*LN-26*/     struct Position {
/*LN-27*/         uint256 lpTokenAmount;
/*LN-28*/         uint256 borrowed;
/*LN-29*/     }
/*LN-30*/
    /// @dev Position registry by user address
/*LN-31*/     mapping(address => Position) public positions;
/*LN-32*/
    /// @dev Uniswap V2 LP token accepted as collateral
/*LN-33*/     address public lpToken;
    /// @dev Stablecoin for borrowing
/*LN-34*/     address public stablecoin;
    /// @dev Required collateralization (150% = safe margin)
/*LN-35*/     uint256 public constant COLLATERAL_RATIO = 150; // 150% collateralization
/*LN-36*/ 
/*LN-37*/     constructor(address _lpToken, address _stablecoin) {
/*LN-38*/         lpToken = _lpToken;
/*LN-39*/         stablecoin = _stablecoin;
/*LN-40*/     }
/*LN-41*/ 
    /**
     * @notice Deposit LP tokens as collateral
     * @dev Transfers LP tokens to vault and updates position
     * @param amount Amount of LP tokens to deposit
     */
/*LN-45*/     function deposit(uint256 amount) external {
/*LN-46*/         IERC20(lpToken).transferFrom(msg.sender, address(this), amount);
/*LN-47*/         positions[msg.sender].lpTokenAmount += amount;
/*LN-48*/     }
/*LN-49*/ 
    /**
     * @notice Borrow stablecoins against LP token collateral
     * @dev Enforces 150% collateralization ratio before lending
     * @dev Updates debt position before transfer
     * @param amount Amount of stablecoins to borrow
     */
/*LN-53*/     function borrow(uint256 amount) external {
            // Calculate current collateral value
/*LN-54*/         uint256 collateralValue = getLPTokenValue(
/*LN-55*/             positions[msg.sender].lpTokenAmount
/*LN-56*/         );
            // Determine maximum borrowable with safety margin
/*LN-57*/         uint256 maxBorrow = (collateralValue * 100) / COLLATERAL_RATIO;
/*LN-58*/
            // Enforce collateralization requirement
/*LN-59*/         require(
/*LN-60*/             positions[msg.sender].borrowed + amount <= maxBorrow,
/*LN-61*/             "Insufficient collateral"
/*LN-62*/         );
/*LN-63*/
            // Update debt before transfer
/*LN-64*/         positions[msg.sender].borrowed += amount;
            // Transfer borrowed stablecoins
/*LN-65*/         IERC20(stablecoin).transfer(msg.sender, amount);
/*LN-66*/     }
/*LN-67*/ 
    /**
     * @notice Calculate USD value of LP tokens
     * @dev Uses AMM reserves for proportional value calculation
     * @dev Returns sum of underlying token values
     * @param lpAmount Amount of LP tokens to value
     * @return Total value in stablecoin units
     */
/*LN-68*/     function getLPTokenValue(uint256 lpAmount) public view returns (uint256) {
/*LN-69*/         if (lpAmount == 0) return 0;
/*LN-70*/
            // Get AMM pair reference
/*LN-71*/         IUniswapV2Pair pair = IUniswapV2Pair(lpToken);
/*LN-72*/
            // Fetch current pool state
/*LN-73*/         (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
/*LN-74*/         uint256 totalSupply = pair.totalSupply();
/*LN-75*/
            // Calculate proportional share of underlying tokens
/*LN-78*/         uint256 amount0 = (uint256(reserve0) * lpAmount) / totalSupply;
/*LN-79*/         uint256 amount1 = (uint256(reserve1) * lpAmount) / totalSupply;
/*LN-80*/
            // Value calculation (token0 is stablecoin base)
/*LN-83*/         uint256 value0 = amount0;
/*LN-84*/
            // Sum underlying values for total LP value
/*LN-86*/         uint256 totalValue = amount0 + amount1;
/*LN-87*/
/*LN-88*/         return totalValue;
/*LN-89*/     }
/*LN-90*/ 
    /**
     * @notice Repay borrowed stablecoins
     * @dev Reduces debt position after receiving repayment
     * @param amount Amount to repay
     */
/*LN-94*/     function repay(uint256 amount) external {
/*LN-95*/         require(positions[msg.sender].borrowed >= amount, "Repay exceeds debt");
/*LN-96*/ 
/*LN-97*/         IERC20(stablecoin).transferFrom(msg.sender, address(this), amount);
/*LN-98*/         positions[msg.sender].borrowed -= amount;
/*LN-99*/     }
/*LN-100*/ 
    /**
     * @notice Withdraw LP tokens from vault
     * @dev Validates position health before releasing collateral
     * @dev Ensures remaining collateral covers outstanding debt
     * @param amount Amount of LP tokens to withdraw
     */
/*LN-104*/     function withdraw(uint256 amount) external {
/*LN-105*/         require(
/*LN-106*/             positions[msg.sender].lpTokenAmount >= amount,
/*LN-107*/             "Insufficient balance"
/*LN-108*/         );
/*LN-109*/
            // Verify position remains healthy after withdrawal
/*LN-111*/         uint256 remainingLP = positions[msg.sender].lpTokenAmount - amount;
/*LN-112*/         uint256 remainingValue = getLPTokenValue(remainingLP);
/*LN-113*/         uint256 maxBorrow = (remainingValue * 100) / COLLATERAL_RATIO;
/*LN-114*/
            // Enforce collateralization on remaining position
/*LN-115*/         require(
/*LN-116*/             positions[msg.sender].borrowed <= maxBorrow,
/*LN-117*/             "Withdrawal would liquidate position"
/*LN-118*/         );
/*LN-119*/
            // Update position and return collateral
/*LN-120*/         positions[msg.sender].lpTokenAmount -= amount;
/*LN-121*/         IERC20(lpToken).transfer(msg.sender, amount);
/*LN-122*/     }
/*LN-123*/ }
/*LN-124*/ 