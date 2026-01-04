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
/*LN-26*/ contract PenpieStaking {
/*LN-27*/     mapping(address => mapping(address => uint256)) public userBalances;
/*LN-28*/     mapping(address => uint256) public totalStaked;
/*LN-29*/ 
/*LN-30*/     /**
/*LN-31*/      * @notice Deposit tokens into Penpie staking
/*LN-32*/      */
/*LN-33*/     function deposit(address market, uint256 amount) external {
/*LN-34*/         IERC20(market).transferFrom(msg.sender, address(this), amount);
/*LN-35*/         userBalances[market][msg.sender] += amount;
/*LN-36*/         totalStaked[market] += amount;
/*LN-37*/     }
/*LN-38*/ 
/*LN-39*/     function claimRewards(address market, address user) external {
/*LN-40*/         
/*LN-41*/ 
/*LN-42*/         
/*LN-43*/ 
/*LN-44*/         // Get pending rewards
/*LN-45*/         uint256[] memory rewards = IPendleMarket(market).claimRewards(user);
/*LN-46*/ 
/*LN-47*/         
/*LN-48*/ 
/*LN-49*/         // Update user's reward balance
/*LN-50*/         for (uint256 i = 0; i < rewards.length; i++) {
/*LN-51*/             // Process rewards
/*LN-52*/         }
/*LN-53*/     }
/*LN-54*/ 
/*LN-55*/     /**
/*LN-56*/      * @notice Withdraw staked tokens
/*LN-57*/      */
/*LN-58*/     function withdraw(address market, uint256 amount) external {
/*LN-59*/         require(
/*LN-60*/             userBalances[market][msg.sender] >= amount,
/*LN-61*/             "Insufficient balance"
/*LN-62*/         );
/*LN-63*/ 
/*LN-64*/         userBalances[market][msg.sender] -= amount;
/*LN-65*/         totalStaked[market] -= amount;
/*LN-66*/ 
/*LN-67*/         IERC20(market).transfer(msg.sender, amount);
/*LN-68*/     }
/*LN-69*/ }
/*LN-70*/ 
/*LN-71*/ contract PendleMarketRegister {
/*LN-72*/     mapping(address => bool) public registeredMarkets;
/*LN-73*/ 
/*LN-74*/     function registerMarket(address market) external {
/*LN-75*/ 
/*LN-76*/        
/*LN-77*/         registeredMarkets[market] = true;
/*LN-78*/     }
/*LN-79*/ }
/*LN-80*/ 