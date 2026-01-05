/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-5*/ 
/*LN-6*/     function transferFrom(
/*LN-7*/         address from,
/*LN-8*/         address to,
/*LN-9*/         uint256 amount
/*LN-10*/     ) external returns (bool);
/*LN-11*/ 
/*LN-12*/     function balanceOf(address account) external view returns (uint256);
/*LN-13*/ 
/*LN-14*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-15*/ }
/*LN-16*/ 
/*LN-17*/ interface IPendleMarket {
/*LN-18*/     function getRewardTokens() external view returns (address[] memory);
/*LN-19*/ 
/*LN-20*/     function rewardIndexesCurrent() external returns (uint256[] memory);
/*LN-21*/ 
/*LN-22*/     function claimRewards(address user) external returns (uint256[] memory);
/*LN-23*/ }
/*LN-24*/ 
/*LN-25*/ contract VeTokenStaking {
/*LN-26*/     mapping(address => mapping(address => uint256)) public userBalances;
/*LN-27*/     mapping(address => uint256) public totalStaked;
/*LN-28*/ 
/*LN-29*/ 
/*LN-30*/     function deposit(address market, uint256 amount) external {
/*LN-31*/         IERC20(market).transferFrom(msg.sender, address(this), amount);
/*LN-32*/         userBalances[market][msg.sender] += amount;
/*LN-33*/         totalStaked[market] += amount;
/*LN-34*/     }
/*LN-35*/ 
/*LN-36*/     function claimRewards(address market, address user) external {
/*LN-37*/ 
/*LN-38*/ 
/*LN-39*/         uint256[] memory rewards = IPendleMarket(market).claimRewards(user);
/*LN-40*/ 
/*LN-41*/ 
/*LN-42*/         for (uint256 i = 0; i < rewards.length; i++) {
/*LN-43*/ 
/*LN-44*/         }
/*LN-45*/     }
/*LN-46*/ 
/*LN-47*/ 
/*LN-48*/     function withdraw(address market, uint256 amount) external {
/*LN-49*/         require(
/*LN-50*/             userBalances[market][msg.sender] >= amount,
/*LN-51*/             "Insufficient balance"
/*LN-52*/         );
/*LN-53*/ 
/*LN-54*/         userBalances[market][msg.sender] -= amount;
/*LN-55*/         totalStaked[market] -= amount;
/*LN-56*/ 
/*LN-57*/         IERC20(market).transfer(msg.sender, amount);
/*LN-58*/     }
/*LN-59*/ }
/*LN-60*/ 
/*LN-61*/ contract YieldMarketRegister {
/*LN-62*/     mapping(address => bool) public registeredMarkets;
/*LN-63*/ 
/*LN-64*/     function registerMarket(address market) external {
/*LN-65*/ 
/*LN-66*/         registeredMarkets[market] = true;
/*LN-67*/     }
/*LN-68*/ }