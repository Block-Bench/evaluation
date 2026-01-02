/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title Yearn yDAI Vault - Flash Loan Curve Pool Manipulation
/*LN-6*/  * @notice This contract demonstrates the vulnerability that led to the Yearn yDAI hack
/*LN-7*/  * @dev February 4, 2021 - $11M stolen through Curve pool manipulation
/*LN-8*/  *
/*LN-9*/  * VULNERABILITY: Using spot price from manipulable Curve pool for vault strategy
/*LN-10*/  *
/*LN-11*/  * ROOT CAUSE:
/*LN-12*/  * The earn() function deposits assets into Curve pool and uses the pool's
/*LN-13*/  * current virtual price to calculate strategy outcomes. An attacker can
/*LN-14*/  * use flash loans to temporarily imbalance the Curve pool, inflating the
/*LN-15*/  * virtual price, which tricks the vault into thinking it has more value
/*LN-16*/  * than it actually does.
/*LN-17*/  *
/*LN-18*/  * ATTACK VECTOR:
/*LN-19*/  * 1. Flash loan large amount of DAI, USDT, USDC
/*LN-20*/  * 2. Add liquidity to Curve 3pool with imbalanced amounts (mostly DAI)
/*LN-21*/  * 3. This inflates Curve's virtual_price temporarily
/*LN-22*/  * 4. Deposit into yDAI vault and call earn()
/*LN-23*/  * 5. earn() calculates value using inflated virtual_price
/*LN-24*/  * 6. Remove liquidity from Curve in imbalanced way (extract USDT)
/*LN-25*/  * 7. Add it back to normalize pool
/*LN-26*/  * 8. Repeat process, siphoning value from vault
/*LN-27*/  * 9. Withdraw from vault with inflated shares
/*LN-28*/  * 10. Repay flash loan and profit
/*LN-29*/  *
/*LN-30*/  * The vulnerability exploits the trust in Curve's virtual_price as a reliable
/*LN-31*/  * value oracle when it can be manipulated within a single transaction.
/*LN-32*/  */
/*LN-33*/ 
/*LN-34*/ interface ICurve3Pool {
/*LN-35*/     function add_liquidity(
/*LN-36*/         uint256[3] memory amounts,
/*LN-37*/         uint256 min_mint_amount
/*LN-38*/     ) external;
/*LN-39*/ 
/*LN-40*/     function remove_liquidity_imbalance(
/*LN-41*/         uint256[3] memory amounts,
/*LN-42*/         uint256 max_burn_amount
/*LN-43*/     ) external;
/*LN-44*/ 
/*LN-45*/     function get_virtual_price() external view returns (uint256);
/*LN-46*/ }
/*LN-47*/ 
/*LN-48*/ interface IERC20 {
/*LN-49*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-50*/ 
/*LN-51*/     function transferFrom(
/*LN-52*/         address from,
/*LN-53*/         address to,
/*LN-54*/         uint256 amount
/*LN-55*/     ) external returns (bool);
/*LN-56*/ 
/*LN-57*/     function balanceOf(address account) external view returns (uint256);
/*LN-58*/ 
/*LN-59*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-60*/ }
/*LN-61*/ 
/*LN-62*/ contract VulnerableYearnVault {
/*LN-63*/     IERC20 public dai;
/*LN-64*/     IERC20 public crv3; // Curve 3pool LP token
/*LN-65*/     ICurve3Pool public curve3Pool;
/*LN-66*/ 
/*LN-67*/     mapping(address => uint256) public shares;
/*LN-68*/     uint256 public totalShares;
/*LN-69*/     uint256 public totalDeposits;
/*LN-70*/ 
/*LN-71*/     uint256 public constant MIN_EARN_THRESHOLD = 1000 ether;
/*LN-72*/ 
/*LN-73*/     constructor(address _dai, address _crv3, address _curve3Pool) {
/*LN-74*/         dai = IERC20(_dai);
/*LN-75*/         crv3 = IERC20(_crv3);
/*LN-76*/         curve3Pool = ICurve3Pool(_curve3Pool);
/*LN-77*/     }
/*LN-78*/ 
/*LN-79*/     /**
/*LN-80*/      * @notice Deposit DAI into the vault
/*LN-81*/      */
/*LN-82*/     function deposit(uint256 amount) external {
/*LN-83*/         dai.transferFrom(msg.sender, address(this), amount);
/*LN-84*/ 
/*LN-85*/         uint256 shareAmount;
/*LN-86*/         if (totalShares == 0) {
/*LN-87*/             shareAmount = amount;
/*LN-88*/         } else {
/*LN-89*/             // Calculate shares based on current vault value
/*LN-90*/             shareAmount = (amount * totalShares) / totalDeposits;
/*LN-91*/         }
/*LN-92*/ 
/*LN-93*/         shares[msg.sender] += shareAmount;
/*LN-94*/         totalShares += shareAmount;
/*LN-95*/         totalDeposits += amount;
/*LN-96*/     }
/*LN-97*/ 
/*LN-98*/     /**
/*LN-99*/      * @notice Execute vault strategy - deposit into Curve
/*LN-100*/      *
/*LN-101*/      * VULNERABILITY IS HERE:
/*LN-102*/      * The function uses Curve's get_virtual_price() to calculate strategy value.
/*LN-103*/      * This price can be manipulated through flash loan attacks that temporarily
/*LN-104*/      * imbalance the Curve pool.
/*LN-105*/      *
/*LN-106*/      * Vulnerable sequence:
/*LN-107*/      * 1. Check if vault has enough idle DAI (line 103)
/*LN-108*/      * 2. Get Curve virtual price (line 106) <- MANIPULABLE
/*LN-109*/      * 3. Add liquidity to Curve (line 109-111)
/*LN-110*/      * 4. Calculate expected LP tokens based on manipulated price
/*LN-111*/      * 5. Vault thinks it gained more value than it actually did
/*LN-112*/      *
/*LN-113*/      * Attacker exploits this by:
/*LN-114*/      * - Imbalancing Curve pool with flash loan
/*LN-115*/      * - Calling earn() while pool is imbalanced
/*LN-116*/      * - Vault uses inflated virtual_price
/*LN-117*/      * - Restoring pool balance
/*LN-118*/      * - Repeating to drain vault
/*LN-119*/      */
/*LN-120*/     function earn() external {
/*LN-121*/         uint256 vaultBalance = dai.balanceOf(address(this));
/*LN-122*/         require(
/*LN-123*/             vaultBalance >= MIN_EARN_THRESHOLD,
/*LN-124*/             "Insufficient balance to earn"
/*LN-125*/         );
/*LN-126*/ 
/*LN-127*/         // VULNERABLE: Using manipulable Curve virtual price
/*LN-128*/         uint256 virtualPrice = curve3Pool.get_virtual_price();
/*LN-129*/ 
/*LN-130*/         // Add all DAI to Curve pool
/*LN-131*/         dai.approve(address(curve3Pool), vaultBalance);
/*LN-132*/         uint256[3] memory amounts = [vaultBalance, 0, 0]; // Only DAI
/*LN-133*/         curve3Pool.add_liquidity(amounts, 0);
/*LN-134*/ 
/*LN-135*/         // The vault now thinks it has value based on the manipulated virtual price
/*LN-136*/         // If virtual_price is inflated, vault overestimates its holdings
/*LN-137*/     }
/*LN-138*/ 
/*LN-139*/     /**
/*LN-140*/      * @notice Withdraw shares from vault
/*LN-141*/      */
/*LN-142*/     function withdrawAll() external {
/*LN-143*/         uint256 userShares = shares[msg.sender];
/*LN-144*/         require(userShares > 0, "No shares");
/*LN-145*/ 
/*LN-146*/         // Calculate withdrawal amount based on current total value
/*LN-147*/         uint256 withdrawAmount = (userShares * totalDeposits) / totalShares;
/*LN-148*/ 
/*LN-149*/         shares[msg.sender] = 0;
/*LN-150*/         totalShares -= userShares;
/*LN-151*/         totalDeposits -= withdrawAmount;
/*LN-152*/ 
/*LN-153*/         dai.transfer(msg.sender, withdrawAmount);
/*LN-154*/     }
/*LN-155*/ 
/*LN-156*/     /**
/*LN-157*/      * @notice Get vault's total value including Curve position
/*LN-158*/      */
/*LN-159*/     function balance() public view returns (uint256) {
/*LN-160*/         return
/*LN-161*/             dai.balanceOf(address(this)) +
/*LN-162*/             (crv3.balanceOf(address(this)) * curve3Pool.get_virtual_price()) /
/*LN-163*/             1e18;
/*LN-164*/     }
/*LN-165*/ }
/*LN-166*/ 
/*LN-167*/ /**
/*LN-168*/  * Example attack flow:
/*LN-169*/  *
/*LN-170*/  * 1. Flash loan 100M DAI, 50M USDT, 50M USDC
/*LN-171*/  * 2. Add liquidity to Curve 3pool: [100M DAI, 50M USDC, 0 USDT]
/*LN-172*/  *    - This imbalances the pool and inflates virtual_price
/*LN-173*/  * 3. Deposit 1M DAI into yDAI vault
/*LN-174*/  * 4. Call vault.earn()
/*LN-175*/  *    - Vault uses inflated virtual_price to value position
/*LN-176*/  * 5. Remove liquidity from Curve imbalanced: [0, 0, 50M USDT]
/*LN-177*/  *    - Extract USDT, leaving pool imbalanced the other way
/*LN-178*/  * 6. Add liquidity back to normalize: [0, 0, 50M USDT]
/*LN-179*/  * 7. Repeat steps 2-6 multiple times
/*LN-180*/  *    - Each iteration siphons value from vault
/*LN-181*/  * 8. Withdraw from vault with inflated share value
/*LN-182*/  * 9. Repay flash loans, keep profit
/*LN-183*/  *
/*LN-184*/  * REAL-WORLD IMPACT:
/*LN-185*/  * - $11M stolen in February 2021
/*LN-186*/  * - Exploited Curve pool manipulation via flash loans
/*LN-187*/  * - Led to improved oracle designs in DeFi
/*LN-188*/  * - Yearn updated strategy to use TWAP instead of spot price
/*LN-189*/  *
/*LN-190*/  * FIX:
/*LN-191*/  * 1. Use Time-Weighted Average Price (TWAP) instead of spot price
/*LN-192*/  * 2. Implement slippage checks on Curve operations
/*LN-193*/  * 3. Use multiple price oracles and sanity checks
/*LN-194*/  * 4. Limit strategy execution frequency
/*LN-195*/  *
/*LN-196*/  * function earn() external {
/*LN-197*/  *     uint256 vaultBalance = dai.balanceOf(address(this));
/*LN-198*/  *     require(vaultBalance >= MIN_EARN_THRESHOLD, "Insufficient");
/*LN-199*/  *
/*LN-200*/  *     // FIX: Use TWAP oracle instead of spot price
/*LN-201*/  *     uint256 expectedPrice = twapOracle.getPrice();
/*LN-202*/  *     uint256 currentPrice = curve3Pool.get_virtual_price();
/*LN-203*/  *
/*LN-204*/  *     // Sanity check: current price shouldn't deviate too much from TWAP
/*LN-205*/  *     require(
/*LN-206*/  *         currentPrice <= expectedPrice * 102 / 100 &&
/*LN-207*/  *         currentPrice >= expectedPrice * 98 / 100,
/*LN-208*/  *         "Price manipulation detected"
/*LN-209*/  *     );
/*LN-210*/  *
/*LN-211*/  *     dai.approve(address(curve3Pool), vaultBalance);
/*LN-212*/  *     uint256[3] memory amounts = [vaultBalance, 0, 0];
/*LN-213*/  *
/*LN-214*/  *     // Add minimum slippage protection
/*LN-215*/  *     uint256 minLPTokens = (vaultBalance * 1e18) / expectedPrice * 99 / 100;
/*LN-216*/  *     curve3Pool.add_liquidity(amounts, minLPTokens);
/*LN-217*/  * }
/*LN-218*/  *
/*LN-219*/  *
/*LN-220*/  * KEY LESSON:
/*LN-221*/  * Never trust spot prices from AMM pools for critical calculations.
/*LN-222*/  * They can be manipulated within a single transaction using flash loans.
/*LN-223*/  * Always use TWAP oracles or multiple price sources with sanity checks.
/*LN-224*/  * Flash loan attacks can temporarily distort any spot price mechanism.
/*LN-225*/  */
/*LN-226*/ 