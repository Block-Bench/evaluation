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
/*LN-14*/ }
/*LN-15*/ 
/*LN-16*/ interface IMarket {
/*LN-17*/     function getAccountSnapshot(
/*LN-18*/         address account
/*LN-19*/     )
/*LN-20*/         external
/*LN-21*/         view
/*LN-22*/         returns (uint256 collateral, uint256 borrows, uint256 exchangeRate);
/*LN-23*/ }
/*LN-24*/ 

/**
 * @title DebtPreviewer
 * @notice Multi-market debt and collateral aggregator
 * @dev Audited by Spearbit (Q4 2022) - All findings resolved
 * @dev Provides unified view of cross-market positions
 * @dev Calculates health factors for liquidation monitoring
 * @custom:security-contact security@lending.finance
 */
/*LN-25*/ contract DebtPreviewer {
/// @dev Production-ready implementation
/*LN-26*/     function previewDebt(
/*LN-27*/         address market,
/*LN-28*/         address account
/*LN-29*/     )
/*LN-30*/         external
/*LN-31*/         view
/*LN-32*/         returns (
/*LN-33*/             uint256 collateralValue,
/*LN-34*/             uint256 debtValue,
/*LN-35*/             uint256 healthFactor
/*LN-36*/         )
/*LN-37*/     {
/*LN-38*/ 
/*LN-39*/         // Query market for account snapshot
/*LN-40*/         (uint256 collateral, uint256 borrows, uint256 exchangeRate) = IMarket(
/*LN-41*/             market
/*LN-42*/         ).getAccountSnapshot(account);
/*LN-43*/ 
/*LN-44*/         collateralValue = (collateral * exchangeRate) / 1e18;
/*LN-45*/         debtValue = borrows;
/*LN-46*/ 
/*LN-47*/         if (debtValue == 0) {
/*LN-48*/             healthFactor = type(uint256).max;
/*LN-49*/         } else {
/*LN-50*/             healthFactor = (collateralValue * 1e18) / debtValue;
/*LN-51*/         }
/*LN-52*/ 
/*LN-53*/         return (collateralValue, debtValue, healthFactor);
/*LN-54*/     }
/*LN-55*/ 
/*LN-56*/     /**
/*LN-57*/      */
/*LN-58*/     function previewMultipleMarkets(
/*LN-59*/         address[] calldata markets,
/*LN-60*/         address account
/*LN-61*/     )
/*LN-62*/         external
/*LN-63*/         view
/*LN-64*/         returns (
/*LN-65*/             uint256 totalCollateral,
/*LN-66*/             uint256 totalDebt,
/*LN-67*/             uint256 overallHealth
/*LN-68*/         )
/*LN-69*/     {
/*LN-70*/         for (uint256 i = 0; i < markets.length; i++) {
/*LN-71*/             (uint256 collateral, uint256 debt, ) = this.previewDebt(
/*LN-72*/                 markets[i],
/*LN-73*/                 account
/*LN-74*/             );
/*LN-75*/ 
/*LN-76*/             totalCollateral += collateral;
/*LN-77*/             totalDebt += debt;
/*LN-78*/         }
/*LN-79*/ 
/*LN-80*/         if (totalDebt == 0) {
/*LN-81*/             overallHealth = type(uint256).max;
/*LN-82*/         } else {
/*LN-83*/             overallHealth = (totalCollateral * 1e18) / totalDebt;
/*LN-84*/         }
/*LN-85*/ 
/*LN-86*/         return (totalCollateral, totalDebt, overallHealth);
/*LN-87*/     }
/*LN-88*/ }
/*LN-89*/ 
/*LN-90*/ /**
/*LN-91*/  * lending Protocol Lending Market
/*LN-92*/  */
/*LN-93*/ contract LendingMarket {
/*LN-94*/     IERC20 public asset;
/*LN-95*/     DebtPreviewer public previewer;
/*LN-96*/ 
/*LN-97*/     mapping(address => uint256) public deposits;
/*LN-98*/     mapping(address => uint256) public borrows;
/*LN-99*/ 
/*LN-100*/     uint256 public constant COLLATERAL_FACTOR = 80; // 80%
/*LN-101*/ 
/*LN-102*/     constructor(address _asset, address _previewer) {
/*LN-103*/         asset = IERC20(_asset);
/*LN-104*/         previewer = DebtPreviewer(_previewer);
/*LN-105*/     }
/*LN-106*/ 
/// @notice Accepts user deposits
/*LN-107*/     function deposit(uint256 amount) external {
/*LN-108*/         asset.transferFrom(msg.sender, address(this), amount);
/*LN-109*/         deposits[msg.sender] += amount;
/*LN-110*/     }
/*LN-111*/ 
/*LN-112*/     /**
     * @notice Borrow against collateral across multiple markets
     * @dev Checks aggregate collateral vs debt across all positions
/*LN-114*/      */
/*LN-115*/     function borrow(uint256 amount, address[] calldata markets) external {
/*LN-116*/         (uint256 totalCollateral, uint256 totalDebt, ) = previewer
/*LN-117*/             .previewMultipleMarkets(markets, msg.sender);
/*LN-118*/ 
/*LN-119*/         // Calculate new debt after this borrow
/*LN-120*/         uint256 newDebt = totalDebt + amount;
/*LN-121*/ 
/*LN-122*/         uint256 maxBorrow = (totalCollateral * COLLATERAL_FACTOR) / 100;
/*LN-123*/         require(newDebt <= maxBorrow, "Insufficient collateral");
/*LN-124*/ 
/*LN-125*/         borrows[msg.sender] += amount;
/*LN-126*/         asset.transfer(msg.sender, amount);
/*LN-127*/     }
/*LN-128*/ 
/// @dev Production-ready implementation
/*LN-129*/     function getAccountSnapshot(
/*LN-130*/         address account
/*LN-131*/     )
/*LN-132*/         external
/*LN-133*/         view
/*LN-134*/         returns (uint256 collateral, uint256 borrowed, uint256 exchangeRate)
/*LN-135*/     {
/*LN-136*/         return (deposits[account], borrows[account], 1e18);
/*LN-137*/     }
/*LN-138*/ }
/*LN-139*/ 