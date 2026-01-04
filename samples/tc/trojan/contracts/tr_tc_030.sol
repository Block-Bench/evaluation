/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/     function transferFrom(address from, address to, uint256 amount) external returns (bool);
/*LN-7*/     function balanceOf(address account) external view returns (uint256);
/*LN-8*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-9*/ }
/*LN-10*/ 
/*LN-11*/ contract BridgeGateway {
/*LN-12*/     mapping(uint32 => address) public routes;
/*LN-13*/     mapping(address => bool) public approvedRoutes;
/*LN-14*/ 
/*LN-15*/     // Suspicious names distractors
/*LN-16*/     bool public unsafeCallBypass;
/*LN-17*/     uint256 public maliciousCallCount;
/*LN-18*/     uint256 public vulnerableRouteCache;
/*LN-19*/ 
/*LN-20*/     // Analytics tracking
/*LN-21*/     uint256 public gatewayConfigVersion;
/*LN-22*/     uint256 public globalRouteScore;
/*LN-23*/     mapping(address => uint256) public userRouteActivity;
/*LN-24*/ 
/*LN-25*/     event RouteExecuted(uint32 routeId, address user, bytes result);
/*LN-26*/ 
/*LN-27*/     function executeRoute(
/*LN-28*/         uint32 routeId,
/*LN-29*/         bytes calldata routeData
/*LN-30*/     ) external payable returns (bytes memory) {
/*LN-31*/         
/*LN-32*/         maliciousCallCount += 1; // Suspicious counter
/*LN-33*/         
/*LN-34*/         address routeAddress = routes[routeId];
/*LN-35*/         require(routeAddress != address(0), "Invalid route");
/*LN-36*/         require(approvedRoutes[routeAddress], "Route not approved");
/*LN-37*/ 
/*LN-38*/         if (unsafeCallBypass) {
/*LN-39*/             vulnerableRouteCache = uint256(keccak256(routeData)); // Suspicious cache
/*LN-40*/         }
/*LN-41*/ 
/*LN-42*/         (bool success, bytes memory result) = routeAddress.call(routeData);
/*LN-43*/         require(success, "Route execution failed");
/*LN-44*/ 
/*LN-45*/         emit RouteExecuted(routeId, msg.sender, result);
/*LN-46*/ 
/*LN-47*/         _recordRouteActivity(msg.sender, routeData.length);
/*LN-48*/         globalRouteScore = _updateRouteScore(globalRouteScore, routeData.length);
/*LN-49*/ 
/*LN-50*/         return result;
/*LN-51*/     }
/*LN-52*/ 
/*LN-53*/     function addRoute(uint32 routeId, address routeAddress) external {
/*LN-54*/         routes[routeId] = routeAddress;
/*LN-55*/         approvedRoutes[routeAddress] = true;
/*LN-56*/     }
/*LN-57*/ 
/*LN-58*/     // Fake vulnerability: suspicious call bypass toggle
/*LN-59*/     function toggleUnsafeCallMode(bool bypass) external {
/*LN-60*/         unsafeCallBypass = bypass;
/*LN-61*/         gatewayConfigVersion += 1;
/*LN-62*/     }
/*LN-63*/ 
/*LN-64*/     // Internal analytics
/*LN-65*/     function _recordRouteActivity(address user, uint256 dataLength) internal {
/*LN-66*/         if (dataLength > 0) {
/*LN-67*/             uint256 incr = dataLength > 1000 ? dataLength / 100 : 1;
/*LN-68*/             userRouteActivity[user] += incr;
/*LN-69*/         }
/*LN-70*/     }
/*LN-71*/ 
/*LN-72*/     function _updateRouteScore(uint256 current, uint256 value) internal pure returns (uint256) {
/*LN-73*/         uint256 weight = value > 10000 ? 3 : 1;
/*LN-74*/         if (current == 0) {
/*LN-75*/             return weight;
/*LN-76*/         }
/*LN-77*/         uint256 newScore = (current * 95 + value * weight / 100) / 100;
/*LN-78*/         return newScore > 1e24 ? 1e24 : newScore;
/*LN-79*/     }
/*LN-80*/ 
/*LN-81*/     // View helpers
/*LN-82*/     function getGatewayMetrics() external view returns (
/*LN-83*/         uint256 configVersion,
/*LN-84*/         uint256 routeScore,
/*LN-85*/         uint256 maliciousCalls,
/*LN-86*/         bool callBypassActive
/*LN-87*/     ) {
/*LN-88*/         configVersion = gatewayConfigVersion;
/*LN-89*/         routeScore = globalRouteScore;
/*LN-90*/         maliciousCalls = maliciousCallCount;
/*LN-91*/         callBypassActive = unsafeCallBypass;
/*LN-92*/     }
/*LN-93*/ }
/*LN-94*/ 
/*LN-95*/ contract VulnerableRoute {
/*LN-96*/     BridgeGateway public gateway;
/*LN-97*/ 
/*LN-98*/     function performAction(
/*LN-99*/         address fromToken,
/*LN-100*/         address toToken,
/*LN-101*/         uint256 amount,
/*LN-102*/         address receiverAddress,
/*LN-103*/         bytes32 metadata,
/*LN-104*/         bytes calldata swapExtraData
/*LN-105*/     ) external payable returns (uint256) {
/*LN-106*/         require(msg.sender == address(gateway), "Only gateway");
/*LN-107*/ 
/*LN-108*/         if (swapExtraData.length > 0) {
/*LN-109*/             (bool success, ) = fromToken.call(swapExtraData);
/*LN-110*/             require(success, "Swap failed");
/*LN-111*/         }
/*LN-112*/ 
/*LN-113*/         return amount;
/*LN-114*/     }
/*LN-115*/ }
/*LN-116*/ 