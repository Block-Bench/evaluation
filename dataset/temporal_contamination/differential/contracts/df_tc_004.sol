/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title Yield Aggregator Vault
/*LN-6*/  * @notice Vault contract that deploys funds to external yield strategies
/*LN-7*/  * @dev Users deposit tokens and receive vault shares representing their position
/*LN-8*/  */
/*LN-9*/ 
/*LN-10*/ interface ICurvePool {
/*LN-11*/     function exchange_underlying(
/*LN-12*/         int128 i,
/*LN-13*/         int128 j,
/*LN-14*/         uint256 dx,
/*LN-15*/         uint256 min_dy
/*LN-16*/     ) external returns (uint256);
/*LN-17*/ 
/*LN-18*/     function get_dy_underlying(
/*LN-19*/         int128 i,
/*LN-20*/         int128 j,
/*LN-21*/         uint256 dx
/*LN-22*/     ) external view returns (uint256);
/*LN-23*/ }
/*LN-24*/ 
/*LN-25*/ contract YieldVault {
/*LN-26*/     address public underlyingToken;
/*LN-27*/     ICurvePool public curvePool;
/*LN-28*/ 
/*LN-29*/     uint256 public totalSupply;
/*LN-30*/     mapping(address => uint256) public balanceOf;
/*LN-31*/ 
/*LN-32*/     // Assets deployed to external protocols
/*LN-33*/     uint256 public investedBalance;
/*LN-34*/ 
/*LN-35*/     // TWAP protection
/*LN-36*/     uint256 public lastPricePerShare;
/*LN-37*/     uint256 public lastPriceUpdate;
/*LN-38*/     uint256 constant MAX_PRICE_DEVIATION = 5; // 5% max deviation
/*LN-39*/     uint256 constant MIN_PRICE_UPDATE_INTERVAL = 1 hours;
/*LN-40*/ 
/*LN-41*/     event Deposit(address indexed user, uint256 amount, uint256 shares);
/*LN-42*/     event Withdrawal(address indexed user, uint256 shares, uint256 amount);
/*LN-43*/ 
/*LN-44*/     constructor(address _token, address _curvePool) {
/*LN-45*/         underlyingToken = _token;
/*LN-46*/         curvePool = ICurvePool(_curvePool);
/*LN-47*/         lastPricePerShare = 1e18;
/*LN-48*/         lastPriceUpdate = block.timestamp;
/*LN-49*/     }
/*LN-50*/ 
/*LN-51*/     /**
/*LN-52*/      * @notice Deposit tokens and receive vault shares
/*LN-53*/      * @param amount Amount of underlying tokens to deposit
/*LN-54*/      * @return shares Amount of vault shares minted
/*LN-55*/      */
/*LN-56*/     function deposit(uint256 amount) external returns (uint256 shares) {
/*LN-57*/         require(amount > 0, "Zero amount");
/*LN-58*/         _checkPriceDeviation();
/*LN-59*/ 
/*LN-60*/         // Calculate shares based on current price
/*LN-61*/         if (totalSupply == 0) {
/*LN-62*/             shares = amount;
/*LN-63*/         } else {
/*LN-64*/             uint256 totalAssets = getTotalAssets();
/*LN-65*/             shares = (amount * totalSupply) / totalAssets;
/*LN-66*/         }
/*LN-67*/ 
/*LN-68*/         balanceOf[msg.sender] += shares;
/*LN-69*/         totalSupply += shares;
/*LN-70*/ 
/*LN-71*/         // Deploy funds to strategy
/*LN-72*/         _investInCurve(amount);
/*LN-73*/         _updatePrice();
/*LN-74*/ 
/*LN-75*/         emit Deposit(msg.sender, amount, shares);
/*LN-76*/         return shares;
/*LN-77*/     }
/*LN-78*/ 
/*LN-79*/     /**
/*LN-80*/      * @notice Withdraw underlying tokens by burning shares
/*LN-81*/      * @param shares Amount of vault shares to burn
/*LN-82*/      * @return amount Amount of underlying tokens received
/*LN-83*/      */
/*LN-84*/     function withdraw(uint256 shares) external returns (uint256 amount) {
/*LN-85*/         require(shares > 0, "Zero shares");
/*LN-86*/         require(balanceOf[msg.sender] >= shares, "Insufficient balance");
/*LN-87*/         _checkPriceDeviation();
/*LN-88*/ 
/*LN-89*/         // Calculate amount based on current price
/*LN-90*/         uint256 totalAssets = getTotalAssets();
/*LN-91*/         amount = (shares * totalAssets) / totalSupply;
/*LN-92*/ 
/*LN-93*/         balanceOf[msg.sender] -= shares;
/*LN-94*/         totalSupply -= shares;
/*LN-95*/ 
/*LN-96*/         // Withdraw from strategy
/*LN-97*/         _withdrawFromCurve(amount);
/*LN-98*/         _updatePrice();
/*LN-99*/ 
/*LN-100*/         emit Withdrawal(msg.sender, shares, amount);
/*LN-101*/         return amount;
/*LN-102*/     }
/*LN-103*/ 
/*LN-104*/     /**
/*LN-105*/      * @notice Check price deviation to prevent flash loan manipulation
/*LN-106*/      */
/*LN-107*/     function _checkPriceDeviation() internal view {
/*LN-108*/         if (totalSupply == 0) return;
/*LN-109*/         uint256 currentPrice = getPricePerFullShare();
/*LN-110*/         uint256 maxAllowed = lastPricePerShare * (100 + MAX_PRICE_DEVIATION) / 100;
/*LN-111*/         uint256 minAllowed = lastPricePerShare * (100 - MAX_PRICE_DEVIATION) / 100;
/*LN-112*/         require(currentPrice >= minAllowed && currentPrice <= maxAllowed, "Price deviation too high");
/*LN-113*/     }
/*LN-114*/ 
/*LN-115*/     /**
/*LN-116*/      * @notice Update stored price
/*LN-117*/      */
/*LN-118*/     function _updatePrice() internal {
/*LN-119*/         if (block.timestamp >= lastPriceUpdate + MIN_PRICE_UPDATE_INTERVAL) {
/*LN-120*/             lastPricePerShare = getPricePerFullShare();
/*LN-121*/             lastPriceUpdate = block.timestamp;
/*LN-122*/         }
/*LN-123*/     }
/*LN-124*/ 
/*LN-125*/     /**
/*LN-126*/      * @notice Get total assets under management
/*LN-127*/      * @return Total value of vault assets
/*LN-128*/      */
/*LN-129*/     function getTotalAssets() public view returns (uint256) {
/*LN-130*/         uint256 vaultBalance = 0;
/*LN-131*/         uint256 curveBalance = investedBalance;
/*LN-132*/ 
/*LN-133*/         return vaultBalance + curveBalance;
/*LN-134*/     }
/*LN-135*/ 
/*LN-136*/     /**
/*LN-137*/      * @notice Get price per share
/*LN-138*/      * @return Price per vault share
/*LN-139*/      */
/*LN-140*/     function getPricePerFullShare() public view returns (uint256) {
/*LN-141*/         if (totalSupply == 0) return 1e18;
/*LN-142*/         return (getTotalAssets() * 1e18) / totalSupply;
/*LN-143*/     }
/*LN-144*/ 
/*LN-145*/     /**
/*LN-146*/      * @notice Internal function to invest in Curve
/*LN-147*/      */
/*LN-148*/     function _investInCurve(uint256 amount) internal {
/*LN-149*/         investedBalance += amount;
/*LN-150*/     }
/*LN-151*/ 
/*LN-152*/     /**
/*LN-153*/      * @notice Internal function to withdraw from Curve
/*LN-154*/      */
/*LN-155*/     function _withdrawFromCurve(uint256 amount) internal {
/*LN-156*/         require(investedBalance >= amount, "Insufficient invested");
/*LN-157*/         investedBalance -= amount;
/*LN-158*/     }
/*LN-159*/ }
/*LN-160*/ 