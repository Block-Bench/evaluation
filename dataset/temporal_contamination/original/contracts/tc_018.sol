/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * DODO REINITALIZATION EXPLOIT (March 2021)
/*LN-6*/  *
/*LN-7*/  * Attack Vector: Reinitialization Vulnerability
/*LN-8*/  * Loss: $3.8 million
/*LN-9*/  *
/*LN-10*/  * VULNERABILITY:
/*LN-11*/  * DODO's liquidity pool contract had an init() function that could be called
/*LN-12*/  * multiple times without proper access control. The initialization function
/*LN-13*/  * set critical parameters including fee recipient addresses and token balances.
/*LN-14*/  *
/*LN-15*/  * An attacker could call init() again after deployment, setting themselves
/*LN-16*/  * as the fee recipient or manipulating pool parameters to drain funds.
/*LN-17*/  *
/*LN-18*/  * Attack Steps:
/*LN-19*/  * 1. Identify DODO pool contract without initialization lock
/*LN-20*/  * 2. Call init() with attacker-controlled parameters
/*LN-21*/  * 3. Set maintainer/fee recipient to attacker address
/*LN-22*/  * 4. Execute swaps or claim accumulated fees
/*LN-23*/  * 5. Drain funds from pool
/*LN-24*/  */
/*LN-25*/ 
/*LN-26*/ interface IERC20 {
/*LN-27*/     function balanceOf(address account) external view returns (uint256);
/*LN-28*/ 
/*LN-29*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-30*/ 
/*LN-31*/     function transferFrom(
/*LN-32*/         address from,
/*LN-33*/         address to,
/*LN-34*/         uint256 amount
/*LN-35*/     ) external returns (bool);
/*LN-36*/ }
/*LN-37*/ 
/*LN-38*/ contract DODOPool {
/*LN-39*/     address public maintainer;
/*LN-40*/     address public baseToken;
/*LN-41*/     address public quoteToken;
/*LN-42*/ 
/*LN-43*/     uint256 public lpFeeRate;
/*LN-44*/     uint256 public baseBalance;
/*LN-45*/     uint256 public quoteBalance;
/*LN-46*/ 
/*LN-47*/     bool public isInitialized;
/*LN-48*/ 
/*LN-49*/     event Initialized(address maintainer, address base, address quote);
/*LN-50*/ 
/*LN-51*/     /**
/*LN-52*/      * @notice VULNERABLE: init() can be called multiple times
/*LN-53*/      * @dev Missing `require(!isInitialized)` check allows reinitialization
/*LN-54*/      *
/*LN-55*/      * This function sets critical pool parameters including the maintainer
/*LN-56*/      * address (fee recipient). Without proper protection, attackers can
/*LN-57*/      * call it again to hijack the pool.
/*LN-58*/      */
/*LN-59*/     function init(
/*LN-60*/         address _maintainer,
/*LN-61*/         address _baseToken,
/*LN-62*/         address _quoteToken,
/*LN-63*/         uint256 _lpFeeRate
/*LN-64*/     ) external {
/*LN-65*/         // VULNERABILITY: Missing initialization check!
/*LN-66*/         // Should have: require(!isInitialized, "Already initialized");
/*LN-67*/ 
/*LN-68*/         maintainer = _maintainer;
/*LN-69*/         baseToken = _baseToken;
/*LN-70*/         quoteToken = _quoteToken;
/*LN-71*/         lpFeeRate = _lpFeeRate;
/*LN-72*/ 
/*LN-73*/         // Even though we set isInitialized = true, the damage is done
/*LN-74*/         // The attacker has already changed the maintainer address
/*LN-75*/         isInitialized = true;
/*LN-76*/ 
/*LN-77*/         emit Initialized(_maintainer, _baseToken, _quoteToken);
/*LN-78*/     }
/*LN-79*/ 
/*LN-80*/     /**
/*LN-81*/      * @notice Add liquidity to pool
/*LN-82*/      */
/*LN-83*/     function addLiquidity(uint256 baseAmount, uint256 quoteAmount) external {
/*LN-84*/         require(isInitialized, "Not initialized");
/*LN-85*/ 
/*LN-86*/         IERC20(baseToken).transferFrom(msg.sender, address(this), baseAmount);
/*LN-87*/         IERC20(quoteToken).transferFrom(msg.sender, address(this), quoteAmount);
/*LN-88*/ 
/*LN-89*/         baseBalance += baseAmount;
/*LN-90*/         quoteBalance += quoteAmount;
/*LN-91*/     }
/*LN-92*/ 
/*LN-93*/     /**
/*LN-94*/      * @notice Swap tokens
/*LN-95*/      */
/*LN-96*/     function swap(
/*LN-97*/         address fromToken,
/*LN-98*/         address toToken,
/*LN-99*/         uint256 fromAmount
/*LN-100*/     ) external returns (uint256 toAmount) {
/*LN-101*/         require(isInitialized, "Not initialized");
/*LN-102*/         require(
/*LN-103*/             (fromToken == baseToken && toToken == quoteToken) ||
/*LN-104*/                 (fromToken == quoteToken && toToken == baseToken),
/*LN-105*/             "Invalid token pair"
/*LN-106*/         );
/*LN-107*/ 
/*LN-108*/         // Transfer tokens in
/*LN-109*/         IERC20(fromToken).transferFrom(msg.sender, address(this), fromAmount);
/*LN-110*/ 
/*LN-111*/         // Calculate swap amount (simplified constant product)
/*LN-112*/         if (fromToken == baseToken) {
/*LN-113*/             toAmount = (quoteBalance * fromAmount) / (baseBalance + fromAmount);
/*LN-114*/             baseBalance += fromAmount;
/*LN-115*/             quoteBalance -= toAmount;
/*LN-116*/         } else {
/*LN-117*/             toAmount = (baseBalance * fromAmount) / (quoteBalance + fromAmount);
/*LN-118*/             quoteBalance += fromAmount;
/*LN-119*/             baseBalance -= toAmount;
/*LN-120*/         }
/*LN-121*/ 
/*LN-122*/         // Deduct fee for maintainer
/*LN-123*/         uint256 fee = (toAmount * lpFeeRate) / 10000;
/*LN-124*/         toAmount -= fee;
/*LN-125*/ 
/*LN-126*/         // Transfer tokens out
/*LN-127*/         IERC20(toToken).transfer(msg.sender, toAmount);
/*LN-128*/ 
/*LN-129*/         // VULNERABILITY: Fees accumulate for maintainer
/*LN-130*/         // If attacker reinitialized and set themselves as maintainer,
/*LN-131*/         // they can claim all fees
/*LN-132*/         IERC20(toToken).transfer(maintainer, fee);
/*LN-133*/ 
/*LN-134*/         return toAmount;
/*LN-135*/     }
/*LN-136*/ 
/*LN-137*/     /**
/*LN-138*/      * @notice Claim accumulated fees (simplified)
/*LN-139*/      */
/*LN-140*/     function claimFees() external {
/*LN-141*/         require(msg.sender == maintainer, "Only maintainer");
/*LN-142*/ 
/*LN-143*/         // In the real DODO contract, there was accumulated fee tracking
/*LN-144*/         // Attacker could reinitialize, set themselves as maintainer,
/*LN-145*/         // then claim all accumulated fees
/*LN-146*/         uint256 baseTokenBalance = IERC20(baseToken).balanceOf(address(this));
/*LN-147*/         uint256 quoteTokenBalance = IERC20(quoteToken).balanceOf(address(this));
/*LN-148*/ 
/*LN-149*/         // Transfer excess (fees) to maintainer
/*LN-150*/         if (baseTokenBalance > baseBalance) {
/*LN-151*/             uint256 excess = baseTokenBalance - baseBalance;
/*LN-152*/             IERC20(baseToken).transfer(maintainer, excess);
/*LN-153*/         }
/*LN-154*/ 
/*LN-155*/         if (quoteTokenBalance > quoteBalance) {
/*LN-156*/             uint256 excess = quoteTokenBalance - quoteBalance;
/*LN-157*/             IERC20(quoteToken).transfer(maintainer, excess);
/*LN-158*/         }
/*LN-159*/     }
/*LN-160*/ }
/*LN-161*/ 
/*LN-162*/ /**
/*LN-163*/  * EXPLOIT SCENARIO:
/*LN-164*/  *
/*LN-165*/  * Initial State:
/*LN-166*/  * - DODO pool deployed and initialized by legitimate owner
/*LN-167*/  * - maintainer = 0xLegitOwner
/*LN-168*/  * - Pool has accumulated $3.8M in fees and liquidity
/*LN-169*/  *
/*LN-170*/  * Attack:
/*LN-171*/  * 1. Attacker notices init() has no initialization guard
/*LN-172*/  *
/*LN-173*/  * 2. Attacker calls:
/*LN-174*/  *    init(
/*LN-175*/  *      _maintainer: 0xAttacker,  // Hijack maintainer role
/*LN-176*/  *      _baseToken: <existing>,
/*LN-177*/  *      _quoteToken: <existing>,
/*LN-178*/  *      _lpFeeRate: 10000  // Max fees to attacker
/*LN-179*/  *    )
/*LN-180*/  *
/*LN-181*/  * 3. Now maintainer = 0xAttacker
/*LN-182*/  *
/*LN-183*/  * 4. Attacker can:
/*LN-184*/  *    a) Call claimFees() to steal accumulated fees
/*LN-185*/  *    b) All future swap fees go to attacker
/*LN-186*/  *    c) In some versions, could manipulate baseBalance/quoteBalance
/*LN-187*/  *       to enable profitable swaps
/*LN-188*/  *
/*LN-189*/  * 5. Drain $3.8M from the pool
/*LN-190*/  *
/*LN-191*/  * Root Cause:
/*LN-192*/  * - init() function lacked proper initialization guard
/*LN-193*/  * - Missing: require(!isInitialized, "Already initialized")
/*LN-194*/  * - Or better: use OpenZeppelin's Initializable pattern
/*LN-195*/  *
/*LN-196*/  * Fix:
/*LN-197*/  * ```solidity
/*LN-198*/  * bool private initialized;
/*LN-199*/  *
/*LN-200*/  * function init(...) external {
/*LN-201*/  *     require(!initialized, "Already initialized");
/*LN-202*/  *     initialized = true;
/*LN-203*/  *     // ... rest of initialization
/*LN-204*/  * }
/*LN-205*/  * ```
/*LN-206*/  *
/*LN-207*/  * Or use OpenZeppelin Initializable:
/*LN-208*/  * ```solidity
/*LN-209*/  * import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
/*LN-210*/  *
/*LN-211*/  * contract DODOPool is Initializable {
/*LN-212*/  *     function init(...) external initializer {
/*LN-213*/  *         // ... initialization logic
/*LN-214*/  *     }
/*LN-215*/  * }
/*LN-216*/  * ```
/*LN-217*/  */
/*LN-218*/ 