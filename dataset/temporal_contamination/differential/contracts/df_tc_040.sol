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
/*LN-35*/ interface IPriceOracle {
/*LN-36*/     function getETHtoBTCRate() external view returns (uint256);
/*LN-37*/ }
/*LN-38*/ 
/*LN-39*/ contract BedrockVault {
/*LN-40*/     IERC20 public immutable uniBTC;
/*LN-41*/     IERC20 public immutable WBTC;
/*LN-42*/     IUniswapV3Router public immutable router;
/*LN-43*/     IPriceOracle public priceOracle;
/*LN-44*/ 
/*LN-45*/     uint256 public totalETHDeposited;
/*LN-46*/     uint256 public totalUniBTCMinted;
/*LN-47*/ 
/*LN-48*/     constructor(address _uniBTC, address _wbtc, address _router, address _oracle) {
/*LN-49*/         uniBTC = IERC20(_uniBTC);
/*LN-50*/         WBTC = IERC20(_wbtc);
/*LN-51*/         router = IUniswapV3Router(_router);
/*LN-52*/         priceOracle = IPriceOracle(_oracle);
/*LN-53*/     }
/*LN-54*/ 
/*LN-55*/     function mint() external payable {
/*LN-56*/         require(msg.value > 0, "No ETH sent");
/*LN-57*/ 
/*LN-58*/         uint256 exchangeRate = getExchangeRate();
/*LN-59*/         uint256 uniBTCAmount = (msg.value * exchangeRate) / 1e18;
/*LN-60*/ 
/*LN-61*/         totalETHDeposited += msg.value;
/*LN-62*/         totalUniBTCMinted += uniBTCAmount;
/*LN-63*/ 
/*LN-64*/         uniBTC.transfer(msg.sender, uniBTCAmount);
/*LN-65*/     }
/*LN-66*/ 
/*LN-67*/     function redeem(uint256 amount) external {
/*LN-68*/         require(amount > 0, "No amount specified");
/*LN-69*/         require(uniBTC.balanceOf(msg.sender) >= amount, "Insufficient balance");
/*LN-70*/ 
/*LN-71*/         uniBTC.transferFrom(msg.sender, address(this), amount);
/*LN-72*/ 
/*LN-73*/         uint256 exchangeRate = getExchangeRate();
/*LN-74*/         uint256 ethAmount = (amount * 1e18) / exchangeRate;
/*LN-75*/         require(address(this).balance >= ethAmount, "Insufficient ETH");
/*LN-76*/ 
/*LN-77*/         payable(msg.sender).transfer(ethAmount);
/*LN-78*/     }
/*LN-79*/ 
/*LN-80*/     function getExchangeRate() public view returns (uint256) {
/*LN-81*/         return priceOracle.getETHtoBTCRate();
/*LN-82*/     }
/*LN-83*/ 
/*LN-84*/     receive() external payable {}
/*LN-85*/ }
/*LN-86*/ 