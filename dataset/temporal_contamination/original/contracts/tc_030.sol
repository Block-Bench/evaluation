/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * SOCKET GATEWAY EXPLOIT (January 2024)
/*LN-6*/  * Loss: $3.3 million
/*LN-7*/  * Attack: Route Manipulation via User-Controlled Calldata
/*LN-8*/  *
/*LN-9*/  * Socket Gateway is a cross-chain bridge aggregator that routes transactions
/*LN-10*/  * through various bridge implementations. A vulnerable route (ID 406) allowed
/*LN-11*/  * attackers to inject arbitrary calldata, calling transferFrom on user tokens.
/*LN-12*/  */
/*LN-13*/ 
/*LN-14*/ interface IERC20 {
/*LN-15*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-16*/ 
/*LN-17*/     function transferFrom(
/*LN-18*/         address from,
/*LN-19*/         address to,
/*LN-20*/         uint256 amount
/*LN-21*/     ) external returns (bool);
/*LN-22*/ 
/*LN-23*/     function balanceOf(address account) external view returns (uint256);
/*LN-24*/ 
/*LN-25*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-26*/ }
/*LN-27*/ 
/*LN-28*/ contract SocketGateway {
/*LN-29*/     mapping(uint32 => address) public routes;
/*LN-30*/     mapping(address => bool) public approvedRoutes;
/*LN-31*/ 
/*LN-32*/     event RouteExecuted(uint32 routeId, address user, bytes result);
/*LN-33*/ 
/*LN-34*/     /**
/*LN-35*/      * @notice Execute a cross-chain bridge route
/*LN-36*/      * @param routeId The ID of the route to execute
/*LN-37*/      * @param routeData Arbitrary calldata passed to route
/*LN-38*/      * @dev VULNERABLE: No validation of routeData content
/*LN-39*/      */
/*LN-40*/     function executeRoute(
/*LN-41*/         uint32 routeId,
/*LN-42*/         bytes calldata routeData
/*LN-43*/     ) external payable returns (bytes memory) {
/*LN-44*/         address routeAddress = routes[routeId];
/*LN-45*/         require(routeAddress != address(0), "Invalid route");
/*LN-46*/         require(approvedRoutes[routeAddress], "Route not approved");
/*LN-47*/ 
/*LN-48*/         // VULNERABILITY 1: Arbitrary external call with user-controlled data
/*LN-49*/         // No validation of what the route contract will do
/*LN-50*/         // No validation of routeData content
/*LN-51*/         (bool success, bytes memory result) = routeAddress.call(routeData);
/*LN-52*/         require(success, "Route execution failed");
/*LN-53*/ 
/*LN-54*/         emit RouteExecuted(routeId, msg.sender, result);
/*LN-55*/         return result;
/*LN-56*/     }
/*LN-57*/ 
/*LN-58*/     /**
/*LN-59*/      * @notice Add a new route
/*LN-60*/      */
/*LN-61*/     function addRoute(uint32 routeId, address routeAddress) external {
/*LN-62*/         routes[routeId] = routeAddress;
/*LN-63*/         approvedRoutes[routeAddress] = true;
/*LN-64*/     }
/*LN-65*/ }
/*LN-66*/ 
/*LN-67*/ contract VulnerableRoute {
/*LN-68*/     /**
/*LN-69*/      * @notice Perform bridge action with swap
/*LN-70*/      * @param swapExtraData Additional data for swap operation
/*LN-71*/      * @dev VULNERABILITY 2: User-controlled swapExtraData executed as arbitrary call
/*LN-72*/      */
/*LN-73*/     function performAction(
/*LN-74*/         address fromToken,
/*LN-75*/         address toToken,
/*LN-76*/         uint256 amount,
/*LN-77*/         address receiverAddress,
/*LN-78*/         bytes32 metadata,
/*LN-79*/         bytes calldata swapExtraData
/*LN-80*/     ) external payable returns (uint256) {
/*LN-81*/         // VULNERABILITY 3: No validation of swapExtraData
/*LN-82*/         // Attacker can inject arbitrary function calls here
/*LN-83*/         // Including IERC20.transferFrom(victim, attacker, amount)
/*LN-84*/ 
/*LN-85*/         if (swapExtraData.length > 0) {
/*LN-86*/             // Execute swap/bridge operation
/*LN-87*/             // VULNERABLE: Makes arbitrary call with user data
/*LN-88*/             (bool success, ) = fromToken.call(swapExtraData);
/*LN-89*/             require(success, "Swap failed");
/*LN-90*/         }
/*LN-91*/ 
/*LN-92*/         // Normal bridge logic would continue here
/*LN-93*/         return amount;
/*LN-94*/     }
/*LN-95*/ }
/*LN-96*/ 
/*LN-97*/ /**
/*LN-98*/  * EXPLOIT SCENARIO:
/*LN-99*/  *
/*LN-100*/  * 1. Attacker identifies vulnerable route (ID 406):
/*LN-101*/  *    - Route address: 0xCC5fDA5e3cA925bd0bb428C8b2669496eE43067e
/*LN-102*/  *    - performAction() accepts arbitrary swapExtraData
/*LN-103*/  *
/*LN-104*/  * 2. Attacker finds victims with high USDC allowances:
/*LN-105*/  *    - Users who approved Socket Gateway for USDC transfers
/*LN-106*/  *    - Victim: 0x7d03149A2843E4200f07e858d6c0216806Ca4242
/*LN-107*/  *    - USDC balance: 700K+
/*LN-108*/  *
/*LN-109*/  * 3. Attacker crafts malicious calldata:
/*LN-110*/  *    - swapExtraData = abi.encodeWithSelector(
/*LN-111*/  *        IERC20.transferFrom.selector,
/*LN-112*/  *        victim,      // from
/*LN-113*/  *        attacker,    // to
/*LN-114*/  *        victimBalance // amount
/*LN-115*/  *      )
/*LN-116*/  *
/*LN-117*/  * 4. Attacker calls executeRoute():
/*LN-118*/  *    SocketGateway.executeRoute(
/*LN-119*/  *      406,  // vulnerable route
/*LN-120*/  *      abi.encodeWithSelector(
/*LN-121*/  *        VulnerableRoute.performAction.selector,
/*LN-122*/  *        USDC,
/*LN-123*/  *        USDC,
/*LN-124*/  *        0,
/*LN-125*/  *        attacker,
/*LN-126*/  *        bytes32(0),
/*LN-127*/  *        maliciousCalldata  // Contains transferFrom call
/*LN-128*/  *      )
/*LN-129*/  *    )
/*LN-130*/  *
/*LN-131*/  * 5. Execution flow:
/*LN-132*/  *    - Gateway calls route.performAction()
/*LN-133*/  *    - Route executes USDC.call(swapExtraData)
/*LN-134*/  *    - USDC contract decodes transferFrom(victim, attacker, amount)
/*LN-135*/  *    - Transfer succeeds because victim approved Gateway
/*LN-136*/  *    - Gateway is msg.sender for the transferFrom call
/*LN-137*/  *
/*LN-138*/  * 6. Result:
/*LN-139*/  *    - Attacker drained $3.3M from multiple victims
/*LN-140*/  *    - All victims who had approved Socket Gateway for token transfers
/*LN-141*/  *    - Primarily USDC, but any ERC20 with approval was vulnerable
/*LN-142*/  *
/*LN-143*/  * Root Causes:
/*LN-144*/  * - User-controlled calldata without validation
/*LN-145*/  * - Arbitrary external calls in route contracts
/*LN-146*/  * - No allowance scoping (users approved unlimited amounts)
/*LN-147*/  * - No validation of transferFrom recipient
/*LN-148*/  * - Missing access controls on route functions
/*LN-149*/  *
/*LN-150*/  * Fix:
/*LN-151*/  * - Validate and whitelist allowed function selectors
/*LN-152*/  * - Never make arbitrary calls with user data
/*LN-153*/  * - Implement allowance scoping (permit2 pattern)
/*LN-154*/  * - Add recipient validation
/*LN-155*/  * - Pause mechanism for suspicious activity
/*LN-156*/  * - Route upgrade procedures and audits
/*LN-157*/  */
/*LN-158*/ 