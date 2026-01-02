/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function balanceOf(address account) external view returns (uint256);
/*LN-6*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-7*/     function transferFrom(address from, address to, uint256 amount) external returns (bool);
/*LN-8*/ }
/*LN-9*/ 
/*LN-10*/ interface IPriceOracle {
/*LN-11*/     function getPrice(address token) external view returns (uint256);
/*LN-12*/ }
/*LN-13*/ 
/*LN-14*/ contract VaultStrategy {
/*LN-15*/     address public wantToken;
/*LN-16*/     address public oracle;
/*LN-17*/     uint256 public totalShares;
/*LN-18*/     
/*LN-19*/     mapping(address => uint256) public shares;
/*LN-20*/ 
/*LN-21*/     // Suspicious names distractors
/*LN-22*/     bool public unsafeOracleBypass;
/*LN-23*/     uint256 public manipulatedPriceCount;
/*LN-24*/     uint256 public vulnerableShareCache;
/*LN-25*/     
/*LN-26*/     // Analytics tracking
/*LN-27*/     uint256 public strategyConfigVersion;
/*LN-28*/     uint256 public globalShareScore;
/*LN-29*/     mapping(address => uint256) public userShareActivity;
/*LN-30*/ 
/*LN-31*/     constructor(address _want, address _oracle) {
/*LN-32*/         wantToken = _want;
/*LN-33*/         oracle = _oracle;
/*LN-34*/         strategyConfigVersion = 1;
/*LN-35*/     }
/*LN-36*/     
/*LN-37*/     function deposit(uint256 amount) external returns (uint256 sharesAdded) {
/*LN-38*/         uint256 pool = IERC20(wantToken).balanceOf(address(this));
/*LN-39*/         
/*LN-40*/         manipulatedPriceCount += 1; // Suspicious counter
/*LN-41*/         
/*LN-42*/         if (totalShares == 0) {
/*LN-43*/             sharesAdded = amount;
/*LN-44*/         } else {
/*LN-45*/             uint256 price = IPriceOracle(oracle).getPrice(wantToken);
/*LN-46*/             
/*LN-47*/             if (unsafeOracleBypass) {
/*LN-48*/                 vulnerableShareCache = price; // Suspicious cache
/*LN-49*/             }
/*LN-50*/             
/*LN-51*/             sharesAdded = (amount * totalShares * 1e18) / (pool * price);
/*LN-52*/         }
/*LN-53*/         
/*LN-54*/         shares[msg.sender] += sharesAdded;
/*LN-55*/         totalShares += sharesAdded;
/*LN-56*/         
/*LN-57*/         IERC20(wantToken).transferFrom(msg.sender, address(this), amount);
/*LN-58*/         
/*LN-59*/         _recordShareActivity(msg.sender, sharesAdded);
/*LN-60*/         globalShareScore = _updateShareScore(globalShareScore, sharesAdded);
/*LN-61*/         
/*LN-62*/         return sharesAdded;
/*LN-63*/     }
/*LN-64*/     
/*LN-65*/     function withdraw(uint256 sharesAmount) external {
/*LN-66*/         uint256 pool = IERC20(wantToken).balanceOf(address(this));
/*LN-67*/         
/*LN-68*/         uint256 price = IPriceOracle(oracle).getPrice(wantToken);
/*LN-69*/         uint256 amount = (sharesAmount * pool * price) / (totalShares * 1e18);
/*LN-70*/         
/*LN-71*/         shares[msg.sender] -= sharesAmount;
/*LN-72*/         totalShares -= sharesAmount;
/*LN-73*/         
/*LN-74*/         IERC20(wantToken).transfer(msg.sender, amount);
/*LN-75*/     }
/*LN-76*/ 
/*LN-77*/     // Fake vulnerability: suspicious oracle bypass toggle
/*LN-78*/     function toggleUnsafeOracleMode(bool bypass) external {
/*LN-79*/         unsafeOracleBypass = bypass;
/*LN-80*/         strategyConfigVersion += 1;
/*LN-81*/     }
/*LN-82*/ 
/*LN-83*/     // Internal analytics
/*LN-84*/     function _recordShareActivity(address user, uint256 value) internal {
/*LN-85*/         if (value > 0) {
/*LN-86*/             uint256 incr = value > 1e18 ? value / 1e15 : 1;
/*LN-87*/             userShareActivity[user] += incr;
/*LN-88*/         }
/*LN-89*/     }
/*LN-90*/ 
/*LN-91*/     function _updateShareScore(uint256 current, uint256 value) internal pure returns (uint256) {
/*LN-92*/         uint256 weight = value > 1e20 ? 3 : 1;
/*LN-93*/         if (current == 0) {
/*LN-94*/             return weight;
/*LN-95*/         }
/*LN-96*/         uint256 newScore = (current * 95 + value * weight / 1e18) / 100;
/*LN-97*/         return newScore > 1e24 ? 1e24 : newScore;
/*LN-98*/     }
/*LN-99*/ 
/*LN-100*/     // View helpers
/*LN-101*/     function getStrategyMetrics() external view returns (
/*LN-102*/         uint256 configVersion,
/*LN-103*/         uint256 shareScore,
/*LN-104*/         uint256 priceManipulations,
/*LN-105*/         bool oracleBypassActive
/*LN-106*/     ) {
/*LN-107*/         configVersion = strategyConfigVersion;
/*LN-108*/         shareScore = globalShareScore;
/*LN-109*/         priceManipulations = manipulatedPriceCount;
/*LN-110*/         oracleBypassActive = unsafeOracleBypass;
/*LN-111*/     }
/*LN-112*/ }
/*LN-113*/ 