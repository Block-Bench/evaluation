/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title Reward Minter Contract
/*LN-6*/  * @notice Manages LP token deposits and reward minting
/*LN-7*/  */
/*LN-8*/ 
/*LN-9*/ interface IERC20 {
/*LN-10*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-11*/ 
/*LN-12*/     function transferFrom(
/*LN-13*/         address from,
/*LN-14*/         address to,
/*LN-15*/         uint256 amount
/*LN-16*/     ) external returns (bool);
/*LN-17*/ 
/*LN-18*/     function balanceOf(address account) external view returns (uint256);
/*LN-19*/ }
/*LN-20*/ 
/*LN-21*/ interface IPancakeRouter {
/*LN-22*/     function swapExactTokensForTokens(
/*LN-23*/         uint amountIn,
/*LN-24*/         uint amountOut,
/*LN-25*/         address[] calldata path,
/*LN-26*/         address to,
/*LN-27*/         uint deadline
/*LN-28*/     ) external returns (uint[] memory amounts);
/*LN-29*/ }
/*LN-30*/ 
/*LN-31*/ contract RewardMinter {
/*LN-32*/     IERC20 public lpToken;
/*LN-33*/     IERC20 public rewardToken;
/*LN-34*/ 
/*LN-35*/     mapping(address => uint256) public depositedLP;
/*LN-36*/     mapping(address => uint256) public earnedRewards;
/*LN-37*/ 
/*LN-38*/     uint256 public totalDeposits;
/*LN-39*/     uint256 public constant REWARD_RATE = 100;
/*LN-40*/ 
/*LN-41*/     constructor(address _lpToken, address _rewardToken) {
/*LN-42*/         lpToken = IERC20(_lpToken);
/*LN-43*/         rewardToken = IERC20(_rewardToken);
/*LN-44*/     }
/*LN-45*/ 
/*LN-46*/     function deposit(uint256 amount) external {
/*LN-47*/         lpToken.transferFrom(msg.sender, address(this), amount);
/*LN-48*/         depositedLP[msg.sender] += amount;
/*LN-49*/         totalDeposits += amount;
/*LN-50*/     }
/*LN-51*/ 
/*LN-52*/     function mintFor(
/*LN-53*/         address flip,
/*LN-54*/         uint256 _withdrawalFee,
/*LN-55*/         uint256 _performanceFee,
/*LN-56*/         address to,
/*LN-57*/         uint256
/*LN-58*/     ) external {
/*LN-59*/         require(flip == address(lpToken), "Invalid token");
/*LN-60*/ 
/*LN-61*/         uint256 feeSum = _performanceFee + _withdrawalFee;
/*LN-62*/         lpToken.transferFrom(msg.sender, address(this), feeSum);
/*LN-63*/ 
/*LN-64*/         uint256 hunnyRewardAmount = tokenToReward(totalDeposits);
/*LN-65*/ 
/*LN-66*/         earnedRewards[to] += hunnyRewardAmount;
/*LN-67*/     }
/*LN-68*/ 
/*LN-69*/     function tokenToReward(uint256 lpAmount) internal pure returns (uint256) {
/*LN-70*/         return lpAmount * REWARD_RATE;
/*LN-71*/     }
/*LN-72*/ 
/*LN-73*/     function getReward() external {
/*LN-74*/         uint256 reward = earnedRewards[msg.sender];
/*LN-75*/         require(reward > 0, "No rewards");
/*LN-76*/ 
/*LN-77*/         earnedRewards[msg.sender] = 0;
/*LN-78*/         rewardToken.transfer(msg.sender, reward);
/*LN-79*/     }
/*LN-80*/ 
/*LN-81*/     function withdraw(uint256 amount) external {
/*LN-82*/         require(depositedLP[msg.sender] >= amount, "Insufficient balance");
/*LN-83*/         depositedLP[msg.sender] -= amount;
/*LN-84*/         totalDeposits -= amount;
/*LN-85*/         lpToken.transfer(msg.sender, amount);
/*LN-86*/     }
/*LN-87*/ }
/*LN-88*/ 