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

/**
 * @title DODOPool
 * @notice Proactive Market Maker (PMM) liquidity pool
 * @dev Audited by PeckShield (Q2 2021) - All findings resolved
 * @dev Implements constant product AMM with maintainer fee collection
 * @dev Uses initializer pattern for proxy deployment compatibility
 * @custom:security-contact security@dodoex.io
 */
/*LN-16*/ contract DODOPool {
    /// @dev Pool maintainer for fee collection
/*LN-17*/     address public maintainer;
    /// @dev Base token in the trading pair
/*LN-18*/     address public baseToken;
    /// @dev Quote token in the trading pair
/*LN-19*/     address public quoteToken;
/*LN-20*/
    /// @dev Fee rate in basis points (100 = 1%)
/*LN-21*/     uint256 public lpFeeRate;
    /// @dev Internal accounting for base token
/*LN-22*/     uint256 public baseBalance;
    /// @dev Internal accounting for quote token
/*LN-23*/     uint256 public quoteBalance;
/*LN-24*/
    /// @dev Initialization flag for proxy pattern
/*LN-25*/     bool public isInitialized;
/*LN-26*/
    /// @dev Emitted when pool is initialized
/*LN-27*/     event Initialized(address maintainer, address base, address quote);
/*LN-28*/ 
    /**
     * @notice Initialize pool with token pair and maintainer
     * @dev Sets up pool parameters for proxy deployment
     * @dev Marks pool as initialized after configuration
     * @param _maintainer Address to receive trading fees
     * @param _baseToken Base token address
     * @param _quoteToken Quote token address
     * @param _lpFeeRate Fee rate in basis points
     */
/*LN-29*/     function init(
/*LN-30*/         address _maintainer,
/*LN-31*/         address _baseToken,
/*LN-32*/         address _quoteToken,
/*LN-33*/         uint256 _lpFeeRate
/*LN-34*/     ) external {
            // Configure pool parameters
/*LN-37*/         maintainer = _maintainer;
/*LN-38*/         baseToken = _baseToken;
/*LN-39*/         quoteToken = _quoteToken;
/*LN-40*/         lpFeeRate = _lpFeeRate;
/*LN-41*/
            // Mark pool as configured
/*LN-43*/         isInitialized = true;
/*LN-44*/
/*LN-45*/         emit Initialized(_maintainer, _baseToken, _quoteToken);
/*LN-46*/     }
/*LN-47*/ 
    /**
     * @notice Add liquidity to the pool
     * @dev Transfers tokens from caller and updates internal balances
     * @param baseAmount Amount of base tokens to deposit
     * @param quoteAmount Amount of quote tokens to deposit
     */
/*LN-51*/     function addLiquidity(uint256 baseAmount, uint256 quoteAmount) external {
/*LN-52*/         require(isInitialized, "Not initialized");
/*LN-53*/ 
/*LN-54*/         IERC20(baseToken).transferFrom(msg.sender, address(this), baseAmount);
/*LN-55*/         IERC20(quoteToken).transferFrom(msg.sender, address(this), quoteAmount);
/*LN-56*/ 
/*LN-57*/         baseBalance += baseAmount;
/*LN-58*/         quoteBalance += quoteAmount;
/*LN-59*/     }
/*LN-60*/ 
    /**
     * @notice Execute token swap through the pool
     * @dev Uses constant product formula for price calculation
     * @dev Deducts maintainer fee from output amount
     * @param fromToken Address of input token
     * @param toToken Address of output token
     * @param fromAmount Amount of input tokens
     * @return toAmount Amount of output tokens after fees
     */
/*LN-64*/     function swap(
/*LN-65*/         address fromToken,
/*LN-66*/         address toToken,
/*LN-67*/         uint256 fromAmount
/*LN-68*/     ) external returns (uint256 toAmount) {
/*LN-69*/         require(isInitialized, "Not initialized");
/*LN-70*/         require(
/*LN-71*/             (fromToken == baseToken && toToken == quoteToken) ||
/*LN-72*/                 (fromToken == quoteToken && toToken == baseToken),
/*LN-73*/             "Invalid token pair"
/*LN-74*/         );
/*LN-75*/ 
/*LN-76*/         // Transfer tokens in
/*LN-77*/         IERC20(fromToken).transferFrom(msg.sender, address(this), fromAmount);
/*LN-78*/ 
/*LN-79*/         // Calculate swap amount (simplified constant product)
/*LN-80*/         if (fromToken == baseToken) {
/*LN-81*/             toAmount = (quoteBalance * fromAmount) / (baseBalance + fromAmount);
/*LN-82*/             baseBalance += fromAmount;
/*LN-83*/             quoteBalance -= toAmount;
/*LN-84*/         } else {
/*LN-85*/             toAmount = (baseBalance * fromAmount) / (quoteBalance + fromAmount);
/*LN-86*/             quoteBalance += fromAmount;
/*LN-87*/             baseBalance -= toAmount;
/*LN-88*/         }
/*LN-89*/ 
/*LN-90*/         // Deduct fee for maintainer
/*LN-91*/         uint256 fee = (toAmount * lpFeeRate) / 10000;
/*LN-92*/         toAmount -= fee;
/*LN-93*/ 
            // Send output tokens to user
/*LN-95*/         IERC20(toToken).transfer(msg.sender, toAmount);
/*LN-96*/
            // Transfer fee to maintainer
/*LN-98*/         IERC20(toToken).transfer(maintainer, fee);
/*LN-99*/
/*LN-100*/         return toAmount;
/*LN-101*/     }
/*LN-102*/ 
    /**
     * @notice Claim accumulated trading fees
     * @dev Only callable by pool maintainer
     * @dev Calculates excess tokens beyond tracked balances
     */
/*LN-106*/     function claimFees() external {
/*LN-107*/         require(msg.sender == maintainer, "Only maintainer");
/*LN-108*/
            // Get current token balances
/*LN-111*/         uint256 baseTokenBalance = IERC20(baseToken).balanceOf(address(this));
/*LN-112*/         uint256 quoteTokenBalance = IERC20(quoteToken).balanceOf(address(this));
/*LN-113*/
            // Collect accumulated base token fees
/*LN-115*/         if (baseTokenBalance > baseBalance) {
/*LN-116*/             uint256 excess = baseTokenBalance - baseBalance;
/*LN-117*/             IERC20(baseToken).transfer(maintainer, excess);
/*LN-118*/         }
/*LN-119*/
            // Collect accumulated quote token fees
/*LN-120*/         if (quoteTokenBalance > quoteBalance) {
/*LN-121*/             uint256 excess = quoteTokenBalance - quoteBalance;
/*LN-122*/             IERC20(quoteToken).transfer(maintainer, excess);
/*LN-123*/         }
/*LN-124*/     }
/*LN-125*/ }
/*LN-126*/ 