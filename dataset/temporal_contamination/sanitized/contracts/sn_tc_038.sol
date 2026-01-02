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
/*LN-18*/ interface IPriceOracle {
/*LN-19*/     function getPrice(address token) external view returns (uint256);
/*LN-20*/ }
/*LN-21*/ 
/*LN-22*/ contract LeveragedLending {
/*LN-23*/     struct Market {
/*LN-24*/         bool isListed;
/*LN-25*/         uint256 collateralFactor;
/*LN-26*/         mapping(address => uint256) accountCollateral;
/*LN-27*/         mapping(address => uint256) accountBorrows;
/*LN-28*/     }
/*LN-29*/ 
/*LN-30*/     mapping(address => Market) public markets;
/*LN-31*/     IPriceOracle public oracle;
/*LN-32*/ 
/*LN-33*/     uint256 public constant COLLATERAL_FACTOR = 75;
/*LN-34*/     uint256 public constant BASIS_POINTS = 100;
/*LN-35*/ 
/*LN-36*/     /**
/*LN-37*/      * @notice Enter markets to use as collateral
/*LN-38*/      */
/*LN-39*/     function enterMarkets(
/*LN-40*/         address[] calldata vTokens
/*LN-41*/     ) external returns (uint256[] memory) {
/*LN-42*/         uint256[] memory results = new uint256[](vTokens.length);
/*LN-43*/         for (uint256 i = 0; i < vTokens.length; i++) {
/*LN-44*/             markets[vTokens[i]].isListed = true;
/*LN-45*/             results[i] = 0;
/*LN-46*/         }
/*LN-47*/         return results;
/*LN-48*/     }
/*LN-49*/ 
/*LN-50*/     /**
/*LN-51*/      * @notice Mint collateral tokens
/*LN-52*/      */
/*LN-53*/     function mint(address token, uint256 amount) external returns (uint256) {
/*LN-54*/         IERC20(token).transferFrom(msg.sender, address(this), amount);
/*LN-55*/ 
/*LN-56*/         uint256 price = oracle.getPrice(token);
/*LN-57*/ 
/*LN-58*/         markets[token].accountCollateral[msg.sender] += amount;
/*LN-59*/         return 0;
/*LN-60*/     }
/*LN-61*/ 
/*LN-62*/     /**
/*LN-63*/      * @notice Borrow tokens against collateral
/*LN-64*/      */
/*LN-65*/     function borrow(
/*LN-66*/         address borrowToken,
/*LN-67*/         uint256 borrowAmount
/*LN-68*/     ) external returns (uint256) {
/*LN-69*/         uint256 totalCollateralValue = 0;
/*LN-70*/ 
/*LN-71*/         // Sum up all collateral value (would iterate through user's collateral)
/*LN-72*/ 
/*LN-73*/         uint256 borrowPrice = oracle.getPrice(borrowToken);
/*LN-74*/         uint256 borrowValue = (borrowAmount * borrowPrice) / 1e18;
/*LN-75*/ 
/*LN-76*/         uint256 maxBorrowValue = (totalCollateralValue * COLLATERAL_FACTOR) /
/*LN-77*/             BASIS_POINTS;
/*LN-78*/ 
/*LN-79*/         require(borrowValue <= maxBorrowValue, "Insufficient collateral");
/*LN-80*/ 
/*LN-81*/         markets[borrowToken].accountBorrows[msg.sender] += borrowAmount;
/*LN-82*/         IERC20(borrowToken).transfer(msg.sender, borrowAmount);
/*LN-83*/ 
/*LN-84*/         return 0;
/*LN-85*/     }
/*LN-86*/ 
/*LN-87*/     /**
/*LN-88*/      * @notice Liquidate undercollateralized position
/*LN-89*/      */
/*LN-90*/     function liquidate(
/*LN-91*/         address borrower,
/*LN-92*/         address repayToken,
/*LN-93*/         uint256 repayAmount,
/*LN-94*/         address collateralToken
/*LN-95*/     ) external {
/*LN-96*/         // Liquidation logic (simplified)
/*LN-97*/         // Would check if borrower is undercollateralized
/*LN-98*/     }
/*LN-99*/ }
/*LN-100*/ 
/*LN-101*/ contract TestOracle is IPriceOracle {
/*LN-102*/     mapping(address => uint256) public prices;
/*LN-103*/ 
/*LN-104*/     /**
/*LN-105*/      * @notice Get token price
/*LN-106*/      */
/*LN-107*/     function getPrice(address token) external view override returns (uint256) {
/*LN-108*/ 
/*LN-109*/         return prices[token];
/*LN-110*/     }
/*LN-111*/ 
/*LN-112*/     function setPrice(address token, uint256 price) external {
/*LN-113*/         prices[token] = price;
/*LN-114*/     }
/*LN-115*/ }
/*LN-116*/ 