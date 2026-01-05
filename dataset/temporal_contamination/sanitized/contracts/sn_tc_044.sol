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
/*LN-18*/ contract CompMarket {
/*LN-19*/     IERC20 public underlying;
/*LN-20*/ 
/*LN-21*/     string public name = "Sonne WETH";
/*LN-22*/     string public symbol = "soWETH";
/*LN-23*/     uint8 public decimals = 8;
/*LN-24*/ 
/*LN-25*/     uint256 public totalSupply;
/*LN-26*/     mapping(address => uint256) public balanceOf;
/*LN-27*/ 
/*LN-28*/     uint256 public totalBorrows;
/*LN-29*/     uint256 public totalReserves;
/*LN-30*/ 
/*LN-31*/     event Mint(address minter, uint256 mintAmount, uint256 mintTokens);
/*LN-32*/     event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);
/*LN-33*/ 
/*LN-34*/     constructor(address _underlying) {
/*LN-35*/         underlying = IERC20(_underlying);
/*LN-36*/     }
/*LN-37*/ 
/*LN-38*/     function exchangeRate() public view returns (uint256) {
/*LN-39*/         if (totalSupply == 0) {
/*LN-40*/             return 1e18; // Initial exchange rate: 1:1
/*LN-41*/         }
/*LN-42*/ 
/*LN-43*/         uint256 cash = underlying.balanceOf(address(this));
/*LN-44*/ 
/*LN-45*/         // exchangeRate = (cash + totalBorrows - totalReserves) / totalSupply
/*LN-46*/         uint256 totalUnderlying = cash + totalBorrows - totalReserves;
/*LN-47*/ 
/*LN-48*/         return (totalUnderlying * 1e18) / totalSupply;
/*LN-49*/     }
/*LN-50*/ 
/*LN-51*/     /**
/*LN-52*/      * @dev Supply underlying tokens, receive cTokens
/*LN-53*/      */
/*LN-54*/     function mint(uint256 mintAmount) external returns (uint256) {
/*LN-55*/         require(mintAmount > 0, "Zero mint");
/*LN-56*/ 
/*LN-57*/         uint256 exchangeRateMantissa = exchangeRate();
/*LN-58*/ 
/*LN-59*/         // Calculate cTokens to mint: mintAmount * 1e18 / exchangeRate
/*LN-60*/         uint256 mintTokens = (mintAmount * 1e18) / exchangeRateMantissa;
/*LN-61*/ 
/*LN-62*/         totalSupply += mintTokens;
/*LN-63*/         balanceOf[msg.sender] += mintTokens;
/*LN-64*/ 
/*LN-65*/         underlying.transferFrom(msg.sender, address(this), mintAmount);
/*LN-66*/ 
/*LN-67*/         emit Mint(msg.sender, mintAmount, mintTokens);
/*LN-68*/         return mintTokens;
/*LN-69*/     }
/*LN-70*/ 
/*LN-71*/     /**
/*LN-72*/      * @dev Redeem cTokens for underlying based on current exchange rate
/*LN-73*/      */
/*LN-74*/     function redeem(uint256 redeemTokens) external returns (uint256) {
/*LN-75*/         require(balanceOf[msg.sender] >= redeemTokens, "Insufficient balance");
/*LN-76*/ 
/*LN-77*/         uint256 exchangeRateMantissa = exchangeRate();
/*LN-78*/ 
/*LN-79*/         // Calculate underlying: redeemTokens * exchangeRate / 1e18
/*LN-80*/         uint256 redeemAmount = (redeemTokens * exchangeRateMantissa) / 1e18;
/*LN-81*/ 
/*LN-82*/         balanceOf[msg.sender] -= redeemTokens;
/*LN-83*/         totalSupply -= redeemTokens;
/*LN-84*/ 
/*LN-85*/         underlying.transfer(msg.sender, redeemAmount);
/*LN-86*/ 
/*LN-87*/         emit Redeem(msg.sender, redeemAmount, redeemTokens);
/*LN-88*/         return redeemAmount;
/*LN-89*/     }
/*LN-90*/ 
/*LN-91*/     /**
/*LN-92*/      * @dev Get account's current underlying balance (for collateral calculation)
/*LN-93*/      */
/*LN-94*/     function balanceOfUnderlying(
/*LN-95*/         address account
/*LN-96*/     ) external view returns (uint256) {
/*LN-97*/         uint256 exchangeRateMantissa = exchangeRate();
/*LN-98*/ 
/*LN-99*/         return (balanceOf[account] * exchangeRateMantissa) / 1e18;
/*LN-100*/     }
/*LN-101*/ }
/*LN-102*/ 