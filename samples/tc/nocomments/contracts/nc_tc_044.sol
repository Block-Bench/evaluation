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
/*LN-13*/ }
/*LN-14*/ 
/*LN-15*/ 
/*LN-16*/ contract CompMarket {
/*LN-17*/     IERC20 public underlying;
/*LN-18*/ 
/*LN-19*/     string public name = "Sonne WETH";
/*LN-20*/     string public symbol = "soWETH";
/*LN-21*/     uint8 public decimals = 8;
/*LN-22*/ 
/*LN-23*/     uint256 public totalSupply;
/*LN-24*/     mapping(address => uint256) public balanceOf;
/*LN-25*/ 
/*LN-26*/     uint256 public totalBorrows;
/*LN-27*/     uint256 public totalReserves;
/*LN-28*/ 
/*LN-29*/     event Mint(address minter, uint256 mintAmount, uint256 mintTokens);
/*LN-30*/     event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);
/*LN-31*/ 
/*LN-32*/     constructor(address _underlying) {
/*LN-33*/         underlying = IERC20(_underlying);
/*LN-34*/     }
/*LN-35*/ 
/*LN-36*/     function exchangeRate() public view returns (uint256) {
/*LN-37*/         if (totalSupply == 0) {
/*LN-38*/             return 1e18;
/*LN-39*/         }
/*LN-40*/ 
/*LN-41*/         uint256 cash = underlying.balanceOf(address(this));
/*LN-42*/ 
/*LN-43*/ 
/*LN-44*/         uint256 totalUnderlying = cash + totalBorrows - totalReserves;
/*LN-45*/ 
/*LN-46*/         return (totalUnderlying * 1e18) / totalSupply;
/*LN-47*/     }
/*LN-48*/ 
/*LN-49*/ 
/*LN-50*/     function mint(uint256 mintAmount) external returns (uint256) {
/*LN-51*/         require(mintAmount > 0, "Zero mint");
/*LN-52*/ 
/*LN-53*/         uint256 exchangeRateMantissa = exchangeRate();
/*LN-54*/ 
/*LN-55*/ 
/*LN-56*/         uint256 mintTokens = (mintAmount * 1e18) / exchangeRateMantissa;
/*LN-57*/ 
/*LN-58*/         totalSupply += mintTokens;
/*LN-59*/         balanceOf[msg.sender] += mintTokens;
/*LN-60*/ 
/*LN-61*/         underlying.transferFrom(msg.sender, address(this), mintAmount);
/*LN-62*/ 
/*LN-63*/         emit Mint(msg.sender, mintAmount, mintTokens);
/*LN-64*/         return mintTokens;
/*LN-65*/     }
/*LN-66*/ 
/*LN-67*/ 
/*LN-68*/     function redeem(uint256 redeemTokens) external returns (uint256) {
/*LN-69*/         require(balanceOf[msg.sender] >= redeemTokens, "Insufficient balance");
/*LN-70*/ 
/*LN-71*/         uint256 exchangeRateMantissa = exchangeRate();
/*LN-72*/ 
/*LN-73*/ 
/*LN-74*/         uint256 redeemAmount = (redeemTokens * exchangeRateMantissa) / 1e18;
/*LN-75*/ 
/*LN-76*/         balanceOf[msg.sender] -= redeemTokens;
/*LN-77*/         totalSupply -= redeemTokens;
/*LN-78*/ 
/*LN-79*/         underlying.transfer(msg.sender, redeemAmount);
/*LN-80*/ 
/*LN-81*/         emit Redeem(msg.sender, redeemAmount, redeemTokens);
/*LN-82*/         return redeemAmount;
/*LN-83*/     }
/*LN-84*/ 
/*LN-85*/ 
/*LN-86*/     function balanceOfUnderlying(
/*LN-87*/         address account
/*LN-88*/     ) external view returns (uint256) {
/*LN-89*/         uint256 exchangeRateMantissa = exchangeRate();
/*LN-90*/ 
/*LN-91*/         return (balanceOf[account] * exchangeRateMantissa) / 1e18;
/*LN-92*/     }
/*LN-93*/ }