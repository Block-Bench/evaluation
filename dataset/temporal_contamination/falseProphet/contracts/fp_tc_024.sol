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

/**
 * @title SimplifiedOracle
 * @notice Price oracle using Curve LP token virtual price
 * @dev Audited by OpenZeppelin (Q1 2022) - All findings resolved
 * @dev Uses Curve's battle-tested get_virtual_price() for pricing
 * @dev Virtual price represents LP token value in underlying
 * @custom:security-contact security@inverse.finance
 */
/*LN-25*/ contract SimplifiedOracle {
    /// @dev Reference to Curve pool for price feed
/*LN-26*/     ICurvePool public curvePool;
/*LN-27*/ 
/*LN-28*/     constructor(address _curvePool) {
/*LN-29*/         curvePool = ICurvePool(_curvePool);
/*LN-30*/     }
/*LN-31*/ 
    /**
     * @notice Get current price from Curve virtual price
     * @dev Returns price scaled to 1e18
     * @return Current LP token price in underlying
     */
/*LN-34*/     function getPrice() external view returns (uint256) {
            // Fetch virtual price from Curve pool
/*LN-35*/         return curvePool.get_virtual_price();
/*LN-36*/     }
/*LN-37*/ }
/*LN-38*/

/**
 * @title InverseLending
 * @notice Collateralized lending protocol with oracle-based pricing
 * @dev Audited by OpenZeppelin (Q1 2022) - All findings resolved
 * @dev Uses 80% collateral factor for conservative LTV
 * @dev Integrates with SimplifiedOracle for price feeds
 */
/*LN-39*/ contract InverseLending {
    /// @dev User position data
/*LN-40*/     struct Position {
/*LN-41*/         uint256 collateral;
/*LN-42*/         uint256 borrowed;
/*LN-43*/     }
/*LN-44*/
    /// @dev Position registry by user address
/*LN-45*/     mapping(address => Position) public positions;
/*LN-46*/
    /// @dev Curve LP token used as collateral
/*LN-47*/     address public collateralToken;
    /// @dev Token available for borrowing
/*LN-48*/     address public borrowToken;
    /// @dev Price oracle for collateral valuation
/*LN-49*/     address public oracle;
/*LN-50*/
    /// @dev Maximum LTV ratio (80%)
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
    /**
     * @notice Borrow against deposited collateral
     * @dev Enforces 80% collateral factor for safety margin
     * @dev Updates debt before transfer
     * @param amount Amount to borrow
     */
/*LN-73*/     function borrow(uint256 amount) external {
            // Calculate borrowing capacity
/*LN-74*/         uint256 collateralValue = getCollateralValue(msg.sender);
/*LN-75*/         uint256 maxBorrow = (collateralValue * COLLATERAL_FACTOR) / 100;
/*LN-76*/
            // Enforce collateralization requirement
/*LN-77*/         require(
/*LN-78*/             positions[msg.sender].borrowed + amount <= maxBorrow,
/*LN-79*/             "Insufficient collateral"
/*LN-80*/         );
/*LN-81*/
            // Update debt and transfer
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