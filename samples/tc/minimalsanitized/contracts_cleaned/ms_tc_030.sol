// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

contract SocketGateway {
    mapping(uint32 => address) public routes;
    mapping(address => bool) public approvedRoutes;

    event RouteExecuted(uint32 routeId, address user, bytes result);

    /**
     * @notice Execute a cross-chain bridge route
     * @param routeId The ID of the route to execute
     * @param routeData Arbitrary calldata passed to route
     */
    function executeRoute(
        uint32 routeId,
        bytes calldata routeData
    ) external payable returns (bytes memory) {
        address routeAddress = routes[routeId];
        require(routeAddress != address(0), "Invalid route");
        require(approvedRoutes[routeAddress], "Route not approved");

        
        
        (bool success, bytes memory result) = routeAddress.call(routeData);
        require(success, "Route execution failed");

        emit RouteExecuted(routeId, msg.sender, result);
        return result;
    }

    /**
     * @notice Add a new route
     */
    function addRoute(uint32 routeId, address routeAddress) external {
        routes[routeId] = routeAddress;
        approvedRoutes[routeAddress] = true;
    }
}

contract Route {
    /**
     * @notice Perform bridge action with swap
     * @param swapExtraData Additional data for swap operation
     */
    function performAction(
        address fromToken,
        address toToken,
        uint256 amount,
        address receiverAddress,
        bytes32 metadata,
        bytes calldata swapExtraData
    ) external payable returns (uint256) {

        if (swapExtraData.length > 0) {
            // Execute swap/bridge operation
            (bool success, ) = fromToken.call(swapExtraData);
            require(success, "Swap failed");
        }

        // Normal bridge logic would continue here
        return amount;
    }
}
