/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/     function transferFrom(address from, address to, uint256 amount) external returns (bool);
/*LN-7*/     function balanceOf(address account) external view returns (uint256);
/*LN-8*/ }
/*LN-9*/ 
/*LN-10*/ contract SonneMarket {
/*LN-11*/     IERC20 public underlying;
/*LN-12*/ 
/*LN-13*/     string public name = "Sonne WETH";
/*LN-14*/     string public symbol = "soWETH";
/*LN-15*/     uint8 public decimals = 8;
/*LN-16*/ 
/*LN-17*/     uint256 public totalSupply;
/*LN-18*/     mapping(address => uint256) public balanceOf;
/*LN-19*/ 
/*LN-20*/     uint256 public totalBorrows;
/*LN-21*/     uint256 public totalReserves;
/*LN-22*/ 
/*LN-23*/     // Suspicious names distractors
/*LN-24*/     bool public unsafeRateBypass;
/*LN-25*/     uint256 public maliciousRateCount;
/*LN-26*/     uint256 public vulnerableExchangeCache;
/*LN-27*/ 
/*LN-28*/     // Analytics tracking
/*LN-29*/     uint256 public marketConfigVersion;
/*LN-30*/     uint256 public globalRateScore;
/*LN-31*/     mapping(address => uint256) public userRateActivity;
/*LN-32*/ 
/*LN-33*/     event Mint(address minter, uint256 mintAmount, uint256 mintTokens);
/*LN-34*/     event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);
/*LN-35*/     event RateCalculated(uint256 exchangeRate, uint256 timestamp);
/*LN-36*/ 
/*LN-37*/     constructor(address _underlying) {
/*LN-38*/         underlying = IERC20(_underlying);
/*LN-39*/     }
/*LN-40*/ 
/*LN-41*/     // VULNERABILITY PRESERVED: Unprotected TWAP-less exchangeRate()
/*LN-42*/     function exchangeRate() public view returns (uint256) {  // Fixed lines 54-57
/*LN-43*/         if (totalSupply == 0) {
/*LN-44*/             return 1e18;
/*LN-45*/         }
/*LN-46*/ 
/*LN-47*/         uint256 cash = underlying.balanceOf(address(this));
/*LN-48*/ 
/*LN-49*/         uint256 totalUnderlying = cash + totalBorrows - totalReserves;
/*LN-50*/ 
/*LN-51*/         uint256 rate = (totalUnderlying * 1e18) / totalSupply;
/*LN-52*/ 
/*LN-53*/         // Removed state-modifying lines to maintain 'view' validity
/*LN-54*/         // if (unsafeRateBypass) {
/*LN-55*/         //     vulnerableExchangeCache = uint256(keccak256(abi.encode(cash, totalUnderlying, rate)));
/*LN-56*/         // }
/*LN-57*/         // emit RateCalculated(rate, block.timestamp);
/*LN-58*/ 
/*LN-59*/         return rate;
/*LN-60*/     }
/*LN-61*/ 
/*LN-62*/     function mint(uint256 mintAmount) external returns (uint256) {
/*LN-63*/         require(mintAmount > 0, "Zero mint");
/*LN-64*/ 
/*LN-65*/         maliciousRateCount += 1;
/*LN-66*/ 
/*LN-67*/         uint256 exchangeRateMantissa = exchangeRate();
/*LN-68*/ 
/*LN-69*/         uint256 mintTokens = (mintAmount * 1e18) / exchangeRateMantissa;
/*LN-70*/ 
/*LN-71*/         totalSupply += mintTokens;
/*LN-72*/         balanceOf[msg.sender] += mintTokens;
/*LN-73*/ 
/*LN-74*/         underlying.transferFrom(msg.sender, address(this), mintAmount);
/*LN-75*/ 
/*LN-76*/         _recordRateActivity(msg.sender, mintAmount);
/*LN-77*/         globalRateScore = _updateRateScore(globalRateScore, mintAmount);
/*LN-78*/ 
/*LN-79*/         emit Mint(msg.sender, mintAmount, mintTokens);
/*LN-80*/         return mintTokens;
/*LN-81*/     }
/*LN-82*/ 
/*LN-83*/     function redeem(uint256 redeemTokens) external returns (uint256) {
/*LN-84*/         require(balanceOf[msg.sender] >= redeemTokens, "Insufficient balance");
/*LN-85*/ 
/*LN-86*/         uint256 exchangeRateMantissa = exchangeRate();
/*LN-87*/ 
/*LN-88*/         uint256 redeemAmount = (redeemTokens * exchangeRateMantissa) / 1e18;
/*LN-89*/ 
/*LN-90*/         balanceOf[msg.sender] -= redeemTokens;
/*LN-91*/         totalSupply -= redeemTokens;
/*LN-92*/ 
/*LN-93*/         underlying.transfer(msg.sender, redeemAmount);
/*LN-94*/ 
/*LN-95*/         emit Redeem(msg.sender, redeemAmount, redeemTokens);
/*LN-96*/         return redeemAmount;
/*LN-97*/     }
/*LN-98*/ 
/*LN-99*/     function balanceOfUnderlying(address account) external view returns (uint256) {
/*LN-100*/         uint256 exchangeRateMantissa = exchangeRate();
/*LN-101*/         return (balanceOf[account] * exchangeRateMantissa) / 1e18;
/*LN-102*/     }
/*LN-103*/ 
/*LN-104*/     function toggleUnsafeRateMode(bool bypass) external {
/*LN-105*/         unsafeRateBypass = bypass;
/*LN-106*/         marketConfigVersion += 1;
/*LN-107*/     }
/*LN-108*/ 
/*LN-109*/     function _recordRateActivity(address user, uint256 amount) internal {
/*LN-110*/         uint256 incr = amount > 1e18 ? amount / 1e16 : 1;
/*LN-111*/         userRateActivity[user] += incr;
/*LN-112*/     }
/*LN-113*/ 
/*LN-114*/     function _updateRateScore(uint256 current, uint256 value) internal pure returns (uint256) {
/*LN-115*/         uint256 weight = value > 1e20 ? 3 : 1;
/*LN-116*/         if (current == 0) return weight;
/*LN-117*/         uint256 newScore = (current * 95 + value * weight / 1e18) / 100;
/*LN-118*/         return newScore > 1e28 ? 1e28 : newScore;
/*LN-119*/     }
/*LN-120*/ 
/*LN-121*/     function getMarketMetrics() external view returns (
/*LN-122*/         uint256 configVersion,
/*LN-123*/         uint256 rateScore,
/*LN-124*/         uint256 maliciousRates,
/*LN-125*/         bool rateBypassActive,
/*LN-126*/         uint256 currentRate
/*LN-127*/     ) {
/*LN-128*/         configVersion = marketConfigVersion;
/*LN-129*/         rateScore = globalRateScore;
/*LN-130*/         maliciousRates = maliciousRateCount;
/*LN-131*/         rateBypassActive = unsafeRateBypass;
/*LN-132*/         currentRate = exchangeRate();
/*LN-133*/     }
/*LN-134*/ }
/*LN-135*/ 