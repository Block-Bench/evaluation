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
/*LN-26*/ contract CowSolver {
/*LN-27*/     IWETH public immutable WETH;
/*LN-28*/     address public immutable settlement;
/*LN-29*/     mapping(address => bool) public validPools;
/*LN-30*/     address public owner;
/*LN-31*/ 
/*LN-32*/     constructor(address _weth, address _settlement) {
/*LN-33*/         WETH = IWETH(_weth);
/*LN-34*/         settlement = _settlement;
/*LN-35*/         owner = msg.sender;
/*LN-36*/     }
/*LN-37*/ 
/*LN-38*/     function addValidPool(address pool) external {
/*LN-39*/         require(msg.sender == owner, "Not owner");
/*LN-40*/         validPools[pool] = true;
/*LN-41*/     }
/*LN-42*/ 
/*LN-43*/     function uniswapV3SwapCallback(
/*LN-44*/         int256 amount0Delta,
/*LN-45*/         int256 amount1Delta,
/*LN-46*/         bytes calldata data
/*LN-47*/     ) external payable {
/*LN-48*/         require(validPools[msg.sender], "Invalid pool");
/*LN-49*/ 
/*LN-50*/         (
/*LN-51*/             uint256 price,
/*LN-52*/             address solver,
/*LN-53*/             address tokenIn,
/*LN-54*/             address recipient
/*LN-55*/         ) = abi.decode(data, (uint256, address, address, address));
/*LN-56*/ 
/*LN-57*/         uint256 amountToPay;
/*LN-58*/         if (amount0Delta > 0) {
/*LN-59*/             amountToPay = uint256(amount0Delta);
/*LN-60*/         } else {
/*LN-61*/             amountToPay = uint256(amount1Delta);
/*LN-62*/         }
/*LN-63*/ 
/*LN-64*/         if (tokenIn == address(WETH)) {
/*LN-65*/             WETH.withdraw(amountToPay);
/*LN-66*/             payable(recipient).transfer(amountToPay);
/*LN-67*/         } else {
/*LN-68*/             IERC20(tokenIn).transfer(recipient, amountToPay);
/*LN-69*/         }
/*LN-70*/     }
/*LN-71*/ 
/*LN-72*/     function executeSettlement(bytes calldata settlementData) external {
/*LN-73*/         require(msg.sender == settlement, "Only settlement");
/*LN-74*/     }
/*LN-75*/ 
/*LN-76*/     receive() external payable {}
/*LN-77*/ }
/*LN-78*/ 