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
/*LN-29*/     mapping(address => bool) public registeredMarkets;
/*LN-30*/     address public admin;
/*LN-31*/ 
/*LN-32*/     bool private _locked;
/*LN-33*/ 
/*LN-34*/     constructor() {
/*LN-35*/         admin = msg.sender;
/*LN-36*/     }
/*LN-37*/ 
/*LN-38*/     modifier nonReentrant() {
/*LN-39*/         require(!_locked, "Reentrant call");
/*LN-40*/         _locked = true;
/*LN-41*/         _;
/*LN-42*/         _locked = false;
/*LN-43*/     }
/*LN-44*/ 
/*LN-45*/     modifier onlyAdmin() {
/*LN-46*/         require(msg.sender == admin, "Not admin");
/*LN-47*/         _;
/*LN-48*/     }
/*LN-49*/ 
/*LN-50*/     function registerMarket(address market) external onlyAdmin {
/*LN-51*/         registeredMarkets[market] = true;
/*LN-52*/     }
/*LN-53*/ 
/*LN-54*/     function deposit(address market, uint256 amount) external nonReentrant {
/*LN-55*/         require(registeredMarkets[market], "Market not registered");
/*LN-56*/         IERC20(market).transferFrom(msg.sender, address(this), amount);
/*LN-57*/         userBalances[market][msg.sender] += amount;
/*LN-58*/         totalStaked[market] += amount;
/*LN-59*/     }
/*LN-60*/ 
/*LN-61*/     function claimRewards(address market, address user) external nonReentrant {
/*LN-62*/         require(registeredMarkets[market], "Market not registered");
/*LN-63*/         uint256[] memory rewards = IPendleMarket(market).claimRewards(user);
/*LN-64*/ 
/*LN-65*/         for (uint256 i = 0; i < rewards.length; i++) {}
/*LN-66*/     }
/*LN-67*/ 
/*LN-68*/     function withdraw(address market, uint256 amount) external nonReentrant {
/*LN-69*/         require(registeredMarkets[market], "Market not registered");
/*LN-70*/         require(
/*LN-71*/             userBalances[market][msg.sender] >= amount,
/*LN-72*/             "Insufficient balance"
/*LN-73*/         );
/*LN-74*/ 
/*LN-75*/         userBalances[market][msg.sender] -= amount;
/*LN-76*/         totalStaked[market] -= amount;
/*LN-77*/ 
/*LN-78*/         IERC20(market).transfer(msg.sender, amount);
/*LN-79*/     }
/*LN-80*/ }
/*LN-81*/ 
/*LN-82*/ contract PendleMarketRegister {
/*LN-83*/     mapping(address => bool) public registeredMarkets;
/*LN-84*/     address public admin;
/*LN-85*/ 
/*LN-86*/     constructor() {
/*LN-87*/         admin = msg.sender;
/*LN-88*/     }
/*LN-89*/ 
/*LN-90*/     function registerMarket(address market) external {
/*LN-91*/         require(msg.sender == admin, "Not admin");
/*LN-92*/         registeredMarkets[market] = true;
/*LN-93*/     }
/*LN-94*/ }
/*LN-95*/ 