/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * ANYSWAP EXPLOIT (January 2022)
/*LN-6*/  * Attack: Permit Signature Bypass
/*LN-7*/  * Loss: $8 million
/*LN-8*/  * 
/*LN-9*/  * Anyswap's anySwapOutUnderlyingWithPermit() function had incomplete
/*LN-10*/  * validation of permit signatures, allowing arbitrary token transfers.
/*LN-11*/  */
/*LN-12*/ 
/*LN-13*/ interface IERC20Permit {
/*LN-14*/     function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
/*LN-15*/ }
/*LN-16*/ 
/*LN-17*/ contract AnyswapRouter {
/*LN-18*/     
/*LN-19*/     function anySwapOutUnderlyingWithPermit(
/*LN-20*/         address from,
/*LN-21*/         address token,
/*LN-22*/         address to,
/*LN-23*/         uint256 amount,
/*LN-24*/         uint256 deadline,
/*LN-25*/         uint8 v,
/*LN-26*/         bytes32 r,
/*LN-27*/         bytes32 s,
/*LN-28*/         uint256 toChainID
/*LN-29*/     ) external {
/*LN-30*/         
/*LN-31*/         // VULNERABLE: Permit validation incomplete or missing
/*LN-32*/         // Should validate signature matches 'from' address
/*LN-33*/         // Attacker can pass invalid v,r,s and still succeed
/*LN-34*/         
/*LN-35*/         if (v != 0 || r != bytes32(0) || s != bytes32(0)) {
/*LN-36*/             // Attempt permit but don't check if it succeeds
/*LN-37*/             try IERC20Permit(token).permit(from, address(this), amount, deadline, v, r, s) {} catch {}
/*LN-38*/         }
/*LN-39*/         
/*LN-40*/         // VULNERABILITY: Proceeds even if permit failed!
/*LN-41*/         // Transfers token without proper authorization
/*LN-42*/         _anySwapOut(from, token, to, amount, toChainID);
/*LN-43*/     }
/*LN-44*/     
/*LN-45*/     function _anySwapOut(address from, address token, address to, uint256 amount, uint256 toChainID) internal {
/*LN-46*/         // Bridge logic - burns or locks tokens
/*LN-47*/         // Since permit wasn't validated, attacker can drain tokens
/*LN-48*/     }
/*LN-49*/ }
/*LN-50*/ 
/*LN-51*/ /**
/*LN-52*/  * EXPLOIT:
/*LN-53*/  * 1. Call anySwapOutUnderlyingWithPermit with victim's token address
/*LN-54*/  * 2. Pass invalid v,r,s signature (e.g., all zeros)  
/*LN-55*/  * 3. Permit fails but function continues
/*LN-56*/  * 4. Tokens transferred/bridged anyway
/*LN-57*/  * 5. Repeat to drain $8M
/*LN-58*/  * 
/*LN-59*/  * Fix: Require valid permit or existing approval, don't proceed on failure
/*LN-60*/  */
/*LN-61*/ 