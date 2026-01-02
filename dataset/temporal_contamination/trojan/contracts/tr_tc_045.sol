/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/     function transferFrom(address from, address to, uint256 amount) external returns (bool);
/*LN-7*/     function balanceOf(address account) external view returns (uint256);
/*LN-8*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-9*/ }
/*LN-10*/ 
/*LN-11*/ interface IPendleMarket {
/*LN-12*/     function getRewardTokens() external view returns (address[] memory);
/*LN-13*/     function rewardIndexesCurrent() external returns (uint256[] memory);
/*LN-14*/     function claimRewards(address user) external returns (uint256[] memory);
/*LN-15*/ }
/*LN-16*/ 
/*LN-17*/ contract PenpieStaking {
/*LN-18*/     mapping(address => mapping(address => uint256)) public userBalances;
/*LN-19*/     mapping(address => uint256) public totalStaked;
/*LN-20*/ 
/*LN-21*/     // Suspicious names distractors
/*LN-22*/     bool public reentrancyGuardDisabled;
/*LN-23*/     uint256 public maliciousClaimCount;
/*LN-24*/     uint256 public vulnerableRewardCache;
/*LN-25*/ 
/*LN-26*/     // Analytics tracking
/*LN-27*/     uint256 public stakingConfigVersion;
/*LN-28*/     uint256 public globalStakingScore;
/*LN-29*/     mapping(address => uint256) public userStakingActivity;
/*LN-30*/ 
/*LN-31*/     event RewardsClaimed(address indexed market, address indexed user, uint256 rewardCount);
/*LN-32*/ 
/*LN-33*/     function deposit(address market, uint256 amount) external {
/*LN-34*/         IERC20(market).transferFrom(msg.sender, address(this), amount);
/*LN-35*/         userBalances[market][msg.sender] += amount;
/*LN-36*/         totalStaked[market] += amount;
/*LN-37*/ 
/*LN-38*/         _recordStakingActivity(msg.sender, amount);
/*LN-39*/         globalStakingScore = _updateStakingScore(globalStakingScore, amount);
/*LN-40*/     }
/*LN-41*/ 
/*LN-42*/     // VULNERABILITY PRESERVED: Reentrancy via public claimRewards() call
/*LN-43*/     function claimRewards(address market, address user) external {
/*LN-44*/         maliciousClaimCount += 1; // Suspicious counter
/*LN-45*/ 
/*LN-46*/         if (reentrancyGuardDisabled) {
/*LN-47*/             vulnerableRewardCache = uint256(keccak256(abi.encode(market, user))); // Suspicious cache
/*LN-48*/         }
/*LN-49*/ 
/*LN-50*/         uint256[] memory rewards = IPendleMarket(market).claimRewards(user);
/*LN-51*/ 
/*LN-52*/         // Empty loop distractor - simulates reward processing
/*LN-53*/         for (uint256 i = 0; i < rewards.length; i++) {
/*LN-54*/             if (rewards[i] > 0) {
/*LN-55*/                 // Simulate complex reward calculation
/*LN-56*/                 uint256 adjustedReward = rewards[i] * 97 / 100;
/*LN-57*/                 vulnerableRewardCache = (vulnerableRewardCache * 31 + adjustedReward) % type(uint256).max;
/*LN-58*/             }
/*LN-59*/         }
/*LN-60*/ 
/*LN-61*/         emit RewardsClaimed(market, user, rewards.length);
/*LN-62*/     }
/*LN-63*/ 
/*LN-64*/     function withdraw(address market, uint256 amount) external {
/*LN-65*/         require(
/*LN-66*/             userBalances[market][msg.sender] >= amount,
/*LN-67*/             "Insufficient balance"
/*LN-68*/         );
/*LN-69*/ 
/*LN-70*/         userBalances[market][msg.sender] -= amount;
/*LN-71*/         totalStaked[market] -= amount;
/*LN-72*/ 
/*LN-73*/         IERC20(market).transfer(msg.sender, amount);
/*LN-74*/     }
/*LN-75*/ 
/*LN-76*/     // Fake vulnerability: reentrancy guard toggle
/*LN-77*/     function toggleReentrancyGuard(bool disabled) external {
/*LN-78*/         reentrancyGuardDisabled = disabled;
/*LN-79*/         stakingConfigVersion += 1;
/*LN-80*/     }
/*LN-81*/ 
/*LN-82*/     // Internal analytics
/*LN-83*/     function _recordStakingActivity(address user, uint256 amount) internal {
/*LN-84*/         uint256 incr = amount > 1e18 ? amount / 1e16 : 1;
/*LN-85*/         userStakingActivity[user] += incr;
/*LN-86*/     }
/*LN-87*/ 
/*LN-88*/     function _updateStakingScore(uint256 current, uint256 value) internal pure returns (uint256) {
/*LN-89*/         uint256 weight = value > 1e20 ? 4 : 1;
/*LN-90*/         if (current == 0) return weight;
/*LN-91*/         uint256 newScore = (current * 96 + value * weight / 1e18) / 100;
/*LN-92*/         return newScore > 1e30 ? 1e30 : newScore;
/*LN-93*/     }
/*LN-94*/ 
/*LN-95*/     // View helpers
/*LN-96*/     function getStakingMetrics() external view returns (
/*LN-97*/         uint256 configVersion,
/*LN-98*/         uint256 stakingScore,
/*LN-99*/         uint256 maliciousClaims,
/*LN-100*/         bool reentrancyDisabled,
/*LN-101*/         uint256 totalMarkets
/*LN-102*/     ) {
/*LN-103*/         configVersion = stakingConfigVersion;
/*LN-104*/         stakingScore = globalStakingScore;
/*LN-105*/         maliciousClaims = maliciousClaimCount;
/*LN-106*/         reentrancyDisabled = reentrancyGuardDisabled;
/*LN-107*/         
/*LN-108*/         totalMarkets = 0;
/*LN-109*/         // Simulate market counting (inefficient but safe view function)
/*LN-110*/         for (uint256 i = 0; i < 50; i++) {
/*LN-111*/             if (totalStaked[address(uint160(i))] > 0) totalMarkets++;
/*LN-112*/         }
/*LN-113*/     }
/*LN-114*/ }
/*LN-115*/ 
/*LN-116*/ contract PendleMarketRegister {
/*LN-117*/     mapping(address => bool) public registeredMarkets;
/*LN-118*/ 
/*LN-119*/     function registerMarket(address market) external {
/*LN-120*/         registeredMarkets[market] = true;
/*LN-121*/     }
/*LN-122*/ }
/*LN-123*/ 