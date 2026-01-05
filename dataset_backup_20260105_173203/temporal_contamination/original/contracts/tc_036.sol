/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * COW PROTOCOL EXPLOIT (November 2024)
/*LN-6*/  * Loss: $166,000
/*LN-7*/  * Attack: Unauthorized Callback Invocation + Solver Manipulation
/*LN-8*/  *
/*LN-9*/  * CoW Protocol is a DEX aggregator using intent-based trading with solvers.
/*LN-10*/  * The exploit involved directly calling the uniswapV3SwapCallback function
/*LN-11*/  * with crafted parameters, bypassing normal swap validation, and extracting
/*LN-12*/  * funds from a solver contract.
/*LN-13*/  */
/*LN-14*/ 
/*LN-15*/ interface IERC20 {
/*LN-16*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-17*/ 
/*LN-18*/     function transferFrom(
/*LN-19*/         address from,
/*LN-20*/         address to,
/*LN-21*/         uint256 amount
/*LN-22*/     ) external returns (bool);
/*LN-23*/ 
/*LN-24*/     function balanceOf(address account) external view returns (uint256);
/*LN-25*/ 
/*LN-26*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-27*/ }
/*LN-28*/ 
/*LN-29*/ interface IWETH {
/*LN-30*/     function deposit() external payable;
/*LN-31*/ 
/*LN-32*/     function withdraw(uint256 amount) external;
/*LN-33*/ 
/*LN-34*/     function balanceOf(address account) external view returns (uint256);
/*LN-35*/ }
/*LN-36*/ 
/*LN-37*/ contract CowSolver {
/*LN-38*/     IWETH public immutable WETH;
/*LN-39*/     address public immutable settlement;
/*LN-40*/ 
/*LN-41*/     constructor(address _weth, address _settlement) {
/*LN-42*/         WETH = IWETH(_weth);
/*LN-43*/         settlement = _settlement;
/*LN-44*/     }
/*LN-45*/ 
/*LN-46*/     /**
/*LN-47*/      * @notice Uniswap V3 swap callback
/*LN-48*/      * @dev VULNERABILITY: Can be called directly by anyone, not just Uniswap pool
/*LN-49*/      */
/*LN-50*/     function uniswapV3SwapCallback(
/*LN-51*/         int256 amount0Delta,
/*LN-52*/         int256 amount1Delta,
/*LN-53*/         bytes calldata data
/*LN-54*/     ) external payable {
/*LN-55*/         // VULNERABILITY 1: No validation that msg.sender is a legitimate Uniswap V3 pool
/*LN-56*/         // Anyone can call this function directly with arbitrary parameters
/*LN-57*/         // Should verify: require(msg.sender == expectedPool, "Unauthorized callback");
/*LN-58*/ 
/*LN-59*/         // Decode callback data
/*LN-60*/         (
/*LN-61*/             uint256 price,
/*LN-62*/             address solver,
/*LN-63*/             address tokenIn,
/*LN-64*/             address recipient
/*LN-65*/         ) = abi.decode(data, (uint256, address, address, address));
/*LN-66*/ 
/*LN-67*/         // VULNERABILITY 2: Trusts user-provided 'solver' address in calldata
/*LN-68*/         // Attacker can specify their own address as solver
/*LN-69*/         // Contract will transfer tokens to attacker-controlled address
/*LN-70*/ 
/*LN-71*/         // VULNERABILITY 3: Trusts user-provided 'recipient' address
/*LN-72*/         // Attacker controls where funds ultimately go
/*LN-73*/ 
/*LN-74*/         // VULNERABILITY 4: No validation of swap amounts or prices
/*LN-75*/         // amount0Delta and amount1Delta controlled by attacker
/*LN-76*/         // Can specify amounts that drain the contract
/*LN-77*/ 
/*LN-78*/         // Calculate payment amount based on manipulated parameters
/*LN-79*/         uint256 amountToPay;
/*LN-80*/         if (amount0Delta > 0) {
/*LN-81*/             amountToPay = uint256(amount0Delta);
/*LN-82*/         } else {
/*LN-83*/             amountToPay = uint256(amount1Delta);
/*LN-84*/         }
/*LN-85*/ 
/*LN-86*/         // VULNERABILITY 5: Transfers tokens without verifying legitimate swap occurred
/*LN-87*/         // No check that a real Uniswap swap initiated this callback
/*LN-88*/         // Attacker gets tokens without providing anything in return
/*LN-89*/ 
/*LN-90*/         if (tokenIn == address(WETH)) {
/*LN-91*/             WETH.withdraw(amountToPay);
/*LN-92*/             payable(recipient).transfer(amountToPay);
/*LN-93*/         } else {
/*LN-94*/             IERC20(tokenIn).transfer(recipient, amountToPay);
/*LN-95*/         }
/*LN-96*/     }
/*LN-97*/ 
/*LN-98*/     /**
/*LN-99*/      * @notice Execute settlement (normal flow)
/*LN-100*/      * @dev This is how the function SHOULD be called, through proper settlement
/*LN-101*/      */
/*LN-102*/     function executeSettlement(bytes calldata settlementData) external {
/*LN-103*/         require(msg.sender == settlement, "Only settlement");
/*LN-104*/         // Normal settlement logic...
/*LN-105*/     }
/*LN-106*/ 
/*LN-107*/     receive() external payable {}
/*LN-108*/ }
/*LN-109*/ 
/*LN-110*/ /**
/*LN-111*/  * EXPLOIT SCENARIO:
/*LN-112*/  *
/*LN-113*/  * 1. Attacker identifies vulnerable CowSolver contract:
/*LN-114*/  *    - Contract: 0xA58cA3013Ed560594557f02420ed77e154De0109
/*LN-115*/  *    - Has uniswapV3SwapCallback function exposed
/*LN-116*/  *    - No msg.sender validation on callback
/*LN-117*/  *
/*LN-118*/  * 2. Attacker crafts malicious callback data:
/*LN-119*/  *    - amount0Delta: -1978613680814188858940 (negative, expects to receive)
/*LN-120*/  *    - amount1Delta: 5373296932158610028 (positive, solver should pay)
/*LN-121*/  *    - data contains:
/*LN-122*/  *      * price: 1976408883179648193852
/*LN-123*/  *      * solver: attacker's address
/*LN-124*/  *      * tokenIn: WETH address
/*LN-125*/  *      * recipient: attacker's address
/*LN-126*/  *
/*LN-127*/  * 3. Attacker directly calls uniswapV3SwapCallback():
/*LN-128*/  *    - Calls solver contract's callback function directly
/*LN-129*/  *    - NOT through a real Uniswap V3 pool swap
/*LN-130*/  *    - Bypasses all normal swap validation
/*LN-131*/  *
/*LN-132*/  * 4. Solver contract processes malicious callback:
/*LN-133*/  *    - No verification that msg.sender is legitimate Uniswap pool
/*LN-134*/  *    - Trusts attacker-provided parameters in data
/*LN-135*/  *    - Calculates payment: amount1Delta = 5.37 WETH
/*LN-136*/  *
/*LN-137*/  * 5. Contract sends WETH to attacker:
/*LN-138*/  *    - Withdraws WETH and converts to ETH
/*LN-139*/  *    - Sends ETH to attacker-specified recipient
/*LN-140*/  *    - Attacker receives ~$166K worth of ETH
/*LN-141*/  *
/*LN-142*/  * 6. No repayment required:
/*LN-143*/  *    - Normal Uniswap callback expects tokens in return
/*LN-144*/  *    - But no validation means attacker pays nothing
/*LN-145*/  *    - Direct call bypasses pool's token transfer requirements
/*LN-146*/  *
/*LN-147*/  * Root Causes:
/*LN-148*/  * - Missing msg.sender validation in callback function
/*LN-149*/  * - Callback function marked as external/public instead of internal
/*LN-150*/  * - No verification that callback came from legitimate Uniswap pool
/*LN-151*/  * - Trusting user-provided addresses in callback data
/*LN-152*/  * - No access control on sensitive callback functions
/*LN-153*/  * - Lack of reentrancy guards
/*LN-154*/  * - Missing context validation (was a swap actually initiated?)
/*LN-155*/  *
/*LN-156*/  * Fix:
/*LN-157*/  * - Validate msg.sender is a legitimate Uniswap V3 pool:
/*LN-158*/  *   ```solidity
/*LN-159*/  *   require(isValidPool[msg.sender], "Unauthorized callback");
/*LN-160*/  *   ```
/*LN-161*/  * - Maintain whitelist of approved pool addresses
/*LN-162*/  * - Use factory.getPool() to verify pool legitimacy
/*LN-163*/  * - Implement reentrancy guards
/*LN-164*/  * - Add access control modifiers
/*LN-165*/  * - Store swap state before initiating, validate in callback
/*LN-166*/  * - Never trust user-provided addresses in callback data
/*LN-167*/  * - Make callbacks internal/private when possible
/*LN-168*/  * - Implement emergency pause functionality
/*LN-169*/  * - Add maximum transfer limits per callback
/*LN-170*/  */
/*LN-171*/ 