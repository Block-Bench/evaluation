/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * URANIUM FINANCE EXPLOIT (April 2021)
/*LN-6*/  *
/*LN-7*/  * Attack Vector: AMM Constant Product Check Miscalculation
/*LN-8*/  * Loss: $50 million
/*LN-9*/  *
/*LN-10*/  * VULNERABILITY:
/*LN-11*/  * Uranium Finance forked Uniswap V2 but made a critical error in the swap
/*LN-12*/  * function. They changed the fee calculation from 0.3% (using denominator 1000)
/*LN-13*/  * to 0.16% (using denominator 10000), but forgot to update the constant product
/*LN-14*/  * (K) validation check.
/*LN-15*/  *
/*LN-16*/  * The mismatch meant:
/*LN-17*/  * - Fee calculation used: balance * 10000
/*LN-18*/  * - K check used: reserve * 1000 * 1000
/*LN-19*/  *
/*LN-20*/  * This allowed the K value to increase by 100x after each swap, enabling
/*LN-21*/  * attackers to repeatedly drain the pool by swapping back and forth.
/*LN-22*/  *
/*LN-23*/  * Vulnerable Code (from original):
/*LN-24*/  * uint balance0Adjusted = balance0.mul(10000).sub(amount0In.mul(16));
/*LN-25*/  * uint balance1Adjusted = balance1.mul(10000).sub(amount1In.mul(16));
/*LN-26*/  * require(balance0Adjusted.mul(balance1Adjusted) >=
/*LN-27*/  *         uint(_reserve0).mul(_reserve1).mul(1000**2), 'UraniumSwap: K');
/*LN-28*/  *
/*LN-29*/  * The left side uses 10000 scale, right side uses 1000 scale!
/*LN-30*/  */
/*LN-31*/ 
/*LN-32*/ interface IERC20 {
/*LN-33*/     function balanceOf(address account) external view returns (uint256);
/*LN-34*/ 
/*LN-35*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-36*/ 
/*LN-37*/     function transferFrom(
/*LN-38*/         address from,
/*LN-39*/         address to,
/*LN-40*/         uint256 amount
/*LN-41*/     ) external returns (bool);
/*LN-42*/ }
/*LN-43*/ 
/*LN-44*/ contract UraniumPair {
/*LN-45*/     address public token0;
/*LN-46*/     address public token1;
/*LN-47*/ 
/*LN-48*/     uint112 private reserve0;
/*LN-49*/     uint112 private reserve1;
/*LN-50*/ 
/*LN-51*/     uint256 public constant TOTAL_FEE = 16; // 0.16% fee
/*LN-52*/ 
/*LN-53*/     constructor(address _token0, address _token1) {
/*LN-54*/         token0 = _token0;
/*LN-55*/         token1 = _token1;
/*LN-56*/     }
/*LN-57*/ 
/*LN-58*/     /**
/*LN-59*/      * @notice Add liquidity to the pair
/*LN-60*/      */
/*LN-61*/     function mint(address to) external returns (uint256 liquidity) {
/*LN-62*/         uint256 balance0 = IERC20(token0).balanceOf(address(this));
/*LN-63*/         uint256 balance1 = IERC20(token1).balanceOf(address(this));
/*LN-64*/ 
/*LN-65*/         uint256 amount0 = balance0 - reserve0;
/*LN-66*/         uint256 amount1 = balance1 - reserve1;
/*LN-67*/ 
/*LN-68*/         // Simplified liquidity calculation
/*LN-69*/         liquidity = sqrt(amount0 * amount1);
/*LN-70*/ 
/*LN-71*/         reserve0 = uint112(balance0);
/*LN-72*/         reserve1 = uint112(balance1);
/*LN-73*/ 
/*LN-74*/         return liquidity;
/*LN-75*/     }
/*LN-76*/ 
/*LN-77*/     /**
/*LN-78*/      * @notice VULNERABLE: Swap tokens with inconsistent K check
/*LN-79*/      * @dev The critical bug is in the constant product validation
/*LN-80*/      */
/*LN-81*/     function swap(
/*LN-82*/         uint256 amount0Out,
/*LN-83*/         uint256 amount1Out,
/*LN-84*/         address to,
/*LN-85*/         bytes calldata data
/*LN-86*/     ) external {
/*LN-87*/         require(
/*LN-88*/             amount0Out > 0 || amount1Out > 0,
/*LN-89*/             "UraniumSwap: INSUFFICIENT_OUTPUT_AMOUNT"
/*LN-90*/         );
/*LN-91*/ 
/*LN-92*/         uint112 _reserve0 = reserve0;
/*LN-93*/         uint112 _reserve1 = reserve1;
/*LN-94*/ 
/*LN-95*/         require(
/*LN-96*/             amount0Out < _reserve0 && amount1Out < _reserve1,
/*LN-97*/             "UraniumSwap: INSUFFICIENT_LIQUIDITY"
/*LN-98*/         );
/*LN-99*/ 
/*LN-100*/         // Transfer tokens out
/*LN-101*/         if (amount0Out > 0) IERC20(token0).transfer(to, amount0Out);
/*LN-102*/         if (amount1Out > 0) IERC20(token1).transfer(to, amount1Out);
/*LN-103*/ 
/*LN-104*/         // Get balances after transfer
/*LN-105*/         uint256 balance0 = IERC20(token0).balanceOf(address(this));
/*LN-106*/         uint256 balance1 = IERC20(token1).balanceOf(address(this));
/*LN-107*/ 
/*LN-108*/         // Calculate input amounts
/*LN-109*/         uint256 amount0In = balance0 > _reserve0 - amount0Out
/*LN-110*/             ? balance0 - (_reserve0 - amount0Out)
/*LN-111*/             : 0;
/*LN-112*/         uint256 amount1In = balance1 > _reserve1 - amount1Out
/*LN-113*/             ? balance1 - (_reserve1 - amount1Out)
/*LN-114*/             : 0;
/*LN-115*/ 
/*LN-116*/         require(
/*LN-117*/             amount0In > 0 || amount1In > 0,
/*LN-118*/             "UraniumSwap: INSUFFICIENT_INPUT_AMOUNT"
/*LN-119*/         );
/*LN-120*/ 
/*LN-121*/         // VULNERABILITY: Inconsistent scaling in K check
/*LN-122*/         // Fee calculation uses 10000 scale (0.16% = 16/10000)
/*LN-123*/         uint256 balance0Adjusted = balance0 * 10000 - amount0In * TOTAL_FEE;
/*LN-124*/         uint256 balance1Adjusted = balance1 * 10000 - amount1In * TOTAL_FEE;
/*LN-125*/ 
/*LN-126*/         // K check uses 1000 scale (should be 10000 to match above!)
/*LN-127*/         // This is the CRITICAL BUG
/*LN-128*/         require(
/*LN-129*/             balance0Adjusted * balance1Adjusted >=
/*LN-130*/                 uint256(_reserve0) * _reserve1 * (1000 ** 2),
/*LN-131*/             "UraniumSwap: K"
/*LN-132*/         );
/*LN-133*/ 
/*LN-134*/         // Update reserves
/*LN-135*/         reserve0 = uint112(balance0);
/*LN-136*/         reserve1 = uint112(balance1);
/*LN-137*/     }
/*LN-138*/ 
/*LN-139*/     /**
/*LN-140*/      * @notice Get current reserves
/*LN-141*/      */
/*LN-142*/     function getReserves() external view returns (uint112, uint112, uint32) {
/*LN-143*/         return (reserve0, reserve1, 0);
/*LN-144*/     }
/*LN-145*/ 
/*LN-146*/     /**
/*LN-147*/      * @notice Helper function for square root
/*LN-148*/      */
/*LN-149*/     function sqrt(uint256 y) internal pure returns (uint256 z) {
/*LN-150*/         if (y > 3) {
/*LN-151*/             z = y;
/*LN-152*/             uint256 x = y / 2 + 1;
/*LN-153*/             while (x < z) {
/*LN-154*/                 z = x;
/*LN-155*/                 x = (y / x + x) / 2;
/*LN-156*/             }
/*LN-157*/         } else if (y != 0) {
/*LN-158*/             z = 1;
/*LN-159*/         }
/*LN-160*/     }
/*LN-161*/ }
/*LN-162*/ 
/*LN-163*/ /**
/*LN-164*/  * EXPLOIT SCENARIO:
/*LN-165*/  *
/*LN-166*/  * Initial State:
/*LN-167*/  * - Uranium WBNB/BUSD pool has balanced liquidity
/*LN-168*/  * - reserve0 (WBNB): 1000 tokens
/*LN-169*/  * - reserve1 (BUSD): 1000 tokens
/*LN-170*/  * - K = 1000 * 1000 = 1,000,000
/*LN-171*/  *
/*LN-172*/  * Attack:
/*LN-173*/  * 1. Attacker deposits 1 WBNB to pool
/*LN-174*/  *
/*LN-175*/  * 2. Calls swap to get BUSD:
/*LN-176*/  *    - Input: 1 WBNB
/*LN-177*/  *    - Output: ~0.99 BUSD (minus 0.16% fee)
/*LN-178*/  *
/*LN-179*/  * 3. In the K check:
/*LN-180*/  *    Left side: balance0Adjusted * balance1Adjusted
/*LN-181*/  *              = (1001 * 10000 - 1 * 16) * (999 * 10000)
/*LN-182*/  *              = 10,009,984 * 9,990,000
/*LN-183*/  *              = ~100,099,800,000,000
/*LN-184*/  *
/*LN-185*/  *    Right side: reserve0 * reserve1 * 1000^2
/*LN-186*/  *              = 1000 * 1000 * 1,000,000
/*LN-187*/  *              = 1,000,000,000,000
/*LN-188*/  *
/*LN-189*/  *    Left >> Right (100x larger!), so check passes
/*LN-190*/  *
/*LN-191*/  * 4. New reserves stored:
/*LN-192*/  *    - reserve0: 1001
/*LN-193*/  *    - reserve1: 999
/*LN-194*/  *    - But effective K is now 100x larger than it should be!
/*LN-195*/  *
/*LN-196*/  * 5. Attacker swaps back BUSD -> WBNB:
/*LN-197*/  *    - Due to inflated K, can extract MORE than initially deposited
/*LN-198*/  *
/*LN-199*/  * 6. Repeat swaps back and forth:
/*LN-200*/  *    - Each swap inflates K by another 100x
/*LN-201*/  *    - Attacker drains more on each iteration
/*LN-202*/  *
/*LN-203*/  * 7. After ~5-10 iterations:
/*LN-204*/  *    - Pool completely drained
/*LN-205*/  *    - Loss: $50M
/*LN-206*/  *
/*LN-207*/  * Root Cause:
/*LN-208*/  * Inconsistent scaling factors in constant product check:
/*LN-209*/  * - Adjusted balances use 10000 scale
/*LN-210*/  * - K check uses 1000 scale
/*LN-211*/  * - Should be: reserve0 * reserve1 * (10000**2)
/*LN-212*/  *
/*LN-213*/  * Fix:
/*LN-214*/  * ```solidity
/*LN-215*/  * require(
/*LN-216*/  *     balance0Adjusted * balance1Adjusted >=
/*LN-217*/  *     uint256(_reserve0) * _reserve1 * (10000 ** 2),  // Use 10000 not 1000!
/*LN-218*/  *     'UraniumSwap: K'
/*LN-219*/  * );
/*LN-220*/  * ```
/*LN-221*/  */
/*LN-222*/ 