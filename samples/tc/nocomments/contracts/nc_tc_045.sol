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
/*LN-13*/ }
/*LN-14*/ 
/*LN-15*/ interface IMarket {
/*LN-16*/     function getAccountSnapshot(
/*LN-17*/         address account
/*LN-18*/     )
/*LN-19*/         external
/*LN-20*/         view
/*LN-21*/         returns (uint256 collateral, uint256 borrows, uint256 exchangeRate);
/*LN-22*/ }
/*LN-23*/ 
/*LN-24*/ contract DebtPreviewer {
/*LN-25*/     function previewDebt(
/*LN-26*/         address market,
/*LN-27*/         address account
/*LN-28*/     )
/*LN-29*/         external
/*LN-30*/         view
/*LN-31*/         returns (
/*LN-32*/             uint256 collateralValue,
/*LN-33*/             uint256 debtValue,
/*LN-34*/             uint256 healthFactor
/*LN-35*/         )
/*LN-36*/     {
/*LN-37*/ 
/*LN-38*/ 
/*LN-39*/         (uint256 collateral, uint256 borrows, uint256 exchangeRate) = IMarket(
/*LN-40*/             market
/*LN-41*/         ).getAccountSnapshot(account);
/*LN-42*/ 
/*LN-43*/         collateralValue = (collateral * exchangeRate) / 1e18;
/*LN-44*/         debtValue = borrows;
/*LN-45*/ 
/*LN-46*/         if (debtValue == 0) {
/*LN-47*/             healthFactor = type(uint256).max;
/*LN-48*/         } else {
/*LN-49*/             healthFactor = (collateralValue * 1e18) / debtValue;
/*LN-50*/         }
/*LN-51*/ 
/*LN-52*/         return (collateralValue, debtValue, healthFactor);
/*LN-53*/     }
/*LN-54*/ 
/*LN-55*/ 
/*LN-56*/     function previewMultipleMarkets(
/*LN-57*/         address[] calldata markets,
/*LN-58*/         address account
/*LN-59*/     )
/*LN-60*/         external
/*LN-61*/         view
/*LN-62*/         returns (
/*LN-63*/             uint256 totalCollateral,
/*LN-64*/             uint256 totalDebt,
/*LN-65*/             uint256 overallHealth
/*LN-66*/         )
/*LN-67*/     {
/*LN-68*/         for (uint256 i = 0; i < markets.length; i++) {
/*LN-69*/             (uint256 collateral, uint256 debt, ) = this.previewDebt(
/*LN-70*/                 markets[i],
/*LN-71*/                 account
/*LN-72*/             );
/*LN-73*/ 
/*LN-74*/             totalCollateral += collateral;
/*LN-75*/             totalDebt += debt;
/*LN-76*/         }
/*LN-77*/ 
/*LN-78*/         if (totalDebt == 0) {
/*LN-79*/             overallHealth = type(uint256).max;
/*LN-80*/         } else {
/*LN-81*/             overallHealth = (totalCollateral * 1e18) / totalDebt;
/*LN-82*/         }
/*LN-83*/ 
/*LN-84*/         return (totalCollateral, totalDebt, overallHealth);
/*LN-85*/     }
/*LN-86*/ }
/*LN-87*/ 
/*LN-88*/ 
/*LN-89*/ contract LendingMarket {
/*LN-90*/     IERC20 public asset;
/*LN-91*/     DebtPreviewer public previewer;
/*LN-92*/ 
/*LN-93*/     mapping(address => uint256) public deposits;
/*LN-94*/     mapping(address => uint256) public borrows;
/*LN-95*/ 
/*LN-96*/     uint256 public constant COLLATERAL_FACTOR = 80;
/*LN-97*/ 
/*LN-98*/     constructor(address _asset, address _previewer) {
/*LN-99*/         asset = IERC20(_asset);
/*LN-100*/         previewer = DebtPreviewer(_previewer);
/*LN-101*/     }
/*LN-102*/ 
/*LN-103*/     function deposit(uint256 amount) external {
/*LN-104*/         asset.transferFrom(msg.sender, address(this), amount);
/*LN-105*/         deposits[msg.sender] += amount;
/*LN-106*/     }
/*LN-107*/ 
/*LN-108*/ 
/*LN-109*/     function borrow(uint256 amount, address[] calldata markets) external {
/*LN-110*/         (uint256 totalCollateral, uint256 totalDebt, ) = previewer
/*LN-111*/             .previewMultipleMarkets(markets, msg.sender);
/*LN-112*/ 
/*LN-113*/ 
/*LN-114*/         uint256 newDebt = totalDebt + amount;
/*LN-115*/ 
/*LN-116*/         uint256 maxBorrow = (totalCollateral * COLLATERAL_FACTOR) / 100;
/*LN-117*/         require(newDebt <= maxBorrow, "Insufficient collateral");
/*LN-118*/ 
/*LN-119*/         borrows[msg.sender] += amount;
/*LN-120*/         asset.transfer(msg.sender, amount);
/*LN-121*/     }
/*LN-122*/ 
/*LN-123*/     function getAccountSnapshot(
/*LN-124*/         address account
/*LN-125*/     )
/*LN-126*/         external
/*LN-127*/         view
/*LN-128*/         returns (uint256 collateral, uint256 borrowed, uint256 exchangeRate)
/*LN-129*/     {
/*LN-130*/         return (deposits[account], borrows[account], 1e18);
/*LN-131*/     }
/*LN-132*/ }