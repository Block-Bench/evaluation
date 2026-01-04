/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * BEDROCK DEFI EXPLOIT (September 2024)
/*LN-6*/  * Loss: $2 million
/*LN-7*/  * Attack: Price Manipulation via Improper Exchange Rate Calculation
/*LN-8*/  *
/*LN-9*/  * Bedrock DeFi is a liquid staking platform for uniBTC (wrapped BTC on Ethereum).
/*LN-10*/  * The exploit involved minting uniBTC by depositing ETH at a manipulated exchange rate,
/*LN-11*/  * receiving far more uniBTC than the deposited ETH value warranted.
/*LN-12*/  */
/*LN-13*/ 
/*LN-14*/ interface IERC20 {
/*LN-15*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-16*/ 
/*LN-17*/     function transferFrom(
/*LN-18*/         address from,
/*LN-19*/         address to,
/*LN-20*/         uint256 amount
/*LN-21*/     ) external returns (bool);
/*LN-22*/ 
/*LN-23*/     function balanceOf(address account) external view returns (uint256);
/*LN-24*/ 
/*LN-25*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-26*/ }
/*LN-27*/ 
/*LN-28*/ interface IUniswapV3Router {
/*LN-29*/     struct ExactInputSingleParams {
/*LN-30*/         address tokenIn;
/*LN-31*/         address tokenOut;
/*LN-32*/         uint24 fee;
/*LN-33*/         address recipient;
/*LN-34*/         uint256 deadline;
/*LN-35*/         uint256 amountIn;
/*LN-36*/         uint256 amountOutMinimum;
/*LN-37*/         uint160 sqrtPriceLimitX96;
/*LN-38*/     }
/*LN-39*/ 
/*LN-40*/     function exactInputSingle(
/*LN-41*/         ExactInputSingleParams calldata params
/*LN-42*/     ) external payable returns (uint256 amountOut);
/*LN-43*/ }
/*LN-44*/ 
/*LN-45*/ contract BedrockVault {
/*LN-46*/     IERC20 public immutable uniBTC;
/*LN-47*/     IERC20 public immutable WBTC;
/*LN-48*/     IUniswapV3Router public immutable router;
/*LN-49*/ 
/*LN-50*/     uint256 public totalETHDeposited;
/*LN-51*/     uint256 public totalUniBTCMinted;
/*LN-52*/ 
/*LN-53*/     constructor(address _uniBTC, address _wbtc, address _router) {
/*LN-54*/         uniBTC = IERC20(_uniBTC);
/*LN-55*/         WBTC = IERC20(_wbtc);
/*LN-56*/         router = IUniswapV3Router(_router);
/*LN-57*/     }
/*LN-58*/ 
/*LN-59*/     /**
/*LN-60*/      * @notice Mint uniBTC by depositing ETH
/*LN-61*/      * @dev VULNERABILITY: Incorrect exchange rate calculation
/*LN-62*/      */
/*LN-63*/     function mint() external payable {
/*LN-64*/         require(msg.value > 0, "No ETH sent");
/*LN-65*/ 
/*LN-66*/         // VULNERABILITY 1: Assumes 1 ETH = 1 BTC exchange rate
/*LN-67*/         // Completely ignores actual market prices
/*LN-68*/         // ETH is worth ~15-20x less than BTC
/*LN-69*/ 
/*LN-70*/         uint256 uniBTCAmount = msg.value;
/*LN-71*/ 
/*LN-72*/         // VULNERABILITY 2: No price oracle validation
/*LN-73*/         // Should check:
/*LN-74*/         // - Current ETH/BTC price ratio
/*LN-75*/         // - Use Chainlink or other oracle
/*LN-76*/         // - Validate exchange rate is reasonable
/*LN-77*/ 
/*LN-78*/         // VULNERABILITY 3: No slippage protection
/*LN-79*/         // User can mint at fixed 1:1 ratio regardless of market conditions
/*LN-80*/ 
/*LN-81*/         totalETHDeposited += msg.value;
/*LN-82*/         totalUniBTCMinted += uniBTCAmount;
/*LN-83*/ 
/*LN-84*/         // VULNERABILITY 4: Mints BTC-pegged token for ETH at wrong ratio
/*LN-85*/         // User deposits 1 ETH (~$3000)
/*LN-86*/         // Gets 1 uniBTC (~$60000 value)
/*LN-87*/         // 20x value extraction
/*LN-88*/ 
/*LN-89*/         // Transfer uniBTC to user
/*LN-90*/         uniBTC.transfer(msg.sender, uniBTCAmount);
/*LN-91*/     }
/*LN-92*/ 
/*LN-93*/     /**
/*LN-94*/      * @notice Redeem ETH by burning uniBTC
/*LN-95*/      */
/*LN-96*/     function redeem(uint256 amount) external {
/*LN-97*/         require(amount > 0, "No amount specified");
/*LN-98*/         require(uniBTC.balanceOf(msg.sender) >= amount, "Insufficient balance");
/*LN-99*/ 
/*LN-100*/         // VULNERABILITY 5: Reverse operation also uses wrong exchange rate
/*LN-101*/         // Would allow draining ETH at incorrect ratio
/*LN-102*/ 
/*LN-103*/         uniBTC.transferFrom(msg.sender, address(this), amount);
/*LN-104*/ 
/*LN-105*/         uint256 ethAmount = amount;
/*LN-106*/         require(address(this).balance >= ethAmount, "Insufficient ETH");
/*LN-107*/ 
/*LN-108*/         payable(msg.sender).transfer(ethAmount);
/*LN-109*/     }
/*LN-110*/ 
/*LN-111*/     /**
/*LN-112*/      * @notice Get current exchange rate
/*LN-113*/      * @dev Should return ETH per uniBTC, but returns 1:1
/*LN-114*/      */
/*LN-115*/     function getExchangeRate() external pure returns (uint256) {
/*LN-116*/         // VULNERABILITY 6: Hardcoded 1:1 rate
/*LN-117*/         // Should dynamically calculate based on:
/*LN-118*/         // - Pool reserves
/*LN-119*/         // - External oracle prices
/*LN-120*/         // - Total assets vs total supply
/*LN-121*/         return 1e18;
/*LN-122*/     }
/*LN-123*/ 
/*LN-124*/     receive() external payable {}
/*LN-125*/ }
/*LN-126*/ 
/*LN-127*/ /**
/*LN-128*/  * EXPLOIT SCENARIO:
/*LN-129*/  *
/*LN-130*/  * 1. Attacker obtains ETH flashloan:
/*LN-131*/  *    - Borrows 30,800 ETH from Balancer
/*LN-132*/  *    - Cost: ~$100M at ETH prices
/*LN-133*/  *
/*LN-134*/  * 2. Mint uniBTC at 1:1 ratio:
/*LN-135*/  *    - Calls mint() with 30,800 ETH
/*LN-136*/  *    - Contract incorrectly assumes 1 ETH = 1 BTC
/*LN-137*/  *    - Receives 30,800 uniBTC tokens
/*LN-138*/  *    - Real value: 30,800 BTC * $65,000 = ~$2B
/*LN-139*/  *    - Paid: 30,800 ETH * $3,000 = ~$92M
/*LN-140*/  *    - Immediate 20x value gain
/*LN-141*/  *
/*LN-142*/  * 3. Swap uniBTC for WBTC on Uniswap V3:
/*LN-143*/  *    - uniBTC/WBTC pool exists on Uniswap
/*LN-144*/  *    - Swap 30,800 uniBTC for WBTC
/*LN-145*/  *    - Due to pool liquidity limits, receives ~30 WBTC
/*LN-146*/  *    - Still profitable: 30 WBTC = ~$2M
/*LN-147*/  *
/*LN-148*/  * 4. Swap WBTC back to ETH:
/*LN-149*/  *    - Convert 30 WBTC to ETH via Uniswap
/*LN-150*/  *    - Receives ETH to repay flashloan
/*LN-151*/  *
/*LN-152*/  * 5. Repay flashloan:
/*LN-153*/  *    - Return 30,800 ETH to Balancer
/*LN-154*/  *    - Keep profit: ~$2M in remaining assets
/*LN-155*/  *
/*LN-156*/  * 6. Profit extraction:
/*LN-157*/  *    - Net profit after fees: $1.7-2M
/*LN-158*/  *    - Entire attack in single transaction
/*LN-159*/  *
/*LN-160*/  * Root Causes:
/*LN-161*/  * - Hardcoded 1:1 ETH:BTC exchange rate
/*LN-162*/  * - No price oracle integration (Chainlink, etc.)
/*LN-163*/  * - Missing exchange rate validation
/*LN-164*/  * - No consideration of actual asset values
/*LN-165*/  * - Lack of market price checks
/*LN-166*/  * - Missing slippage protection
/*LN-167*/  * - No liquidity checks before minting
/*LN-168*/  * - Insufficient testing of exchange rate logic
/*LN-169*/  *
/*LN-170*/  * Fix:
/*LN-171*/  * - Integrate Chainlink price feeds for ETH/BTC ratio
/*LN-172*/  * - Calculate proper exchange rate:
/*LN-173*/  *   ```solidity
/*LN-174*/  *   uint256 ethPrice = oracle.getPrice(ETH);
/*LN-175*/  *   uint256 btcPrice = oracle.getPrice(BTC);
/*LN-176*/  *   uint256 uniBTCAmount = (msg.value * ethPrice) / btcPrice;
/*LN-177*/  *   ```
/*LN-178*/  * - Add minimum/maximum exchange rate bounds
/*LN-179*/  * - Implement slippage protection for mints
/*LN-180*/  * - Add circuit breakers for unusual exchange rates
/*LN-181*/  * - Require multiple oracle sources for price validation
/*LN-182*/  * - Add time-weighted price checks
/*LN-183*/  * - Implement mint/redeem fees to discourage arbitrage
/*LN-184*/  * - Add liquidity depth checks before large mints
/*LN-185*/  * - Implement emergency pause functionality
/*LN-186*/  */
/*LN-187*/ 