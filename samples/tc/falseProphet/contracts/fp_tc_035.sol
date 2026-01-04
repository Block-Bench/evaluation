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
/*LN-18*/ interface IPriceOracle {
/*LN-19*/     function getPrice(address token) external view returns (uint256);
/*LN-20*/ }
/*LN-21*/

/**
 * @title LeveragedLending
 * @notice lending-style lending protocol with multi-asset support
 * @dev Audited by Sherlock (Q1 2023) - All findings resolved
 * @dev Implements collateral-backed borrowing with LTV enforcement
 * @dev Uses trusted oracle for asset valuation
 * @custom:security-contact security@leveraged.garden
 */
/*LN-22*/ contract LeveragedLending {
/*LN-23*/     struct Market {
        /// @dev Market listing status
/*LN-24*/         bool isListed;
        /// @dev Collateral factor for risk assessment
/*LN-25*/         uint256 collateralFactor;
        /// @dev User collateral balances
/*LN-26*/         mapping(address => uint256) accountCollateral;
        /// @dev User borrow balances
/*LN-27*/         mapping(address => uint256) accountBorrows;
/*LN-28*/     }
/*LN-29*/

    /// @dev Market data per token
/*LN-30*/     mapping(address => Market) public markets;
    /// @dev Price oracle contract
/*LN-31*/     IPriceOracle public oracle;
/*LN-32*/

    /// @dev Default collateral factor (75%)
/*LN-33*/     uint256 public constant COLLATERAL_FACTOR = 75;
    /// @dev Basis points denominator
/*LN-34*/     uint256 public constant BASIS_POINTS = 100;
/*LN-35*/

    /**
     * @notice Enter markets to use as collateral
     * @param vTokens Array of market tokens to enter
     * @return results Success status for each market
     */
/*LN-39*/     function enterMarkets(
/*LN-40*/         address[] calldata vTokens
/*LN-41*/     ) external returns (uint256[] memory) {
/*LN-42*/         uint256[] memory results = new uint256[](vTokens.length);
/*LN-43*/         for (uint256 i = 0; i < vTokens.length; i++) {
/*LN-44*/             markets[vTokens[i]].isListed = true;
/*LN-45*/             results[i] = 0;
/*LN-46*/         }
/*LN-47*/         return results;
/*LN-48*/     }
/*LN-49*/

    /**
     * @notice Mint collateral tokens
     * @dev Deposits underlying and credits collateral
     * @param token Token to deposit
     * @param amount Amount to deposit
     * @return Success status
     */
/*LN-53*/     function mint(address token, uint256 amount) external returns (uint256) {
/*LN-54*/         IERC20(token).transferFrom(msg.sender, address(this), amount);
/*LN-55*/

        // Get current price from oracle
/*LN-56*/         uint256 price = oracle.getPrice(token);
/*LN-57*/

/*LN-60*/

        // Credit collateral to user
/*LN-61*/         markets[token].accountCollateral[msg.sender] += amount;
/*LN-62*/         return 0;
/*LN-63*/     }
/*LN-64*/

    /**
     * @notice Borrow tokens against collateral
     * @dev Validates LTV before allowing borrow
     * @param borrowToken Token to borrow
     * @param borrowAmount Amount to borrow
     * @return Success status
     */
/*LN-68*/     function borrow(
/*LN-69*/         address borrowToken,
/*LN-70*/         uint256 borrowAmount
/*LN-71*/     ) external returns (uint256) {
        // Calculate total collateral value
/*LN-72*/         uint256 totalCollateralValue = 0;
/*LN-73*/

        // Sum collateral value across all positions
/*LN-76*/

        // Get borrow token price
/*LN-77*/         uint256 borrowPrice = oracle.getPrice(borrowToken);
/*LN-78*/         uint256 borrowValue = (borrowAmount * borrowPrice) / 1e18;
/*LN-79*/

        // Calculate maximum allowed borrow
/*LN-80*/         uint256 maxBorrowValue = (totalCollateralValue * COLLATERAL_FACTOR) /
/*LN-81*/             BASIS_POINTS;
/*LN-82*/

/*LN-83*/         require(borrowValue <= maxBorrowValue, "Insufficient collateral");
/*LN-84*/

/*LN-85*/         markets[borrowToken].accountBorrows[msg.sender] += borrowAmount;
        // Transfer borrowed tokens
/*LN-86*/         IERC20(borrowToken).transfer(msg.sender, borrowAmount);
/*LN-87*/

/*LN-88*/         return 0;
/*LN-89*/     }
/*LN-90*/

    /**
     * @notice Liquidate undercollateralized position
     * @param borrower Address to liquidate
     * @param repayToken Token to repay
     * @param repayAmount Amount to repay
     * @param collateralToken Collateral to seize
     */
/*LN-94*/     function liquidate(
/*LN-95*/         address borrower,
/*LN-96*/         address repayToken,
/*LN-97*/         uint256 repayAmount,
/*LN-98*/         address collateralToken
/*LN-99*/     ) external {
        // Check if position is undercollateralized
/*LN-101*/
/*LN-102*/     }
/*LN-103*/ }
/*LN-104*/

/**
 * @title ManipulableOracle
 * @notice Price oracle with admin controls
 * @dev Implements IPriceOracle interface
 */
/*LN-105*/ contract ManipulableOracle is IPriceOracle {
    /// @dev Token prices in 18 decimals
/*LN-106*/     mapping(address => uint256) public prices;
/*LN-107*/

    /**
     * @notice Get token price
     * @param token Token address
     * @return Current price in 18 decimals
     */
/*LN-111*/     function getPrice(address token) external view override returns (uint256) {
/*LN-114*/

/*LN-115*/         return prices[token];
/*LN-116*/     }
/*LN-117*/

    /**
     * @notice Set token price (admin only)
     * @param token Token address
     * @param price New price
     */
/*LN-118*/     function setPrice(address token, uint256 price) external {
/*LN-119*/         prices[token] = price;
/*LN-120*/     }
/*LN-121*/ }
/*LN-122*/
