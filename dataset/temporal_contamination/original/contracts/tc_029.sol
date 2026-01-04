/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * RADIANT CAPITAL EXPLOIT (January 2024)
/*LN-6*/  * Loss: $4.5 million
/*LN-7*/  * Attack: Time Manipulation + Rounding Error in LiquidityIndex
/*LN-8*/  *
/*LN-9*/  * Radiant Capital is an Aave V2 fork on Arbitrum. The exploit manipulated
/*LN-10*/  * the liquidityIndex through repeated flashloan deposits/withdrawals,
/*LN-11*/  * causing rounding errors that allowed draining funds from the pool.
/*LN-12*/  */
/*LN-13*/ 
/*LN-14*/ interface IERC20 {
/*LN-15*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-16*/ 
/*LN-17*/     function transferFrom(
/*LN-18*/         address from,
/*LN-19*/         address to,
/*LN-20*/         uint256 amount
/*LN-21*/     ) external returns (bool);
/*LN-22*/ 
/*LN-23*/     function balanceOf(address account) external view returns (uint256);
/*LN-24*/ 
/*LN-25*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-26*/ }
/*LN-27*/ 
/*LN-28*/ interface IFlashLoanReceiver {
/*LN-29*/     function executeOperation(
/*LN-30*/         address[] calldata assets,
/*LN-31*/         uint256[] calldata amounts,
/*LN-32*/         uint256[] calldata premiums,
/*LN-33*/         address initiator,
/*LN-34*/         bytes calldata params
/*LN-35*/     ) external returns (bool);
/*LN-36*/ }
/*LN-37*/ 
/*LN-38*/ contract RadiantLendingPool {
/*LN-39*/     uint256 public constant RAY = 1e27;
/*LN-40*/ 
/*LN-41*/     struct ReserveData {
/*LN-42*/         uint256 liquidityIndex;
/*LN-43*/         uint256 totalLiquidity;
/*LN-44*/         address rTokenAddress;
/*LN-45*/     }
/*LN-46*/ 
/*LN-47*/     mapping(address => ReserveData) public reserves;
/*LN-48*/ 
/*LN-49*/     /**
/*LN-50*/      * @notice Deposit tokens into lending pool
/*LN-51*/      * @dev VULNERABLE: liquidityIndex manipulation through rounding
/*LN-52*/      */
/*LN-53*/     function deposit(
/*LN-54*/         address asset,
/*LN-55*/         uint256 amount,
/*LN-56*/         address onBehalfOf,
/*LN-57*/         uint16 referralCode
/*LN-58*/     ) external {
/*LN-59*/         IERC20(asset).transferFrom(msg.sender, address(this), amount);
/*LN-60*/ 
/*LN-61*/         ReserveData storage reserve = reserves[asset];
/*LN-62*/ 
/*LN-63*/         // VULNERABILITY 1: liquidityIndex increases on each deposit
/*LN-64*/         // With repeated flashloan deposits, index grows exponentially
/*LN-65*/         uint256 currentLiquidityIndex = reserve.liquidityIndex;
/*LN-66*/         if (currentLiquidityIndex == 0) {
/*LN-67*/             currentLiquidityIndex = RAY;
/*LN-68*/         }
/*LN-69*/ 
/*LN-70*/         // Update index (simplified)
/*LN-71*/         reserve.liquidityIndex =
/*LN-72*/             currentLiquidityIndex +
/*LN-73*/             (amount * RAY) /
/*LN-74*/             (reserve.totalLiquidity + 1);
/*LN-75*/         reserve.totalLiquidity += amount;
/*LN-76*/ 
/*LN-77*/         // Mint rTokens to user
/*LN-78*/         uint256 rTokenAmount = rayDiv(amount, reserve.liquidityIndex);
/*LN-79*/         _mintRToken(reserve.rTokenAddress, onBehalfOf, rTokenAmount);
/*LN-80*/     }
/*LN-81*/ 
/*LN-82*/     /**
/*LN-83*/      * @notice Withdraw tokens from lending pool
/*LN-84*/      * @dev VULNERABLE: Rounding error in rayDiv allows extracting extra funds
/*LN-85*/      */
/*LN-86*/     function withdraw(
/*LN-87*/         address asset,
/*LN-88*/         uint256 amount,
/*LN-89*/         address to
/*LN-90*/     ) external returns (uint256) {
/*LN-91*/         ReserveData storage reserve = reserves[asset];
/*LN-92*/ 
/*LN-93*/         // VULNERABILITY 2: When liquidityIndex is manipulated to be very large,
/*LN-94*/         // rayDiv rounding errors become significant
/*LN-95*/         // User can burn fewer rTokens than they should need
/*LN-96*/         uint256 rTokensToBurn = rayDiv(amount, reserve.liquidityIndex);
/*LN-97*/ 
/*LN-98*/         _burnRToken(reserve.rTokenAddress, msg.sender, rTokensToBurn);
/*LN-99*/ 
/*LN-100*/         reserve.totalLiquidity -= amount;
/*LN-101*/         IERC20(asset).transfer(to, amount);
/*LN-102*/ 
/*LN-103*/         return amount;
/*LN-104*/     }
/*LN-105*/ 
/*LN-106*/     /**
/*LN-107*/      * @notice Borrow tokens from pool with collateral
/*LN-108*/      */
/*LN-109*/     function borrow(
/*LN-110*/         address asset,
/*LN-111*/         uint256 amount,
/*LN-112*/         uint256 interestRateMode,
/*LN-113*/         uint16 referralCode,
/*LN-114*/         address onBehalfOf
/*LN-115*/     ) external {
/*LN-116*/         // Simplified borrow logic
/*LN-117*/         IERC20(asset).transfer(onBehalfOf, amount);
/*LN-118*/     }
/*LN-119*/ 
/*LN-120*/     /**
/*LN-121*/      * @notice Execute flashloan
/*LN-122*/      * @dev VULNERABLE: Can be called repeatedly to manipulate liquidityIndex
/*LN-123*/      */
/*LN-124*/     function flashLoan(
/*LN-125*/         address receiverAddress,
/*LN-126*/         address[] calldata assets,
/*LN-127*/         uint256[] calldata amounts,
/*LN-128*/         uint256[] calldata modes,
/*LN-129*/         address onBehalfOf,
/*LN-130*/         bytes calldata params,
/*LN-131*/         uint16 referralCode
/*LN-132*/     ) external {
/*LN-133*/         for (uint256 i = 0; i < assets.length; i++) {
/*LN-134*/             IERC20(assets[i]).transfer(receiverAddress, amounts[i]);
/*LN-135*/         }
/*LN-136*/ 
/*LN-137*/         // Call receiver callback
/*LN-138*/         require(
/*LN-139*/             IFlashLoanReceiver(receiverAddress).executeOperation(
/*LN-140*/                 assets,
/*LN-141*/                 amounts,
/*LN-142*/                 new uint256[](assets.length),
/*LN-143*/                 msg.sender,
/*LN-144*/                 params
/*LN-145*/             ),
/*LN-146*/             "Flashloan callback failed"
/*LN-147*/         );
/*LN-148*/ 
/*LN-149*/         // VULNERABILITY 3: Flashloan deposit/withdrawal cycle
/*LN-150*/         // Each cycle slightly increases liquidityIndex
/*LN-151*/         // After 150+ iterations, rounding errors become exploitable
/*LN-152*/ 
/*LN-153*/         for (uint256 i = 0; i < assets.length; i++) {
/*LN-154*/             IERC20(assets[i]).transferFrom(
/*LN-155*/                 receiverAddress,
/*LN-156*/                 address(this),
/*LN-157*/                 amounts[i]
/*LN-158*/             );
/*LN-159*/         }
/*LN-160*/     }
/*LN-161*/ 
/*LN-162*/     /**
/*LN-163*/      * @notice Ray division with rounding down
/*LN-164*/      * @dev VULNERABILITY 4: Rounding down becomes significant when liquidityIndex is huge
/*LN-165*/      */
/*LN-166*/     function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
/*LN-167*/         uint256 halfB = b / 2;
/*LN-168*/         require(b != 0, "Division by zero");
/*LN-169*/         return (a * RAY + halfB) / b;
/*LN-170*/     }
/*LN-171*/ 
/*LN-172*/     function _mintRToken(address rToken, address to, uint256 amount) internal {
/*LN-173*/         // Simplified mint
/*LN-174*/     }
/*LN-175*/ 
/*LN-176*/     function _burnRToken(
/*LN-177*/         address rToken,
/*LN-178*/         address from,
/*LN-179*/         uint256 amount
/*LN-180*/     ) internal {
/*LN-181*/         // Simplified burn
/*LN-182*/     }
/*LN-183*/ }
/*LN-184*/ 
/*LN-185*/ /**
/*LN-186*/  * EXPLOIT SCENARIO:
/*LN-187*/  *
/*LN-188*/  * 1. Attacker borrows 3M USDC via Aave V3 flashloan
/*LN-189*/  *
/*LN-190*/  * 2. Deposits 2M USDC into Radiant pool
/*LN-191*/  *    - Receives rUSDC tokens
/*LN-192*/  *    - liquidityIndex starts at 1e27 (RAY)
/*LN-193*/  *
/*LN-194*/  * 3. Executes 151 nested flashloans from Radiant:
/*LN-195*/  *    - Each flashloan borrows 2M USDC
/*LN-196*/  *    - In callback: immediately re-deposit the 2M USDC
/*LN-197*/  *    - Then withdraw it back
/*LN-198*/  *    - This cycle repeats 151 times
/*LN-199*/  *    - Each iteration slightly increases liquidityIndex
/*LN-200*/  *
/*LN-201*/  * 4. After 151 iterations:
/*LN-202*/  *    - liquidityIndex has grown to astronomical value
/*LN-203*/  *    - Rounding errors in rayDiv become significant
/*LN-204*/  *
/*LN-205*/  * 5. Attacker transfers rUSDC balance to helper contract
/*LN-206*/  *
/*LN-207*/  * 6. Helper contract exploits rounding:
/*LN-208*/  *    - Due to huge liquidityIndex, burning rTokens returns more USDC than expected
/*LN-209*/  *    - rayDiv(amount, hugeLiquidityIndex) rounds down significantly
/*LN-210*/  *    - Attacker receives extra USDC on withdrawal
/*LN-211*/  *
/*LN-212*/  * 7. Borrows WETH against manipulated collateral
/*LN-213*/  *
/*LN-214*/  * 8. Swaps tokens and profits $4.5M
/*LN-215*/  *
/*LN-216*/  * Root Causes:
/*LN-217*/  * - Unbounded liquidityIndex growth
/*LN-218*/  * - No rate limiting on flashloan recursion
/*LN-219*/  * - Rounding errors in fixed-point arithmetic at extreme values
/*LN-220*/  * - Missing overflow/manipulation checks
/*LN-221*/  *
/*LN-222*/  * Fix:
/*LN-223*/  * - Implement reentrancy guards on flashloan
/*LN-224*/  * - Limit flashloan recursion depth
/*LN-225*/  * - Add bounds checking on liquidityIndex
/*LN-226*/  * - Use higher precision arithmetic
/*LN-227*/  * - Monitor for unusual liquidityIndex changes
/*LN-228*/  * - Add withdrawal delays after deposits
/*LN-229*/  */
/*LN-230*/ 