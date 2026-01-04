/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * WISE LENDING EXPLOIT (January 2024)
/*LN-6*/  * Loss: $460,000
/*LN-7*/  * Attack: Share Rounding Error Through Pool State Manipulation
/*LN-8*/  *
/*LN-9*/  * Wise Lending is a lending protocol with deposit shares. Attackers manipulated
/*LN-10*/  * the pool state by setting pseudoTotalPool to 2 wei and totalDepositShares to 1 wei,
/*LN-11*/  * then exploited rounding errors in share calculations to extract more tokens than deposited.
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
/*LN-28*/ interface IERC721 {
/*LN-29*/     function transferFrom(address from, address to, uint256 tokenId) external;
/*LN-30*/ 
/*LN-31*/     function ownerOf(uint256 tokenId) external view returns (address);
/*LN-32*/ }
/*LN-33*/ 
/*LN-34*/ contract WiseLending {
/*LN-35*/     struct PoolData {
/*LN-36*/         uint256 pseudoTotalPool;
/*LN-37*/         uint256 totalDepositShares;
/*LN-38*/         uint256 totalBorrowShares;
/*LN-39*/         uint256 collateralFactor;
/*LN-40*/     }
/*LN-41*/ 
/*LN-42*/     mapping(address => PoolData) public lendingPoolData;
/*LN-43*/     mapping(uint256 => mapping(address => uint256)) public userLendingShares;
/*LN-44*/     mapping(uint256 => mapping(address => uint256)) public userBorrowShares;
/*LN-45*/ 
/*LN-46*/     IERC721 public positionNFTs;
/*LN-47*/     uint256 public nftIdCounter;
/*LN-48*/ 
/*LN-49*/     /**
/*LN-50*/      * @notice Mint position NFT
/*LN-51*/      */
/*LN-52*/     function mintPosition() external returns (uint256) {
/*LN-53*/         uint256 nftId = ++nftIdCounter;
/*LN-54*/         return nftId;
/*LN-55*/     }
/*LN-56*/ 
/*LN-57*/     /**
/*LN-58*/      * @notice Deposit exact amount of tokens
/*LN-59*/      * @dev VULNERABLE: Share calculation with rounding errors
/*LN-60*/      */
/*LN-61*/     function depositExactAmount(
/*LN-62*/         uint256 _nftId,
/*LN-63*/         address _poolToken,
/*LN-64*/         uint256 _amount
/*LN-65*/     ) external returns (uint256 shareAmount) {
/*LN-66*/         IERC20(_poolToken).transferFrom(msg.sender, address(this), _amount);
/*LN-67*/ 
/*LN-68*/         PoolData storage pool = lendingPoolData[_poolToken];
/*LN-69*/ 
/*LN-70*/         // VULNERABILITY 1: When pseudoTotalPool and totalDepositShares are very small
/*LN-71*/         // (e.g., 2 wei and 1 wei), rounding errors become significant
/*LN-72*/ 
/*LN-73*/         if (pool.totalDepositShares == 0) {
/*LN-74*/             shareAmount = _amount;
/*LN-75*/             pool.totalDepositShares = _amount;
/*LN-76*/         } else {
/*LN-77*/             // VULNERABILITY 2: Integer division rounding
/*LN-78*/             // shareAmount = (_amount * totalDepositShares) / pseudoTotalPool
/*LN-79*/             // When pseudoTotalPool = 2, totalDepositShares = 1:
/*LN-80*/             // Large deposits get rounded down significantly
/*LN-81*/             shareAmount =
/*LN-82*/                 (_amount * pool.totalDepositShares) /
/*LN-83*/                 pool.pseudoTotalPool;
/*LN-84*/             pool.totalDepositShares += shareAmount;
/*LN-85*/         }
/*LN-86*/ 
/*LN-87*/         pool.pseudoTotalPool += _amount;
/*LN-88*/         userLendingShares[_nftId][_poolToken] += shareAmount;
/*LN-89*/ 
/*LN-90*/         return shareAmount;
/*LN-91*/     }
/*LN-92*/ 
/*LN-93*/     /**
/*LN-94*/      * @notice Withdraw exact shares amount
/*LN-95*/      * @dev VULNERABLE: Withdrawal returns more tokens than deposited due to rounding
/*LN-96*/      */
/*LN-97*/     function withdrawExactShares(
/*LN-98*/         uint256 _nftId,
/*LN-99*/         address _poolToken,
/*LN-100*/         uint256 _shares
/*LN-101*/     ) external returns (uint256 withdrawAmount) {
/*LN-102*/         require(
/*LN-103*/             userLendingShares[_nftId][_poolToken] >= _shares,
/*LN-104*/             "Insufficient shares"
/*LN-105*/         );
/*LN-106*/ 
/*LN-107*/         PoolData storage pool = lendingPoolData[_poolToken];
/*LN-108*/ 
/*LN-109*/         // VULNERABILITY 3: Reverse calculation amplifies rounding errors
/*LN-110*/         // withdrawAmount = (_shares * pseudoTotalPool) / totalDepositShares
/*LN-111*/         // When pool state is manipulated (2 wei / 1 wei ratio):
/*LN-112*/         // Withdrawing 1 share returns 2 wei worth of tokens
/*LN-113*/         // But depositor received fewer shares due to rounding down
/*LN-114*/ 
/*LN-115*/         withdrawAmount =
/*LN-116*/             (_shares * pool.pseudoTotalPool) /
/*LN-117*/             pool.totalDepositShares;
/*LN-118*/ 
/*LN-119*/         userLendingShares[_nftId][_poolToken] -= _shares;
/*LN-120*/         pool.totalDepositShares -= _shares;
/*LN-121*/         pool.pseudoTotalPool -= withdrawAmount;
/*LN-122*/ 
/*LN-123*/         IERC20(_poolToken).transfer(msg.sender, withdrawAmount);
/*LN-124*/ 
/*LN-125*/         return withdrawAmount;
/*LN-126*/     }
/*LN-127*/ 
/*LN-128*/     /**
/*LN-129*/      * @notice Withdraw exact amount of tokens
/*LN-130*/      * @dev Also vulnerable to same rounding issues
/*LN-131*/      */
/*LN-132*/     function withdrawExactAmount(
/*LN-133*/         uint256 _nftId,
/*LN-134*/         address _poolToken,
/*LN-135*/         uint256 _withdrawAmount
/*LN-136*/     ) external returns (uint256 shareBurned) {
/*LN-137*/         PoolData storage pool = lendingPoolData[_poolToken];
/*LN-138*/ 
/*LN-139*/         // VULNERABILITY 4: Calculating shares to burn has rounding issues
/*LN-140*/         shareBurned =
/*LN-141*/             (_withdrawAmount * pool.totalDepositShares) /
/*LN-142*/             pool.pseudoTotalPool;
/*LN-143*/ 
/*LN-144*/         require(
/*LN-145*/             userLendingShares[_nftId][_poolToken] >= shareBurned,
/*LN-146*/             "Insufficient shares"
/*LN-147*/         );
/*LN-148*/ 
/*LN-149*/         userLendingShares[_nftId][_poolToken] -= shareBurned;
/*LN-150*/         pool.totalDepositShares -= shareBurned;
/*LN-151*/         pool.pseudoTotalPool -= _withdrawAmount;
/*LN-152*/ 
/*LN-153*/         IERC20(_poolToken).transfer(msg.sender, _withdrawAmount);
/*LN-154*/ 
/*LN-155*/         return shareBurned;
/*LN-156*/     }
/*LN-157*/ 
/*LN-158*/     /**
/*LN-159*/      * @notice Get position lending shares
/*LN-160*/      */
/*LN-161*/     function getPositionLendingShares(
/*LN-162*/         uint256 _nftId,
/*LN-163*/         address _poolToken
/*LN-164*/     ) external view returns (uint256) {
/*LN-165*/         return userLendingShares[_nftId][_poolToken];
/*LN-166*/     }
/*LN-167*/ 
/*LN-168*/     /**
/*LN-169*/      * @notice Get total pool balance
/*LN-170*/      */
/*LN-171*/     function getTotalPool(address _poolToken) external view returns (uint256) {
/*LN-172*/         return lendingPoolData[_poolToken].pseudoTotalPool;
/*LN-173*/     }
/*LN-174*/ }
/*LN-175*/ 
/*LN-176*/ /**
/*LN-177*/  * EXPLOIT SCENARIO:
/*LN-178*/  *
/*LN-179*/  * 1. Attacker prepares pool state manipulation:
/*LN-180*/  *    - Mint position NFT #8
/*LN-181*/  *    - Make small deposits to establish position
/*LN-182*/  *    - Withdraw most shares, leaving pool in bad state:
/*LN-183*/  *      * pseudoTotalPool = 2 wei
/*LN-184*/  *      * totalDepositShares = 1 wei
/*LN-185*/  *      * Ratio = 2:1 (2 tokens per share)
/*LN-186*/  *
/*LN-187*/  * 2. Transfer position NFT to exploit contract:
/*LN-188*/  *    - Position #8 now has favorable pool state set up
/*LN-189*/  *
/*LN-190*/  * 3. Deposit large amount (520 Pendle LP tokens):
/*LN-191*/  *    - Approve and deposit into LP wrapper
/*LN-192*/  *    - Deposit LP tokens into Wise Lending
/*LN-193*/  *    - Share calculation: shares = (amount * 1) / 2
/*LN-194*/  *    - Due to division rounding, receives fewer shares than deserved
/*LN-195*/  *    - Example: 520 tokens → 260 shares (should be ~520)
/*LN-196*/  *
/*LN-197*/  * 4. Withdraw shares immediately:
/*LN-198*/  *    - Call withdrawExactShares with received share amount
/*LN-199*/  *    - Withdrawal calculation: amount = (260 * pseudoTotalPool) / 1
/*LN-200*/  *    - Due to manipulated 2:1 ratio, gets 2x tokens back
/*LN-201*/  *    - Receives 520+ tokens from 260 shares
/*LN-202*/  *
/*LN-203*/  * 5. Repeat exploit multiple times:
/*LN-204*/  *    - Use helper contracts to compound the effect
/*LN-205*/  *    - Each iteration extracts more value due to rounding
/*LN-206*/  *    - Pool state degrades further with each cycle
/*LN-207*/  *
/*LN-208*/  * 6. Final profit extraction:
/*LN-209*/  *    - Convert Pendle LP back to underlying assets
/*LN-210*/  *    - Drain $460K total from manipulated rounding
/*LN-211*/  *
/*LN-212*/  * Root Causes:
/*LN-213*/  * - Unbounded share/pool ratio manipulation
/*LN-214*/  * - Integer division rounding without minimum checks
/*LN-215*/  * - No minimum pool size enforcement
/*LN-216*/  * - Missing invariant checks (share value should not exceed deposits)
/*LN-217*/  * - No limits on share:pool ratio
/*LN-218*/  * - Lack of precision in calculations (should use higher decimals)
/*LN-219*/  *
/*LN-220*/  * Fix:
/*LN-221*/  * - Enforce minimum pool size (e.g., 1e18 wei minimum)
/*LN-222*/  * - Add invariant checks: withdrawAmount <= depositAmount
/*LN-223*/  * - Implement share:pool ratio bounds checking
/*LN-224*/  * - Use higher precision calculations (e.g., 1e27 instead of 1e18)
/*LN-225*/  * - Add rounding direction checks (always favor protocol)
/*LN-226*/  * - Implement circuit breakers for unusual share calculations
/*LN-227*/  * - Add withdrawal delays after deposits
/*LN-228*/  * - Monitor for rapid deposit/withdrawal cycles
/*LN-229*/  */
/*LN-230*/ 