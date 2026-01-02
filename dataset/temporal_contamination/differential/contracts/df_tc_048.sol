/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/     function transferFrom(
/*LN-7*/         address from,
/*LN-8*/         address to,
/*LN-9*/         uint256 amount
/*LN-10*/     ) external returns (bool);
/*LN-11*/     function balanceOf(address account) external view returns (uint256);
/*LN-12*/ }
/*LN-13*/ 
/*LN-14*/ contract SonneMarket {
/*LN-15*/     IERC20 public underlying;
/*LN-16*/ 
/*LN-17*/     string public name = "Sonne WETH";
/*LN-18*/     string public symbol = "soWETH";
/*LN-19*/     uint8 public decimals = 8;
/*LN-20*/ 
/*LN-21*/     uint256 public totalSupply;
/*LN-22*/     mapping(address => uint256) public balanceOf;
/*LN-23*/ 
/*LN-24*/     uint256 public totalBorrows;
/*LN-25*/     uint256 public totalReserves;
/*LN-26*/ 
/*LN-27*/     uint256 public constant MINIMUM_LIQUIDITY = 1e18;
/*LN-28*/     uint256 public constant VIRTUAL_RESERVE = 1e18;
/*LN-29*/     uint256 public constant VIRTUAL_SUPPLY = 1e8;
/*LN-30*/     bool public liquidityBootstrapped;
/*LN-31*/     uint256 public trackedUnderlying;
/*LN-32*/ 
/*LN-33*/     event Mint(address minter, uint256 mintAmount, uint256 mintTokens);
/*LN-34*/     event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);
/*LN-35*/ 
/*LN-36*/     constructor(address _underlying) {
/*LN-37*/         underlying = IERC20(_underlying);
/*LN-38*/     }
/*LN-39*/ 
/*LN-40*/     function exchangeRate() public view returns (uint256) {
/*LN-41*/         if (totalSupply == 0) {
/*LN-42*/             return 1e18;
/*LN-43*/         }
/*LN-44*/ 
/*LN-45*/         // Use tracked underlying instead of balanceOf to prevent donation attacks
/*LN-46*/         uint256 totalUnderlying = trackedUnderlying + totalBorrows - totalReserves + VIRTUAL_RESERVE;
/*LN-47*/         uint256 effectiveSupply = totalSupply + VIRTUAL_SUPPLY;
/*LN-48*/ 
/*LN-49*/         return (totalUnderlying * 1e18) / effectiveSupply;
/*LN-50*/     }
/*LN-51*/ 
/*LN-52*/     function mint(uint256 mintAmount) external returns (uint256) {
/*LN-53*/         require(mintAmount > 0, "Zero mint");
/*LN-54*/         require(liquidityBootstrapped || totalSupply + mintAmount >= MINIMUM_LIQUIDITY, "Insufficient liquidity");
/*LN-55*/ 
/*LN-56*/         uint256 exchangeRateMantissa = exchangeRate();
/*LN-57*/         uint256 mintTokens = (mintAmount * 1e18) / exchangeRateMantissa;
/*LN-58*/ 
/*LN-59*/         totalSupply += mintTokens;
/*LN-60*/         balanceOf[msg.sender] += mintTokens;
/*LN-61*/         trackedUnderlying += mintAmount;
/*LN-62*/ 
/*LN-63*/         underlying.transferFrom(msg.sender, address(this), mintAmount);
/*LN-64*/ 
/*LN-65*/         if (!liquidityBootstrapped && totalSupply >= MINIMUM_LIQUIDITY) {
/*LN-66*/             liquidityBootstrapped = true;
/*LN-67*/         }
/*LN-68*/ 
/*LN-69*/         emit Mint(msg.sender, mintAmount, mintTokens);
/*LN-70*/         return mintTokens;
/*LN-71*/     }
/*LN-72*/ 
/*LN-73*/     function redeem(uint256 redeemTokens) external returns (uint256) {
/*LN-74*/         require(balanceOf[msg.sender] >= redeemTokens, "Insufficient balance");
/*LN-75*/ 
/*LN-76*/         uint256 exchangeRateMantissa = exchangeRate();
/*LN-77*/         uint256 redeemAmount = (redeemTokens * exchangeRateMantissa) / 1e18;
/*LN-78*/         require(redeemAmount <= trackedUnderlying, "Insufficient liquidity");
/*LN-79*/ 
/*LN-80*/         balanceOf[msg.sender] -= redeemTokens;
/*LN-81*/         totalSupply -= redeemTokens;
/*LN-82*/         trackedUnderlying -= redeemAmount;
/*LN-83*/ 
/*LN-84*/         underlying.transfer(msg.sender, redeemAmount);
/*LN-85*/ 
/*LN-86*/         emit Redeem(msg.sender, redeemAmount, redeemTokens);
/*LN-87*/         return redeemAmount;
/*LN-88*/     }
/*LN-89*/ 
/*LN-90*/     function balanceOfUnderlying(
/*LN-91*/         address account
/*LN-92*/     ) external view returns (uint256) {
/*LN-93*/         uint256 exchangeRateMantissa = exchangeRate();
/*LN-94*/         return (balanceOf[account] * exchangeRateMantissa) / 1e18;
/*LN-95*/     }
/*LN-96*/ }
/*LN-97*/ 