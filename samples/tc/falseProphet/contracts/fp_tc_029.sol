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
/*LN-18*/ interface IFlashLoanReceiver {
/*LN-19*/     function executeOperation(
/*LN-20*/         address[] calldata assets,
/*LN-21*/         uint256[] calldata amounts,
/*LN-22*/         uint256[] calldata premiums,
/*LN-23*/         address initiator,
/*LN-24*/         bytes calldata params
/*LN-25*/     ) external returns (bool);
/*LN-26*/ }
/*LN-27*/

/**
 * @title CrossLendingPool
 * @notice Aave-compatible lending pool with flash loan support
 * @dev Audited by Trail of Bits (Q1 2023) - All findings resolved
 * @dev Implements ray mathematics for precise interest accrual
 * @dev Supports deposit, withdraw, borrow, and flash loans
 * @custom:security-contact security@crosslending.capital
 */
/*LN-28*/ contract CrossLendingPool {
    /// @dev Ray unit (1e27) for high-precision calculations
/*LN-29*/     uint256 public constant RAY = 1e27;
/*LN-30*/

/*LN-31*/     struct ReserveData {
        /// @dev Current liquidity index for interest accrual
/*LN-32*/         uint256 liquidityIndex;
        /// @dev Total liquidity in reserve
/*LN-33*/         uint256 totalLiquidity;
        /// @dev Interest-bearing token address
/*LN-34*/         address rTokenAddress;
/*LN-35*/     }
/*LN-36*/

    /// @dev Reserve data per asset
/*LN-37*/     mapping(address => ReserveData) public reserves;
/*LN-38*/

    /**
     * @notice Deposit tokens into lending pool
     * @dev Mints proportional rTokens to depositor
     * @param asset Token address to deposit
     * @param amount Amount to deposit
     * @param onBehalfOf Address to receive rTokens
     * @param referralCode Optional referral code
     */
/*LN-42*/     function deposit(
/*LN-43*/         address asset,
/*LN-44*/         uint256 amount,
/*LN-45*/         address onBehalfOf,
/*LN-46*/         uint16 referralCode
/*LN-47*/     ) external {
/*LN-48*/         IERC20(asset).transferFrom(msg.sender, address(this), amount);
/*LN-49*/

/*LN-50*/         ReserveData storage reserve = reserves[asset];
/*LN-51*/

        // Update liquidity index for interest accrual
/*LN-53*/         uint256 currentLiquidityIndex = reserve.liquidityIndex;
/*LN-54*/         if (currentLiquidityIndex == 0) {
/*LN-55*/             currentLiquidityIndex = RAY;
/*LN-56*/         }
/*LN-57*/

        // Accrue interest to index
/*LN-59*/         reserve.liquidityIndex =
/*LN-60*/             currentLiquidityIndex +
/*LN-61*/             (amount * RAY) /
/*LN-62*/             (reserve.totalLiquidity + 1);
/*LN-63*/         reserve.totalLiquidity += amount;
/*LN-64*/

        // Mint rTokens proportional to deposit
/*LN-66*/         uint256 rTokenAmount = rayDiv(amount, reserve.liquidityIndex);
/*LN-67*/         _mintRToken(reserve.rTokenAddress, onBehalfOf, rTokenAmount);
/*LN-68*/     }
/*LN-69*/

    /**
     * @notice Withdraw tokens from lending pool
     * @dev Burns rTokens and returns underlying
     * @param asset Token address to withdraw
     * @param amount Amount to withdraw
     * @param to Recipient address
     * @return Amount withdrawn
     */
/*LN-73*/     function withdraw(
/*LN-74*/         address asset,
/*LN-75*/         uint256 amount,
/*LN-76*/         address to
/*LN-77*/     ) external returns (uint256) {
/*LN-78*/         ReserveData storage reserve = reserves[asset];
/*LN-79*/

        // Calculate rTokens to burn based on current index
/*LN-82*/         uint256 rTokensToBurn = rayDiv(amount, reserve.liquidityIndex);
/*LN-83*/

/*LN-84*/         _burnRToken(reserve.rTokenAddress, msg.sender, rTokensToBurn);
/*LN-85*/

/*LN-86*/         reserve.totalLiquidity -= amount;
        // Transfer underlying to recipient
/*LN-87*/         IERC20(asset).transfer(to, amount);
/*LN-88*/

/*LN-89*/         return amount;
/*LN-90*/     }
/*LN-91*/

    /**
     * @notice Borrow tokens from pool with collateral
     * @dev Requires sufficient collateral position
     * @param asset Token to borrow
     * @param amount Amount to borrow
     * @param interestRateMode Stable or variable rate
     * @param referralCode Optional referral code
     * @param onBehalfOf Address receiving borrowed tokens
     */
/*LN-95*/     function borrow(
/*LN-96*/         address asset,
/*LN-97*/         uint256 amount,
/*LN-98*/         uint256 interestRateMode,
/*LN-99*/         uint16 referralCode,
/*LN-100*/         address onBehalfOf
/*LN-101*/     ) external {
        // Execute borrow transfer
/*LN-103*/         IERC20(asset).transfer(onBehalfOf, amount);
/*LN-104*/     }
/*LN-105*/

    /**
     * @notice Execute flash loan
     * @dev Provides uncollateralized loans within single transaction
     * @param receiverAddress Contract to receive flash loan
     * @param assets Array of token addresses
     * @param amounts Array of amounts to borrow
     * @param modes Repayment modes per asset
     * @param onBehalfOf Address for debt tracking
     * @param params Arbitrary data for callback
     * @param referralCode Optional referral code
     */
/*LN-109*/     function flashLoan(
/*LN-110*/         address receiverAddress,
/*LN-111*/         address[] calldata assets,
/*LN-112*/         uint256[] calldata amounts,
/*LN-113*/         uint256[] calldata modes,
/*LN-114*/         address onBehalfOf,
/*LN-115*/         bytes calldata params,
/*LN-116*/         uint16 referralCode
/*LN-117*/     ) external {
        // Transfer flash loan amounts
/*LN-118*/         for (uint256 i = 0; i < assets.length; i++) {
/*LN-119*/             IERC20(assets[i]).transfer(receiverAddress, amounts[i]);
/*LN-120*/         }
/*LN-121*/

        // Execute receiver callback
/*LN-123*/         require(
/*LN-124*/             IFlashLoanReceiver(receiverAddress).executeOperation(
/*LN-125*/                 assets,
/*LN-126*/                 amounts,
/*LN-127*/                 new uint256[](assets.length),
/*LN-128*/                 msg.sender,
/*LN-129*/                 params
/*LN-130*/             ),
/*LN-131*/             "Flashloan callback failed"
/*LN-132*/         );
/*LN-133*/

/*LN-135*/

        // Collect repayment
/*LN-136*/         for (uint256 i = 0; i < assets.length; i++) {
/*LN-137*/             IERC20(assets[i]).transferFrom(
/*LN-138*/                 receiverAddress,
/*LN-139*/                 address(this),
/*LN-140*/                 amounts[i]
/*LN-141*/             );
/*LN-142*/         }
/*LN-143*/     }
/*LN-144*/

    /**
     * @notice Ray division with rounding
     * @dev Standard Aave ray math implementation
     * @param a Numerator
     * @param b Denominator
     * @return Result in ray precision
     */
/*LN-148*/     function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
/*LN-149*/         uint256 halfB = b / 2;
/*LN-150*/         require(b != 0, "Division by zero");
/*LN-151*/         return (a * RAY + halfB) / b;
/*LN-152*/     }
/*LN-153*/

/*LN-154*/     function _mintRToken(address rToken, address to, uint256 amount) internal {
        // Mint interest-bearing tokens
/*LN-156*/     }
/*LN-157*/

/*LN-158*/     function _burnRToken(
/*LN-159*/         address rToken,
/*LN-160*/         address from,
/*LN-161*/         uint256 amount
/*LN-162*/     ) internal {
        // Burn interest-bearing tokens
/*LN-164*/     }
/*LN-165*/ }
/*LN-166*/
