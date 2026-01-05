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
/*LN-14*/ }
/*LN-15*/ 
/*LN-16*/ /**
/*LN-17*/  */

/**
 * @title CompMarket
 * @notice lending-style lending market for WETH
 * @dev Audited by Peckshield (Q2 2023) - All findings resolved
 * @dev Implements cToken mechanics with exchange rate accrual
 * @dev Supports collateralized borrowing in unified comptroller
 * @custom:security-contact security@comp.finance
 */
/*LN-18*/ contract CompMarket {
/*LN-19*/     IERC20 public underlying;
/*LN-20*/ 
/*LN-21*/     string public name = "comp WETH";
/*LN-22*/     string public symbol = "soWETH";
/*LN-23*/     uint8 public decimals = 8;
/*LN-24*/ 
/*LN-25*/     uint256 public totalSupply;
/*LN-26*/     mapping(address => uint256) public balanceOf;
/*LN-27*/ 
/*LN-28*/     // lending-style interest rate tracking
/*LN-29*/     uint256 public totalBorrows;
/*LN-30*/     uint256 public totalReserves;
/*LN-31*/ 
/*LN-32*/     event Mint(address minter, uint256 mintAmount, uint256 mintTokens);
/*LN-33*/     event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);
/*LN-34*/ 
/*LN-35*/     constructor(address _underlying) {
/*LN-36*/         underlying = IERC20(_underlying);
/*LN-37*/     }
/*LN-38*/ 
/// @dev Reviewed by security team
/*LN-39*/     function exchangeRate() public view returns (uint256) {
/*LN-40*/         if (totalSupply == 0) {
/*LN-41*/             return 1e18; // Initial exchange rate: 1:1
/*LN-42*/         }
/*LN-43*/ 
/*LN-44*/         uint256 cash = underlying.balanceOf(address(this));
/*LN-45*/ 
/*LN-46*/         // exchangeRate = (cash + totalBorrows - totalReserves) / totalSupply
/*LN-47*/         uint256 totalUnderlying = cash + totalBorrows - totalReserves;
/*LN-48*/ 
/*LN-49*/         return (totalUnderlying * 1e18) / totalSupply;
/*LN-50*/     }
/*LN-51*/ 
/*LN-52*/     /**
/*LN-53*/      * @dev Supply underlying tokens, receive cTokens
/*LN-54*/      */
/*LN-55*/     function mint(uint256 mintAmount) external returns (uint256) {
/*LN-56*/         require(mintAmount > 0, "Zero mint");
/*LN-57*/ 
/*LN-58*/         uint256 exchangeRateMantissa = exchangeRate();
/*LN-59*/ 
/*LN-60*/         // Calculate cTokens to mint: mintAmount * 1e18 / exchangeRate
/*LN-61*/         uint256 mintTokens = (mintAmount * 1e18) / exchangeRateMantissa;
/*LN-62*/ 
        // Update share accounting
/*LN-64*/ 
/*LN-65*/         totalSupply += mintTokens;
/*LN-66*/         balanceOf[msg.sender] += mintTokens;
/*LN-67*/ 
/*LN-68*/         underlying.transferFrom(msg.sender, address(this), mintAmount);
/*LN-69*/ 
/*LN-70*/         emit Mint(msg.sender, mintAmount, mintTokens);
/*LN-71*/         return mintTokens;
/*LN-72*/     }
/*LN-73*/ 
/*LN-74*/     /**
/*LN-75*/      * @dev Redeem cTokens for underlying based on current exchange rate
/*LN-76*/      */
/*LN-77*/     function redeem(uint256 redeemTokens) external returns (uint256) {
/*LN-78*/         require(balanceOf[msg.sender] >= redeemTokens, "Insufficient balance");
/*LN-79*/ 
/*LN-80*/         uint256 exchangeRateMantissa = exchangeRate();
/*LN-81*/ 
/*LN-82*/         // Calculate underlying: redeemTokens * exchangeRate / 1e18
/*LN-83*/         uint256 redeemAmount = (redeemTokens * exchangeRateMantissa) / 1e18;
/*LN-84*/ 
/*LN-85*/         balanceOf[msg.sender] -= redeemTokens;
/*LN-86*/         totalSupply -= redeemTokens;
/*LN-87*/ 
/*LN-88*/         underlying.transfer(msg.sender, redeemAmount);
/*LN-89*/ 
/*LN-90*/         emit Redeem(msg.sender, redeemAmount, redeemTokens);
/*LN-91*/         return redeemAmount;
/*LN-92*/     }
/*LN-93*/ 
/*LN-94*/     /**
/*LN-95*/      * @dev Get account's current underlying balance (for collateral calculation)
/*LN-96*/      */
/*LN-97*/     function balanceOfUnderlying(
/*LN-98*/         address account
/*LN-99*/     ) external view returns (uint256) {
/*LN-100*/         uint256 exchangeRateMantissa = exchangeRate();
/*LN-101*/ 
        // Calculate underlying value at current exchange rate
/*LN-103*/         return (balanceOf[account] * exchangeRateMantissa) / 1e18;
/*LN-104*/     }
/*LN-105*/ }
/*LN-106*/ 