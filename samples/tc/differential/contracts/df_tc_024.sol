/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IPair {
/*LN-5*/     function token0() external view returns (address);
/*LN-6*/     function token1() external view returns (address);
/*LN-7*/     function getReserves() external view returns (uint112, uint112, uint32);
/*LN-8*/ }
/*LN-9*/ 
/*LN-10*/ interface IFactory {
/*LN-11*/     function getPair(address tokenA, address tokenB) external view returns (address);
/*LN-12*/ }
/*LN-13*/ 
/*LN-14*/ contract SwapRouter {
/*LN-15*/     IFactory public factory;
/*LN-16*/ 
/*LN-17*/     constructor(address _factory) {
/*LN-18*/         factory = IFactory(_factory);
/*LN-19*/     }
/*LN-20*/ 
/*LN-21*/     function swapExactTokensForTokens(
/*LN-22*/         uint256 amountIn,
/*LN-23*/         uint256 amountOutMin,
/*LN-24*/         address[] calldata path,
/*LN-25*/         address to,
/*LN-26*/         uint256 deadline
/*LN-27*/     ) external returns (uint[] memory amounts) {
/*LN-28*/ 
/*LN-29*/         amounts = new uint[](path.length);
/*LN-30*/         amounts[0] = amountIn;
/*LN-31*/ 
/*LN-32*/         for (uint i = 0; i < path.length - 1; i++) {
/*LN-33*/             address pair = factory.getPair(path[i], path[i+1]);
/*LN-34*/             require(pair != address(0), "Pair does not exist");
/*LN-35*/ 
/*LN-36*/             (uint112 reserve0, uint112 reserve1,) = IPair(pair).getReserves();
/*LN-37*/ 
/*LN-38*/             amounts[i+1] = _getAmountOut(amounts[i], reserve0, reserve1);
/*LN-39*/         }
/*LN-40*/ 
/*LN-41*/         return amounts;
/*LN-42*/     }
/*LN-43*/ 
/*LN-44*/     function _getAmountOut(uint256 amountIn, uint112 reserveIn, uint112 reserveOut) internal pure returns (uint256) {
/*LN-45*/         return (amountIn * uint256(reserveOut)) / uint256(reserveIn);
/*LN-46*/     }
/*LN-47*/ }
/*LN-48*/ 