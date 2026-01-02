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
/*LN-16*/ interface IStablePool {
/*LN-17*/     function get_virtual_price() external view returns (uint256);
/*LN-18*/ 
/*LN-19*/     function add_liquidity(
/*LN-20*/         uint256[3] calldata amounts,
/*LN-21*/         uint256 minMintAmount
/*LN-22*/     ) external;
/*LN-23*/ }
/*LN-24*/ 
/*LN-25*/ contract SimplifiedOracle {
/*LN-26*/     IStablePool public stablePool;
/*LN-27*/ 
/*LN-28*/     constructor(address _stablePool) {
/*LN-29*/         stablePool = IStablePool(_stablePool);
/*LN-30*/     }
/*LN-31*/ 
/*LN-32*/     /**
/*LN-33*/      */
/*LN-34*/     function getPrice() external view returns (uint256) {
/*LN-35*/         return stablePool.get_virtual_price();
/*LN-36*/     }
/*LN-37*/ }
/*LN-38*/ 
/*LN-39*/ contract SyntheticLending {
/*LN-40*/     struct Position {
/*LN-41*/         uint256 collateral;
/*LN-42*/         uint256 borrowed;
/*LN-43*/     }
/*LN-44*/ 
/*LN-45*/     mapping(address => Position) public positions;
/*LN-46*/ 
/*LN-47*/     address public collateralToken;
/*LN-48*/     address public borrowToken;
/*LN-49*/     address public oracle;
/*LN-50*/ 
/*LN-51*/     uint256 public constant COLLATERAL_FACTOR = 80;
/*LN-52*/ 
/*LN-53*/     constructor(
/*LN-54*/         address _collateralToken,
/*LN-55*/         address _borrowToken,
/*LN-56*/         address _oracle
/*LN-57*/     ) {
/*LN-58*/         collateralToken = _collateralToken;
/*LN-59*/         borrowToken = _borrowToken;
/*LN-60*/         oracle = _oracle;
/*LN-61*/     }
/*LN-62*/ 
/*LN-63*/     /**
/*LN-64*/      * @notice Deposit collateral
/*LN-65*/      */
/*LN-66*/     function deposit(uint256 amount) external {
/*LN-67*/         IERC20(collateralToken).transferFrom(msg.sender, address(this), amount);
/*LN-68*/         positions[msg.sender].collateral += amount;
/*LN-69*/     }
/*LN-70*/ 
/*LN-71*/     /**
/*LN-72*/      */
/*LN-73*/     function borrow(uint256 amount) external {
/*LN-74*/         uint256 collateralValue = getCollateralValue(msg.sender);
/*LN-75*/         uint256 maxBorrow = (collateralValue * COLLATERAL_FACTOR) / 100;
/*LN-76*/ 
/*LN-77*/         require(
/*LN-78*/             positions[msg.sender].borrowed + amount <= maxBorrow,
/*LN-79*/             "Insufficient collateral"
/*LN-80*/         );
/*LN-81*/ 
/*LN-82*/         positions[msg.sender].borrowed += amount;
/*LN-83*/         IERC20(borrowToken).transfer(msg.sender, amount);
/*LN-84*/     }
/*LN-85*/ 
/*LN-86*/     /**
/*LN-87*/      * @notice Calculate collateral value using oracle price
/*LN-88*/      */
/*LN-89*/     function getCollateralValue(address user) public view returns (uint256) {
/*LN-90*/         uint256 collateralAmount = positions[user].collateral;
/*LN-91*/         uint256 price = SimplifiedOracle(oracle).getPrice();
/*LN-92*/ 
/*LN-93*/         return (collateralAmount * price) / 1e18;
/*LN-94*/     }
/*LN-95*/ }
/*LN-96*/ 