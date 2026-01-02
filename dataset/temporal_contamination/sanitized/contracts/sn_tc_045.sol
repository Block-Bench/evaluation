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
/*LN-14*/ 
/*LN-15*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-16*/ }
/*LN-17*/ 
/*LN-18*/ interface IPendleMarket {
/*LN-19*/     function getRewardTokens() external view returns (address[] memory);
/*LN-20*/ 
/*LN-21*/     function rewardIndexesCurrent() external returns (uint256[] memory);
/*LN-22*/ 
/*LN-23*/     function claimRewards(address user) external returns (uint256[] memory);
/*LN-24*/ }
/*LN-25*/ 
/*LN-26*/ contract VeTokenStaking {
/*LN-27*/     mapping(address => mapping(address => uint256)) public userBalances;
/*LN-28*/     mapping(address => uint256) public totalStaked;
/*LN-29*/ 
/*LN-30*/     /**
/*LN-31*/ 
/*LN-32*/      */
/*LN-33*/     function deposit(address market, uint256 amount) external {
/*LN-34*/         IERC20(market).transferFrom(msg.sender, address(this), amount);
/*LN-35*/         userBalances[market][msg.sender] += amount;
/*LN-36*/         totalStaked[market] += amount;
/*LN-37*/     }
/*LN-38*/ 
/*LN-39*/     function claimRewards(address market, address user) external {
/*LN-40*/ 
/*LN-41*/         // Get pending rewards
/*LN-42*/         uint256[] memory rewards = IPendleMarket(market).claimRewards(user);
/*LN-43*/ 
/*LN-44*/         // Update user's reward balance
/*LN-45*/         for (uint256 i = 0; i < rewards.length; i++) {
/*LN-46*/             // Process rewards
/*LN-47*/         }
/*LN-48*/     }
/*LN-49*/ 
/*LN-50*/     /**
/*LN-51*/      * @notice Withdraw staked tokens
/*LN-52*/      */
/*LN-53*/     function withdraw(address market, uint256 amount) external {
/*LN-54*/         require(
/*LN-55*/             userBalances[market][msg.sender] >= amount,
/*LN-56*/             "Insufficient balance"
/*LN-57*/         );
/*LN-58*/ 
/*LN-59*/         userBalances[market][msg.sender] -= amount;
/*LN-60*/         totalStaked[market] -= amount;
/*LN-61*/ 
/*LN-62*/         IERC20(market).transfer(msg.sender, amount);
/*LN-63*/     }
/*LN-64*/ }
/*LN-65*/ 
/*LN-66*/ contract YieldMarketRegister {
/*LN-67*/     mapping(address => bool) public registeredMarkets;
/*LN-68*/ 
/*LN-69*/     function registerMarket(address market) external {
/*LN-70*/ 
/*LN-71*/         registeredMarkets[market] = true;
/*LN-72*/     }
/*LN-73*/ }
/*LN-74*/ 