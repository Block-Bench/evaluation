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
/*LN-17*/ interface IUniswapV3Router {
/*LN-18*/     struct ExactInputSingleParams {
/*LN-19*/         address tokenIn;
/*LN-20*/         address tokenOut;
/*LN-21*/         uint24 fee;
/*LN-22*/         address recipient;
/*LN-23*/         uint256 deadline;
/*LN-24*/         uint256 amountIn;
/*LN-25*/         uint256 amountOutMinimum;
/*LN-26*/         uint160 sqrtPriceLimitX96;
/*LN-27*/     }
/*LN-28*/ 
/*LN-29*/     function exactInputSingle(
/*LN-30*/         ExactInputSingleParams calldata params
/*LN-31*/     ) external payable returns (uint256 amountOut);
/*LN-32*/ }
/*LN-33*/ 
/*LN-34*/ contract StakingVault {
/*LN-35*/     IERC20 public immutable uniBTC;
/*LN-36*/     IERC20 public immutable WBTC;
/*LN-37*/     IUniswapV3Router public immutable router;
/*LN-38*/ 
/*LN-39*/     uint256 public totalETHDeposited;
/*LN-40*/     uint256 public totalUniBTCMinted;
/*LN-41*/ 
/*LN-42*/     constructor(address _uniBTC, address _wbtc, address _router) {
/*LN-43*/         uniBTC = IERC20(_uniBTC);
/*LN-44*/         WBTC = IERC20(_wbtc);
/*LN-45*/         router = IUniswapV3Router(_router);
/*LN-46*/     }
/*LN-47*/ 
/*LN-48*/     function mint() external payable {
/*LN-49*/         require(msg.value > 0, "No ETH sent");
/*LN-50*/ 
/*LN-51*/         uint256 uniBTCAmount = msg.value;
/*LN-52*/ 
/*LN-53*/         totalETHDeposited += msg.value;
/*LN-54*/         totalUniBTCMinted += uniBTCAmount;
/*LN-55*/ 
/*LN-56*/ 
/*LN-57*/         uniBTC.transfer(msg.sender, uniBTCAmount);
/*LN-58*/     }
/*LN-59*/ 
/*LN-60*/ 
/*LN-61*/     function redeem(uint256 amount) external {
/*LN-62*/         require(amount > 0, "No amount specified");
/*LN-63*/         require(uniBTC.balanceOf(msg.sender) >= amount, "Insufficient balance");
/*LN-64*/ 
/*LN-65*/         uniBTC.transferFrom(msg.sender, address(this), amount);
/*LN-66*/ 
/*LN-67*/         uint256 ethAmount = amount;
/*LN-68*/         require(address(this).balance >= ethAmount, "Insufficient ETH");
/*LN-69*/ 
/*LN-70*/         payable(msg.sender).transfer(ethAmount);
/*LN-71*/     }
/*LN-72*/ 
/*LN-73*/ 
/*LN-74*/     function getExchangeRate() external pure returns (uint256) {
/*LN-75*/ 
/*LN-76*/         return 1e18;
/*LN-77*/     }
/*LN-78*/ 
/*LN-79*/     receive() external payable {}
/*LN-80*/ }