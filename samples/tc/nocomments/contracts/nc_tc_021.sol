/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function balanceOf(address account) external view returns (uint256);
/*LN-5*/ 
/*LN-6*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-7*/ 
/*LN-8*/     function transferFrom(
/*LN-9*/         address from,
/*LN-10*/         address to,
/*LN-11*/         uint256 amount
/*LN-12*/     ) external returns (bool);
/*LN-13*/ }
/*LN-14*/ 
/*LN-15*/ interface IStablePool {
/*LN-16*/     function get_virtual_price() external view returns (uint256);
/*LN-17*/ 
/*LN-18*/     function add_liquidity(
/*LN-19*/         uint256[3] calldata amounts,
/*LN-20*/         uint256 minMintAmount
/*LN-21*/     ) external;
/*LN-22*/ }
/*LN-23*/ 
/*LN-24*/ contract SimplifiedOracle {
/*LN-25*/     IStablePool public stablePool;
/*LN-26*/ 
/*LN-27*/     constructor(address _stablePool) {
/*LN-28*/         stablePool = IStablePool(_stablePool);
/*LN-29*/     }
/*LN-30*/ 
/*LN-31*/ 
/*LN-32*/     function getPrice() external view returns (uint256) {
/*LN-33*/         return stablePool.get_virtual_price();
/*LN-34*/     }
/*LN-35*/ }
/*LN-36*/ 
/*LN-37*/ contract SyntheticLending {
/*LN-38*/     struct Position {
/*LN-39*/         uint256 collateral;
/*LN-40*/         uint256 borrowed;
/*LN-41*/     }
/*LN-42*/ 
/*LN-43*/     mapping(address => Position) public positions;
/*LN-44*/ 
/*LN-45*/     address public collateralToken;
/*LN-46*/     address public borrowToken;
/*LN-47*/     address public oracle;
/*LN-48*/ 
/*LN-49*/     uint256 public constant COLLATERAL_FACTOR = 80;
/*LN-50*/ 
/*LN-51*/     constructor(
/*LN-52*/         address _collateralToken,
/*LN-53*/         address _borrowToken,
/*LN-54*/         address _oracle
/*LN-55*/     ) {
/*LN-56*/         collateralToken = _collateralToken;
/*LN-57*/         borrowToken = _borrowToken;
/*LN-58*/         oracle = _oracle;
/*LN-59*/     }
/*LN-60*/ 
/*LN-61*/ 
/*LN-62*/     function deposit(uint256 amount) external {
/*LN-63*/         IERC20(collateralToken).transferFrom(msg.sender, address(this), amount);
/*LN-64*/         positions[msg.sender].collateral += amount;
/*LN-65*/     }
/*LN-66*/ 
/*LN-67*/ 
/*LN-68*/     function borrow(uint256 amount) external {
/*LN-69*/         uint256 collateralValue = getCollateralValue(msg.sender);
/*LN-70*/         uint256 maxBorrow = (collateralValue * COLLATERAL_FACTOR) / 100;
/*LN-71*/ 
/*LN-72*/         require(
/*LN-73*/             positions[msg.sender].borrowed + amount <= maxBorrow,
/*LN-74*/             "Insufficient collateral"
/*LN-75*/         );
/*LN-76*/ 
/*LN-77*/         positions[msg.sender].borrowed += amount;
/*LN-78*/         IERC20(borrowToken).transfer(msg.sender, amount);
/*LN-79*/     }
/*LN-80*/ 
/*LN-81*/ 
/*LN-82*/     function getCollateralValue(address user) public view returns (uint256) {
/*LN-83*/         uint256 collateralAmount = positions[user].collateral;
/*LN-84*/         uint256 price = SimplifiedOracle(oracle).getPrice();
/*LN-85*/ 
/*LN-86*/         return (collateralAmount * price) / 1e18;
/*LN-87*/     }
/*LN-88*/ }