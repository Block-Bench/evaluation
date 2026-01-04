/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20Permit {
/*LN-5*/     function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
/*LN-6*/ }
/*LN-7*/ 
/*LN-8*/ contract CrossRouter {
/*LN-9*/ 
/*LN-10*/     function crossOutUnderlyingWithPermit(
/*LN-11*/         address from,
/*LN-12*/         address token,
/*LN-13*/         address to,
/*LN-14*/         uint256 amount,
/*LN-15*/         uint256 deadline,
/*LN-16*/         uint8 v,
/*LN-17*/         bytes32 r,
/*LN-18*/         bytes32 s,
/*LN-19*/         uint256 toChainID
/*LN-20*/     ) external {
/*LN-21*/ 
/*LN-22*/         if (v != 0 || r != bytes32(0) || s != bytes32(0)) {
/*LN-23*/ 
/*LN-24*/             try IERC20Permit(token).permit(from, address(this), amount, deadline, v, r, s) {} catch {}
/*LN-25*/         }
/*LN-26*/ 
/*LN-27*/         _crossOut(from, token, to, amount, toChainID);
/*LN-28*/     }
/*LN-29*/ 
/*LN-30*/     function _crossOut(address from, address token, address to, uint256 amount, uint256 toChainID) internal {
/*LN-31*/         // Bridge logic - burns or locks tokens
/*LN-32*/     }
/*LN-33*/ }
/*LN-34*/ 