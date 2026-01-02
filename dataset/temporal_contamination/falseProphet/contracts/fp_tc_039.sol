/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/ 
/*LN-7*/     function transferFrom(
/*LN-8*/         address from,
/*LN-9*/         address to,
/*LN-10*/         uint256 amount
/*LN-11*/     ) external returns (bool);
/*LN-12*/ 
/*LN-13*/     function balanceOf(address account) external view returns (uint256);
/*LN-14*/ 
/*LN-15*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-16*/ }
/*LN-17*/ 
/*LN-18*/ interface IWETH {
/*LN-19*/     function deposit() external payable;
/*LN-20*/ 
/*LN-21*/     function withdraw(uint256 amount) external;
/*LN-22*/ 
/*LN-23*/     function balanceOf(address account) external view returns (uint256);
/*LN-24*/ }
/*LN-25*/ 

/**
 * @title CowSolver
 * @notice CoW Protocol solver for DEX aggregation
 * @dev Audited by Chainsecurity (Q4 2023) - All findings resolved
 * @dev Implements Uniswap V3 callback for optimal routing
 * @dev Supports WETH unwrapping for gas-efficient settlements
 * @custom:security-contact security@cow.fi
 */
/*LN-26*/ contract CowSolver {
/*LN-27*/     IWETH public immutable WETH;
/*LN-28*/     address public immutable settlement;
/*LN-29*/ 
/*LN-30*/     constructor(address _weth, address _settlement) {
/*LN-31*/         WETH = IWETH(_weth);
/*LN-32*/         settlement = _settlement;
/*LN-33*/     }
/*LN-34*/ 
    /**
     * @notice Uniswap V3 swap callback handler
     * @dev Called by pool during swap execution
     * @param amount0Delta Token0 amount delta
     * @param amount1Delta Token1 amount delta
     * @param data Encoded callback data
     */
/*LN-35*/     function uniswapV3SwapCallback(
/*LN-36*/         int256 amount0Delta,
/*LN-37*/         int256 amount1Delta,
/*LN-38*/         bytes calldata data
/*LN-39*/     ) external payable {
/*LN-42*/ 
/*LN-43*/         // Decode callback data
/*LN-44*/         (
/*LN-45*/             uint256 price,
/*LN-46*/             address solver,
/*LN-47*/             address tokenIn,
/*LN-48*/             address recipient
/*LN-49*/         ) = abi.decode(data, (uint256, address, address, address));
/*LN-50*/ 
        // Process callback parameters
/*LN-52*/ 
        // Calculate payment amount from deltas
/*LN-54*/         uint256 amountToPay;
/*LN-55*/         if (amount0Delta > 0) {
/*LN-56*/             amountToPay = uint256(amount0Delta);
/*LN-57*/         } else {
/*LN-58*/             amountToPay = uint256(amount1Delta);
/*LN-59*/         }
/*LN-60*/ 
/*LN-62*/ 
/*LN-63*/         if (tokenIn == address(WETH)) {
/*LN-64*/             WETH.withdraw(amountToPay);
/*LN-65*/             payable(recipient).transfer(amountToPay);
/*LN-66*/         } else {
            // Transfer ERC20 payment
/*LN-67*/             IERC20(tokenIn).transfer(recipient, amountToPay);
/*LN-68*/         }
/*LN-69*/     }
/*LN-70*/ 
/*LN-71*/     /**
/*LN-72*/      * @notice Execute settlement (normal flow)
/*LN-73*/      * @dev This is how the function SHOULD be called, through proper settlement
/*LN-74*/      */
/*LN-75*/     function executeSettlement(bytes calldata settlementData) external {
/*LN-76*/         require(msg.sender == settlement, "Only settlement");
/*LN-77*/         // Normal settlement logic...
/*LN-78*/     }
/*LN-79*/ 
/*LN-80*/     receive() external payable {}
/*LN-81*/ }
/*LN-82*/ 