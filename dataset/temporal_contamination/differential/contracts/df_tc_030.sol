/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/     function transferFrom(
/*LN-7*/         address from,
/*LN-8*/         address to,
/*LN-9*/         uint256 amount
/*LN-10*/     ) external returns (bool);
/*LN-11*/     function balanceOf(address account) external view returns (uint256);
/*LN-12*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-13*/ }
/*LN-14*/ 
/*LN-15*/ contract SocketGateway {
/*LN-16*/     mapping(uint32 => address) public routes;
/*LN-17*/     mapping(address => bool) public approvedRoutes;
/*LN-18*/ 
/*LN-19*/     event RouteExecuted(uint32 routeId, address user, bytes result);
/*LN-20*/ 
/*LN-21*/     function executeRoute(
/*LN-22*/         uint32 routeId,
/*LN-23*/         bytes calldata routeData
/*LN-24*/     ) external payable returns (bytes memory) {
/*LN-25*/         address routeAddress = routes[routeId];
/*LN-26*/         require(routeAddress != address(0), "Invalid route");
/*LN-27*/         require(approvedRoutes[routeAddress], "Route not approved");
/*LN-28*/ 
/*LN-29*/         (bool success, bytes memory result) = routeAddress.call(routeData);
/*LN-30*/         require(success, "Route execution failed");
/*LN-31*/ 
/*LN-32*/         emit RouteExecuted(routeId, msg.sender, result);
/*LN-33*/         return result;
/*LN-34*/     }
/*LN-35*/ 
/*LN-36*/     function addRoute(uint32 routeId, address routeAddress) external {
/*LN-37*/         routes[routeId] = routeAddress;
/*LN-38*/         approvedRoutes[routeAddress] = true;
/*LN-39*/     }
/*LN-40*/ }
/*LN-41*/ 
/*LN-42*/ contract VulnerableRoute {
/*LN-43*/     // Whitelist of allowed function selectors
/*LN-44*/     bytes4[] public allowedSelectors = [IERC20.transfer.selector, IERC20.approve.selector];
/*LN-45*/ 
/*LN-46*/     function performAction(
/*LN-47*/         address fromToken,
/*LN-48*/         address toToken,
/*LN-49*/         uint256 amount,
/*LN-50*/         address receiverAddress,
/*LN-51*/         bytes32 metadata,
/*LN-52*/         bytes calldata swapExtraData
/*LN-53*/     ) external payable returns (uint256) {
/*LN-54*/         if (swapExtraData.length > 0) {
/*LN-55*/             bytes4 selector = bytes4(swapExtraData);
/*LN-56*/             bool allowed = false;
/*LN-57*/             for (uint i = 0; i < allowedSelectors.length; i++) {
/*LN-58*/                 if (allowedSelectors[i] == selector) {
/*LN-59*/                     allowed = true;
/*LN-60*/                     break;
/*LN-61*/                 }
/*LN-62*/             }
/*LN-63*/             require(allowed, "Function selector not allowed");
/*LN-64*/             (bool success, ) = fromToken.call(swapExtraData);
/*LN-65*/             require(success, "Swap failed");
/*LN-66*/         }
/*LN-67*/ 
/*LN-68*/         return amount;
/*LN-69*/     }
/*LN-70*/ }
/*LN-71*/ 