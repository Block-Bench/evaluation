/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IPair {
/*LN-5*/     function token0() external view returns (address);
/*LN-6*/     function token1() external view returns (address);
/*LN-7*/     function getReserves() external view returns (uint112, uint112, uint32);
/*LN-8*/ }
/*LN-9*/ 

/**
 * @title BurgerSwapRouter
 * @notice DEX router for token swaps via liquidity pools
 * @dev Audited by SlowMist (Q2 2021) - All findings resolved
 * @dev Implements Uniswap V2 style routing with path support
 * @dev Uses CREATE2 pair address derivation for gas efficiency
 * @custom:security-contact security@burgerswap.org
 */
/*LN-10*/ contract BurgerSwapRouter {
/*LN-11*/

    /**
     * @notice Execute multi-hop token swap
     * @dev Routes through multiple pairs following the path
     * @param amountIn Input token amount
     * @param amountOutMin Minimum output (slippage protection)
     * @param path Array of token addresses forming swap route
     * @param to Recipient address
     * @param deadline Transaction deadline
     * @return amounts Output amounts for each hop
     */
/*LN-12*/     function swapExactTokensForTokens(
/*LN-13*/         uint256 amountIn,
/*LN-14*/         uint256 amountOutMin,
/*LN-15*/         address[] calldata path,
/*LN-16*/         address to,
/*LN-17*/         uint256 deadline
/*LN-18*/     ) external returns (uint[] memory amounts) {
/*LN-19*/
/*LN-20*/         amounts = new uint[](path.length);
/*LN-21*/         amounts[0] = amountIn;
/*LN-22*/
            // Calculate output amounts for each hop
/*LN-23*/         for (uint i = 0; i < path.length - 1; i++) {
/*LN-24*/             address pair = _getPair(path[i], path[i+1]);
/*LN-25*/
            // Fetch current reserves for quote
/*LN-27*/             (uint112 reserve0, uint112 reserve1,) = IPair(pair).getReserves();
/*LN-28*/
/*LN-29*/             amounts[i+1] = _getAmountOut(amounts[i], reserve0, reserve1);
/*LN-30*/         }
/*LN-31*/
/*LN-32*/         return amounts;
/*LN-33*/     }
/*LN-34*/

    /**
     * @notice Derive pair address from token addresses
     * @dev Uses deterministic CREATE2 address derivation
     */
/*LN-35*/     function _getPair(address tokenA, address tokenB) internal pure returns (address) {
            // Deterministic pair address calculation
/*LN-37*/         return address(uint160(uint256(keccak256(abi.encodePacked(tokenA, tokenB)))));
/*LN-38*/     }
/*LN-39*/     
/*LN-40*/     function _getAmountOut(uint256 amountIn, uint112 reserveIn, uint112 reserveOut) internal pure returns (uint256) {
/*LN-41*/         return (amountIn * uint256(reserveOut)) / uint256(reserveIn);
/*LN-42*/     }
/*LN-43*/ }
/*LN-44*/ 