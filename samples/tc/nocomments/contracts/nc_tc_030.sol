/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-5*/ 
/*LN-6*/     function transferFrom(
/*LN-7*/         address from,
/*LN-8*/         address to,
/*LN-9*/         uint256 amount
/*LN-10*/     ) external returns (bool);
/*LN-11*/ 
/*LN-12*/     function balanceOf(address account) external view returns (uint256);
/*LN-13*/ 
/*LN-14*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-15*/ }
/*LN-16*/ 
/*LN-17*/ contract BridgeGateway {
/*LN-18*/     mapping(uint32 => address) public routes;
/*LN-19*/     mapping(address => bool) public approvedRoutes;
/*LN-20*/ 
/*LN-21*/     event RouteExecuted(uint32 routeId, address user, bytes result);
/*LN-22*/ 
/*LN-23*/ 
/*LN-24*/     function executeRoute(
/*LN-25*/         uint32 routeId,
/*LN-26*/         bytes calldata routeData
/*LN-27*/     ) external payable returns (bytes memory) {
/*LN-28*/         address routeAddress = routes[routeId];
/*LN-29*/         require(routeAddress != address(0), "Invalid route");
/*LN-30*/         require(approvedRoutes[routeAddress], "Route not approved");
/*LN-31*/ 
/*LN-32*/         (bool success, bytes memory result) = routeAddress.call(routeData);
/*LN-33*/         require(success, "Route execution failed");
/*LN-34*/ 
/*LN-35*/         emit RouteExecuted(routeId, msg.sender, result);
/*LN-36*/         return result;
/*LN-37*/     }
/*LN-38*/ 
/*LN-39*/ 
/*LN-40*/     function addRoute(uint32 routeId, address routeAddress) external {
/*LN-41*/         routes[routeId] = routeAddress;
/*LN-42*/         approvedRoutes[routeAddress] = true;
/*LN-43*/     }
/*LN-44*/ }
/*LN-45*/ 
/*LN-46*/ contract Route {
/*LN-47*/ 
/*LN-48*/     function performAction(
/*LN-49*/         address fromToken,
/*LN-50*/         address toToken,
/*LN-51*/         uint256 amount,
/*LN-52*/         address receiverAddress,
/*LN-53*/         bytes32 metadata,
/*LN-54*/         bytes calldata swapExtraData
/*LN-55*/     ) external payable returns (uint256) {
/*LN-56*/ 
/*LN-57*/         if (swapExtraData.length > 0) {
/*LN-58*/ 
/*LN-59*/             (bool success, ) = fromToken.call(swapExtraData);
/*LN-60*/             require(success, "Swap failed");
/*LN-61*/         }
/*LN-62*/ 
/*LN-63*/ 
/*LN-64*/         return amount;
/*LN-65*/     }
/*LN-66*/ }