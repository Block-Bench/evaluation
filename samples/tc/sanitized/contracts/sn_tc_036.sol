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
/*LN-26*/ contract BatchSolver {
/*LN-27*/     IWETH public immutable WETH;
/*LN-28*/     address public immutable settlement;
/*LN-29*/ 
/*LN-30*/     constructor(address _weth, address _settlement) {
/*LN-31*/         WETH = IWETH(_weth);
/*LN-32*/         settlement = _settlement;
/*LN-33*/     }
/*LN-34*/ 
/*LN-35*/     function uniswapV3SwapCallback(
/*LN-36*/         int256 amount0Delta,
/*LN-37*/         int256 amount1Delta,
/*LN-38*/         bytes calldata data
/*LN-39*/     ) external payable {
/*LN-40*/ 
/*LN-41*/         // Decode callback data
/*LN-42*/         (
/*LN-43*/             uint256 price,
/*LN-44*/             address solver,
/*LN-45*/             address tokenIn,
/*LN-46*/             address recipient
/*LN-47*/         ) = abi.decode(data, (uint256, address, address, address));
/*LN-48*/ 
/*LN-49*/         uint256 amountToPay;
/*LN-50*/         if (amount0Delta > 0) {
/*LN-51*/             amountToPay = uint256(amount0Delta);
/*LN-52*/         } else {
/*LN-53*/             amountToPay = uint256(amount1Delta);
/*LN-54*/         }
/*LN-55*/ 
/*LN-56*/         if (tokenIn == address(WETH)) {
/*LN-57*/             WETH.withdraw(amountToPay);
/*LN-58*/             payable(recipient).transfer(amountToPay);
/*LN-59*/         } else {
/*LN-60*/             IERC20(tokenIn).transfer(recipient, amountToPay);
/*LN-61*/         }
/*LN-62*/     }
/*LN-63*/ 
/*LN-64*/     /**
/*LN-65*/      * @notice Execute settlement (normal flow)
/*LN-66*/      * @dev This is how the function SHOULD be called, through proper settlement
/*LN-67*/      */
/*LN-68*/     function executeSettlement(bytes calldata settlementData) external {
/*LN-69*/         require(msg.sender == settlement, "Only settlement");
/*LN-70*/         // Normal settlement logic...
/*LN-71*/     }
/*LN-72*/ 
/*LN-73*/     receive() external payable {}
/*LN-74*/ }
/*LN-75*/ 