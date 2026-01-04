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
/*LN-74*/     /**
/*LN-75*/      * @notice Deposit collateral into pool
/*LN-76*/      */
/*LN-77*/     function deposit(
/*LN-78*/         address asset,
/*LN-79*/         uint256 amount,
/*LN-80*/         address onBehalfOf,
/*LN-81*/         uint16 referralCode
/*LN-82*/     ) external override {
/*LN-83*/         IERC20(asset).transferFrom(msg.sender, address(this), amount);
/*LN-84*/         deposits[onBehalfOf] += amount;
/*LN-85*/     }
/*LN-86*/ 
/*LN-87*/     /**
/*LN-88*/      * @notice Borrow assets from pool
/*LN-89*/      */
/*LN-90*/     function borrow(
/*LN-91*/         address asset,
/*LN-92*/         uint256 amount,
/*LN-93*/         uint256 interestRateMode,
/*LN-94*/         uint16 referralCode,
/*LN-95*/         address onBehalfOf
/*LN-96*/     ) external override {
/*LN-97*/         uint256 collateralPrice = oracle.getAssetPrice(msg.sender);
/*LN-98*/         uint256 borrowPrice = oracle.getAssetPrice(asset);
/*LN-99*/ 
/*LN-100*/         
/*LN-101*/         
/*LN-102*/ 
/*LN-103*/         uint256 collateralValue = (deposits[msg.sender] * collateralPrice) /
/*LN-104*/             1e18;
/*LN-105*/         uint256 maxBorrow = (collateralValue * LTV) / BASIS_POINTS;
/*LN-106*/ 
/*LN-107*/         uint256 borrowValue = (amount * borrowPrice) / 1e18;
/*LN-108*/ 
/*LN-109*/         require(borrowValue <= maxBorrow, "Insufficient collateral");
/*LN-110*/ 
/*LN-111*/         borrows[msg.sender] += amount;
/*LN-112*/         IERC20(asset).transfer(onBehalfOf, amount);
/*LN-113*/     }
/*LN-114*/ 
/*LN-115*/     /**
/*LN-116*/      * @notice Withdraw collateral
/*LN-117*/      */
/*LN-118*/     function withdraw(
/*LN-119*/         address asset,
/*LN-120*/         uint256 amount,
/*LN-121*/         address to
/*LN-122*/     ) external override returns (uint256) {
/*LN-123*/         require(deposits[msg.sender] >= amount, "Insufficient balance");
/*LN-124*/         deposits[msg.sender] -= amount;
/*LN-125*/         IERC20(asset).transfer(to, amount);
/*LN-126*/         return amount;
/*LN-127*/     }
/*LN-128*/ }
/*LN-129*/ 
/*LN-130*/ contract CurveOracle {
/*LN-131*/     ICurvePool public curvePool;
/*LN-132*/ 
/*LN-133*/     constructor(address _pool) {
/*LN-134*/         curvePool = _pool;
/*LN-135*/     }
/*LN-136*/ 
/*LN-137*/     /**
/*LN-138*/      * @notice Get asset price from Curve pool
/*LN-139*/      */
/*LN-140*/     function getAssetPrice(address asset) external view returns (uint256) {
/*LN-141*/        
/*LN-142*/         
/*LN-143*/ 
/*LN-144*/         uint256 balance0 = curvePool.balances(0);
/*LN-145*/         uint256 balance1 = curvePool.balances(1);
/*LN-146*/ 
/*LN-147*/         
/*LN-148*/         uint256 price = (balance1 * 1e18) / balance0;
/*LN-149*/ 
/*LN-150*/         return price;
/*LN-151*/     }
/*LN-152*/ }
/*LN-153*/ 