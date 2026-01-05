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
/*LN-26*/ contract RewardMinter {
/*LN-27*/     IERC20 public lpToken; // LP token (e.g., CAKE-BNB)
/*LN-28*/     IERC20 public rewardToken;
/*LN-29*/ 
/*LN-30*/     mapping(address => uint256) public depositedLP;
/*LN-31*/     mapping(address => uint256) public earnedRewards;
/*LN-32*/ 
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
/*LN-48*/     /**
/*LN-49*/      * @notice Calculate and mint rewards for user
/*LN-50*/      * @param flip The LP token address
/*LN-51*/      * @param _withdrawalFee Withdrawal fee amount
/*LN-52*/      * @param _performanceFee Performance fee amount
/*LN-53*/      * @param to Recipient address
/*LN-54*/      *
/*LN-55*/ 
/*LN-56*/      *
/*LN-57*/      *
/*LN-58*/ 
/*LN-59*/      *
/*LN-60*/      *
/*LN-61*/      *
/*LN-62*/      *
/*LN-63*/      *
/*LN-64*/      */
/*LN-65*/     function mintFor(
/*LN-66*/         address flip,
/*LN-67*/         uint256 _withdrawalFee,
/*LN-68*/         uint256 _performanceFee,
/*LN-69*/         address to,
/*LN-70*/         uint256 /* amount - unused */
/*LN-71*/     ) external {
/*LN-72*/         require(flip == address(lpToken), "Invalid token");
/*LN-73*/ 
/*LN-74*/         // Transfer fees from caller
/*LN-75*/         uint256 feeSum = _performanceFee + _withdrawalFee;
/*LN-76*/         lpToken.transferFrom(msg.sender, address(this), feeSum);
/*LN-77*/ 
/*LN-78*/         uint256 rewardAmount = tokenToReward(
/*LN-79*/             lpToken.balanceOf(address(this))
/*LN-80*/         );
/*LN-81*/ 
/*LN-82*/         earnedRewards[to] += rewardAmount;
/*LN-83*/     }
/*LN-84*/ 
/*LN-85*/     /**
/*LN-86*/      * @notice Convert LP token amount to reward amount
/*LN-87*/      * @dev This is called with the inflated balance
/*LN-88*/      */
/*LN-89*/     function tokenToReward(uint256 lpAmount) internal pure returns (uint256) {
/*LN-90*/         return lpAmount * REWARD_RATE;
/*LN-91*/     }
/*LN-92*/ 
/*LN-93*/     /**
/*LN-94*/      * @notice Claim earned rewards
/*LN-95*/      */
/*LN-96*/     function getReward() external {
/*LN-97*/         uint256 reward = earnedRewards[msg.sender];
/*LN-98*/         require(reward > 0, "No rewards");
/*LN-99*/ 
/*LN-100*/         earnedRewards[msg.sender] = 0;
/*LN-101*/         rewardToken.transfer(msg.sender, reward);
/*LN-102*/     }
/*LN-103*/ 
/*LN-104*/     /**
/*LN-105*/      * @notice Withdraw deposited LP tokens
/*LN-106*/      */
/*LN-107*/     function withdraw(uint256 amount) external {
/*LN-108*/         require(depositedLP[msg.sender] >= amount, "Insufficient balance");
/*LN-109*/         depositedLP[msg.sender] -= amount;
/*LN-110*/         lpToken.transfer(msg.sender, amount);
/*LN-111*/     }
/*LN-112*/ }
/*LN-113*/ 