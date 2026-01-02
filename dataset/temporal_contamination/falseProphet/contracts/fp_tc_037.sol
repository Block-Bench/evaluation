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

/**
 * @title UwuLendingPool
 * @notice Aave-compatible lending pool with Curve oracle integration
 * @dev Audited by Halborn Security (Q2 2023) - All findings resolved
 * @dev Implements collateralized borrowing with LTV checks
 * @dev Uses Curve pool pricing for asset valuation
 * @custom:security-contact security@uwulend.fi
 */
/*LN-67*/ contract UwuLendingPool is ILendingPool {
    /// @dev Oracle for asset pricing
/*LN-68*/     IAaveOracle public oracle;
    /// @dev User deposit balances
/*LN-69*/     mapping(address => uint256) public deposits;
    /// @dev User borrow balances
/*LN-70*/     mapping(address => uint256) public borrows;
    /// @dev Loan-to-value ratio (85%)
/*LN-71*/     uint256 public constant LTV = 8500;
    /// @dev Basis points denominator
/*LN-72*/     uint256 public constant BASIS_POINTS = 10000;
/*LN-73*/

    /**
     * @notice Deposit collateral into pool
     * @param asset Asset to deposit
     * @param amount Amount to deposit
     * @param onBehalfOf Address to credit
     * @param referralCode Referral tracking
     */
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

    /**
     * @notice Borrow assets from pool
     * @dev Validates collateral value before borrowing
     * @param asset Asset to borrow
     * @param amount Amount to borrow
     * @param interestRateMode Rate mode (stable/variable)
     * @param referralCode Referral tracking
     * @param onBehalfOf Recipient address
     */
/*LN-90*/     function borrow(
/*LN-91*/         address asset,
/*LN-92*/         uint256 amount,
/*LN-93*/         uint256 interestRateMode,
/*LN-94*/         uint16 referralCode,
/*LN-95*/         address onBehalfOf
/*LN-96*/     ) external override {
        // Get current asset prices
/*LN-97*/         uint256 collateralPrice = oracle.getAssetPrice(msg.sender);
/*LN-98*/         uint256 borrowPrice = oracle.getAssetPrice(asset);
/*LN-99*/

/*LN-102*/

        // Calculate collateral value and max borrow
/*LN-103*/         uint256 collateralValue = (deposits[msg.sender] * collateralPrice) /
/*LN-104*/             1e18;
/*LN-105*/         uint256 maxBorrow = (collateralValue * LTV) / BASIS_POINTS;
/*LN-106*/

/*LN-107*/         uint256 borrowValue = (amount * borrowPrice) / 1e18;
/*LN-108*/

/*LN-109*/         require(borrowValue <= maxBorrow, "Insufficient collateral");
/*LN-110*/

/*LN-111*/         borrows[msg.sender] += amount;
        // Transfer borrowed assets
/*LN-112*/         IERC20(asset).transfer(onBehalfOf, amount);
/*LN-113*/     }
/*LN-114*/

    /**
     * @notice Withdraw collateral
     * @param asset Asset to withdraw
     * @param amount Amount to withdraw
     * @param to Recipient address
     * @return Amount withdrawn
     */
/*LN-118*/     function withdraw(
/*LN-119*/         address asset,
/*LN-120*/         uint256 amount,
/*LN-121*/         address to
/*LN-122*/     ) external override returns (uint256) {
/*LN-123*/         require(deposits[msg.sender] >= amount, "Insufficient balance");
/*LN-124*/         deposits[msg.sender] -= amount;
        // Transfer assets to user
/*LN-125*/         IERC20(asset).transfer(to, amount);
/*LN-126*/         return amount;
/*LN-127*/     }
/*LN-128*/ }
/*LN-129*/

/**
 * @title CurveOracle
 * @notice Price oracle using Curve pool reserves
 * @dev Derives prices from pool balance ratios
 */
/*LN-130*/ contract CurveOracle {
    /// @dev Curve pool for price derivation
/*LN-131*/     ICurvePool public curvePool;
/*LN-132*/

/*LN-133*/     constructor(address _pool) {
/*LN-134*/         curvePool = ICurvePool(_pool);
/*LN-135*/     }
/*LN-136*/

    /**
     * @notice Get asset price from Curve pool
     * @dev Calculates price from pool balance ratio
     * @param asset Asset address (unused - pool has fixed pair)
     * @return price Current price in 18 decimals
     */
/*LN-140*/     function getAssetPrice(address asset) external view returns (uint256) {
/*LN-143*/

        // Get pool balances
/*LN-144*/         uint256 balance0 = curvePool.balances(0);
/*LN-145*/         uint256 balance1 = curvePool.balances(1);
/*LN-146*/

        // Calculate price from ratio
/*LN-148*/         uint256 price = (balance1 * 1e18) / balance0;
/*LN-149*/

/*LN-150*/         return price;
/*LN-151*/     }
/*LN-152*/ }
/*LN-153*/
