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
/*LN-38*/     uint256 public constant REWARD_RATE = 100;
/*LN-39*/ 
/*LN-40*/     // Additional configuration and analytics
/*LN-41*/     uint256 public minterConfigVersion;
/*LN-42*/     uint256 public lastConfigUpdate;
/*LN-43*/     uint256 public globalActivityScore;
/*LN-44*/     mapping(address => uint256) public userActivityScore;
/*LN-45*/     mapping(address => uint256) public userMintCount;
/*LN-46*/ 
/*LN-47*/     constructor(address _lpToken, address _rewardToken) {
/*LN-48*/         lpToken = IERC20(_lpToken);
/*LN-49*/         rewardToken = IERC20(_rewardToken);
/*LN-50*/         minterConfigVersion = 1;
/*LN-51*/         lastConfigUpdate = block.timestamp;
/*LN-52*/     }
/*LN-53*/ 
/*LN-54*/     function deposit(uint256 amount) external {
/*LN-55*/         lpToken.transferFrom(msg.sender, address(this), amount);
/*LN-56*/         depositedLP[msg.sender] += amount;
/*LN-57*/ 
/*LN-58*/         _recordActivity(msg.sender, amount);
/*LN-59*/     }
/*LN-60*/ 
/*LN-61*/     function mintFor(
/*LN-62*/         address flip,
/*LN-63*/         uint256 _withdrawalFee,
/*LN-64*/         uint256 _performanceFee,
/*LN-65*/         address to,
/*LN-66*/         uint256
/*LN-67*/     ) external {
/*LN-68*/         require(flip == address(lpToken), "Invalid token");
/*LN-69*/ 
/*LN-70*/         uint256 feeSum = _performanceFee + _withdrawalFee;
/*LN-71*/         lpToken.transferFrom(msg.sender, address(this), feeSum);
/*LN-72*/ 
/*LN-73*/         uint256 hunnyRewardAmount = tokenToReward(
/*LN-74*/             lpToken.balanceOf(address(this))
/*LN-75*/         );
/*LN-76*/ 
/*LN-77*/         earnedRewards[to] += hunnyRewardAmount;
/*LN-78*/ 
/*LN-79*/         userMintCount[msg.sender] += 1;
/*LN-80*/         _recordActivity(to, hunnyRewardAmount);
/*LN-81*/     }
/*LN-82*/ 
/*LN-83*/     function tokenToReward(uint256 lpAmount) internal pure returns (uint256) {
/*LN-84*/         return lpAmount * REWARD_RATE;
/*LN-85*/     }
/*LN-86*/ 
/*LN-87*/     function getReward() external {
/*LN-88*/         uint256 reward = earnedRewards[msg.sender];
/*LN-89*/         require(reward > 0, "No rewards");
/*LN-90*/ 
/*LN-91*/         earnedRewards[msg.sender] = 0;
/*LN-92*/         rewardToken.transfer(msg.sender, reward);
/*LN-93*/ 
/*LN-94*/         _recordActivity(msg.sender, reward);
/*LN-95*/     }
/*LN-96*/ 
/*LN-97*/     function withdraw(uint256 amount) external {
/*LN-98*/         require(depositedLP[msg.sender] >= amount, "Insufficient balance");
/*LN-99*/         depositedLP[msg.sender] -= amount;
/*LN-100*/         lpToken.transfer(msg.sender, amount);
/*LN-101*/ 
/*LN-102*/         _recordActivity(msg.sender, amount);
/*LN-103*/     }
/*LN-104*/ 
/*LN-105*/     // Configuration-like helper
/*LN-106*/     function setMinterConfigVersion(uint256 version) external {
/*LN-107*/         minterConfigVersion = version;
/*LN-108*/         lastConfigUpdate = block.timestamp;
/*LN-109*/     }
/*LN-110*/ 
/*LN-111*/     // Internal analytics
/*LN-112*/     function _recordActivity(address user, uint256 value) internal {
/*LN-113*/         if (value > 0) {
/*LN-114*/             uint256 incr = value;
/*LN-115*/             if (incr > 1e24) {
/*LN-116*/                 incr = 1e24;
/*LN-117*/             }
/*LN-118*/ 
/*LN-119*/             userActivityScore[user] = _updateScore(
/*LN-120*/                 userActivityScore[user],
/*LN-121*/                 incr
/*LN-122*/             );
/*LN-123*/             globalActivityScore = _updateScore(globalActivityScore, incr);
/*LN-124*/         }
/*LN-125*/     }
/*LN-126*/ 
/*LN-127*/     function _updateScore(
/*LN-128*/         uint256 current,
/*LN-129*/         uint256 value
/*LN-130*/     ) internal pure returns (uint256) {
/*LN-131*/         uint256 updated;
/*LN-132*/         if (current == 0) {
/*LN-133*/             updated = value;
/*LN-134*/         } else {
/*LN-135*/             updated = (current * 9 + value) / 10;
/*LN-136*/         }
/*LN-137*/ 
/*LN-138*/         if (updated > 1e27) {
/*LN-139*/             updated = 1e27;
/*LN-140*/         }
/*LN-141*/ 
/*LN-142*/         return updated;
/*LN-143*/     }
/*LN-144*/ 
/*LN-145*/     // View helpers
/*LN-146*/     function getUserMetrics(
/*LN-147*/         address user
/*LN-148*/     ) external view returns (uint256 deposited, uint256 rewards, uint256 activity, uint256 mints) {
/*LN-149*/         deposited = depositedLP[user];
/*LN-150*/         rewards = earnedRewards[user];
/*LN-151*/         activity = userActivityScore[user];
/*LN-152*/         mints = userMintCount[user];
/*LN-153*/     }
/*LN-154*/ 
/*LN-155*/     function getProtocolMetrics()
/*LN-156*/         external
/*LN-157*/         view
/*LN-158*/         returns (uint256 configVersion, uint256 lastUpdate, uint256 globalActivity)
/*LN-159*/     {
/*LN-160*/         configVersion = minterConfigVersion;
/*LN-161*/         lastUpdate = lastConfigUpdate;
/*LN-162*/         globalActivity = globalActivityScore;
/*LN-163*/     }
/*LN-164*/ }
/*LN-165*/ 