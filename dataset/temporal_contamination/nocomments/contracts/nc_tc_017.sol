/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IUniswapV2Pair {
/*LN-4*/     function getReserves()
/*LN-5*/         external
/*LN-6*/         view
/*LN-7*/         returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
/*LN-8*/ 
/*LN-9*/     function totalSupply() external view returns (uint256);
/*LN-10*/ }
/*LN-11*/ 
/*LN-12*/ interface IERC20 {
/*LN-13*/     function balanceOf(address account) external view returns (uint256);
/*LN-14*/ 
/*LN-15*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-16*/ 
/*LN-17*/     function transferFrom(
/*LN-18*/         address from,
/*LN-19*/         address to,
/*LN-20*/         uint256 amount
/*LN-21*/     ) external returns (bool);
/*LN-22*/ }
/*LN-23*/ 
/*LN-24*/ contract CollateralVault {
/*LN-25*/     struct Position {
/*LN-26*/         uint256 lpTokenAmount;
/*LN-27*/         uint256 borrowed;
/*LN-28*/     }
/*LN-29*/ 
/*LN-30*/     mapping(address => Position) public positions;
/*LN-31*/ 
/*LN-32*/     address public lpToken;
/*LN-33*/     address public stablecoin;
/*LN-34*/     uint256 public constant COLLATERAL_RATIO = 150;
/*LN-35*/ 
/*LN-36*/     constructor(address _lpToken, address _stablecoin) {
/*LN-37*/         lpToken = _lpToken;
/*LN-38*/         stablecoin = _stablecoin;
/*LN-39*/     }
/*LN-40*/ 
/*LN-41*/ 
/*LN-42*/     function deposit(uint256 amount) external {
/*LN-43*/         IERC20(lpToken).transferFrom(msg.sender, address(this), amount);
/*LN-44*/         positions[msg.sender].lpTokenAmount += amount;
/*LN-45*/     }
/*LN-46*/ 
/*LN-47*/ 
/*LN-48*/     function borrow(uint256 amount) external {
/*LN-49*/         uint256 collateralValue = getLPTokenValue(
/*LN-50*/             positions[msg.sender].lpTokenAmount
/*LN-51*/         );
/*LN-52*/         uint256 maxBorrow = (collateralValue * 100) / COLLATERAL_RATIO;
/*LN-53*/ 
/*LN-54*/         require(
/*LN-55*/             positions[msg.sender].borrowed + amount <= maxBorrow,
/*LN-56*/             "Insufficient collateral"
/*LN-57*/         );
/*LN-58*/ 
/*LN-59*/         positions[msg.sender].borrowed += amount;
/*LN-60*/         IERC20(stablecoin).transfer(msg.sender, amount);
/*LN-61*/     }
/*LN-62*/ 
/*LN-63*/     function getLPTokenValue(uint256 lpAmount) public view returns (uint256) {
/*LN-64*/         if (lpAmount == 0) return 0;
/*LN-65*/ 
/*LN-66*/         IUniswapV2Pair pair = IUniswapV2Pair(lpToken);
/*LN-67*/ 
/*LN-68*/         (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
/*LN-69*/         uint256 totalSupply = pair.totalSupply();
/*LN-70*/ 
/*LN-71*/ 
/*LN-72*/         uint256 amount0 = (uint256(reserve0) * lpAmount) / totalSupply;
/*LN-73*/         uint256 amount1 = (uint256(reserve1) * lpAmount) / totalSupply;
/*LN-74*/ 
/*LN-75*/ 
/*LN-76*/         uint256 value0 = amount0;
/*LN-77*/ 
/*LN-78*/ 
/*LN-79*/         uint256 totalValue = amount0 + amount1;
/*LN-80*/ 
/*LN-81*/         return totalValue;
/*LN-82*/     }
/*LN-83*/ 
/*LN-84*/ 
/*LN-85*/     function repay(uint256 amount) external {
/*LN-86*/         require(positions[msg.sender].borrowed >= amount, "Repay exceeds debt");
/*LN-87*/ 
/*LN-88*/         IERC20(stablecoin).transferFrom(msg.sender, address(this), amount);
/*LN-89*/         positions[msg.sender].borrowed -= amount;
/*LN-90*/     }
/*LN-91*/ 
/*LN-92*/ 
/*LN-93*/     function withdraw(uint256 amount) external {
/*LN-94*/         require(
/*LN-95*/             positions[msg.sender].lpTokenAmount >= amount,
/*LN-96*/             "Insufficient balance"
/*LN-97*/         );
/*LN-98*/ 
/*LN-99*/ 
/*LN-100*/         uint256 remainingLP = positions[msg.sender].lpTokenAmount - amount;
/*LN-101*/         uint256 remainingValue = getLPTokenValue(remainingLP);
/*LN-102*/         uint256 maxBorrow = (remainingValue * 100) / COLLATERAL_RATIO;
/*LN-103*/ 
/*LN-104*/         require(
/*LN-105*/             positions[msg.sender].borrowed <= maxBorrow,
/*LN-106*/             "Withdrawal would liquidate position"
/*LN-107*/         );
/*LN-108*/ 
/*LN-109*/         positions[msg.sender].lpTokenAmount -= amount;
/*LN-110*/         IERC20(lpToken).transfer(msg.sender, amount);
/*LN-111*/     }
/*LN-112*/ }