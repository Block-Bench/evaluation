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
/*LN-18*/ interface IUniswapV3Router {
/*LN-19*/     struct ExactInputSingleParams {
/*LN-20*/         address tokenIn;
/*LN-21*/         address tokenOut;
/*LN-22*/         uint24 fee;
/*LN-23*/         address recipient;
/*LN-24*/         uint256 deadline;
/*LN-25*/         uint256 amountIn;
/*LN-26*/         uint256 amountOutMinimum;
/*LN-27*/         uint160 sqrtPriceLimitX96;
/*LN-28*/     }
/*LN-29*/ 
/*LN-30*/     function exactInputSingle(
/*LN-31*/         ExactInputSingleParams calldata params
/*LN-32*/     ) external payable returns (uint256 amountOut);
/*LN-33*/ }
/*LN-34*/ 
/*LN-35*/ contract StakingVault {
/*LN-36*/     IERC20 public immutable uniBTC;
/*LN-37*/     IERC20 public immutable WBTC;
/*LN-38*/     IUniswapV3Router public immutable router;
/*LN-39*/ 
/*LN-40*/     uint256 public totalETHDeposited;
/*LN-41*/     uint256 public totalUniBTCMinted;
/*LN-42*/ 
/*LN-43*/     constructor(address _uniBTC, address _wbtc, address _router) {
/*LN-44*/         uniBTC = IERC20(_uniBTC);
/*LN-45*/         WBTC = IERC20(_wbtc);
/*LN-46*/         router = IUniswapV3Router(_router);
/*LN-47*/     }
/*LN-48*/ 
/*LN-49*/     function mint() external payable {
/*LN-50*/         require(msg.value > 0, "No ETH sent");
/*LN-51*/ 
/*LN-52*/         uint256 uniBTCAmount = msg.value;
/*LN-53*/ 
/*LN-54*/         totalETHDeposited += msg.value;
/*LN-55*/         totalUniBTCMinted += uniBTCAmount;
/*LN-56*/ 
/*LN-57*/         // Transfer uniBTC to user
/*LN-58*/         uniBTC.transfer(msg.sender, uniBTCAmount);
/*LN-59*/     }
/*LN-60*/ 
/*LN-61*/     /**
/*LN-62*/      * @notice Redeem ETH by burning uniBTC
/*LN-63*/      */
/*LN-64*/     function redeem(uint256 amount) external {
/*LN-65*/         require(amount > 0, "No amount specified");
/*LN-66*/         require(uniBTC.balanceOf(msg.sender) >= amount, "Insufficient balance");
/*LN-67*/ 
/*LN-68*/         uniBTC.transferFrom(msg.sender, address(this), amount);
/*LN-69*/ 
/*LN-70*/         uint256 ethAmount = amount;
/*LN-71*/         require(address(this).balance >= ethAmount, "Insufficient ETH");
/*LN-72*/ 
/*LN-73*/         payable(msg.sender).transfer(ethAmount);
/*LN-74*/     }
/*LN-75*/ 
/*LN-76*/     /**
/*LN-77*/      * @notice Get current exchange rate
/*LN-78*/      * @dev Should return ETH per uniBTC, but returns 1:1
/*LN-79*/      */
/*LN-80*/     function getExchangeRate() external pure returns (uint256) {
/*LN-81*/ 
/*LN-82*/         return 1e18;
/*LN-83*/     }
/*LN-84*/ 
/*LN-85*/     receive() external payable {}
/*LN-86*/ }
/*LN-87*/ 