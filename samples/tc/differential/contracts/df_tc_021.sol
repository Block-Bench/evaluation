/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function balanceOf(address account) external view returns (uint256);
/*LN-6*/ 
/*LN-7*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-8*/ 
/*LN-9*/     function transferFrom(
/*LN-10*/         address from,
/*LN-11*/         address to,
/*LN-12*/         uint256 amount
/*LN-13*/     ) external returns (bool);
/*LN-14*/ }
/*LN-15*/ 
/*LN-16*/ interface ICurvePool {
/*LN-17*/     function get_virtual_price() external view returns (uint256);
/*LN-18*/ 
/*LN-19*/     function add_liquidity(
/*LN-20*/         uint256[3] calldata amounts,
/*LN-21*/         uint256 minMintAmount
/*LN-22*/     ) external;
/*LN-23*/ }
/*LN-24*/ 
/*LN-25*/ contract PriceOracle {
/*LN-26*/     ICurvePool public curvePool;
/*LN-27*/ 
/*LN-28*/     uint256 public twapPrice;
/*LN-29*/     uint256 public lastUpdateTime;
/*LN-30*/ 
/*LN-31*/     constructor(address _curvePool) {
/*LN-32*/         curvePool = ICurvePool(_curvePool);
/*LN-33*/         lastUpdateTime = block.timestamp;
/*LN-34*/     }
/*LN-35*/ 
/*LN-36*/     function updatePrice() external {
/*LN-37*/         uint256 spotPrice = curvePool.get_virtual_price();
/*LN-38*/         uint256 timeElapsed = block.timestamp - lastUpdateTime;
/*LN-39*/ 
/*LN-40*/         if (timeElapsed > 0) {
/*LN-41*/             twapPrice = (twapPrice * lastUpdateTime + spotPrice * timeElapsed) / block.timestamp;
/*LN-42*/             lastUpdateTime = block.timestamp;
/*LN-43*/         }
/*LN-44*/     }
/*LN-45*/ 
/*LN-46*/     function getPrice() external view returns (uint256) {
/*LN-47*/         return twapPrice;
/*LN-48*/     }
/*LN-49*/ }
/*LN-50*/ 
/*LN-51*/ contract LendingProtocol {
/*LN-52*/     struct Position {
/*LN-53*/         uint256 collateral;
/*LN-54*/         uint256 borrowed;
/*LN-55*/     }
/*LN-56*/ 
/*LN-57*/     mapping(address => Position) public positions;
/*LN-58*/ 
/*LN-59*/     address public collateralToken;
/*LN-60*/     address public borrowToken;
/*LN-61*/     address public oracle;
/*LN-62*/ 
/*LN-63*/     uint256 public constant COLLATERAL_FACTOR = 80;
/*LN-64*/ 
/*LN-65*/     constructor(
/*LN-66*/         address _collateralToken,
/*LN-67*/         address _borrowToken,
/*LN-68*/         address _oracle
/*LN-69*/     ) {
/*LN-70*/         collateralToken = _collateralToken;
/*LN-71*/         borrowToken = _borrowToken;
/*LN-72*/         oracle = _oracle;
/*LN-73*/     }
/*LN-74*/ 
/*LN-75*/     function deposit(uint256 amount) external {
/*LN-76*/         IERC20(collateralToken).transferFrom(msg.sender, address(this), amount);
/*LN-77*/         positions[msg.sender].collateral += amount;
/*LN-78*/     }
/*LN-79*/ 
/*LN-80*/     function borrow(uint256 amount) external {
/*LN-81*/         uint256 collateralValue = getCollateralValue(msg.sender);
/*LN-82*/         uint256 maxBorrow = (collateralValue * COLLATERAL_FACTOR) / 100;
/*LN-83*/ 
/*LN-84*/         require(
/*LN-85*/             positions[msg.sender].borrowed + amount <= maxBorrow,
/*LN-86*/             "Insufficient collateral"
/*LN-87*/         );
/*LN-88*/ 
/*LN-89*/         positions[msg.sender].borrowed += amount;
/*LN-90*/         IERC20(borrowToken).transfer(msg.sender, amount);
/*LN-91*/     }
/*LN-92*/ 
/*LN-93*/     function getCollateralValue(address user) public view returns (uint256) {
/*LN-94*/         uint256 collateralAmount = positions[user].collateral;
/*LN-95*/         uint256 price = PriceOracle(oracle).getPrice();
/*LN-96*/ 
/*LN-97*/         return (collateralAmount * price) / 1e18;
/*LN-98*/     }
/*LN-99*/ }
/*LN-100*/ 