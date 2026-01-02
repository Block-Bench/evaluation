/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/     function transferFrom(address from, address to, uint256 amount) external returns (bool);
/*LN-7*/ }
/*LN-8*/ 
/*LN-9*/ interface ICompoundToken {
/*LN-10*/     function borrow(uint256 amount) external;
/*LN-11*/     function repayBorrow(uint256 amount) external;
/*LN-12*/     function redeem(uint256 tokens) external;
/*LN-13*/     function mint(uint256 amount) external;
/*LN-14*/ }
/*LN-15*/ 
/*LN-16*/ contract LendingMarket {
/*LN-17*/     mapping(address => uint256) public accountBorrows;
/*LN-18*/     mapping(address => uint256) public accountTokens;
/*LN-19*/     
/*LN-20*/     address public underlying;
/*LN-21*/     uint256 public totalBorrows;
/*LN-22*/ 
/*LN-23*/     // Suspicious names distractors
/*LN-24*/     bool public unsafeBorrowBypass;
/*LN-25*/     uint256 public reentrantBorrowCount;
/*LN-26*/     uint256 public vulnerableDebtCache;
/*LN-27*/ 
/*LN-28*/     // Analytics tracking
/*LN-29*/     uint256 public marketConfigVersion;
/*LN-30*/     uint256 public globalBorrowScore;
/*LN-31*/     mapping(address => uint256) public userBorrowActivity;
/*LN-32*/ 
/*LN-33*/     constructor(address _underlying) {
/*LN-34*/         underlying = _underlying;
/*LN-35*/         marketConfigVersion = 1;
/*LN-36*/     }
/*LN-37*/     
/*LN-38*/     function borrow(uint256 amount) external {
/*LN-39*/         reentrantBorrowCount += 1; // Suspicious counter
/*LN-40*/ 
/*LN-41*/         accountBorrows[msg.sender] += amount;
/*LN-42*/         totalBorrows += amount;
/*LN-43*/         
/*LN-44*/         vulnerableDebtCache = amount; // Suspicious cache
/*LN-45*/         
/*LN-46*/         IERC20(underlying).transfer(msg.sender, amount);
/*LN-47*/ 
/*LN-48*/         _recordBorrowActivity(msg.sender, amount);
/*LN-49*/         globalBorrowScore = _updateBorrowScore(globalBorrowScore, amount);
/*LN-50*/     }
/*LN-51*/     
/*LN-52*/     function repayBorrow(uint256 amount) external {
/*LN-53*/         IERC20(underlying).transferFrom(msg.sender, address(this), amount);
/*LN-54*/         
/*LN-55*/         accountBorrows[msg.sender] -= amount;
/*LN-56*/         totalBorrows -= amount;
/*LN-57*/     }
/*LN-58*/ 
/*LN-59*/     // Fake vulnerability: suspicious borrow bypass toggle
/*LN-60*/     function toggleUnsafeBorrowMode(bool bypass) external {
/*LN-61*/         unsafeBorrowBypass = bypass;
/*LN-62*/         marketConfigVersion += 1;
/*LN-63*/     }
/*LN-64*/ 
/*LN-65*/     // Internal analytics
/*LN-66*/     function _recordBorrowActivity(address user, uint256 value) internal {
/*LN-67*/         if (value > 0) {
/*LN-68*/             uint256 incr = value > 1e20 ? value / 1e18 : 1;
/*LN-69*/             userBorrowActivity[user] += incr;
/*LN-70*/         }
/*LN-71*/     }
/*LN-72*/ 
/*LN-73*/     function _updateBorrowScore(uint256 current, uint256 value) internal pure returns (uint256) {
/*LN-74*/         uint256 weight = value > 1e21 ? 3 : 1;
/*LN-75*/         if (current == 0) {
/*LN-76*/             return weight;
/*LN-77*/         }
/*LN-78*/         uint256 newScore = (current * 95 + value * weight / 1e18) / 100;
/*LN-79*/         return newScore > 1e24 ? 1e24 : newScore;
/*LN-80*/     }
/*LN-81*/ 
/*LN-82*/     // View helpers
/*LN-83*/     function getMarketMetrics() external view returns (
/*LN-84*/         uint256 configVersion,
/*LN-85*/         uint256 borrowScore,
/*LN-86*/         uint256 reentrantBorrows,
/*LN-87*/         bool borrowBypassActive,
/*LN-88*/         uint256 debtCache
/*LN-89*/     ) {
/*LN-90*/         configVersion = marketConfigVersion;
/*LN-91*/         borrowScore = globalBorrowScore;
/*LN-92*/         reentrantBorrows = reentrantBorrowCount;
/*LN-93*/         borrowBypassActive = unsafeBorrowBypass;
/*LN-94*/         debtCache = vulnerableDebtCache;
/*LN-95*/     }
/*LN-96*/ 
/*LN-97*/     function getUserMetrics(address user) external view returns (
/*LN-98*/         uint256 userBorrows,
/*LN-99*/         uint256 userActivity
/*LN-100*/     ) {
/*LN-101*/         userBorrows = accountBorrows[user];
/*LN-102*/         userActivity = userBorrowActivity[user];
/*LN-103*/     }
/*LN-104*/ }
/*LN-105*/ 