/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IUniswapV2Pair {
/*LN-5*/     function getReserves()
/*LN-6*/         external
/*LN-7*/         view
/*LN-8*/         returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
/*LN-9*/ 
/*LN-10*/     function totalSupply() external view returns (uint256);
/*LN-11*/ }
/*LN-12*/ 
/*LN-13*/ interface IERC20 {
/*LN-14*/     function balanceOf(address account) external view returns (uint256);
/*LN-15*/ 
/*LN-16*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-17*/ 
/*LN-18*/     function transferFrom(
/*LN-19*/         address from,
/*LN-20*/         address to,
/*LN-21*/         uint256 amount
/*LN-22*/     ) external returns (bool);
/*LN-23*/ }
/*LN-24*/ 
/*LN-25*/ contract LendingVault {
/*LN-26*/     struct Position {
/*LN-27*/         uint256 lpTokenAmount;
/*LN-28*/         uint256 borrowed;
/*LN-29*/     }
/*LN-30*/ 
/*LN-31*/     mapping(address => Position) public positions;
/*LN-32*/ 
/*LN-33*/     address public lpToken;
/*LN-34*/     address public stablecoin;
/*LN-35*/     uint256 public constant COLLATERAL_RATIO = 150;
/*LN-36*/ 
/*LN-37*/     // Price protection
/*LN-38*/     uint256 public lastLPValue;
/*LN-39*/     uint256 public lastUpdateBlock;
/*LN-40*/     uint256 constant MAX_DEVIATION = 10; // 10% max deviation
/*LN-41*/ 
/*LN-42*/     constructor(address _lpToken, address _stablecoin) {
/*LN-43*/         lpToken = _lpToken;
/*LN-44*/         stablecoin = _stablecoin;
/*LN-45*/     }
/*LN-46*/ 
/*LN-47*/     function deposit(uint256 amount) external {
/*LN-48*/         IERC20(lpToken).transferFrom(msg.sender, address(this), amount);
/*LN-49*/         positions[msg.sender].lpTokenAmount += amount;
/*LN-50*/     }
/*LN-51*/ 
/*LN-52*/     function borrow(uint256 amount) external {
/*LN-53*/         _checkPriceDeviation();
/*LN-54*/         uint256 collateralValue = getLPTokenValue(
/*LN-55*/             positions[msg.sender].lpTokenAmount
/*LN-56*/         );
/*LN-57*/         uint256 maxBorrow = (collateralValue * 100) / COLLATERAL_RATIO;
/*LN-58*/ 
/*LN-59*/         require(
/*LN-60*/             positions[msg.sender].borrowed + amount <= maxBorrow,
/*LN-61*/             "Insufficient collateral"
/*LN-62*/         );
/*LN-63*/ 
/*LN-64*/         positions[msg.sender].borrowed += amount;
/*LN-65*/         IERC20(stablecoin).transfer(msg.sender, amount);
/*LN-66*/     }
/*LN-67*/ 
/*LN-68*/     function _checkPriceDeviation() internal {
/*LN-69*/         if (lastUpdateBlock == 0) {
/*LN-70*/             lastLPValue = getLPTokenValue(1e18);
/*LN-71*/             lastUpdateBlock = block.number;
/*LN-72*/             return;
/*LN-73*/         }
/*LN-74*/         uint256 currentValue = getLPTokenValue(1e18);
/*LN-75*/         uint256 maxAllowed = lastLPValue * (100 + MAX_DEVIATION) / 100;
/*LN-76*/         uint256 minAllowed = lastLPValue * (100 - MAX_DEVIATION) / 100;
/*LN-77*/         require(currentValue >= minAllowed && currentValue <= maxAllowed, "Price deviation too high");
/*LN-78*/         if (block.number > lastUpdateBlock + 100) {
/*LN-79*/             lastLPValue = currentValue;
/*LN-80*/             lastUpdateBlock = block.number;
/*LN-81*/         }
/*LN-82*/     }
/*LN-83*/ 
/*LN-84*/     function getLPTokenValue(uint256 lpAmount) public view returns (uint256) {
/*LN-85*/         if (lpAmount == 0) return 0;
/*LN-86*/ 
/*LN-87*/         IUniswapV2Pair pair = IUniswapV2Pair(lpToken);
/*LN-88*/ 
/*LN-89*/         (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
/*LN-90*/         uint256 totalSupply = pair.totalSupply();
/*LN-91*/ 
/*LN-92*/         uint256 amount0 = (uint256(reserve0) * lpAmount) / totalSupply;
/*LN-93*/         uint256 amount1 = (uint256(reserve1) * lpAmount) / totalSupply;
/*LN-94*/ 
/*LN-95*/         uint256 totalValue = amount0 + amount1;
/*LN-96*/ 
/*LN-97*/         return totalValue;
/*LN-98*/     }
/*LN-99*/ 
/*LN-100*/     function repay(uint256 amount) external {
/*LN-101*/         require(positions[msg.sender].borrowed >= amount, "Repay exceeds debt");
/*LN-102*/ 
/*LN-103*/         IERC20(stablecoin).transferFrom(msg.sender, address(this), amount);
/*LN-104*/         positions[msg.sender].borrowed -= amount;
/*LN-105*/     }
/*LN-106*/ 
/*LN-107*/     function withdraw(uint256 amount) external {
/*LN-108*/         require(
/*LN-109*/             positions[msg.sender].lpTokenAmount >= amount,
/*LN-110*/             "Insufficient balance"
/*LN-111*/         );
/*LN-112*/ 
/*LN-113*/         uint256 remainingLP = positions[msg.sender].lpTokenAmount - amount;
/*LN-114*/         uint256 remainingValue = getLPTokenValue(remainingLP);
/*LN-115*/         uint256 maxBorrow = (remainingValue * 100) / COLLATERAL_RATIO;
/*LN-116*/ 
/*LN-117*/         require(
/*LN-118*/             positions[msg.sender].borrowed <= maxBorrow,
/*LN-119*/             "Withdrawal would liquidate position"
/*LN-120*/         );
/*LN-121*/ 
/*LN-122*/         positions[msg.sender].lpTokenAmount -= amount;
/*LN-123*/         IERC20(lpToken).transfer(msg.sender, amount);
/*LN-124*/     }
/*LN-125*/ }
/*LN-126*/ 