/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IPair {
/*LN-4*/     function token0() external view returns (address);
/*LN-5*/     function token1() external view returns (address);
/*LN-6*/     function getReserves() external view returns (uint112, uint112, uint32);
/*LN-7*/ }
/*LN-8*/ 
/*LN-9*/ contract SwapRouter {
/*LN-10*/ 
/*LN-11*/     function swapExactTokensForTokens(
/*LN-12*/         uint256 amountIn,
/*LN-13*/         uint256 amountOutMin,
/*LN-14*/         address[] calldata path,
/*LN-15*/         address to,
/*LN-16*/         uint256 deadline
/*LN-17*/     ) external returns (uint[] memory amounts) {
/*LN-18*/ 
/*LN-19*/         amounts = new uint[](path.length);
/*LN-20*/         amounts[0] = amountIn;
/*LN-21*/ 
/*LN-22*/         for (uint i = 0; i < path.length - 1; i++) {
/*LN-23*/             address pair = _getPair(path[i], path[i+1]);
/*LN-24*/ 
/*LN-25*/             (uint112 reserve0, uint112 reserve1,) = IPair(pair).getReserves();
/*LN-26*/ 
/*LN-27*/             amounts[i+1] = _getAmountOut(amounts[i], reserve0, reserve1);
/*LN-28*/         }
/*LN-29*/ 
/*LN-30*/         return amounts;
/*LN-31*/     }
/*LN-32*/ 
/*LN-33*/     function _getPair(address tokenA, address tokenB) internal pure returns (address) {
/*LN-34*/ 
/*LN-35*/         return address(uint160(uint256(keccak256(abi.encodePacked(tokenA, tokenB)))));
/*LN-36*/     }
/*LN-37*/ 
/*LN-38*/     function _getAmountOut(uint256 amountIn, uint112 reserveIn, uint112 reserveOut) internal pure returns (uint256) {
/*LN-39*/         return (amountIn * uint256(reserveOut)) / uint256(reserveIn);
/*LN-40*/     }
/*LN-41*/ }