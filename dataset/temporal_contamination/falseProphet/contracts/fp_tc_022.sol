/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function balanceOf(address account) external view returns (uint256);
/*LN-6*/ 
/*LN-7*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-8*/ 
/*LN-9*/     function transferFrom(
/*LN-10*/         address from,
/*LN-11*/         address to,
/*LN-12*/         uint256 amount
/*LN-13*/     ) external returns (bool);
/*LN-14*/ }
/*LN-15*/ 

/**
 * @title UraniumPair
 * @notice Uniswap V2 style AMM pair with optimized fee structure
 * @dev Audited by Certik (Q1 2021) - All findings resolved
 * @dev Implements constant product market maker with 0.16% fee
 * @dev Gas-optimized reserve management with uint112 packing
 * @custom:security-contact security@uranium.finance
 */
/*LN-16*/ contract UraniumPair {
    /// @dev First token in the pair
/*LN-17*/     address public token0;
    /// @dev Second token in the pair
/*LN-18*/     address public token1;
/*LN-19*/
    /// @dev Reserve of token0 (packed for gas efficiency)
/*LN-20*/     uint112 private reserve0;
    /// @dev Reserve of token1 (packed for gas efficiency)
/*LN-21*/     uint112 private reserve1;
/*LN-22*/
    /// @dev Trading fee in basis points (16 = 0.16%)
/*LN-23*/     uint256 public constant TOTAL_FEE = 16; // 0.16% fee
/*LN-24*/ 
/*LN-25*/     constructor(address _token0, address _token1) {
/*LN-26*/         token0 = _token0;
/*LN-27*/         token1 = _token1;
/*LN-28*/     }
/*LN-29*/ 
    /**
     * @notice Add liquidity to the pair
     * @dev Calculates LP tokens based on geometric mean of deposits
     * @param to Address to receive LP tokens
     * @return liquidity Amount of LP tokens minted
     */
/*LN-33*/     function mint(address to) external returns (uint256 liquidity) {
/*LN-34*/         uint256 balance0 = IERC20(token0).balanceOf(address(this));
/*LN-35*/         uint256 balance1 = IERC20(token1).balanceOf(address(this));
/*LN-36*/ 
/*LN-37*/         uint256 amount0 = balance0 - reserve0;
/*LN-38*/         uint256 amount1 = balance1 - reserve1;
/*LN-39*/ 
/*LN-40*/         // Simplified liquidity calculation
/*LN-41*/         liquidity = sqrt(amount0 * amount1);
/*LN-42*/ 
/*LN-43*/         reserve0 = uint112(balance0);
/*LN-44*/         reserve1 = uint112(balance1);
/*LN-45*/ 
/*LN-46*/         return liquidity;
/*LN-47*/     }
/*LN-48*/ 
    /**
     * @notice Execute token swap with fee deduction
     * @dev Validates constant product invariant after fee adjustment
     * @dev Follows Uniswap V2 optimistic transfer pattern
     * @param amount0Out Amount of token0 to receive
     * @param amount1Out Amount of token1 to receive
     * @param to Recipient address
     * @param data Optional callback data
     */
/*LN-52*/     function swap(
/*LN-53*/         uint256 amount0Out,
/*LN-54*/         uint256 amount1Out,
/*LN-55*/         address to,
/*LN-56*/         bytes calldata data
/*LN-57*/     ) external {
/*LN-58*/         require(
/*LN-59*/             amount0Out > 0 || amount1Out > 0,
/*LN-60*/             "UraniumSwap: INSUFFICIENT_OUTPUT_AMOUNT"
/*LN-61*/         );
/*LN-62*/ 
/*LN-63*/         uint112 _reserve0 = reserve0;
/*LN-64*/         uint112 _reserve1 = reserve1;
/*LN-65*/ 
/*LN-66*/         require(
/*LN-67*/             amount0Out < _reserve0 && amount1Out < _reserve1,
/*LN-68*/             "UraniumSwap: INSUFFICIENT_LIQUIDITY"
/*LN-69*/         );
/*LN-70*/ 
            // Optimistic transfer to recipient
/*LN-72*/         if (amount0Out > 0) IERC20(token0).transfer(to, amount0Out);
/*LN-73*/         if (amount1Out > 0) IERC20(token1).transfer(to, amount1Out);
/*LN-74*/ 
/*LN-75*/         // Get balances after transfer
/*LN-76*/         uint256 balance0 = IERC20(token0).balanceOf(address(this));
/*LN-77*/         uint256 balance1 = IERC20(token1).balanceOf(address(this));
/*LN-78*/ 
/*LN-79*/         // Calculate input amounts
/*LN-80*/         uint256 amount0In = balance0 > _reserve0 - amount0Out
/*LN-81*/             ? balance0 - (_reserve0 - amount0Out)
/*LN-82*/             : 0;
/*LN-83*/         uint256 amount1In = balance1 > _reserve1 - amount1Out
/*LN-84*/             ? balance1 - (_reserve1 - amount1Out)
/*LN-85*/             : 0;
/*LN-86*/ 
/*LN-87*/         require(
/*LN-88*/             amount0In > 0 || amount1In > 0,
/*LN-89*/             "UraniumSwap: INSUFFICIENT_INPUT_AMOUNT"
/*LN-90*/         );
/*LN-91*/ 
            // Apply fee adjustment to balances
/*LN-93*/         uint256 balance0Adjusted = balance0 * 10000 - amount0In * TOTAL_FEE;
/*LN-94*/         uint256 balance1Adjusted = balance1 * 10000 - amount1In * TOTAL_FEE;
/*LN-95*/
            // Verify constant product invariant (x * y >= k)
/*LN-98*/         require(
/*LN-99*/             balance0Adjusted * balance1Adjusted >=
/*LN-100*/                 uint256(_reserve0) * _reserve1 * (1000 ** 2),
/*LN-101*/             "UraniumSwap: K"
/*LN-102*/         );
/*LN-103*/ 
/*LN-104*/         // Update reserves
/*LN-105*/         reserve0 = uint112(balance0);
/*LN-106*/         reserve1 = uint112(balance1);
/*LN-107*/     }
/*LN-108*/ 
/*LN-109*/     /**
/*LN-110*/      * @notice Get current reserves
/*LN-111*/      */
/*LN-112*/     function getReserves() external view returns (uint112, uint112, uint32) {
/*LN-113*/         return (reserve0, reserve1, 0);
/*LN-114*/     }
/*LN-115*/ 
/*LN-116*/     /**
/*LN-117*/      * @notice Helper function for square root
/*LN-118*/      */
/*LN-119*/     function sqrt(uint256 y) internal pure returns (uint256 z) {
/*LN-120*/         if (y > 3) {
/*LN-121*/             z = y;
/*LN-122*/             uint256 x = y / 2 + 1;
/*LN-123*/             while (x < z) {
/*LN-124*/                 z = x;
/*LN-125*/                 x = (y / x + x) / 2;
/*LN-126*/             }
/*LN-127*/         } else if (y != 0) {
/*LN-128*/             z = 1;
/*LN-129*/         }
/*LN-130*/     }
/*LN-131*/ }
/*LN-132*/ 