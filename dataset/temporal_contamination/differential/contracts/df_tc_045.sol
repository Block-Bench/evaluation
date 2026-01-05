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
/*LN-12*/ }
/*LN-13*/ 
/*LN-14*/ interface IMarket {
/*LN-15*/     function getAccountSnapshot(
/*LN-16*/         address account
/*LN-17*/     )
/*LN-18*/         external
/*LN-19*/         view
/*LN-20*/         returns (uint256 collateral, uint256 borrows, uint256 exchangeRate);
/*LN-21*/ }
/*LN-22*/ 
/*LN-23*/ contract DebtPreviewer {
/*LN-24*/     mapping(address => bool) public approvedMarkets;
/*LN-25*/     address public admin;
/*LN-26*/ 
/*LN-27*/     constructor() {
/*LN-28*/         admin = msg.sender;
/*LN-29*/     }
/*LN-30*/ 
/*LN-31*/     modifier onlyAdmin() {
/*LN-32*/         require(msg.sender == admin, "Not admin");
/*LN-33*/         _;
/*LN-34*/     }
/*LN-35*/ 
/*LN-36*/     function addApprovedMarket(address market) external onlyAdmin {
/*LN-37*/         approvedMarkets[market] = true;
/*LN-38*/     }
/*LN-39*/ 
/*LN-40*/     function previewDebt(
/*LN-41*/         address market,
/*LN-42*/         address account
/*LN-43*/     )
/*LN-44*/         external
/*LN-45*/         view
/*LN-46*/         returns (
/*LN-47*/             uint256 collateralValue,
/*LN-48*/             uint256 debtValue,
/*LN-49*/             uint256 healthFactor
/*LN-50*/         )
/*LN-51*/     {
/*LN-52*/         require(approvedMarkets[market], "Market not approved");
/*LN-53*/         (uint256 collateral, uint256 borrows, uint256 exchangeRate) = IMarket(
/*LN-54*/             market
/*LN-55*/         ).getAccountSnapshot(account);
/*LN-56*/ 
/*LN-57*/         collateralValue = (collateral * exchangeRate) / 1e18;
/*LN-58*/         debtValue = borrows;
/*LN-59*/ 
/*LN-60*/         if (debtValue == 0) {
/*LN-61*/             healthFactor = type(uint256).max;
/*LN-62*/         } else {
/*LN-63*/             healthFactor = (collateralValue * 1e18) / debtValue;
/*LN-64*/         }
/*LN-65*/ 
/*LN-66*/         return (collateralValue, debtValue, healthFactor);
/*LN-67*/     }
/*LN-68*/ 
/*LN-69*/     function previewMultipleMarkets(
/*LN-70*/         address[] calldata markets,
/*LN-71*/         address account
/*LN-72*/     )
/*LN-73*/         external
/*LN-74*/         view
/*LN-75*/         returns (
/*LN-76*/             uint256 totalCollateral,
/*LN-77*/             uint256 totalDebt,
/*LN-78*/             uint256 overallHealth
/*LN-79*/         )
/*LN-80*/     {
/*LN-81*/         for (uint256 i = 0; i < markets.length; i++) {
/*LN-82*/             require(approvedMarkets[markets[i]], "Market not approved");
/*LN-83*/             (uint256 collateral, uint256 debt, ) = this.previewDebt(
/*LN-84*/                 markets[i],
/*LN-85*/                 account
/*LN-86*/             );
/*LN-87*/ 
/*LN-88*/             totalCollateral += collateral;
/*LN-89*/             totalDebt += debt;
/*LN-90*/         }
/*LN-91*/ 
/*LN-92*/         if (totalDebt == 0) {
/*LN-93*/             overallHealth = type(uint256).max;
/*LN-94*/         } else {
/*LN-95*/             overallHealth = (totalCollateral * 1e18) / totalDebt;
/*LN-96*/         }
/*LN-97*/ 
/*LN-98*/         return (totalCollateral, totalDebt, overallHealth);
/*LN-99*/     }
/*LN-100*/ }
/*LN-101*/ 
/*LN-102*/ contract ExactlyMarket {
/*LN-103*/     IERC20 public asset;
/*LN-104*/     DebtPreviewer public previewer;
/*LN-105*/ 
/*LN-106*/     mapping(address => uint256) public deposits;
/*LN-107*/     mapping(address => uint256) public borrows;
/*LN-108*/ 
/*LN-109*/     uint256 public constant COLLATERAL_FACTOR = 80;
/*LN-110*/ 
/*LN-111*/     constructor(address _asset, address _previewer) {
/*LN-112*/         asset = IERC20(_asset);
/*LN-113*/         previewer = DebtPreviewer(_previewer);
/*LN-114*/     }
/*LN-115*/ 
/*LN-116*/     function deposit(uint256 amount) external {
/*LN-117*/         asset.transferFrom(msg.sender, address(this), amount);
/*LN-118*/         deposits[msg.sender] += amount;
/*LN-119*/     }
/*LN-120*/ 
/*LN-121*/     function borrow(uint256 amount, address[] calldata markets) external {
/*LN-122*/         (uint256 totalCollateral, uint256 totalDebt, ) = previewer
/*LN-123*/             .previewMultipleMarkets(markets, msg.sender);
/*LN-124*/ 
/*LN-125*/         uint256 newDebt = totalDebt + amount;
/*LN-126*/ 
/*LN-127*/         uint256 maxBorrow = (totalCollateral * COLLATERAL_FACTOR) / 100;
/*LN-128*/         require(newDebt <= maxBorrow, "Insufficient collateral");
/*LN-129*/ 
/*LN-130*/         borrows[msg.sender] += amount;
/*LN-131*/         asset.transfer(msg.sender, amount);
/*LN-132*/     }
/*LN-133*/ 
/*LN-134*/     function getAccountSnapshot(
/*LN-135*/         address account
/*LN-136*/     )
/*LN-137*/         external
/*LN-138*/         view
/*LN-139*/         returns (uint256 collateral, uint256 borrowed, uint256 exchangeRate)
/*LN-140*/     {
/*LN-141*/         return (deposits[account], borrows[account], 1e18);
/*LN-142*/     }
/*LN-143*/ }
/*LN-144*/ 