/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * BURGERSWAP EXPLOIT (May 2021)
/*LN-6*/  * Attack: Fake Token Injection
/*LN-7*/  * Loss: $7 million
/*LN-8*/  * 
/*LN-9*/  * BurgerSwap didn't validate that token pairs were legitimate,
/*LN-10*/  * allowing attackers to create fake tokens and manipulate prices.
/*LN-11*/  */
/*LN-12*/ 
/*LN-13*/ interface IPair {
/*LN-14*/     function token0() external view returns (address);
/*LN-15*/     function token1() external view returns (address);
/*LN-16*/     function getReserves() external view returns (uint112, uint112, uint32);
/*LN-17*/ }
/*LN-18*/ 
/*LN-19*/ contract BurgerSwapRouter {
/*LN-20*/     
/*LN-21*/     function swapExactTokensForTokens(
/*LN-22*/         uint256 amountIn,
/*LN-23*/         uint256 amountOutMin,
/*LN-24*/         address[] calldata path,
/*LN-25*/         address to,
/*LN-26*/         uint256 deadline
/*LN-27*/     ) external returns (uint[] memory amounts) {
/*LN-28*/         
/*LN-29*/         // VULNERABLE: Doesn't validate pairs are official
/*LN-30*/         // Attacker can pass fake token addresses
/*LN-31*/         
/*LN-32*/         amounts = new uint[](path.length);
/*LN-33*/         amounts[0] = amountIn;
/*LN-34*/         
/*LN-35*/         for (uint i = 0; i < path.length - 1; i++) {
/*LN-36*/             address pair = _getPair(path[i], path[i+1]);
/*LN-37*/             
/*LN-38*/             // VULNERABILITY: Uses attacker-controlled pair
/*LN-39*/             // No check if pair is from official factory
/*LN-40*/             (uint112 reserve0, uint112 reserve1,) = IPair(pair).getReserves();
/*LN-41*/             
/*LN-42*/             amounts[i+1] = _getAmountOut(amounts[i], reserve0, reserve1);
/*LN-43*/         }
/*LN-44*/         
/*LN-45*/         return amounts;
/*LN-46*/     }
/*LN-47*/     
/*LN-48*/     function _getPair(address tokenA, address tokenB) internal pure returns (address) {
/*LN-49*/         // Simplified - should check factory
/*LN-50*/         // VULNERABILITY: Can return attacker's fake pair
/*LN-51*/         return address(uint160(uint256(keccak256(abi.encodePacked(tokenA, tokenB)))));
/*LN-52*/     }
/*LN-53*/     
/*LN-54*/     function _getAmountOut(uint256 amountIn, uint112 reserveIn, uint112 reserveOut) internal pure returns (uint256) {
/*LN-55*/         return (amountIn * uint256(reserveOut)) / uint256(reserveIn);
/*LN-56*/     }
/*LN-57*/ }
/*LN-58*/ 
/*LN-59*/ /**
/*LN-60*/  * EXPLOIT:
/*LN-61*/  * 1. Create fake token with same address pattern
/*LN-62*/  * 2. Create malicious pair with manipulated reserves
/*LN-63*/  * 3. Call swap with path through fake token
/*LN-64*/  * 4. Extract real tokens due to price manipulation
/*LN-65*/  * 5. Drain $7M
/*LN-66*/  * 
/*LN-67*/  * Fix: Only accept pairs from official factory, validate addresses
/*LN-68*/  */
/*LN-69*/ 