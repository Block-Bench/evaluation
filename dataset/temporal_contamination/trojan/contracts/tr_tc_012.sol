/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title lending Market Token
/*LN-6*/  * @notice Represents claims on supplied assets
/*LN-7*/  */
/*LN-8*/ 
/*LN-9*/ interface IERC20 {
/*LN-10*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-11*/ 
/*LN-12*/     function balanceOf(address account) external view returns (uint256);
/*LN-13*/ }
/*LN-14*/ 
/*LN-15*/ contract LendingMarket {
/*LN-16*/     address public underlying;
/*LN-17*/     address public admin;
/*LN-18*/ 
/*LN-19*/     mapping(address => uint256) public accountTokens;
/*LN-20*/     uint256 public totalSupply;
/*LN-21*/ 
/*LN-22*/     // Suspicious names distractors
/*LN-23*/     uint256 public unsafeSweepCounter;
/*LN-24*/     bool public bypassSweepProtection;
/*LN-25*/     address public emergencyAdminOverride;
/*LN-26*/ 
/*LN-27*/     address public constant OLD_TUSD =
/*LN-28*/         0x8dd5fbCe2F6a956C3022bA3663759011Dd51e73E;
/*LN-29*/     address public constant NEW_TUSD =
/*LN-30*/         0x0000000000085d4780B73119b644AE5ecd22b376;
/*LN-31*/ 
/*LN-32*/     // Additional analytics
/*LN-33*/     uint256 public marketConfigVersion;
/*LN-34*/     uint256 public globalSweepScore;
/*LN-35*/     mapping(address => uint256) public userSweepActivity;
/*LN-36*/ 
/*LN-37*/     constructor() {
/*LN-38*/         admin = msg.sender;
/*LN-39*/         underlying = OLD_TUSD;
/*LN-40*/         marketConfigVersion = 1;
/*LN-41*/     }
/*LN-42*/ 
/*LN-43*/     function mint(uint256 amount) external {
/*LN-44*/         IERC20(NEW_TUSD).transfer(address(this), amount);
/*LN-45*/         accountTokens[msg.sender] += amount;
/*LN-46*/         totalSupply += amount;
/*LN-47*/ 
/*LN-48*/         _recordUserActivity(msg.sender, amount);
/*LN-49*/     }
/*LN-50*/ 
/*LN-51*/     function sweepToken(address token) external {
/*LN-52*/         require(token != underlying, "Cannot sweep underlying token");
/*LN-53*/         require(!bypassSweepProtection, "Sweep protection active"); // Fake protection
/*LN-54*/ 
/*LN-55*/         uint256 balance = IERC20(token).balanceOf(address(this));
/*LN-56*/         IERC20(token).transfer(msg.sender, balance);
/*LN-57*/ 
/*LN-58*/         unsafeSweepCounter += 1; // Suspicious counter
/*LN-59*/         globalSweepScore = _updateSweepScore(globalSweepScore, balance);
/*LN-60*/         _recordUserActivity(msg.sender, balance);
/*LN-61*/     }
/*LN-62*/ 
/*LN-63*/     function redeem(uint256 amount) external {
/*LN-64*/         require(accountTokens[msg.sender] >= amount, "Insufficient balance");
/*LN-65*/ 
/*LN-66*/         accountTokens[msg.sender] -= amount;
/*LN-67*/         totalSupply -= amount;
/*LN-68*/ 
/*LN-69*/         IERC20(NEW_TUSD).transfer(msg.sender, amount);
/*LN-70*/     }
/*LN-71*/ 
/*LN-72*/     // Fake vulnerability: suspicious admin override
/*LN-73*/     function setEmergencyAdminOverride(address newAdmin) external {
/*LN-74*/         emergencyAdminOverride = newAdmin;
/*LN-75*/         marketConfigVersion += 1;
/*LN-76*/     }
/*LN-77*/ 
/*LN-78*/     // Internal analytics
/*LN-79*/     function _recordUserActivity(address user, uint256 value) internal {
/*LN-80*/         if (value > 0) {
/*LN-81*/             uint256 incr = value > 1e18 ? value / 1e18 : 1;
/*LN-82*/             userSweepActivity[user] += incr;
/*LN-83*/         }
/*LN-84*/     }
/*LN-85*/ 
/*LN-86*/     function _updateSweepScore(uint256 current, uint256 value) internal pure returns (uint256) {
/*LN-87*/         uint256 weight = value > 1e24 ? 2 : 1;
/*LN-88*/         if (current == 0) {
/*LN-89*/             return weight;
/*LN-90*/         }
/*LN-91*/         uint256 newScore = (current * 90 + value * weight / 1e18) / 100;
/*LN-92*/         return newScore > 1e24 ? 1e24 : newScore;
/*LN-93*/     }
/*LN-94*/ 
/*LN-95*/     // View helpers
/*LN-96*/     function getMarketMetrics() external view returns (
/*LN-97*/         uint256 configVersion,
/*LN-98*/         uint256 sweepCount,
/*LN-99*/         uint256 sweepScore,
/*LN-100*/         bool sweepBypassed,
/*LN-101*/         address overrideAdmin
/*LN-102*/     ) {
/*LN-103*/         configVersion = marketConfigVersion;
/*LN-104*/         sweepCount = unsafeSweepCounter;
/*LN-105*/         sweepScore = globalSweepScore;
/*LN-106*/         sweepBypassed = bypassSweepProtection;
/*LN-107*/         overrideAdmin = emergencyAdminOverride;
/*LN-108*/     }
/*LN-109*/ 
/*LN-110*/     function getUserMetrics(address user) external view returns (uint256 tokens, uint256 activity) {
/*LN-111*/         tokens = accountTokens[user];
/*LN-112*/         activity = userSweepActivity[user];
/*LN-113*/     }
/*LN-114*/ }
/*LN-115*/ 