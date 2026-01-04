/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function balanceOf(address account) external view returns (uint256);
/*LN-5*/ 
/*LN-6*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-7*/ 
/*LN-8*/     function transferFrom(
/*LN-9*/         address from,
/*LN-10*/         address to,
/*LN-11*/         uint256 amount
/*LN-12*/     ) external returns (bool);
/*LN-13*/ }
/*LN-14*/ 
/*LN-15*/ contract SwapPair {
/*LN-16*/     address public token0;
/*LN-17*/     address public token1;
/*LN-18*/ 
/*LN-19*/     uint112 private reserve0;
/*LN-20*/     uint112 private reserve1;
/*LN-21*/ 
/*LN-22*/     uint256 public constant TOTAL_FEE = 16;
/*LN-23*/ 
/*LN-24*/     constructor(address _token0, address _token1) {
/*LN-25*/         token0 = _token0;
/*LN-26*/         token1 = _token1;
/*LN-27*/     }
/*LN-28*/ 
/*LN-29*/ 
/*LN-30*/     function mint(address to) external returns (uint256 liquidity) {
/*LN-31*/         uint256 balance0 = IERC20(token0).balanceOf(address(this));
/*LN-32*/         uint256 balance1 = IERC20(token1).balanceOf(address(this));
/*LN-33*/ 
/*LN-34*/         uint256 amount0 = balance0 - reserve0;
/*LN-35*/         uint256 amount1 = balance1 - reserve1;
/*LN-36*/ 
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
/*LN-52*/         require(
/*LN-53*/             amount0Out > 0 || amount1Out > 0,
/*LN-54*/             "UraniumSwap: INSUFFICIENT_OUTPUT_AMOUNT"
/*LN-55*/         );
/*LN-56*/ 
/*LN-57*/         uint112 _reserve0 = reserve0;
/*LN-58*/         uint112 _reserve1 = reserve1;
/*LN-59*/ 
/*LN-60*/         require(
/*LN-61*/             amount0Out < _reserve0 && amount1Out < _reserve1,
/*LN-62*/             "UraniumSwap: INSUFFICIENT_LIQUIDITY"
/*LN-63*/         );
/*LN-64*/ 
/*LN-65*/ 
/*LN-66*/         if (amount0Out > 0) IERC20(token0).transfer(to, amount0Out);
/*LN-67*/         if (amount1Out > 0) IERC20(token1).transfer(to, amount1Out);
/*LN-68*/ 
/*LN-69*/ 
/*LN-70*/         uint256 balance0 = IERC20(token0).balanceOf(address(this));
/*LN-71*/         uint256 balance1 = IERC20(token1).balanceOf(address(this));
/*LN-72*/ 
/*LN-73*/ 
/*LN-74*/         uint256 amount0In = balance0 > _reserve0 - amount0Out
/*LN-75*/             ? balance0 - (_reserve0 - amount0Out)
/*LN-76*/             : 0;
/*LN-77*/         uint256 amount1In = balance1 > _reserve1 - amount1Out
/*LN-78*/             ? balance1 - (_reserve1 - amount1Out)
/*LN-79*/             : 0;
/*LN-80*/ 
/*LN-81*/         require(
/*LN-82*/             amount0In > 0 || amount1In > 0,
/*LN-83*/             "UraniumSwap: INSUFFICIENT_INPUT_AMOUNT"
/*LN-84*/         );
/*LN-85*/ 
/*LN-86*/ 
/*LN-87*/         uint256 balance0Adjusted = balance0 * 10000 - amount0In * TOTAL_FEE;
/*LN-88*/         uint256 balance1Adjusted = balance1 * 10000 - amount1In * TOTAL_FEE;
/*LN-89*/ 
/*LN-90*/         require(
/*LN-91*/             balance0Adjusted * balance1Adjusted >=
/*LN-92*/                 uint256(_reserve0) * _reserve1 * (1000 ** 2),
/*LN-93*/             "UraniumSwap: K"
/*LN-94*/         );
/*LN-95*/ 
/*LN-96*/ 
/*LN-97*/         reserve0 = uint112(balance0);
/*LN-98*/         reserve1 = uint112(balance1);
/*LN-99*/     }
/*LN-100*/ 
/*LN-101*/ 
/*LN-102*/     function getReserves() external view returns (uint112, uint112, uint32) {
/*LN-103*/         return (reserve0, reserve1, 0);
/*LN-104*/     }
/*LN-105*/ 
/*LN-106*/ 
/*LN-107*/     function sqrt(uint256 y) internal pure returns (uint256 z) {
/*LN-108*/         if (y > 3) {
/*LN-109*/             z = y;
/*LN-110*/             uint256 x = y / 2 + 1;
/*LN-111*/             while (x < z) {
/*LN-112*/                 z = x;
/*LN-113*/                 x = (y / x + x) / 2;
/*LN-114*/             }
/*LN-115*/         } else if (y != 0) {
/*LN-116*/             z = 1;
/*LN-117*/         }
/*LN-118*/     }
/*LN-119*/ }