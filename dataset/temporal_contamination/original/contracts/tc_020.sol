/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * ALPHA HOMORA EXPLOIT (February 2021)
/*LN-6*/  *
/*LN-7*/  * Attack Vector: Credit Account Manipulation via Iron Bank Integration
/*LN-8*/  * Loss: $37 million
/*LN-9*/  *
/*LN-10*/  * VULNERABILITY:
/*LN-11*/  * Alpha Homora V2 integrated with Cream Finance's Iron Bank as a lending
/*LN-12*/  * protocol. The vulnerability was in how credit accounts were tracked when
/*LN-13*/  * users borrowed through leveraged yield farming positions.
/*LN-14*/  *
/*LN-15*/  * The attacker exploited a flaw in the debt calculation mechanism that
/*LN-16*/  * allowed them to borrow far more than their collateral was worth by
/*LN-17*/  * manipulating the share-to-amount conversion in the lending pool.
/*LN-18*/  *
/*LN-19*/  * Attack Steps:
/*LN-20*/  * 1. Open leveraged farming position on Alpha Homora
/*LN-21*/  * 2. Manipulate sUSD/USDC pool reserves via large swap
/*LN-22*/  * 3. Exploit debt share calculation to borrow excessive amounts
/*LN-23*/  * 4. Drain Iron Bank reserves backing the position
/*LN-24*/  * 5. Profit from overborrowed funds
/*LN-25*/  */
/*LN-26*/ 
/*LN-27*/ interface IERC20 {
/*LN-28*/     function balanceOf(address account) external view returns (uint256);
/*LN-29*/ 
/*LN-30*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-31*/ 
/*LN-32*/     function transferFrom(
/*LN-33*/         address from,
/*LN-34*/         address to,
/*LN-35*/         uint256 amount
/*LN-36*/     ) external returns (bool);
/*LN-37*/ }
/*LN-38*/ 
/*LN-39*/ interface ICErc20 {
/*LN-40*/     function borrow(uint256 amount) external returns (uint256);
/*LN-41*/ 
/*LN-42*/     function borrowBalanceCurrent(address account) external returns (uint256);
/*LN-43*/ }
/*LN-44*/ 
/*LN-45*/ contract AlphaHomoraBank {
/*LN-46*/     struct Position {
/*LN-47*/         address owner;
/*LN-48*/         uint256 collateral;
/*LN-49*/         uint256 debtShare;
/*LN-50*/     }
/*LN-51*/ 
/*LN-52*/     mapping(uint256 => Position) public positions;
/*LN-53*/     uint256 public nextPositionId;
/*LN-54*/ 
/*LN-55*/     address public cToken;
/*LN-56*/     uint256 public totalDebt;
/*LN-57*/     uint256 public totalDebtShare;
/*LN-58*/ 
/*LN-59*/     constructor(address _cToken) {
/*LN-60*/         cToken = _cToken;
/*LN-61*/         nextPositionId = 1;
/*LN-62*/     }
/*LN-63*/ 
/*LN-64*/     /**
/*LN-65*/      * @notice Open a leveraged position
/*LN-66*/      */
/*LN-67*/     function openPosition(
/*LN-68*/         uint256 collateralAmount,
/*LN-69*/         uint256 borrowAmount
/*LN-70*/     ) external returns (uint256 positionId) {
/*LN-71*/         positionId = nextPositionId++;
/*LN-72*/ 
/*LN-73*/         positions[positionId] = Position({
/*LN-74*/             owner: msg.sender,
/*LN-75*/             collateral: collateralAmount,
/*LN-76*/             debtShare: 0
/*LN-77*/         });
/*LN-78*/ 
/*LN-79*/         // User provides collateral (simplified)
/*LN-80*/         // In real Alpha Homora, this would involve LP tokens
/*LN-81*/ 
/*LN-82*/         // Borrow from Iron Bank
/*LN-83*/         _borrow(positionId, borrowAmount);
/*LN-84*/ 
/*LN-85*/         return positionId;
/*LN-86*/     }
/*LN-87*/ 
/*LN-88*/     /**
/*LN-89*/      * @notice VULNERABLE: Borrow function with flawed share calculation
/*LN-90*/      * @dev Debt shares are calculated incorrectly when totalDebt is manipulated
/*LN-91*/      */
/*LN-92*/     function _borrow(uint256 positionId, uint256 amount) internal {
/*LN-93*/         Position storage pos = positions[positionId];
/*LN-94*/ 
/*LN-95*/         // Calculate debt shares for this borrow
/*LN-96*/         uint256 share;
/*LN-97*/ 
/*LN-98*/         if (totalDebtShare == 0) {
/*LN-99*/             share = amount;
/*LN-100*/         } else {
/*LN-101*/             // VULNERABILITY: This calculation is vulnerable when totalDebt
/*LN-102*/             // has been manipulated via external pool state changes
/*LN-103*/             share = (amount * totalDebtShare) / totalDebt;
/*LN-104*/         }
/*LN-105*/ 
/*LN-106*/         pos.debtShare += share;
/*LN-107*/         totalDebtShare += share;
/*LN-108*/         totalDebt += amount;
/*LN-109*/ 
/*LN-110*/         // Borrow from Iron Bank (Cream Finance)
/*LN-111*/         ICErc20(cToken).borrow(amount);
/*LN-112*/     }
/*LN-113*/ 
/*LN-114*/     /**
/*LN-115*/      * @notice Repay debt for a position
/*LN-116*/      */
/*LN-117*/     function repay(uint256 positionId, uint256 amount) external {
/*LN-118*/         Position storage pos = positions[positionId];
/*LN-119*/         require(msg.sender == pos.owner, "Not position owner");
/*LN-120*/ 
/*LN-121*/         // Calculate how many shares this repayment covers
/*LN-122*/         uint256 shareToRemove = (amount * totalDebtShare) / totalDebt;
/*LN-123*/ 
/*LN-124*/         require(pos.debtShare >= shareToRemove, "Excessive repayment");
/*LN-125*/ 
/*LN-126*/         pos.debtShare -= shareToRemove;
/*LN-127*/         totalDebtShare -= shareToRemove;
/*LN-128*/         totalDebt -= amount;
/*LN-129*/ 
/*LN-130*/         // Transfer tokens from user (simplified)
/*LN-131*/     }
/*LN-132*/ 
/*LN-133*/     /**
/*LN-134*/      * @notice Get current debt amount for a position
/*LN-135*/      * @dev VULNERABLE: Returns debt based on current share ratio
/*LN-136*/      */
/*LN-137*/     function getPositionDebt(
/*LN-138*/         uint256 positionId
/*LN-139*/     ) external view returns (uint256) {
/*LN-140*/         Position storage pos = positions[positionId];
/*LN-141*/ 
/*LN-142*/         if (totalDebtShare == 0) return 0;
/*LN-143*/ 
/*LN-144*/         // Debt calculation based on current share
/*LN-145*/         // VULNERABILITY: If attacker manipulates totalDebt down, their debt appears smaller
/*LN-146*/         return (pos.debtShare * totalDebt) / totalDebtShare;
/*LN-147*/     }
/*LN-148*/ 
/*LN-149*/     /**
/*LN-150*/      * @notice Liquidate an unhealthy position
/*LN-151*/      */
/*LN-152*/     function liquidate(uint256 positionId) external {
/*LN-153*/         Position storage pos = positions[positionId];
/*LN-154*/ 
/*LN-155*/         uint256 debt = (pos.debtShare * totalDebt) / totalDebtShare;
/*LN-156*/ 
/*LN-157*/         // Check if position is underwater
/*LN-158*/         // Simplified: collateral should be > 150% of debt
/*LN-159*/         require(pos.collateral * 100 < debt * 150, "Position is healthy");
/*LN-160*/ 
/*LN-161*/         // Liquidate and transfer collateral to liquidator
/*LN-162*/         pos.collateral = 0;
/*LN-163*/         pos.debtShare = 0;
/*LN-164*/     }
/*LN-165*/ }
/*LN-166*/ 
/*LN-167*/ /**
/*LN-168*/  * EXPLOIT SCENARIO:
/*LN-169*/  *
/*LN-170*/  * Initial State:
/*LN-171*/  * - Alpha Homora integrated with Iron Bank (Cream)
/*LN-172*/  * - Users can open leveraged yield farming positions
/*LN-173*/  * - totalDebt: 100M, totalDebtShare: 100M (1:1 ratio)
/*LN-174*/  *
/*LN-175*/  * Attack:
/*LN-176*/  * 1. Attacker opens initial position:
/*LN-177*/  *    - Deposits 10 ETH collateral
/*LN-178*/  *    - Borrows 1M USDC
/*LN-179*/  *    - Gets debtShare = (1M * 100M) / 100M = 1M shares
/*LN-180*/  *    - totalDebt now 101M, totalDebtShare 101M
/*LN-181*/  *
/*LN-182*/  * 2. Attacker manipulates external pool (sUSD/USDC):
/*LN-183*/  *    - Uses flash loan to massively imbalance pool
/*LN-184*/  *    - This affects how Iron Bank calculates borrowed amounts
/*LN-185*/  *    - Due to integration complexity, totalDebt value becomes stale/incorrect
/*LN-186*/  *
/*LN-187*/  * 3. Critical exploitation - opening second position:
/*LN-188*/  *    - Due to pool manipulation, when calculating new debt shares:
/*LN-189*/  *    - totalDebt appears much larger than it should be (e.g., 200M instead of 101M)
/*LN-190*/  *    - Attacker borrows another 10M USDC
/*LN-191*/  *    - Share calculation: (10M * 101M) / 200M = 5.05M shares
/*LN-192*/  *    - Should have been: (10M * 101M) / 101M = 10M shares
/*LN-193*/  *
/*LN-194*/  * 4. Result:
/*LN-195*/  *    - Attacker borrowed 11M USDC total
/*LN-196*/  *    - But only has 6.05M debt shares
/*LN-197*/  *    - When shares are converted back to debt:
/*LN-198*/  *      debt = (6.05M * 101M) / 101M = 6.05M
/*LN-199*/  *    - Attacker appears to owe only 6.05M instead of 11M!
/*LN-200*/  *
/*LN-201*/  * 5. Attacker can now:
/*LN-202*/  *    - Repay the calculated "debt" of 6.05M
/*LN-203*/  *    - Close position and withdraw collateral
/*LN-204*/  *    - Keep the difference: 11M - 6.05M = 4.95M profit
/*LN-205*/  *    - Repeat multiple times to drain $37M
/*LN-206*/  *
/*LN-207*/  * Root Cause:
/*LN-208*/  * - Debt share calculation relied on totalDebt value
/*LN-209*/  * - totalDebt could be manipulated via external pool state
/*LN-210*/  * - Share-to-amount conversion was vulnerable to manipulation
/*LN-211*/  * - Lack of synchronization between Iron Bank and Alpha Homora accounting
/*LN-212*/  *
/*LN-213*/  * Fix:
/*LN-214*/  * - Use time-weighted average for debt calculations
/*LN-215*/  * - Implement debt ceilings per position
/*LN-216*/  * - Add manipulation-resistant accounting
/*LN-217*/  * - Separate internal debt tracking from external pool states
/*LN-218*/  * - Implement sanity checks on debt share calculations
/*LN-219*/  */
/*LN-220*/ 