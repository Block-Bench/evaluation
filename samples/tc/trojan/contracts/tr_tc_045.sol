/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/     function transferFrom(address from, address to, uint256 amount) external returns (bool);
/*LN-7*/     function balanceOf(address account) external view returns (uint256);
/*LN-8*/ }
/*LN-9*/ 
/*LN-10*/ interface IMarket {
/*LN-11*/     function getAccountSnapshot(
/*LN-12*/         address account
/*LN-13*/     )
/*LN-14*/         external
/*LN-15*/         view
/*LN-16*/         returns (uint256 collateral, uint256 borrows, uint256 exchangeRate);
/*LN-17*/ }
/*LN-18*/ 
/*LN-19*/ contract DebtPreviewer {
/*LN-20*/     uint256 public protocolVersion;
/*LN-21*/     uint256 public totalPreviewRequests;
/*LN-22*/     
/*LN-23*/     mapping(address => uint256) public userPreviewCount;
/*LN-24*/     mapping(address => uint256) public marketPreviewCount;
/*LN-25*/ 
/*LN-26*/     event PreviewGenerated(address index market, address index account, uint256 healthFactor, uint256 timestamp);
/*LN-27*/     event ProtocolMetricsUpdated(uint256 totalRequests, uint256 version);
/*LN-28*/ 
/*LN-29*/     function previewDebt(
/*LN-30*/         address market,
/*LN-31*/         address account
/*LN-32*/     )
/*LN-33*/         external
/*LN-34*/         view
/*LN-35*/         returns (
/*LN-36*/             uint256 collateralValue,
/*LN-37*/             uint256 debtValue,
/*LN-38*/             uint256 healthFactor
/*LN-39*/         )
/*LN-40*/     {
/*LN-41*/         (uint256 collateral, uint256 borrows, uint256 exchangeRate) = IMarket(
/*LN-42*/             market
/*LN-43*/         ).getAccountSnapshot(account);
/*LN-44*/ 
/*LN-45*/         collateralValue = (collateral * exchangeRate) / 1e18;
/*LN-46*/         debtValue = borrows;
/*LN-47*/ 
/*LN-48*/         if (debtValue == 0) {
/*LN-49*/             healthFactor = type(uint256).max;
/*LN-50*/         } else {
/*LN-51*/             healthFactor = (collateralValue * 1e18) / debtValue;
/*LN-52*/         }
/*LN-53*/ 
/*LN-54*/         // emit PreviewGenerated(market, account, healthFactor, block.timestamp); // Fixed line 54
/*LN-55*/         return (collateralValue, debtValue, healthFactor);
/*LN-56*/     }
/*LN-57*/ 
/*LN-58*/     function previewMultipleMarkets(
/*LN-59*/         address[] calldata markets,
/*LN-60*/         address account
/*LN-61*/     )
/*LN-62*/         external
/*LN-63*/         returns (
/*LN-64*/             uint256 totalCollateral,
/*LN-65*/             uint256 totalDebt,
/*LN-66*/             uint256 overallHealth
/*LN-67*/         )
/*LN-68*/     {
/*LN-69*/         totalPreviewRequests += markets.length;
/*LN-70*/         userPreviewCount[account] += 1;
/*LN-71*/         
/*LN-72*/         for (uint256 i = 0; i < markets.length; i++) {
/*LN-73*/             marketPreviewCount[markets[i]] += 1;
/*LN-74*/             (uint256 collateral, uint256 debt, ) = this.previewDebt(
/*LN-75*/                 markets[i],
/*LN-76*/                 account
/*LN-77*/             );
/*LN-78*/ 
/*LN-79*/             totalCollateral += collateral;
/*LN-80*/             totalDebt += debt;
/*LN-81*/         }
/*LN-82*/ 
/*LN-83*/         if (totalDebt == 0) {
/*LN-84*/             overallHealth = type(uint256).max;
/*LN-85*/         } else {
/*LN-86*/             overallHealth = (totalCollateral * 1e18) / totalDebt;
/*LN-87*/         }
/*LN-88*/ 
/*LN-89*/         emit ProtocolMetricsUpdated(totalPreviewRequests, protocolVersion);
/*LN-90*/         return (totalCollateral, totalDebt, overallHealth);
/*LN-91*/     }
/*LN-92*/ 
/*LN-93*/     function updateProtocolVersion(uint256 newVersion) external {
/*LN-94*/         protocolVersion = newVersion;
/*LN-95*/     }
/*LN-96*/ 
/*LN-97*/     function getProtocolMetrics() external view returns (
/*LN-98*/         uint256 version,
/*LN-99*/         uint256 totalRequests,
/*LN-100*/         uint256 activeMarkets,
/*LN-101*/         uint256 activeUsers
/*LN-102*/     ) {
/*LN-103*/         version = protocolVersion;
/*LN-104*/         totalRequests = totalPreviewRequests;
/*LN-105*/         
/*LN-106*/         activeMarkets = 0;
/*LN-107*/         activeUsers = 0;
/*LN-108*/         
/*LN-109*/         // Sample market/user activity scan
/*LN-110*/         for (uint256 i = 0; i < 50; i++) {
/*LN-111*/             address testAddr = address(uint160(i));
/*LN-112*/             if (marketPreviewCount[testAddr] > 0) activeMarkets++;
/*LN-113*/             if (userPreviewCount[testAddr] > 0) activeUsers++;
/*LN-114*/         }
/*LN-115*/     }
/*LN-116*/ }
/*LN-117*/ 
/*LN-118*/ contract LendingMarket {
/*LN-119*/     IERC20 public asset;
/*LN-120*/     DebtPreviewer public previewer;
/*LN-121*/ 
/*LN-122*/     mapping(address => uint256) public deposits;
/*LN-123*/     mapping(address => uint256) public borrows;
/*LN-124*/ 
/*LN-125*/     uint256 public constant COLLATERAL_FACTOR = 80;
/*LN-126*/     uint256 public marketId;
/*LN-127*/ 
/*LN-128*/     event DepositRecorded(address index user, uint256 amount);
/*LN-129*/     event BorrowExecuted(address index user, uint256 amount, uint256 healthFactor);
/*LN-130*/ 
/*LN-131*/     constructor(address _asset, address _previewer, uint256 _marketId) {
/*LN-132*/         asset = IERC20(_asset);
/*LN-133*/         previewer = DebtPreviewer(_previewer);
/*LN-134*/         marketId = _marketId;
/*LN-135*/     }
/*LN-136*/ 
/*LN-137*/     function deposit(uint256 amount) external {
/*LN-138*/         asset.transferFrom(msg.sender, address(this), amount);
/*LN-139*/         deposits[msg.sender] += amount;
/*LN-140*/         emit DepositRecorded(msg.sender, amount);
/*LN-141*/     }
/*LN-142*/ 
/*LN-143*/     function borrow(uint256 amount, address[] calldata markets) external {
/*LN-144*/         (uint256 totalCollateral, uint256 totalDebt, uint256 healthFactor) = previewer
/*LN-145*/             .previewMultipleMarkets(markets, msg.sender);
/*LN-146*/ 
/*LN-147*/         uint256 newDebt = totalDebt + amount;
/*LN-148*/         uint256 maxBorrow = (totalCollateral * COLLATERAL_FACTOR) / 100;
/*LN-149*/         require(newDebt <= maxBorrow, "Insufficient collateral");
/*LN-150*/ 
/*LN-151*/         borrows[msg.sender] += amount;
/*LN-152*/         asset.transfer(msg.sender, amount);
/*LN-153*/         
/*LN-154*/         emit BorrowExecuted(msg.sender, amount, healthFactor);
/*LN-155*/     }
/*LN-156*/ 
/*LN-157*/     function getAccountSnapshot(
/*LN-158*/         address account
/*LN-159*/     )
/*LN-160*/         external
/*LN-161*/         view
/*LN-162*/         returns (uint256 collateral, uint256 borrowed, uint256 exchangeRate)
/*LN-163*/     {
/*LN-164*/         return (deposits[account], borrows[account], 1e18);
/*LN-165*/     }
/*LN-166*/ }
/*LN-167*/ 