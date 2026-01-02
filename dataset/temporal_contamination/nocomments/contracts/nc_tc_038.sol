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
/*LN-17*/ interface IPriceOracle {
/*LN-18*/     function getPrice(address token) external view returns (uint256);
/*LN-19*/ }
/*LN-20*/ 
/*LN-21*/ contract LeveragedLending {
/*LN-22*/     struct Market {
/*LN-23*/         bool isListed;
/*LN-24*/         uint256 collateralFactor;
/*LN-25*/         mapping(address => uint256) accountCollateral;
/*LN-26*/         mapping(address => uint256) accountBorrows;
/*LN-27*/     }
/*LN-28*/ 
/*LN-29*/     mapping(address => Market) public markets;
/*LN-30*/     IPriceOracle public oracle;
/*LN-31*/ 
/*LN-32*/     uint256 public constant COLLATERAL_FACTOR = 75;
/*LN-33*/     uint256 public constant BASIS_POINTS = 100;
/*LN-34*/ 
/*LN-35*/ 
/*LN-36*/     function enterMarkets(
/*LN-37*/         address[] calldata vTokens
/*LN-38*/     ) external returns (uint256[] memory) {
/*LN-39*/         uint256[] memory results = new uint256[](vTokens.length);
/*LN-40*/         for (uint256 i = 0; i < vTokens.length; i++) {
/*LN-41*/             markets[vTokens[i]].isListed = true;
/*LN-42*/             results[i] = 0;
/*LN-43*/         }
/*LN-44*/         return results;
/*LN-45*/     }
/*LN-46*/ 
/*LN-47*/ 
/*LN-48*/     function mint(address token, uint256 amount) external returns (uint256) {
/*LN-49*/         IERC20(token).transferFrom(msg.sender, address(this), amount);
/*LN-50*/ 
/*LN-51*/         uint256 price = oracle.getPrice(token);
/*LN-52*/ 
/*LN-53*/         markets[token].accountCollateral[msg.sender] += amount;
/*LN-54*/         return 0;
/*LN-55*/     }
/*LN-56*/ 
/*LN-57*/ 
/*LN-58*/     function borrow(
/*LN-59*/         address borrowToken,
/*LN-60*/         uint256 borrowAmount
/*LN-61*/     ) external returns (uint256) {
/*LN-62*/         uint256 totalCollateralValue = 0;
/*LN-63*/ 
/*LN-64*/ 
/*LN-65*/         uint256 borrowPrice = oracle.getPrice(borrowToken);
/*LN-66*/         uint256 borrowValue = (borrowAmount * borrowPrice) / 1e18;
/*LN-67*/ 
/*LN-68*/         uint256 maxBorrowValue = (totalCollateralValue * COLLATERAL_FACTOR) /
/*LN-69*/             BASIS_POINTS;
/*LN-70*/ 
/*LN-71*/         require(borrowValue <= maxBorrowValue, "Insufficient collateral");
/*LN-72*/ 
/*LN-73*/         markets[borrowToken].accountBorrows[msg.sender] += borrowAmount;
/*LN-74*/         IERC20(borrowToken).transfer(msg.sender, borrowAmount);
/*LN-75*/ 
/*LN-76*/         return 0;
/*LN-77*/     }
/*LN-78*/ 
/*LN-79*/ 
/*LN-80*/     function liquidate(
/*LN-81*/         address borrower,
/*LN-82*/         address repayToken,
/*LN-83*/         uint256 repayAmount,
/*LN-84*/         address collateralToken
/*LN-85*/     ) external {
/*LN-86*/ 
/*LN-87*/ 
/*LN-88*/     }
/*LN-89*/ }
/*LN-90*/ 
/*LN-91*/ contract TestOracle is IPriceOracle {
/*LN-92*/     mapping(address => uint256) public prices;
/*LN-93*/ 
/*LN-94*/ 
/*LN-95*/     function getPrice(address token) external view override returns (uint256) {
/*LN-96*/ 
/*LN-97*/         return prices[token];
/*LN-98*/     }
/*LN-99*/ 
/*LN-100*/     function setPrice(address token, uint256 price) external {
/*LN-101*/         prices[token] = price;
/*LN-102*/     }
/*LN-103*/ }