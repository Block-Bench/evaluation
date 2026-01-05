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
/*LN-18*/ interface IUniswapV3Pool {
/*LN-19*/     function swap(
/*LN-20*/         address recipient,
/*LN-21*/         bool zeroForOne,
/*LN-22*/         int256 amountSpecified,
/*LN-23*/         uint160 sqrtPriceLimitX96,
/*LN-24*/         bytes calldata data
/*LN-25*/     ) external returns (int256 amount0, int256 amount1);
/*LN-26*/ 
/*LN-27*/     function flash(
/*LN-28*/         address recipient,
/*LN-29*/         uint256 amount0,
/*LN-30*/         uint256 amount1,
/*LN-31*/         bytes calldata data
/*LN-32*/     ) external;
/*LN-33*/ }
/*LN-34*/ 
/*LN-35*/ contract GammaHypervisor {
/*LN-36*/     IERC20 public token0;
/*LN-37*/     IERC20 public token1;
/*LN-38*/     IUniswapV3Pool public pool;
/*LN-39*/ 
/*LN-40*/     uint256 public totalSupply;
/*LN-41*/     mapping(address => uint256) public balanceOf;
/*LN-42*/ 
/*LN-43*/     struct Position {
/*LN-44*/         uint128 liquidity;
/*LN-45*/         int24 tickLower;
/*LN-46*/         int24 tickUpper;
/*LN-47*/     }
/*LN-48*/ 
/*LN-49*/     Position public basePosition;
/*LN-50*/     Position public limitPosition;
/*LN-51*/ 
/*LN-52*/     // Price protection
/*LN-53*/     uint256 public lastTotalValue;
/*LN-54*/     uint256 public lastUpdateBlock;
/*LN-55*/     uint256 constant MAX_DEVIATION = 5; // 5% max deviation
/*LN-56*/ 
/*LN-57*/     function deposit(
/*LN-58*/         uint256 deposit0,
/*LN-59*/         uint256 deposit1,
/*LN-60*/         address to
/*LN-61*/     ) external returns (uint256 shares) {
/*LN-62*/         uint256 total0 = token0.balanceOf(address(this));
/*LN-63*/         uint256 total1 = token1.balanceOf(address(this));
/*LN-64*/ 
/*LN-65*/         _checkPriceDeviation(total0, total1);
/*LN-66*/ 
/*LN-67*/         token0.transferFrom(msg.sender, address(this), deposit0);
/*LN-68*/         token1.transferFrom(msg.sender, address(this), deposit1);
/*LN-69*/ 
/*LN-70*/         if (totalSupply == 0) {
/*LN-71*/             shares = deposit0 + deposit1;
/*LN-72*/         } else {
/*LN-73*/             uint256 amount0Current = total0 + deposit0;
/*LN-74*/             uint256 amount1Current = total1 + deposit1;
/*LN-75*/ 
/*LN-76*/             shares = (totalSupply * (deposit0 + deposit1)) / (total0 + total1);
/*LN-77*/         }
/*LN-78*/ 
/*LN-79*/         balanceOf[to] += shares;
/*LN-80*/         totalSupply += shares;
/*LN-81*/ 
/*LN-82*/         _addLiquidity(deposit0, deposit1);
/*LN-83*/     }
/*LN-84*/ 
/*LN-85*/     function _checkPriceDeviation(uint256 total0, uint256 total1) internal {
/*LN-86*/         uint256 currentValue = total0 + total1;
/*LN-87*/         if (lastUpdateBlock == 0) {
/*LN-88*/             lastTotalValue = currentValue;
/*LN-89*/             lastUpdateBlock = block.number;
/*LN-90*/             return;
/*LN-91*/         }
/*LN-92*/         if (lastTotalValue > 0) {
/*LN-93*/             uint256 maxAllowed = lastTotalValue * (100 + MAX_DEVIATION) / 100;
/*LN-94*/             uint256 minAllowed = lastTotalValue * (100 - MAX_DEVIATION) / 100;
/*LN-95*/             require(currentValue >= minAllowed && currentValue <= maxAllowed, "Price deviation");
/*LN-96*/         }
/*LN-97*/         if (block.number > lastUpdateBlock + 100) {
/*LN-98*/             lastTotalValue = currentValue;
/*LN-99*/             lastUpdateBlock = block.number;
/*LN-100*/         }
/*LN-101*/     }
/*LN-102*/ 
/*LN-103*/     function withdraw(
/*LN-104*/         uint256 shares,
/*LN-105*/         address to
/*LN-106*/     ) external returns (uint256 amount0, uint256 amount1) {
/*LN-107*/         require(balanceOf[msg.sender] >= shares, "Insufficient balance");
/*LN-108*/ 
/*LN-109*/         uint256 total0 = token0.balanceOf(address(this));
/*LN-110*/         uint256 total1 = token1.balanceOf(address(this));
/*LN-111*/ 
/*LN-112*/         _checkPriceDeviation(total0, total1);
/*LN-113*/ 
/*LN-114*/         amount0 = (shares * total0) / totalSupply;
/*LN-115*/         amount1 = (shares * total1) / totalSupply;
/*LN-116*/ 
/*LN-117*/         balanceOf[msg.sender] -= shares;
/*LN-118*/         totalSupply -= shares;
/*LN-119*/ 
/*LN-120*/         token0.transfer(to, amount0);
/*LN-121*/         token1.transfer(to, amount1);
/*LN-122*/     }
/*LN-123*/ 
/*LN-124*/     function rebalance() external {
/*LN-125*/         _removeLiquidity(basePosition.liquidity);
/*LN-126*/ 
/*LN-127*/         _addLiquidity(
/*LN-128*/             token0.balanceOf(address(this)),
/*LN-129*/             token1.balanceOf(address(this))
/*LN-130*/         );
/*LN-131*/     }
/*LN-132*/ 
/*LN-133*/     function _addLiquidity(uint256 amount0, uint256 amount1) internal {}
/*LN-134*/ 
/*LN-135*/     function _removeLiquidity(uint128 liquidity) internal {}
/*LN-136*/ }
/*LN-137*/ 