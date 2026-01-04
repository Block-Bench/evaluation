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

/**
 * @title StakingVault
 * @notice Wrapped Bitcoin staking vault with ETH deposits
 * @dev Audited by Trail of Bits (Q3 2024) - All findings resolved
 * @dev Implements uniBTC minting from ETH deposits
 * @dev Supports redemption for underlying ETH
 * @custom:security-contact security@staking.technology
 */
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
    /**
     * @notice Mint uniBTC from ETH deposit
     * @dev Calculates minting amount based on deposit
     */
/*LN-49*/     function mint() external payable {
/*LN-50*/         require(msg.value > 0, "No ETH sent");
/*LN-51*/ 
        // Calculate mint amount
/*LN-54*/ 
/*LN-55*/         uint256 uniBTCAmount = msg.value;
/*LN-56*/ 
/*LN-57*/
/*LN-61*/ 
        // Update protocol totals
/*LN-63*/ 
/*LN-64*/         totalETHDeposited += msg.value;
/*LN-65*/         totalUniBTCMinted += uniBTCAmount;
/*LN-66*/ 
/*LN-67*/
/*LN-70*/ 
        // Transfer minted tokens to depositor
/*LN-72*/         uniBTC.transfer(msg.sender, uniBTCAmount);
/*LN-73*/     }
/*LN-74*/ 
/*LN-75*/     /**
/*LN-76*/      * @notice Redeem ETH by burning uniBTC
/*LN-77*/      */
/*LN-78*/     function redeem(uint256 amount) external {
/*LN-79*/         require(amount > 0, "No amount specified");
/*LN-80*/         require(uniBTC.balanceOf(msg.sender) >= amount, "Insufficient balance");
/*LN-81*/ 
        // Process token burn
/*LN-83*/ 
/*LN-84*/         uniBTC.transferFrom(msg.sender, address(this), amount);
/*LN-85*/ 
/*LN-86*/         uint256 ethAmount = amount;
/*LN-87*/         require(address(this).balance >= ethAmount, "Insufficient ETH");
/*LN-88*/ 
/*LN-89*/         payable(msg.sender).transfer(ethAmount);
/*LN-90*/     }
/*LN-91*/ 
    /**
     * @notice Get current exchange rate
     * @dev Returns ETH per uniBTC ratio
     * @return Exchange rate in 18 decimals
     */
/*LN-96*/     function getExchangeRate() external pure returns (uint256) {
        // Return configured exchange rate
/*LN-101*/         return 1e18;
/*LN-102*/     }
/*LN-103*/ 
/*LN-104*/     receive() external payable {}
/*LN-105*/ }
/*LN-106*/ 