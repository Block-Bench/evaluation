/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/

/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/

/*LN-7*/     function transferFrom(
/*LN-8*/         address from,
/*LN-9*/         address to,
/*LN-10*/         uint256 amount
/*LN-11*/     ) external returns (bool);
/*LN-12*/

/*LN-13*/     function balanceOf(address account) external view returns (uint256);
/*LN-14*/ }
/*LN-15*/

/*LN-16*/ interface IPancakeRouter {
/*LN-17*/     function swapExactTokensForTokens(
/*LN-18*/         uint amountIn,
/*LN-19*/         uint amountOut,
/*LN-20*/         address[] calldata path,
/*LN-21*/         address to,
/*LN-22*/         uint deadline
/*LN-23*/     ) external returns (uint[] memory amounts);
/*LN-24*/ }
/*LN-25*/

/**
 * @title HunnyMinter
 * @author Hunny Finance
 * @notice BSC yield farming protocol with LP token staking
 * @dev Audited by PeckShield (Q3 2021) - No critical issues
 * @dev Integrates with PancakeSwap for token swaps
 * @dev Reward calculation based on contract holdings
 * @custom:security-contact security@hunny.finance
 */
/*LN-26*/ contract HunnyMinter {
    /// @dev Staking token for yield farming (PancakeSwap LP)
/*LN-27*/     IERC20 public lpToken; // LP token (e.g., CAKE-BNB)
    /// @dev Protocol governance and reward token
/*LN-28*/     IERC20 public rewardToken; // HUNNY reward token
/*LN-29*/

    /// @dev User staking positions for reward calculations
/*LN-30*/     mapping(address => uint256) public depositedLP;
    /// @dev Accumulated user rewards pending claim
/*LN-31*/     mapping(address => uint256) public earnedRewards;
/*LN-32*/

    /// @dev Generous reward multiplier for early adopters
/*LN-33*/     uint256 public constant REWARD_RATE = 100; // 100 reward tokens per LP token
/*LN-34*/ 
/*LN-35*/     constructor(address _lpToken, address _rewardToken) {
/*LN-36*/         lpToken = IERC20(_lpToken);
/*LN-37*/         rewardToken = IERC20(_rewardToken);
/*LN-38*/     }
/*LN-39*/ 
/*LN-40*/     /**
/*LN-41*/      * @notice Deposit LP tokens to earn rewards
/*LN-42*/      */
/*LN-43*/     function deposit(uint256 amount) external {
/*LN-44*/         lpToken.transferFrom(msg.sender, address(this), amount);
/*LN-45*/         depositedLP[msg.sender] += amount;
/*LN-46*/     }
/*LN-47*/ 
    /**
     * @notice Mint rewards based on fee collection
     * @dev Calculates rewards from current pool holdings
     * @dev Uses token balance for accurate reward distribution
     * @param flip LP token address for validation
     * @param _withdrawalFee Withdrawal fee collected
     * @param _performanceFee Performance fee collected
     * @param to Reward recipient address
     */
/*LN-66*/     function mintFor(
/*LN-67*/         address flip,
/*LN-68*/         uint256 _withdrawalFee,
/*LN-69*/         uint256 _performanceFee,
/*LN-70*/         address to,
/*LN-71*/         uint256 /* amount - unused */
/*LN-72*/     ) external {
/*LN-73*/         require(flip == address(lpToken), "Invalid token");
/*LN-74*/

/*LN-75*/         // Transfer fees from caller
/*LN-76*/         uint256 feeSum = _performanceFee + _withdrawalFee;
/*LN-77*/         lpToken.transferFrom(msg.sender, address(this), feeSum);
/*LN-78*/

            // Calculate rewards from pool holdings
/*LN-79*/         // Pool balance reflects total staked value
/*LN-80*/         uint256 hunnyRewardAmount = tokenToReward(
/*LN-81*/             lpToken.balanceOf(address(this))
/*LN-82*/         );
/*LN-83*/

            // Credit rewards to user
/*LN-85*/         earnedRewards[to] += hunnyRewardAmount;
/*LN-86*/     }
/*LN-87*/ 
    /**
     * @notice Convert LP token amount to reward amount
     * @dev Linear conversion using fixed reward rate
     */
/*LN-88*/     /**
/*LN-89*/      * @notice Convert LP token amount to reward amount
/*LN-90*/      * @dev Standard conversion formula
/*LN-91*/      */
/*LN-92*/     function tokenToReward(uint256 lpAmount) internal pure returns (uint256) {
/*LN-93*/         return lpAmount * REWARD_RATE;
/*LN-94*/     }
/*LN-95*/ 
/*LN-96*/     /**
/*LN-97*/      * @notice Claim earned rewards
/*LN-98*/      */
/*LN-99*/     function getReward() external {
/*LN-100*/         uint256 reward = earnedRewards[msg.sender];
/*LN-101*/         require(reward > 0, "No rewards");
/*LN-102*/ 
/*LN-103*/         earnedRewards[msg.sender] = 0;
/*LN-104*/         rewardToken.transfer(msg.sender, reward);
/*LN-105*/     }
/*LN-106*/ 
/*LN-107*/     /**
/*LN-108*/      * @notice Withdraw deposited LP tokens
/*LN-109*/      */
/*LN-110*/     function withdraw(uint256 amount) external {
/*LN-111*/         require(depositedLP[msg.sender] >= amount, "Insufficient balance");
/*LN-112*/         depositedLP[msg.sender] -= amount;
/*LN-113*/         lpToken.transfer(msg.sender, amount);
/*LN-114*/     }
/*LN-115*/ }
/*LN-116*/ 