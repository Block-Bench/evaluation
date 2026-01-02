/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/     function transferFrom(
/*LN-7*/         address from,
/*LN-8*/         address to,
/*LN-9*/         uint256 amount
/*LN-10*/     ) external returns (bool);
/*LN-11*/     function balanceOf(address account) external view returns (uint256);
/*LN-12*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-13*/ }
/*LN-14*/ 
/*LN-15*/ interface IPriceOracle {
/*LN-16*/     function getPrice(address token) external view returns (uint256);
/*LN-17*/ }
/*LN-18*/ 
/*LN-19*/ contract BlueberryLending {
/*LN-20*/     struct Market {
/*LN-21*/         bool isListed;
/*LN-22*/         uint256 collateralFactor;
/*LN-23*/         mapping(address => uint256) accountCollateral;
/*LN-24*/         mapping(address => uint256) accountBorrows;
/*LN-25*/     }
/*LN-26*/ 
/*LN-27*/     mapping(address => Market) public markets;
/*LN-28*/     IPriceOracle public oracle;
/*LN-29*/ 
/*LN-30*/     uint256 public constant COLLATERAL_FACTOR = 75;
/*LN-31*/     uint256 public constant BASIS_POINTS = 100;
/*LN-32*/ 
/*LN-33*/     function enterMarkets(
/*LN-34*/         address[] calldata vTokens
/*LN-35*/     ) external returns (uint256[] memory) {
/*LN-36*/         uint256[] memory results = new uint256[](vTokens.length);
/*LN-37*/         for (uint256 i = 0; i < vTokens.length; i++) {
/*LN-38*/             markets[vTokens[i]].isListed = true;
/*LN-39*/             results[i] = 0;
/*LN-40*/         }
/*LN-41*/         return results;
/*LN-42*/     }
/*LN-43*/ 
/*LN-44*/     function mint(address token, uint256 amount) external returns (uint256) {
/*LN-45*/         IERC20(token).transferFrom(msg.sender, address(this), amount);
/*LN-46*/ 
/*LN-47*/         uint256 price = oracle.getPrice(token);
/*LN-48*/ 
/*LN-49*/         markets[token].accountCollateral[msg.sender] += amount;
/*LN-50*/         return 0;
/*LN-51*/     }
/*LN-52*/ 
/*LN-53*/     function borrow(
/*LN-54*/         address borrowToken,
/*LN-55*/         uint256 borrowAmount
/*LN-56*/     ) external returns (uint256) {
/*LN-57*/         uint256 totalCollateralValue = 0;
/*LN-58*/ 
/*LN-59*/         uint256 borrowPrice = oracle.getPrice(borrowToken);
/*LN-60*/         uint256 borrowValue = (borrowAmount * borrowPrice) / 1e18;
/*LN-61*/ 
/*LN-62*/         uint256 maxBorrowValue = (totalCollateralValue * COLLATERAL_FACTOR) / BASIS_POINTS;
/*LN-63*/ 
/*LN-64*/         require(borrowValue <= maxBorrowValue, "Insufficient collateral");
/*LN-65*/ 
/*LN-66*/         markets[borrowToken].accountBorrows[msg.sender] += borrowAmount;
/*LN-67*/         IERC20(borrowToken).transfer(msg.sender, borrowAmount);
/*LN-68*/ 
/*LN-69*/         return 0;
/*LN-70*/     }
/*LN-71*/ 
/*LN-72*/     function liquidate(
/*LN-73*/         address borrower,
/*LN-74*/         address repayToken,
/*LN-75*/         uint256 repayAmount,
/*LN-76*/         address collateralToken
/*LN-77*/     ) external {}
/*LN-78*/ }
/*LN-79*/ 
/*LN-80*/ contract ManipulableOracle is IPriceOracle {
/*LN-81*/     mapping(address => uint256) public prices;
/*LN-82*/     mapping(address => uint256) public lastUpdate;
/*LN-83*/     uint256 public constant MIN_LIQUIDITY = 1e18;
/*LN-84*/     uint256 public constant UPDATE_INTERVAL = 1 hours;
/*LN-85*/ 
/*LN-86*/     function getPrice(address token) external view override returns (uint256) {
/*LN-87*/         require(block.timestamp - lastUpdate[token] < UPDATE_INTERVAL, "Price stale");
/*LN-88*/         return prices[token];
/*LN-89*/     }
/*LN-90*/ 
/*LN-91*/     function setPrice(address token, uint256 price) external {
/*LN-92*/         require(price >= MIN_LIQUIDITY, "Price too low");
/*LN-93*/         prices[token] = price;
/*LN-94*/         lastUpdate[token] = block.timestamp;
/*LN-95*/     }
/*LN-96*/ }
/*LN-97*/ 