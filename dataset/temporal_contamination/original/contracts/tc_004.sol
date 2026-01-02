/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title Harvest Finance Vault (Vulnerable Version)
/*LN-6*/  * @notice This contract demonstrates the vulnerability that led to the $24M Harvest Finance hack
/*LN-7*/  * @dev October 26, 2020 - Flash loan price manipulation attack
/*LN-8*/  *
/*LN-9*/  * VULNERABILITY: Price manipulation via flash loan arbitrage
/*LN-10*/  *
/*LN-11*/  * ROOT CAUSE:
/*LN-12*/  * Harvest Finance vaults calculated the share price based on the total assets held,
/*LN-13*/  * which included assets in external AMM pools (Curve y pool). An attacker could:
/*LN-14*/  * 1. Take a flash loan
/*LN-15*/  * 2. Manipulate the price in the Curve pool
/*LN-16*/  * 3. Deposit into Harvest at the inflated price
/*LN-17*/  * 4. Reverse the manipulation
/*LN-18*/  * 5. Withdraw at a profit
/*LN-19*/  *
/*LN-20*/  * The vault's deposit/withdraw functions used spot prices from Curve without
/*LN-21*/  * considering slippage protection or time-weighted average prices (TWAP).
/*LN-22*/  *
/*LN-23*/  * ATTACK VECTOR:
/*LN-24*/  * 1. Attacker takes $50M USDC + $17M USDT flash loans from Uniswap
/*LN-25*/  * 2. Swaps USDT -> USDC on Curve, inflating USDC price
/*LN-26*/  * 3. Deposits 49M USDC into Harvest vault at inflated price (gets more fUSDC shares)
/*LN-27*/  * 4. Swaps USDC -> USDT on Curve, deflating USDC price
/*LN-28*/  * 5. Withdraws fUSDC from Harvest at normal price (gets more USDC than deposited)
/*LN-29*/  * 6. Repeats the cycle multiple times to amplify profit
/*LN-30*/  * 7. Repays flash loans, keeps profit (~$24M)
/*LN-31*/  */
/*LN-32*/ 
/*LN-33*/ interface ICurvePool {
/*LN-34*/     function exchange_underlying(
/*LN-35*/         int128 i,
/*LN-36*/         int128 j,
/*LN-37*/         uint256 dx,
/*LN-38*/         uint256 min_dy
/*LN-39*/     ) external returns (uint256);
/*LN-40*/ 
/*LN-41*/     function get_dy_underlying(
/*LN-42*/         int128 i,
/*LN-43*/         int128 j,
/*LN-44*/         uint256 dx
/*LN-45*/     ) external view returns (uint256);
/*LN-46*/ }
/*LN-47*/ 
/*LN-48*/ contract VulnerableHarvestVault {
/*LN-49*/     address public underlyingToken; // e.g., USDC
/*LN-50*/     ICurvePool public curvePool;
/*LN-51*/ 
/*LN-52*/     uint256 public totalSupply; // Total fUSDC shares
/*LN-53*/     mapping(address => uint256) public balanceOf;
/*LN-54*/ 
/*LN-55*/     // This tracks assets that are "working" in external protocols
/*LN-56*/     uint256 public investedBalance;
/*LN-57*/ 
/*LN-58*/     event Deposit(address indexed user, uint256 amount, uint256 shares);
/*LN-59*/     event Withdrawal(address indexed user, uint256 shares, uint256 amount);
/*LN-60*/ 
/*LN-61*/     constructor(address _token, address _curvePool) {
/*LN-62*/         underlyingToken = _token;
/*LN-63*/         curvePool = ICurvePool(_curvePool);
/*LN-64*/     }
/*LN-65*/ 
/*LN-66*/     /**
/*LN-67*/      * @notice Deposit tokens and receive vault shares
/*LN-68*/      * @param amount Amount of underlying tokens to deposit
/*LN-69*/      *
/*LN-70*/      * VULNERABILITY:
/*LN-71*/      * The share calculation uses getPricePerFullShare() which relies on
/*LN-72*/      * current pool balances. This can be manipulated via flash loans.
/*LN-73*/      */
/*LN-74*/     function deposit(uint256 amount) external returns (uint256 shares) {
/*LN-75*/         require(amount > 0, "Zero amount");
/*LN-76*/ 
/*LN-77*/         // Transfer tokens from user
/*LN-78*/         // IERC20(underlyingToken).transferFrom(msg.sender, address(this), amount);
/*LN-79*/ 
/*LN-80*/         // Calculate shares based on current price
/*LN-81*/         // VULNERABILITY: This price can be manipulated!
/*LN-82*/         if (totalSupply == 0) {
/*LN-83*/             shares = amount;
/*LN-84*/         } else {
/*LN-85*/             // shares = amount * totalSupply / totalAssets()
/*LN-86*/             // If totalAssets() is artificially inflated via Curve manipulation,
/*LN-87*/             // user gets fewer shares than they should
/*LN-88*/             uint256 totalAssets = getTotalAssets();
/*LN-89*/             shares = (amount * totalSupply) / totalAssets;
/*LN-90*/         }
/*LN-91*/ 
/*LN-92*/         balanceOf[msg.sender] += shares;
/*LN-93*/         totalSupply += shares;
/*LN-94*/ 
/*LN-95*/         // Strategy: Deploy funds to Curve for yield
/*LN-96*/         _investInCurve(amount);
/*LN-97*/ 
/*LN-98*/         emit Deposit(msg.sender, amount, shares);
/*LN-99*/         return shares;
/*LN-100*/     }
/*LN-101*/ 
/*LN-102*/     /**
/*LN-103*/      * @notice Withdraw underlying tokens by burning shares
/*LN-104*/      * @param shares Amount of vault shares to burn
/*LN-105*/      *
/*LN-106*/      * VULNERABILITY:
/*LN-107*/      * The withdraw amount calculation uses getPricePerFullShare() which can
/*LN-108*/      * be manipulated. After manipulating Curve prices downward, attacker
/*LN-109*/      * can withdraw more tokens than they should receive.
/*LN-110*/      */
/*LN-111*/     function withdraw(uint256 shares) external returns (uint256 amount) {
/*LN-112*/         require(shares > 0, "Zero shares");
/*LN-113*/         require(balanceOf[msg.sender] >= shares, "Insufficient balance");
/*LN-114*/ 
/*LN-115*/         // Calculate amount based on current price
/*LN-116*/         // VULNERABILITY: This price can be manipulated!
/*LN-117*/         uint256 totalAssets = getTotalAssets();
/*LN-118*/         amount = (shares * totalAssets) / totalSupply;
/*LN-119*/ 
/*LN-120*/         balanceOf[msg.sender] -= shares;
/*LN-121*/         totalSupply -= shares;
/*LN-122*/ 
/*LN-123*/         // Withdraw from Curve strategy if needed
/*LN-124*/         _withdrawFromCurve(amount);
/*LN-125*/ 
/*LN-126*/         // Transfer tokens to user
/*LN-127*/         // IERC20(underlyingToken).transfer(msg.sender, amount);
/*LN-128*/ 
/*LN-129*/         emit Withdrawal(msg.sender, shares, amount);
/*LN-130*/         return amount;
/*LN-131*/     }
/*LN-132*/ 
/*LN-133*/     /**
/*LN-134*/      * @notice Get total assets under management
/*LN-135*/      * @dev VULNERABILITY: Uses spot prices from Curve, subject to manipulation
/*LN-136*/      */
/*LN-137*/     function getTotalAssets() public view returns (uint256) {
/*LN-138*/         // Assets in vault + assets in Curve
/*LN-139*/         // In reality, Harvest calculated this including Curve pool values
/*LN-140*/         // which could be manipulated via large swaps
/*LN-141*/ 
/*LN-142*/         uint256 vaultBalance = 0; // IERC20(underlyingToken).balanceOf(address(this));
/*LN-143*/         uint256 curveBalance = investedBalance;
/*LN-144*/ 
/*LN-145*/         // VULNERABILITY: curveBalance value can be inflated by manipulating
/*LN-146*/         // the Curve pool's exchange rates
/*LN-147*/         return vaultBalance + curveBalance;
/*LN-148*/     }
/*LN-149*/ 
/*LN-150*/     /**
/*LN-151*/      * @notice Get price per share
/*LN-152*/      * @dev VULNERABILITY: Manipulable via Curve price manipulation
/*LN-153*/      */
/*LN-154*/     function getPricePerFullShare() public view returns (uint256) {
/*LN-155*/         if (totalSupply == 0) return 1e18;
/*LN-156*/         return (getTotalAssets() * 1e18) / totalSupply;
/*LN-157*/     }
/*LN-158*/ 
/*LN-159*/     /**
/*LN-160*/      * @notice Internal function to invest in Curve
/*LN-161*/      * @dev Simplified - in reality, Harvest used Curve pools for yield
/*LN-162*/      */
/*LN-163*/     function _investInCurve(uint256 amount) internal {
/*LN-164*/         investedBalance += amount;
/*LN-165*/ 
/*LN-166*/         // In reality, this would:
/*LN-167*/         // 1. Add liquidity to Curve pool
/*LN-168*/         // 2. Stake LP tokens
/*LN-169*/         // 3. Track the invested amount
/*LN-170*/     }
/*LN-171*/ 
/*LN-172*/     /**
/*LN-173*/      * @notice Internal function to withdraw from Curve
/*LN-174*/      * @dev Simplified - in reality, would unstake and remove liquidity
/*LN-175*/      */
/*LN-176*/     function _withdrawFromCurve(uint256 amount) internal {
/*LN-177*/         require(investedBalance >= amount, "Insufficient invested");
/*LN-178*/         investedBalance -= amount;
/*LN-179*/ 
/*LN-180*/         // In reality, this would:
/*LN-181*/         // 1. Unstake LP tokens
/*LN-182*/         // 2. Remove liquidity from Curve
/*LN-183*/         // 3. Get underlying tokens back
/*LN-184*/     }
/*LN-185*/ }
/*LN-186*/ 
/*LN-187*/ /**
/*LN-188*/  * REAL-WORLD IMPACT:
/*LN-189*/  * - $24M stolen on October 26, 2020
/*LN-190*/  * - Attacker repeated the attack cycle 6 times to maximize profit
/*LN-191*/  * - Used flash loans from Uniswap V2 ($50M USDC + $17M USDT)
/*LN-192*/  * - Manipulated Curve y pool prices via large swaps
/*LN-193*/  * - One of the first major flash loan price manipulation attacks
/*LN-194*/  *
/*LN-195*/  * FIX:
/*LN-196*/  * The fix requires:
/*LN-197*/  * 1. Use Time-Weighted Average Price (TWAP) oracles instead of spot prices
/*LN-198*/  * 2. Implement deposit/withdrawal fees to make flash loan attacks unprofitable
/*LN-199*/  * 3. Add slippage protection on swaps
/*LN-200*/  * 4. Limit maximum deposit/withdrawal amounts per block
/*LN-201*/  * 5. Use multiple price sources (Chainlink, etc.) not just AMM pools
/*LN-202*/  * 6. Implement commit-reveal pattern for deposits/withdrawals
/*LN-203*/  * 7. Add time delay between deposit and withdrawal
/*LN-204*/  *
/*LN-205*/  * KEY LESSON:
/*LN-206*/  * Vaults that use AMM pool prices for accounting are vulnerable to flash loan
/*LN-207*/  * manipulation. Spot prices can be manipulated within a single transaction,
/*LN-208*/  * allowing attackers to deposit at inflated prices and withdraw at deflated
/*LN-209*/  * prices (or vice versa).
/*LN-210*/  *
/*LN-211*/  * The attack demonstrates the importance of oracle manipulation resistance.
/*LN-212*/  * Any protocol that uses AMM spot prices for critical calculations is at risk.
/*LN-213*/  *
/*LN-214*/  *
/*LN-215*/  * ATTACK FLOW:
/*LN-216*/  * 1. Flash loan 50M USDC + 17M USDT
/*LN-217*/  * 2. Swap USDT -> USDC on Curve (inflates USDC value in pool)
/*LN-218*/  * 3. Deposit 49M USDC to Harvest (gets shares at inflated price - more shares)
/*LN-219*/  * 4. Swap USDC -> USDT on Curve (deflates USDC value in pool)
/*LN-220*/  * 5. Withdraw shares from Harvest (gets more USDC than deposited)
/*LN-221*/  * 6. Repeat steps 2-5 six times
/*LN-222*/  * 7. Repay flash loans, profit ~$24M
/*LN-223*/  */
/*LN-224*/ 