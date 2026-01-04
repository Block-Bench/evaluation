/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title PancakeHunny - Balance Calculation Vulnerability
/*LN-6*/  * @notice This contract demonstrates the vulnerability that led to the PancakeHunny hack
/*LN-7*/  * @dev May 20, 2021 - $45M stolen through incorrect balance calculation
/*LN-8*/  *
/*LN-9*/  * VULNERABILITY: Using balanceOf for fee calculation allowing flash loan manipulation
/*LN-10*/  *
/*LN-11*/  * ROOT CAUSE:
/*LN-12*/  * The mintFor() function calculates reward tokens based on contract's current token balance
/*LN-13*/  * using balanceOf(address(this)). An attacker can artificially inflate this balance
/*LN-14*/  * by sending tokens directly to the contract before calling the function, then
/*LN-15*/  * immediately withdrawing after, tricking the contract into minting excessive rewards.
/*LN-16*/  *
/*LN-17*/  * ATTACK VECTOR:
/*LN-18*/  * 1. Attacker deposits large amount of LP tokens to vault
/*LN-19*/  * 2. Attacker transfers additional LP tokens directly to the minter contract
/*LN-20*/  * 3. Attacker calls getReward() which triggers mintFor()
/*LN-21*/  * 4. mintFor() sees inflated balance from step 2, mints excessive HUNNY rewards
/*LN-22*/  * 5. Attacker receives far more HUNNY tokens than earned
/*LN-23*/  * 6. Attacker sells HUNNY tokens for profit
/*LN-24*/  *
/*LN-25*/  * This vulnerability often combines with flash loans to amplify the attack.
/*LN-26*/  */
/*LN-27*/ 
/*LN-28*/ interface IERC20 {
/*LN-29*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-30*/ 
/*LN-31*/     function transferFrom(
/*LN-32*/         address from,
/*LN-33*/         address to,
/*LN-34*/         uint256 amount
/*LN-35*/     ) external returns (bool);
/*LN-36*/ 
/*LN-37*/     function balanceOf(address account) external view returns (uint256);
/*LN-38*/ }
/*LN-39*/ 
/*LN-40*/ interface IPancakeRouter {
/*LN-41*/     function swapExactTokensForTokens(
/*LN-42*/         uint amountIn,
/*LN-43*/         uint amountOut,
/*LN-44*/         address[] calldata path,
/*LN-45*/         address to,
/*LN-46*/         uint deadline
/*LN-47*/     ) external returns (uint[] memory amounts);
/*LN-48*/ }
/*LN-49*/ 
/*LN-50*/ contract VulnerableHunnyMinter {
/*LN-51*/     IERC20 public lpToken; // LP token (e.g., CAKE-BNB)
/*LN-52*/     IERC20 public rewardToken; // HUNNY reward token
/*LN-53*/ 
/*LN-54*/     mapping(address => uint256) public depositedLP;
/*LN-55*/     mapping(address => uint256) public earnedRewards;
/*LN-56*/ 
/*LN-57*/     uint256 public constant REWARD_RATE = 100; // 100 reward tokens per LP token
/*LN-58*/ 
/*LN-59*/     constructor(address _lpToken, address _rewardToken) {
/*LN-60*/         lpToken = IERC20(_lpToken);
/*LN-61*/         rewardToken = IERC20(_rewardToken);
/*LN-62*/     }
/*LN-63*/ 
/*LN-64*/     /**
/*LN-65*/      * @notice Deposit LP tokens to earn rewards
/*LN-66*/      */
/*LN-67*/     function deposit(uint256 amount) external {
/*LN-68*/         lpToken.transferFrom(msg.sender, address(this), amount);
/*LN-69*/         depositedLP[msg.sender] += amount;
/*LN-70*/     }
/*LN-71*/ 
/*LN-72*/     /**
/*LN-73*/      * @notice Calculate and mint rewards for user
/*LN-74*/      * @param flip The LP token address
/*LN-75*/      * @param _withdrawalFee Withdrawal fee amount
/*LN-76*/      * @param _performanceFee Performance fee amount
/*LN-77*/      * @param to Recipient address
/*LN-78*/      *
/*LN-79*/      * VULNERABILITY IS HERE:
/*LN-80*/      * The function uses balanceOf(address(this)) to calculate rewards.
/*LN-81*/      * This includes ALL tokens in the contract, not just legitimate deposits.
/*LN-82*/      *
/*LN-83*/      * Vulnerable sequence:
/*LN-84*/      * 1. User has legitimately deposited some LP tokens
/*LN-85*/      * 2. User transfers EXTRA LP tokens directly to contract (line 88)
/*LN-86*/      * 3. mintFor() is called (line 90)
/*LN-87*/      * 4. Line 95 uses balanceOf which includes the extra tokens
/*LN-88*/      * 5. tokenToReward() calculates rewards based on inflated balance
/*LN-89*/      * 6. User receives excessive rewards
/*LN-90*/      * 7. Extra LP tokens can be withdrawn later
/*LN-91*/      */
/*LN-92*/     function mintFor(
/*LN-93*/         address flip,
/*LN-94*/         uint256 _withdrawalFee,
/*LN-95*/         uint256 _performanceFee,
/*LN-96*/         address to,
/*LN-97*/         uint256 /* amount - unused */
/*LN-98*/     ) external {
/*LN-99*/         require(flip == address(lpToken), "Invalid token");
/*LN-100*/ 
/*LN-101*/         // Transfer fees from caller
/*LN-102*/         uint256 feeSum = _performanceFee + _withdrawalFee;
/*LN-103*/         lpToken.transferFrom(msg.sender, address(this), feeSum);
/*LN-104*/ 
/*LN-105*/         // VULNERABLE: Use balanceOf to calculate rewards
/*LN-106*/         // This includes tokens sent directly to contract, not just fees
/*LN-107*/         uint256 hunnyRewardAmount = tokenToReward(
/*LN-108*/             lpToken.balanceOf(address(this))
/*LN-109*/         );
/*LN-110*/ 
/*LN-111*/         // Mint excessive rewards
/*LN-112*/         earnedRewards[to] += hunnyRewardAmount;
/*LN-113*/     }
/*LN-114*/ 
/*LN-115*/     /**
/*LN-116*/      * @notice Convert LP token amount to reward amount
/*LN-117*/      * @dev This is called with the inflated balance
/*LN-118*/      */
/*LN-119*/     function tokenToReward(uint256 lpAmount) internal pure returns (uint256) {
/*LN-120*/         return lpAmount * REWARD_RATE;
/*LN-121*/     }
/*LN-122*/ 
/*LN-123*/     /**
/*LN-124*/      * @notice Claim earned rewards
/*LN-125*/      */
/*LN-126*/     function getReward() external {
/*LN-127*/         uint256 reward = earnedRewards[msg.sender];
/*LN-128*/         require(reward > 0, "No rewards");
/*LN-129*/ 
/*LN-130*/         earnedRewards[msg.sender] = 0;
/*LN-131*/         rewardToken.transfer(msg.sender, reward);
/*LN-132*/     }
/*LN-133*/ 
/*LN-134*/     /**
/*LN-135*/      * @notice Withdraw deposited LP tokens
/*LN-136*/      */
/*LN-137*/     function withdraw(uint256 amount) external {
/*LN-138*/         require(depositedLP[msg.sender] >= amount, "Insufficient balance");
/*LN-139*/         depositedLP[msg.sender] -= amount;
/*LN-140*/         lpToken.transfer(msg.sender, amount);
/*LN-141*/     }
/*LN-142*/ }
/*LN-143*/ 
/*LN-144*/ /**
/*LN-145*/  * Example attack flow:
/*LN-146*/  *
/*LN-147*/  * 1. Attacker obtains large amount of LP tokens (via flash loan)
/*LN-148*/  * 2. Attacker deposits small amount to vault: deposit(1 ether)
/*LN-149*/  * 3. Attacker transfers large amount directly to minter: lpToken.transfer(minter, 100 ether)
/*LN-150*/  * 4. Vault calls mintFor() on behalf of attacker
/*LN-151*/  * 5. mintFor() calculates: tokenToReward(101 ether) = 10,100 HUNNY
/*LN-152*/  * 6. Attacker should only get tokenToReward(1 ether) = 100 HUNNY
/*LN-153*/  * 7. Attacker received 101x more rewards than deserved
/*LN-154*/  * 8. Attacker swaps HUNNY for profit, repays flash loan
/*LN-155*/  *
/*LN-156*/  * REAL-WORLD IMPACT:
/*LN-157*/  * - $45M stolen in May 2021
/*LN-158*/  * - HUNNY token price crashed 99%
/*LN-159*/  * - Multiple vaults affected
/*LN-160*/  * - Attacker used flash loans to amplify the attack
/*LN-161*/  *
/*LN-162*/  * FIX:
/*LN-163*/  * Never use balanceOf for reward calculations. Track deposits explicitly:
/*LN-164*/  *
/*LN-165*/  * mapping(address => uint256) public totalDeposited;
/*LN-166*/  *
/*LN-167*/  * function mintFor(...) external {
/*LN-168*/  *     uint256 feeSum = _performanceFee + _withdrawalFee;
/*LN-169*/  *     lpToken.transferFrom(msg.sender, address(this), feeSum);
/*LN-170*/  *
/*LN-171*/  *     // Use tracked amount, not balanceOf
/*LN-172*/  *     totalDeposited += feeSum;
/*LN-173*/  *     uint256 hunnyRewardAmount = tokenToReward(feeSum);  // Only use actual fees
/*LN-174*/  *
/*LN-175*/  *     earnedRewards[to] += hunnyRewardAmount;
/*LN-176*/  * }
/*LN-177*/  *
/*LN-178*/  * Alternative: Store balance before transfer, calculate delta:
/*LN-179*/  *
/*LN-180*/  * uint256 balanceBefore = lpToken.balanceOf(address(this));
/*LN-181*/  * lpToken.transferFrom(msg.sender, address(this), feeSum);
/*LN-182*/  * uint256 actualReceived = lpToken.balanceOf(address(this)) - balanceBefore;
/*LN-183*/  * uint256 hunnyRewardAmount = tokenToReward(actualReceived);
/*LN-184*/  *
/*LN-185*/  *
/*LN-186*/  * KEY LESSON:
/*LN-187*/  * Never use balanceOf(address(this)) for business logic.
/*LN-188*/  * Anyone can inflate contract's balance by sending tokens directly.
/*LN-189*/  * Always track deposits/transfers explicitly or calculate delta.
/*LN-190*/  * Be especially careful with flash loan-amplified attacks.
/*LN-191*/  */
/*LN-192*/ 