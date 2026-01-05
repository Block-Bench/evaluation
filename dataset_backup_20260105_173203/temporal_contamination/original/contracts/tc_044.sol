/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * SONNE FINANCE EXPLOIT (May 2024)
/*LN-6*/  * Loss: $20 million
/*LN-7*/  * Attack: Oracle Manipulation via Donation Attack on Empty Market
/*LN-8*/  *
/*LN-9*/  * VULNERABILITY OVERVIEW:
/*LN-10*/  * Sonne Finance, a Compound V2 fork on Optimism, was exploited through oracle manipulation.
/*LN-11*/  * Attacker created an empty lending market, donated collateral to manipulate exchange rate,
/*LN-12*/  * then used inflated collateral value to borrow assets from other markets.
/*LN-13*/  *
/*LN-14*/  * ROOT CAUSE:
/*LN-15*/  * 1. Exchange rate calculation vulnerable when totalSupply is very small
/*LN-16*/  * 2. Direct token donation could manipulate underlying/supply ratio
/*LN-17*/  * 3. No minimum liquidity requirement for new markets
/*LN-18*/  * 4. Missing sanity checks on exchange rate jumps
/*LN-19*/  *
/*LN-20*/  * ATTACK FLOW:
/*LN-21*/  * 1. Attacker supplied VELO tokens as collateral on Sonne
/*LN-22*/  * 2. Borrowed small amount from new soWETH market (low liquidity)
/*LN-23*/  * 3. Donated large amount of WETH directly to soWETH contract
/*LN-24*/  * 4. Exchange rate inflated: totalUnderlying/totalSupply became huge
/*LN-25*/  * 5. Redeemed minimal soWETH for massive WETH due to manipulated rate
/*LN-26*/  * 6. Used over-valued collateral to borrow from other markets
/*LN-27*/  * 7. Drained ~$20M in various assets
/*LN-28*/  */
/*LN-29*/ 
/*LN-30*/ interface IERC20 {
/*LN-31*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-32*/ 
/*LN-33*/     function transferFrom(
/*LN-34*/         address from,
/*LN-35*/         address to,
/*LN-36*/         uint256 amount
/*LN-37*/     ) external returns (bool);
/*LN-38*/ 
/*LN-39*/     function balanceOf(address account) external view returns (uint256);
/*LN-40*/ }
/*LN-41*/ 
/*LN-42*/ /**
/*LN-43*/  * Simplified model of Sonne Finance's vulnerable cToken (Compound V2 fork)
/*LN-44*/  */
/*LN-45*/ contract SonneMarket {
/*LN-46*/     IERC20 public underlying;
/*LN-47*/ 
/*LN-48*/     string public name = "Sonne WETH";
/*LN-49*/     string public symbol = "soWETH";
/*LN-50*/     uint8 public decimals = 8;
/*LN-51*/ 
/*LN-52*/     uint256 public totalSupply;
/*LN-53*/     mapping(address => uint256) public balanceOf;
/*LN-54*/ 
/*LN-55*/     // Compound-style interest rate tracking
/*LN-56*/     uint256 public totalBorrows;
/*LN-57*/     uint256 public totalReserves;
/*LN-58*/ 
/*LN-59*/     event Mint(address minter, uint256 mintAmount, uint256 mintTokens);
/*LN-60*/     event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);
/*LN-61*/ 
/*LN-62*/     constructor(address _underlying) {
/*LN-63*/         underlying = IERC20(_underlying);
/*LN-64*/     }
/*LN-65*/ 
/*LN-66*/     /**
/*LN-67*/      * @dev VULNERABILITY: Exchange rate calculation susceptible to donation attack
/*LN-68*/      * @dev When totalSupply is small, direct donations massively inflate rate
/*LN-69*/      */
/*LN-70*/     function exchangeRate() public view returns (uint256) {
/*LN-71*/         if (totalSupply == 0) {
/*LN-72*/             return 1e18; // Initial exchange rate: 1:1
/*LN-73*/         }
/*LN-74*/ 
/*LN-75*/         // VULNERABILITY 1: Uses balanceOf which includes donated tokens
/*LN-76*/         uint256 cash = underlying.balanceOf(address(this));
/*LN-77*/ 
/*LN-78*/         // exchangeRate = (cash + totalBorrows - totalReserves) / totalSupply
/*LN-79*/         // VULNERABILITY 2: If totalSupply very small, rate easily manipulated
/*LN-80*/         uint256 totalUnderlying = cash + totalBorrows - totalReserves;
/*LN-81*/ 
/*LN-82*/         // VULNERABILITY 3: No sanity check on rate changes
/*LN-83*/         // VULNERABILITY 4: Rate can jump 1000x in single block
/*LN-84*/         return (totalUnderlying * 1e18) / totalSupply;
/*LN-85*/     }
/*LN-86*/ 
/*LN-87*/     /**
/*LN-88*/      * @dev Supply underlying tokens, receive cTokens
/*LN-89*/      */
/*LN-90*/     function mint(uint256 mintAmount) external returns (uint256) {
/*LN-91*/         require(mintAmount > 0, "Zero mint");
/*LN-92*/ 
/*LN-93*/         uint256 exchangeRateMantissa = exchangeRate();
/*LN-94*/ 
/*LN-95*/         // Calculate cTokens to mint: mintAmount * 1e18 / exchangeRate
/*LN-96*/         uint256 mintTokens = (mintAmount * 1e18) / exchangeRateMantissa;
/*LN-97*/ 
/*LN-98*/         // VULNERABILITY 5: First depositor can manipulate by minting tiny amount
/*LN-99*/         // then donating to inflate rate for their subsequent operations
/*LN-100*/ 
/*LN-101*/         totalSupply += mintTokens;
/*LN-102*/         balanceOf[msg.sender] += mintTokens;
/*LN-103*/ 
/*LN-104*/         underlying.transferFrom(msg.sender, address(this), mintAmount);
/*LN-105*/ 
/*LN-106*/         emit Mint(msg.sender, mintAmount, mintTokens);
/*LN-107*/         return mintTokens;
/*LN-108*/     }
/*LN-109*/ 
/*LN-110*/     /**
/*LN-111*/      * @dev Redeem cTokens for underlying based on current exchange rate
/*LN-112*/      */
/*LN-113*/     function redeem(uint256 redeemTokens) external returns (uint256) {
/*LN-114*/         require(balanceOf[msg.sender] >= redeemTokens, "Insufficient balance");
/*LN-115*/ 
/*LN-116*/         uint256 exchangeRateMantissa = exchangeRate();
/*LN-117*/ 
/*LN-118*/         // Calculate underlying: redeemTokens * exchangeRate / 1e18
/*LN-119*/         // VULNERABILITY 6: Manipulated rate allows redeeming far more than deposited
/*LN-120*/         uint256 redeemAmount = (redeemTokens * exchangeRateMantissa) / 1e18;
/*LN-121*/ 
/*LN-122*/         balanceOf[msg.sender] -= redeemTokens;
/*LN-123*/         totalSupply -= redeemTokens;
/*LN-124*/ 
/*LN-125*/         // VULNERABILITY 7: Contract pays out based on manipulated calculation
/*LN-126*/         underlying.transfer(msg.sender, redeemAmount);
/*LN-127*/ 
/*LN-128*/         emit Redeem(msg.sender, redeemAmount, redeemTokens);
/*LN-129*/         return redeemAmount;
/*LN-130*/     }
/*LN-131*/ 
/*LN-132*/     /**
/*LN-133*/      * @dev Get account's current underlying balance (for collateral calculation)
/*LN-134*/      */
/*LN-135*/     function balanceOfUnderlying(
/*LN-136*/         address account
/*LN-137*/     ) external view returns (uint256) {
/*LN-138*/         uint256 exchangeRateMantissa = exchangeRate();
/*LN-139*/ 
/*LN-140*/         // VULNERABILITY 8: Inflated exchange rate makes collateral appear much larger
/*LN-141*/         // This allows borrowing more from other markets than justified
/*LN-142*/         return (balanceOf[account] * exchangeRateMantissa) / 1e18;
/*LN-143*/     }
/*LN-144*/ }
/*LN-145*/ 
/*LN-146*/ /**
/*LN-147*/  * ATTACK SCENARIO:
/*LN-148*/  *
/*LN-149*/  * Setup Phase:
/*LN-150*/  * 1. Sonne Finance deploys new soWETH market (low initial liquidity)
/*LN-151*/  * 2. Initial market state:
/*LN-152*/  *    - totalSupply: 0
/*LN-153*/  *    - totalUnderlying: 0
/*LN-154*/  *
/*LN-155*/  * Manipulation Phase:
/*LN-156*/  * 1. Attacker mints minimal amount:
/*LN-157*/  *    mint(1 wei WETH)
/*LN-158*/  *    - Receives 1 soWETH token
/*LN-159*/  *    - totalSupply: 1
/*LN-160*/  *    - totalUnderlying: 1
/*LN-161*/  *
/*LN-162*/  * 2. Attacker directly transfers large amount to contract:
/*LN-163*/  *    WETH.transfer(soWETH_contract, 200 WETH)
/*LN-164*/  *    - This is a donation, not a mint
/*LN-165*/  *    - totalSupply: still 1
/*LN-166*/  *    - totalUnderlying: now 200 * 1e18 + 1
/*LN-167*/  *
/*LN-168*/  * 3. Exchange rate now massively inflated:
/*LN-169*/  *    exchangeRate = (200e18 + 1) / 1 = 200e18
/*LN-170*/  *    - Should be 1e18
/*LN-171*/  *    - Now 200 billion times higher!
/*LN-172*/  *
/*LN-173*/  * Exploitation Phase:
/*LN-174*/  * 1. Attacker deposits small amount normally:
/*LN-175*/  *    mint(1 WETH)
/*LN-176*/  *    - Gets: 1e18 / 200e18 = ~0 soWETH (rounds to tiny amount)
/*LN-177*/  *
/*LN-178*/  * 2. Better approach - attacker uses inflated collateral value:
/*LN-179*/  *    - Their 1 soWETH token appears worth 200 WETH
/*LN-180*/  *    - Comptroller values collateral at inflated exchangeRate
/*LN-181*/  *    - Can borrow up to collateral factor * 200 WETH from other markets
/*LN-182*/  *
/*LN-183*/  * 3. Attacker borrows maximum from all markets:
/*LN-184*/  *    - USDC market: borrow $7M
/*LN-185*/  *    - DAI market: borrow $5M
/*LN-186*/  *    - WETH market: borrow $8M
/*LN-187*/  *    - Total: ~$20M borrowed against ~$1 actual collateral
/*LN-188*/  *
/*LN-189*/  * 4. Attacker transfers borrowed assets to external wallet
/*LN-190*/  * 5. Abandons manipulated position
/*LN-191*/  *
/*LN-192*/  * MITIGATION STRATEGIES:
/*LN-193*/  *
/*LN-194*/  * 1. Minimum Liquidity Lock:
/*LN-195*/  *    if (totalSupply == 0) {
/*LN-196*/  *        // Burn first 1000 tokens permanently
/*LN-197*/  *        totalSupply = 1000;
/*LN-198*/  *        balanceOf[address(0)] = 1000;
/*LN-199*/  *    }
/*LN-200*/  *
/*LN-201*/  * 2. Virtual Reserves (Uniswap V2 style):
/*LN-202*/  *    uint256 totalUnderlying = cash + totalBorrows - totalReserves + VIRTUAL_RESERVE;
/*LN-203*/  *    uint256 supply = totalSupply + VIRTUAL_SUPPLY;
/*LN-204*/  *    return (totalUnderlying * 1e18) / supply;
/*LN-205*/  *
/*LN-206*/  * 3. Exchange Rate Sanity Checks:
/*LN-207*/  *    uint256 newRate = calculateRate();
/*LN-208*/  *    require(newRate <= lastRate * 110 / 100, "Rate increased too fast");
/*LN-209*/  *    require(newRate >= lastRate * 90 / 100, "Rate decreased too fast");
/*LN-210*/  *
/*LN-211*/  * 4. Minimum Market Liquidity:
/*LN-212*/  *    require(totalSupply >= MIN_LIQUIDITY, "Market too small");
/*LN-213*/  *
/*LN-214*/  * 5. Time-Weighted Average Exchange Rate:
/*LN-215*/  *    - Use TWAP for collateral valuation
/*LN-216*/  *    - Harder to manipulate in single transaction
/*LN-217*/  *
/*LN-218*/  * 6. Deposit/Withdrawal Caps:
/*LN-219*/  *    - Limit size of first deposits
/*LN-220*/  *    - Gradual liquidity bootstrapping
/*LN-221*/  *
/*LN-222*/  * 7. Circuit Breakers:
/*LN-223*/  *    - Pause market if exchange rate jumps > X%
/*LN-224*/  *    - Require admin review for unusual movements
/*LN-225*/  */
/*LN-226*/ 