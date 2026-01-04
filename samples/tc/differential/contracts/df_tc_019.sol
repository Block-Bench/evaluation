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
/*LN-16*/ contract TokenPair {
/*LN-17*/     address public token0;
/*LN-18*/     address public token1;
/*LN-19*/ 
/*LN-20*/     uint112 private reserve0;
/*LN-21*/     uint112 private reserve1;
/*LN-22*/ 
/*LN-23*/     uint256 public constant TOTAL_FEE = 16;
/*LN-24*/     uint256 public constant FEE_SCALE = 10000; // Fee scale for 0.16%
/*LN-25*/ 
/*LN-26*/     constructor(address _token0, address _token1) {
/*LN-27*/         token0 = _token0;
/*LN-28*/         token1 = _token1;
/*LN-29*/     }
/*LN-30*/ 
/*LN-31*/     function mint(address to) external returns (uint256 liquidity) {
/*LN-32*/         uint256 balance0 = IERC20(token0).balanceOf(address(this));
/*LN-33*/         uint256 balance1 = IERC20(token1).balanceOf(address(this));
/*LN-34*/ 
/*LN-35*/         uint256 amount0 = balance0 - reserve0;
/*LN-36*/         uint256 amount1 = balance1 - reserve1;
/*LN-37*/ 
/*LN-38*/         liquidity = sqrt(amount0 * amount1);
/*LN-39*/ 
/*LN-40*/         reserve0 = uint112(balance0);
/*LN-41*/         reserve1 = uint112(balance1);
/*LN-42*/ 
/*LN-43*/         return liquidity;
/*LN-44*/     }
/*LN-45*/ 
/*LN-46*/     function swap(
/*LN-47*/         uint256 amount0Out,
/*LN-48*/         uint256 amount1Out,
/*LN-49*/         address to,
/*LN-50*/         bytes calldata data
/*LN-51*/     ) external {
/*LN-52*/         require(amount0Out > 0 || amount1Out > 0, "INSUFFICIENT_OUTPUT_AMOUNT");
/*LN-53*/ 
/*LN-54*/         uint112 _reserve0 = reserve0;
/*LN-55*/         uint112 _reserve1 = reserve1;
/*LN-56*/ 
/*LN-57*/         require(
/*LN-58*/             amount0Out < _reserve0 && amount1Out < _reserve1,
/*LN-59*/             "INSUFFICIENT_LIQUIDITY"
/*LN-60*/         );
/*LN-61*/ 
/*LN-62*/         if (amount0Out > 0) IERC20(token0).transfer(to, amount0Out);
/*LN-63*/         if (amount1Out > 0) IERC20(token1).transfer(to, amount1Out);
/*LN-64*/ 
/*LN-65*/         uint256 balance0 = IERC20(token0).balanceOf(address(this));
/*LN-66*/         uint256 balance1 = IERC20(token1).balanceOf(address(this));
/*LN-67*/ 
/*LN-68*/         uint256 amount0In = balance0 > _reserve0 - amount0Out
/*LN-69*/             ? balance0 - (_reserve0 - amount0Out)
/*LN-70*/             : 0;
/*LN-71*/         uint256 amount1In = balance1 > _reserve1 - amount1Out
/*LN-72*/             ? balance1 - (_reserve1 - amount1Out)
/*LN-73*/             : 0;
/*LN-74*/ 
/*LN-75*/         require(amount0In > 0 || amount1In > 0, "INSUFFICIENT_INPUT_AMOUNT");
/*LN-76*/ 
/*LN-77*/         uint256 balance0Adjusted = balance0 * FEE_SCALE - amount0In * TOTAL_FEE;
/*LN-78*/         uint256 balance1Adjusted = balance1 * FEE_SCALE - amount1In * TOTAL_FEE;
/*LN-79*/ 
/*LN-80*/         require(
/*LN-81*/             balance0Adjusted * balance1Adjusted >=
/*LN-82*/                 uint256(_reserve0) * _reserve1 * (FEE_SCALE ** 2),
/*LN-83*/             "K"
/*LN-84*/         );
/*LN-85*/ 
/*LN-86*/         reserve0 = uint112(balance0);
/*LN-87*/         reserve1 = uint112(balance1);
/*LN-88*/     }
/*LN-89*/ 
/*LN-90*/     function getReserves() external view returns (uint112, uint112, uint32) {
/*LN-91*/         return (reserve0, reserve1, 0);
/*LN-92*/     }
/*LN-93*/ 
/*LN-94*/     function sqrt(uint256 y) internal pure returns (uint256 z) {
/*LN-95*/         if (y > 3) {
/*LN-96*/             z = y;
/*LN-97*/             uint256 x = y / 2 + 1;
/*LN-98*/             while (x < z) {
/*LN-99*/                 z = x;
/*LN-100*/                 x = (y / x + x) / 2;
/*LN-101*/             }
/*LN-102*/         } else if (y != 0) {
/*LN-103*/             z = 1;
/*LN-104*/         }
/*LN-105*/     }
/*LN-106*/ }
/*LN-107*/ 