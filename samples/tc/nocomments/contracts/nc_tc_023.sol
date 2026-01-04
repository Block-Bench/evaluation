/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20Permit {
/*LN-4*/     function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
/*LN-5*/ }
/*LN-6*/ 
/*LN-7*/ contract CrossRouter {
/*LN-8*/ 
/*LN-9*/     function crossOutUnderlyingWithPermit(
/*LN-10*/         address from,
/*LN-11*/         address token,
/*LN-12*/         address to,
/*LN-13*/         uint256 amount,
/*LN-14*/         uint256 deadline,
/*LN-15*/         uint8 v,
/*LN-16*/         bytes32 r,
/*LN-17*/         bytes32 s,
/*LN-18*/         uint256 toChainID
/*LN-19*/     ) external {
/*LN-20*/ 
/*LN-21*/         if (v != 0 || r != bytes32(0) || s != bytes32(0)) {
/*LN-22*/ 
/*LN-23*/             try IERC20Permit(token).permit(from, address(this), amount, deadline, v, r, s) {} catch {}
/*LN-24*/         }
/*LN-25*/ 
/*LN-26*/         _crossOut(from, token, to, amount, toChainID);
/*LN-27*/     }
/*LN-28*/ 
/*LN-29*/     function _crossOut(address from, address token, address to, uint256 amount, uint256 toChainID) internal {
/*LN-30*/ 
/*LN-31*/     }
/*LN-32*/ }