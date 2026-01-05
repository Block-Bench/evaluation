/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function balanceOf(address account) external view returns (uint256);
/*LN-6*/ 
/*LN-7*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-8*/ 
/*LN-9*/     function transferFrom(
/*LN-10*/         address from,
/*LN-11*/         address to,
/*LN-12*/         uint256 amount
/*LN-13*/     ) external returns (bool);
/*LN-14*/ }
/*LN-15*/ 
/*LN-16*/ contract LiquidityPool {
/*LN-17*/     address public maintainer;
/*LN-18*/     address public baseToken;
/*LN-19*/     address public quoteToken;
/*LN-20*/ 
/*LN-21*/     uint256 public lpFeeRate;
/*LN-22*/     uint256 public baseBalance;
/*LN-23*/     uint256 public quoteBalance;
/*LN-24*/ 
/*LN-25*/     bool public isInitialized;
/*LN-26*/ 
/*LN-27*/     event Initialized(address maintainer, address base, address quote);
/*LN-28*/ 
/*LN-29*/     function init(
/*LN-30*/         address _maintainer,
/*LN-31*/         address _baseToken,
/*LN-32*/         address _quoteToken,
/*LN-33*/         uint256 _lpFeeRate
/*LN-34*/     ) external {
/*LN-35*/         require(!isInitialized, "Already initialized");
/*LN-36*/ 
/*LN-37*/         maintainer = _maintainer;
/*LN-38*/         baseToken = _baseToken;
/*LN-39*/         quoteToken = _quoteToken;
/*LN-40*/         lpFeeRate = _lpFeeRate;
/*LN-41*/ 
/*LN-42*/         isInitialized = true;
/*LN-43*/ 
/*LN-44*/         emit Initialized(_maintainer, _baseToken, _quoteToken);
/*LN-45*/     }
/*LN-46*/ 
/*LN-47*/     function addLiquidity(uint256 baseAmount, uint256 quoteAmount) external {
/*LN-48*/         require(isInitialized, "Not initialized");
/*LN-49*/ 
/*LN-50*/         IERC20(baseToken).transferFrom(msg.sender, address(this), baseAmount);
/*LN-51*/         IERC20(quoteToken).transferFrom(msg.sender, address(this), quoteAmount);
/*LN-52*/ 
/*LN-53*/         baseBalance += baseAmount;
/*LN-54*/         quoteBalance += quoteAmount;
/*LN-55*/     }
/*LN-56*/ 
/*LN-57*/     function swap(
/*LN-58*/         address fromToken,
/*LN-59*/         address toToken,
/*LN-60*/         uint256 fromAmount
/*LN-61*/     ) external returns (uint256 toAmount) {
/*LN-62*/         require(isInitialized, "Not initialized");
/*LN-63*/         require(
/*LN-64*/             (fromToken == baseToken && toToken == quoteToken) ||
/*LN-65*/                 (fromToken == quoteToken && toToken == baseToken),
/*LN-66*/             "Invalid token pair"
/*LN-67*/         );
/*LN-68*/ 
/*LN-69*/         IERC20(fromToken).transferFrom(msg.sender, address(this), fromAmount);
/*LN-70*/ 
/*LN-71*/         if (fromToken == baseToken) {
/*LN-72*/             toAmount = (quoteBalance * fromAmount) / (baseBalance + fromAmount);
/*LN-73*/             baseBalance += fromAmount;
/*LN-74*/             quoteBalance -= toAmount;
/*LN-75*/         } else {
/*LN-76*/             toAmount = (baseBalance * fromAmount) / (quoteBalance + fromAmount);
/*LN-77*/             quoteBalance += fromAmount;
/*LN-78*/             baseBalance -= toAmount;
/*LN-79*/         }
/*LN-80*/ 
/*LN-81*/         uint256 fee = (toAmount * lpFeeRate) / 10000;
/*LN-82*/         toAmount -= fee;
/*LN-83*/ 
/*LN-84*/         IERC20(toToken).transfer(msg.sender, toAmount);
/*LN-85*/         IERC20(toToken).transfer(maintainer, fee);
/*LN-86*/ 
/*LN-87*/         return toAmount;
/*LN-88*/     }
/*LN-89*/ 
/*LN-90*/     function claimFees() external {
/*LN-91*/         require(msg.sender == maintainer, "Only maintainer");
/*LN-92*/ 
/*LN-93*/         uint256 baseTokenBalance = IERC20(baseToken).balanceOf(address(this));
/*LN-94*/         uint256 quoteTokenBalance = IERC20(quoteToken).balanceOf(address(this));
/*LN-95*/ 
/*LN-96*/         if (baseTokenBalance > baseBalance) {
/*LN-97*/             uint256 excess = baseTokenBalance - baseBalance;
/*LN-98*/             IERC20(baseToken).transfer(maintainer, excess);
/*LN-99*/         }
/*LN-100*/ 
/*LN-101*/         if (quoteTokenBalance > quoteBalance) {
/*LN-102*/             uint256 excess = quoteTokenBalance - quoteBalance;
/*LN-103*/             IERC20(quoteToken).transfer(maintainer, excess);
/*LN-104*/         }
/*LN-105*/     }
/*LN-106*/ }
/*LN-107*/ 