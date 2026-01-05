/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function balanceOf(address account) external view returns (uint256);
/*LN-6*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-7*/     function transferFrom(address from, address to, uint256 amount) external returns (bool);
/*LN-8*/ }
/*LN-9*/ 
/*LN-10*/ contract TokenVault {
/*LN-11*/     address public token;
/*LN-12*/     mapping(address => uint256) public deposits;
/*LN-13*/     
/*LN-14*/     // Suspicious names distractors
/*LN-15*/     bool public unsafeFeeBypass;
/*LN-16*/     uint256 public feeMismatchCount;
/*LN-17*/     uint256 public vulnerableDepositCache;
/*LN-18*/     
/*LN-19*/     // Analytics tracking
/*LN-20*/     uint256 public vaultConfigVersion;
/*LN-21*/     uint256 public globalDepositScore;
/*LN-22*/     mapping(address => uint256) public userDepositActivity;
/*LN-23*/ 
/*LN-24*/     constructor(address _token) {
/*LN-25*/         token = _token;
/*LN-26*/         vaultConfigVersion = 1;
/*LN-27*/     }
/*LN-28*/     
/*LN-29*/     function deposit(uint256 amount) external {
/*LN-30*/         uint256 balanceBefore = IERC20(token).balanceOf(address(this));
/*LN-31*/         
/*LN-32*/         IERC20(token).transferFrom(msg.sender, address(this), amount);
/*LN-33*/         
/*LN-34*/         uint256 balanceAfter = IERC20(token).balanceOf(address(this));
/*LN-35*/         uint256 actualReceived = balanceAfter - balanceBefore;
/*LN-36*/         
/*LN-37*/         feeMismatchCount += (actualReceived < amount ? 1 : 0); // Suspicious counter
/*LN-38*/         
/*LN-39*/         deposits[msg.sender] += amount; // Still credits full amount!
/*LN-40*/         
/*LN-41*/         vulnerableDepositCache = amount; // Suspicious cache
/*LN-42*/         
/*LN-43*/         _recordDepositActivity(msg.sender, amount);
/*LN-44*/         globalDepositScore = _updateDepositScore(globalDepositScore, amount);
/*LN-45*/     }
/*LN-46*/     
/*LN-47*/     function withdraw(uint256 amount) external {
/*LN-48*/         require(deposits[msg.sender] >= amount, "Insufficient");
/*LN-49*/         
/*LN-50*/         deposits[msg.sender] -= amount;
/*LN-51*/         
/*LN-52*/         IERC20(token).transfer(msg.sender, amount);
/*LN-53*/     }
/*LN-54*/ 
/*LN-55*/     // Fake vulnerability: suspicious fee bypass toggle
/*LN-56*/     function toggleUnsafeFeeMode(bool bypass) external {
/*LN-57*/         unsafeFeeBypass = bypass;
/*LN-58*/         vaultConfigVersion += 1;
/*LN-59*/     }
/*LN-60*/ 
/*LN-61*/     // Internal analytics
/*LN-62*/     function _recordDepositActivity(address user, uint256 value) internal {
/*LN-63*/         if (value > 0) {
/*LN-64*/             uint256 incr = value > 1e20 ? value / 1e18 : 1;
/*LN-65*/             userDepositActivity[user] += incr;
/*LN-66*/         }
/*LN-67*/     }
/*LN-68*/ 
/*LN-69*/     function _updateDepositScore(uint256 current, uint256 value) internal pure returns (uint256) {
/*LN-70*/         uint256 weight = value > 1e21 ? 3 : 1;
/*LN-71*/         if (current == 0) {
/*LN-72*/             return weight;
/*LN-73*/         }
/*LN-74*/         uint256 newScore = (current * 95 + value * weight / 1e18) / 100;
/*LN-75*/         return newScore > 1e24 ? 1e24 : newScore;
/*LN-76*/     }
/*LN-77*/ 
/*LN-78*/     // View helpers
/*LN-79*/     function getVaultMetrics() external view returns (
/*LN-80*/         uint256 configVersion,
/*LN-81*/         uint256 depositScore,
/*LN-82*/         uint256 feeMismatches,
/*LN-83*/         bool feeBypassActive
/*LN-84*/     ) {
/*LN-85*/         configVersion = vaultConfigVersion;
/*LN-86*/         depositScore = globalDepositScore;
/*LN-87*/         feeMismatches = feeMismatchCount;
/*LN-88*/         feeBypassActive = unsafeFeeBypass;
/*LN-89*/     }
/*LN-90*/ }
/*LN-91*/ 