/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title Curve Finance Pool (Vulnerable Vyper Version)
/*LN-6*/  * @notice This contract demonstrates the Vyper reentrancy vulnerability that led to the $70M Curve hack
/*LN-7*/  * @dev July 30, 2023 - Vyper compiler bug causing reentrancy vulnerability
/*LN-8*/  *
/*LN-9*/  * VULNERABILITY: Reentrancy due to Vyper compiler bug
/*LN-10*/  *
/*LN-11*/  * ROOT CAUSE:
/*LN-12*/  * Certain versions of the Vyper compiler (0.2.15, 0.2.16, 0.3.0) had a bug in
/*LN-13*/  * handling reentrancy guards. The nonreentrant decorator did not properly protect
/*LN-14*/  * functions when:
/*LN-15*/  * 1. Multiple nonreentrant functions existed
/*LN-16*/  * 2. Functions made external calls (like ETH transfers)
/*LN-17*/  *
/*LN-18*/  * In Curve pools, the add_liquidity() function:
/*LN-19*/  * 1. Accepted ETH
/*LN-20*/  * 2. Transferred ETH to update balances
/*LN-21*/  * 3. The ETH transfer triggered receive()/fallback() in attacker contract
/*LN-22*/  * 4. Attacker could call add_liquidity() again during this callback
/*LN-23*/  * 5. The reentrancy guard failed to prevent this
/*LN-24*/  *
/*LN-25*/  * ATTACK VECTOR:
/*LN-26*/  * 1. Attacker takes flash loan (80,000 ETH from Balancer)
/*LN-27*/  * 2. Calls add_liquidity() with 40,000 ETH
/*LN-28*/  * 3. During ETH transfer in add_liquidity(), receive() is triggered
/*LN-29*/  * 4. In receive(), attacker calls add_liquidity() AGAIN with another 40,000 ETH
/*LN-30*/  * 5. Pool's internal accounting gets confused - mints LP tokens twice
/*LN-31*/  * 6. Attacker removes liquidity with inflated LP token balance
/*LN-32*/  * 7. Extracts more assets than deposited
/*LN-33*/  * 8. Repays flash loan with profit
/*LN-34*/  *
/*LN-35*/  * NOTE: This is a COMPILER BUG, not a logic error. The Solidity version below
/*LN-36*/  * demonstrates the behavior, but the actual vulnerable code was in Vyper.
/*LN-37*/  */
/*LN-38*/ 
/*LN-39*/ contract VulnerableCurvePool {
/*LN-40*/     // Token balances in the pool
/*LN-41*/     mapping(uint256 => uint256) public balances; // 0 = ETH, 1 = pETH
/*LN-42*/ 
/*LN-43*/     // LP token
/*LN-44*/     mapping(address => uint256) public lpBalances;
/*LN-45*/     uint256 public totalLPSupply;
/*LN-46*/ 
/*LN-47*/     // Reentrancy guard (VULNERABLE - doesn't work properly like in Vyper bug)
/*LN-48*/     uint256 private _status;
/*LN-49*/     uint256 private constant _NOT_ENTERED = 1;
/*LN-50*/     uint256 private constant _ENTERED = 2;
/*LN-51*/ 
/*LN-52*/     event LiquidityAdded(
/*LN-53*/         address indexed provider,
/*LN-54*/         uint256[2] amounts,
/*LN-55*/         uint256 lpMinted
/*LN-56*/     );
/*LN-57*/     event LiquidityRemoved(
/*LN-58*/         address indexed provider,
/*LN-59*/         uint256 lpBurned,
/*LN-60*/         uint256[2] amounts
/*LN-61*/     );
/*LN-62*/ 
/*LN-63*/     constructor() {
/*LN-64*/         _status = _NOT_ENTERED;
/*LN-65*/     }
/*LN-66*/ 
/*LN-67*/     /**
/*LN-68*/      * @notice Add liquidity to the pool
/*LN-69*/      * @param amounts Array of token amounts to deposit [ETH, pETH]
/*LN-70*/      * @param min_mint_amount Minimum LP tokens to mint
/*LN-71*/      *
/*LN-72*/      * VULNERABILITY:
/*LN-73*/      * The nonreentrant modifier in Vyper was supposed to prevent reentrancy,
/*LN-74*/      * but due to a compiler bug, it failed when:
/*LN-75*/      * 1. Function made external calls (ETH transfer)
/*LN-76*/      * 2. Multiple nonreentrant functions existed
/*LN-77*/      *
/*LN-78*/      * This allowed attackers to call add_liquidity recursively.
/*LN-79*/      */
/*LN-80*/     function add_liquidity(
/*LN-81*/         uint256[2] memory amounts,
/*LN-82*/         uint256 min_mint_amount
/*LN-83*/     ) external payable returns (uint256) {
/*LN-84*/         // VULNERABILITY: Reentrancy guard doesn't work properly (Vyper bug simulation)
/*LN-85*/         // In the real Vyper code, @nonreentrant decorator was present but ineffective
/*LN-86*/ 
/*LN-87*/         require(amounts[0] == msg.value, "ETH amount mismatch");
/*LN-88*/ 
/*LN-89*/         // Calculate LP tokens to mint
/*LN-90*/         uint256 lpToMint;
/*LN-91*/         if (totalLPSupply == 0) {
/*LN-92*/             lpToMint = amounts[0] + amounts[1];
/*LN-93*/         } else {
/*LN-94*/             // Simplified: real formula is more complex
/*LN-95*/             uint256 totalValue = balances[0] + balances[1];
/*LN-96*/             lpToMint = ((amounts[0] + amounts[1]) * totalLPSupply) / totalValue;
/*LN-97*/         }
/*LN-98*/ 
/*LN-99*/         require(lpToMint >= min_mint_amount, "Slippage");
/*LN-100*/ 
/*LN-101*/         // Update balances BEFORE external call (following CEI pattern)
/*LN-102*/         // But Vyper bug allows reentrancy anyway
/*LN-103*/         balances[0] += amounts[0];
/*LN-104*/         balances[1] += amounts[1];
/*LN-105*/ 
/*LN-106*/         // Mint LP tokens
/*LN-107*/         lpBalances[msg.sender] += lpToMint;
/*LN-108*/         totalLPSupply += lpToMint;
/*LN-109*/ 
/*LN-110*/         // VULNERABILITY: ETH transfer can trigger reentrancy
/*LN-111*/         // In Vyper, this line existed and triggered the attacker's receive()
/*LN-112*/         // The @nonreentrant decorator SHOULD have prevented reentrancy but didn't
/*LN-113*/         // due to compiler bug
/*LN-114*/         if (amounts[0] > 0) {
/*LN-115*/             // Simulate pool's internal operations that involve ETH transfer
/*LN-116*/             // In reality, Curve pools update internal state during this
/*LN-117*/             _handleETHTransfer(amounts[0]);
/*LN-118*/         }
/*LN-119*/ 
/*LN-120*/         emit LiquidityAdded(msg.sender, amounts, lpToMint);
/*LN-121*/         return lpToMint;
/*LN-122*/     }
/*LN-123*/ 
/*LN-124*/     /**
/*LN-125*/      * @notice Remove liquidity from the pool
/*LN-126*/      * @param lpAmount Amount of LP tokens to burn
/*LN-127*/      * @param min_amounts Minimum amounts to receive [ETH, pETH]
/*LN-128*/      */
/*LN-129*/     function remove_liquidity(
/*LN-130*/         uint256 lpAmount,
/*LN-131*/         uint256[2] memory min_amounts
/*LN-132*/     ) external {
/*LN-133*/         require(lpBalances[msg.sender] >= lpAmount, "Insufficient LP");
/*LN-134*/ 
/*LN-135*/         // Calculate amounts to return
/*LN-136*/         uint256 amount0 = (lpAmount * balances[0]) / totalLPSupply;
/*LN-137*/         uint256 amount1 = (lpAmount * balances[1]) / totalLPSupply;
/*LN-138*/ 
/*LN-139*/         require(
/*LN-140*/             amount0 >= min_amounts[0] && amount1 >= min_amounts[1],
/*LN-141*/             "Slippage"
/*LN-142*/         );
/*LN-143*/ 
/*LN-144*/         // Burn LP tokens
/*LN-145*/         lpBalances[msg.sender] -= lpAmount;
/*LN-146*/         totalLPSupply -= lpAmount;
/*LN-147*/ 
/*LN-148*/         // Update balances
/*LN-149*/         balances[0] -= amount0;
/*LN-150*/         balances[1] -= amount1;
/*LN-151*/ 
/*LN-152*/         // Transfer tokens
/*LN-153*/         if (amount0 > 0) {
/*LN-154*/             payable(msg.sender).transfer(amount0);
/*LN-155*/         }
/*LN-156*/ 
/*LN-157*/         uint256[2] memory amounts = [amount0, amount1];
/*LN-158*/         emit LiquidityRemoved(msg.sender, lpAmount, amounts);
/*LN-159*/     }
/*LN-160*/ 
/*LN-161*/     /**
/*LN-162*/      * @notice Internal function that handles ETH operations
/*LN-163*/      * @dev This is where the reentrancy vulnerability is exploited
/*LN-164*/      */
/*LN-165*/     function _handleETHTransfer(uint256 amount) internal {
/*LN-166*/         // In the real Curve Vyper code, operations here triggered reentrancy
/*LN-167*/         // The Vyper @nonreentrant decorator failed to prevent it
/*LN-168*/ 
/*LN-169*/         // Simulate operations that trigger external call
/*LN-170*/         // In reality, this involved complex pool rebalancing
/*LN-171*/         (bool success, ) = msg.sender.call{value: 0}("");
/*LN-172*/         require(success, "Transfer failed");
/*LN-173*/     }
/*LN-174*/ 
/*LN-175*/     /**
/*LN-176*/      * @notice Exchange tokens (simplified)
/*LN-177*/      * @param i Index of input token
/*LN-178*/      * @param j Index of output token
/*LN-179*/      * @param dx Input amount
/*LN-180*/      * @param min_dy Minimum output amount
/*LN-181*/      */
/*LN-182*/     function exchange(
/*LN-183*/         int128 i,
/*LN-184*/         int128 j,
/*LN-185*/         uint256 dx,
/*LN-186*/         uint256 min_dy
/*LN-187*/     ) external payable returns (uint256) {
/*LN-188*/         uint256 ui = uint256(int256(i));
/*LN-189*/         uint256 uj = uint256(int256(j));
/*LN-190*/ 
/*LN-191*/         require(ui < 2 && uj < 2 && ui != uj, "Invalid indices");
/*LN-192*/ 
/*LN-193*/         // Simplified exchange logic
/*LN-194*/         uint256 dy = (dx * balances[uj]) / (balances[ui] + dx);
/*LN-195*/         require(dy >= min_dy, "Slippage");
/*LN-196*/ 
/*LN-197*/         if (ui == 0) {
/*LN-198*/             require(msg.value == dx, "ETH mismatch");
/*LN-199*/             balances[0] += dx;
/*LN-200*/         }
/*LN-201*/ 
/*LN-202*/         balances[ui] += dx;
/*LN-203*/         balances[uj] -= dy;
/*LN-204*/ 
/*LN-205*/         if (uj == 0) {
/*LN-206*/             payable(msg.sender).transfer(dy);
/*LN-207*/         }
/*LN-208*/ 
/*LN-209*/         return dy;
/*LN-210*/     }
/*LN-211*/ 
/*LN-212*/     receive() external payable {
/*LN-213*/         // Attacker's contract would implement receive() to call add_liquidity() again
/*LN-214*/         // This creates the reentrancy vulnerability
/*LN-215*/     }
/*LN-216*/ }
/*LN-217*/ 
/*LN-218*/ /**
/*LN-219*/  * REAL-WORLD IMPACT:
/*LN-220*/  * - ~$70M stolen across multiple Curve pools on July 30, 2023
/*LN-221*/  * - Affected pools: pETH/ETH, msETH/ETH, alETH/ETH, CRV/ETH
/*LN-222*/  * - Vyper versions 0.2.15, 0.2.16, 0.3.0 were vulnerable
/*LN-223*/  * - Compiler bug, not a logic error in the contracts themselves
/*LN-224*/  * - Multiple attackers exploited it within hours
/*LN-225*/  *
/*LN-226*/  * VYPER COMPILER BUG DETAILS:
/*LN-227*/  * The @nonreentrant decorator in Vyper uses a storage variable to track
/*LN-228*/  * reentrancy state. The bug occurred when:
/*LN-229*/  * 1. Multiple functions had @nonreentrant decorator
/*LN-230*/  * 2. The compiler generated incorrect bytecode for the guard
/*LN-231*/  * 3. The guard checked a different storage slot than it should
/*LN-232*/  * 4. This allowed reentrancy despite the decorator being present
/*LN-233*/  *
/*LN-234*/  * FIX:
/*LN-235*/  * 1. Upgrade to patched Vyper versions (0.3.1+, 0.2.17+)
/*LN-236*/  * 2. Recompile all contracts with fixed compiler
/*LN-237*/  * 3. Redeploy affected pools
/*LN-238*/  * 4. Add additional reentrancy guards at contract level
/*LN-239*/  * 5. Follow Checks-Effects-Interactions pattern strictly
/*LN-240*/  * 6. Minimize external calls in critical functions
/*LN-241*/  *
/*LN-242*/  * KEY LESSON:
/*LN-243*/  * Compiler bugs can introduce vulnerabilities even in well-written code.
/*LN-244*/  * The Curve contracts followed best practices and used @nonreentrant,
/*LN-245*/  * but a compiler bug made the protection ineffective.
/*LN-246*/  *
/*LN-247*/  * This highlights the importance of:
/*LN-248*/  * - Compiler audits and verification
/*LN-249*/  * - Multiple layers of defense (not relying solely on language features)
/*LN-250*/  * - Careful testing with different compiler versions
/*LN-251*/  * - Following CEI pattern even when using reentrancy guards
/*LN-252*/  *
/*LN-253*/  *
/*LN-254*/  * ATTACK FLOW:
/*LN-255*/  * 1. Flash loan 80,000 ETH
/*LN-256*/  * 2. Call add_liquidity() with 40,000 ETH
/*LN-257*/  * 3. In receive(), detect reentrancy opportunity
/*LN-258*/  * 4. Call add_liquidity() AGAIN with another 40,000 ETH (bypassing guard)
/*LN-259*/  * 5. Pool mints LP tokens twice for overlapping deposits
/*LN-260*/  * 6. Call remove_liquidity() with inflated LP balance
/*LN-261*/  * 7. Extract more ETH/pETH than deposited
/*LN-262*/  * 8. Swap pETH to ETH
/*LN-263*/  * 9. Repay flash loan with profit
/*LN-264*/  */
/*LN-265*/ 