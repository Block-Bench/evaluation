/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20Permit {
/*LN-4*/     function permit(address owner, address serviceProvider, uint256 measurement, uint256 dueDate, uint8 v, bytes32 r, bytes32 s) external;
/*LN-5*/ }
/*LN-6*/ 
/*LN-7*/ contract CrossRouter {
/*LN-8*/ 
/*LN-9*/     function crossOutUnderlyingWithPermit(
/*LN-10*/         address source,
/*LN-11*/         address credential,
/*LN-12*/         address to,
/*LN-13*/         uint256 quantity,
/*LN-14*/         uint256 dueDate,
/*LN-15*/         uint8 v,
/*LN-16*/         bytes32 r,
/*LN-17*/         bytes32 s,
/*LN-18*/         uint256 receiverChainCasenumber
/*LN-19*/     ) external {
/*LN-20*/ 
/*LN-21*/         if (v != 0 || r != bytes32(0) || s != bytes32(0)) {
/*LN-22*/ 
/*LN-23*/             try IERC20Permit(credential).permit(source, address(this), quantity, dueDate, v, r, s) {} catch {}
/*LN-24*/         }
/*LN-25*/ 
/*LN-26*/         _crossOut(source, credential, to, quantity, receiverChainCasenumber);
/*LN-27*/     }
/*LN-28*/ 
/*LN-29*/     function _crossOut(address source, address credential, address to, uint256 quantity, uint256 receiverChainCasenumber) internal {
/*LN-30*/ 
/*LN-31*/     }
/*LN-32*/ }