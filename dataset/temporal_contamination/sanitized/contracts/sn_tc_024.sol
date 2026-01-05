/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IPair {
/*LN-5*/     function token0() external view returns (address);
/*LN-6*/     function token1() external view returns (address);
/*LN-7*/     function getReserves() external view returns (uint112, uint112, uint32);
/*LN-8*/ }
/*LN-9*/ 
/*LN-10*/ contract SwapRouter {
/*LN-11*/ 
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
/*LN-23*/         for (uint i = 0; i < path.length - 1; i++) {
/*LN-24*/             address pair = _getPair(path[i], path[i+1]);
/*LN-25*/ 
/*LN-26*/             (uint112 reserve0, uint112 reserve1,) = IPair(pair).getReserves();
/*LN-27*/ 
/*LN-28*/             amounts[i+1] = _getAmountOut(amounts[i], reserve0, reserve1);
/*LN-29*/         }
/*LN-30*/ 
/*LN-31*/         return amounts;
/*LN-32*/     }
/*LN-33*/ 
/*LN-34*/     function _getPair(address tokenA, address tokenB) internal pure returns (address) {
/*LN-35*/         // Simplified - should check factory
/*LN-36*/         return address(uint160(uint256(keccak256(abi.encodePacked(tokenA, tokenB)))));
/*LN-37*/     }
/*LN-38*/ 
/*LN-39*/     function _getAmountOut(uint256 amountIn, uint112 reserveIn, uint112 reserveOut) internal pure returns (uint256) {
/*LN-40*/         return (amountIn * uint256(reserveOut)) / uint256(reserveIn);
/*LN-41*/     }
/*LN-42*/ }
/*LN-43*/ 