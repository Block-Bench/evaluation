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
/*LN-18*/ interface IAaveOracle {
/*LN-19*/     function getAssetPrice(address asset) external view returns (uint256);
/*LN-20*/ 
/*LN-21*/     function setAssetSources(
/*LN-22*/         address[] calldata assets,
/*LN-23*/         address[] calldata sources
/*LN-24*/     ) external;
/*LN-25*/ }
/*LN-26*/ 
/*LN-27*/ interface ICurvePool {
/*LN-28*/     function exchange(
/*LN-29*/         int128 i,
/*LN-30*/         int128 j,
/*LN-31*/         uint256 dx,
/*LN-32*/         uint256 min_dy
/*LN-33*/     ) external returns (uint256);
/*LN-34*/ 
/*LN-35*/     function get_dy(
/*LN-36*/         int128 i,
/*LN-37*/         int128 j,
/*LN-38*/         uint256 dx
/*LN-39*/     ) external view returns (uint256);
/*LN-40*/ 
/*LN-41*/     function balances(uint256 i) external view returns (uint256);
/*LN-42*/ }
/*LN-43*/ 
/*LN-44*/ interface ILendingPool {
/*LN-45*/     function deposit(
/*LN-46*/         address asset,
/*LN-47*/         uint256 amount,
/*LN-48*/         address onBehalfOf,
/*LN-49*/         uint16 referralCode
/*LN-50*/     ) external;
/*LN-51*/ 
/*LN-52*/     function borrow(
/*LN-53*/         address asset,
/*LN-54*/         uint256 amount,
/*LN-55*/         uint256 interestRateMode,
/*LN-56*/         uint16 referralCode,
/*LN-57*/         address onBehalfOf
/*LN-58*/     ) external;
/*LN-59*/ 
/*LN-60*/     function withdraw(
/*LN-61*/         address asset,
/*LN-62*/         uint256 amount,
/*LN-63*/         address to
/*LN-64*/     ) external returns (uint256);
/*LN-65*/ }
/*LN-66*/ 
/*LN-67*/ contract UwuLendingPool is ILendingPool {
/*LN-68*/     IAaveOracle public oracle;
/*LN-69*/     mapping(address => uint256) public deposits;
/*LN-70*/     mapping(address => uint256) public borrows;
/*LN-71*/     uint256 public constant LTV = 8500;
/*LN-72*/     uint256 public constant BASIS_POINTS = 10000;
/*LN-73*/ 
/*LN-74*/     function deposit(
/*LN-75*/         address asset,
/*LN-76*/         uint256 amount,
/*LN-77*/         address onBehalfOf,
/*LN-78*/         uint16 referralCode
/*LN-79*/     ) external override {
/*LN-80*/         IERC20(asset).transferFrom(msg.sender, address(this), amount);
/*LN-81*/         deposits[onBehalfOf] += amount;
/*LN-82*/     }
/*LN-83*/ 
/*LN-84*/     function borrow(
/*LN-85*/         address asset,
/*LN-86*/         uint256 amount,
/*LN-87*/         uint256 interestRateMode,
/*LN-88*/         uint16 referralCode,
/*LN-89*/         address onBehalfOf
/*LN-90*/     ) external override {
/*LN-91*/         uint256 collateralPrice = oracle.getAssetPrice(msg.sender);
/*LN-92*/         uint256 borrowPrice = oracle.getAssetPrice(asset);
/*LN-93*/ 
/*LN-94*/         uint256 collateralValue = (deposits[msg.sender] * collateralPrice) /
/*LN-95*/             1e18;
/*LN-96*/         uint256 maxBorrow = (collateralValue * LTV) / BASIS_POINTS;
/*LN-97*/ 
/*LN-98*/         uint256 borrowValue = (amount * borrowPrice) / 1e18;
/*LN-99*/ 
/*LN-100*/         require(borrowValue <= maxBorrow, "Insufficient collateral");
/*LN-101*/ 
/*LN-102*/         borrows[msg.sender] += amount;
/*LN-103*/         IERC20(asset).transfer(onBehalfOf, amount);
/*LN-104*/     }
/*LN-105*/ 
/*LN-106*/     function withdraw(
/*LN-107*/         address asset,
/*LN-108*/         uint256 amount,
/*LN-109*/         address to
/*LN-110*/     ) external override returns (uint256) {
/*LN-111*/         require(deposits[msg.sender] >= amount, "Insufficient balance");
/*LN-112*/         deposits[msg.sender] -= amount;
/*LN-113*/         IERC20(asset).transfer(to, amount);
/*LN-114*/         return amount;
/*LN-115*/     }
/*LN-116*/ }
/*LN-117*/ 
/*LN-118*/ contract CurveOracle {
/*LN-119*/     ICurvePool public curvePool;
/*LN-120*/     uint256 public cachedPrice;
/*LN-121*/     uint256 public lastUpdate;
/*LN-122*/     uint256 constant MIN_UPDATE_INTERVAL = 1 hours;
/*LN-123*/ 
/*LN-124*/     constructor(address _pool) {
/*LN-125*/         curvePool = ICurvePool(_pool);
/*LN-126*/         _updatePrice();
/*LN-127*/     }
/*LN-128*/ 
/*LN-129*/     function getAssetPrice(address asset) external view returns (uint256) {
/*LN-130*/         if (block.timestamp < lastUpdate + MIN_UPDATE_INTERVAL) {
/*LN-131*/             return cachedPrice;
/*LN-132*/         }
/*LN-133*/         return _calculatePrice();
/*LN-134*/     }
/*LN-135*/ 
/*LN-136*/     function updatePrice() external {
/*LN-137*/         require(block.timestamp >= lastUpdate + MIN_UPDATE_INTERVAL, "Too soon");
/*LN-138*/         _updatePrice();
/*LN-139*/     }
/*LN-140*/ 
/*LN-141*/     function _updatePrice() internal {
/*LN-142*/         cachedPrice = _calculatePrice();
/*LN-143*/         lastUpdate = block.timestamp;
/*LN-144*/     }
/*LN-145*/ 
/*LN-146*/     function _calculatePrice() internal view returns (uint256) {
/*LN-147*/         uint256 balance0 = curvePool.balances(0);
/*LN-148*/         uint256 balance1 = curvePool.balances(1);
/*LN-149*/         return (balance1 * 1e18) / balance0;
/*LN-150*/     }
/*LN-151*/ }
/*LN-152*/ 