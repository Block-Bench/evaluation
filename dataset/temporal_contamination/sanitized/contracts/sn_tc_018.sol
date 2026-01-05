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
/*LN-35*/ 
/*LN-36*/         maintainer = _maintainer;
/*LN-37*/         baseToken = _baseToken;
/*LN-38*/         quoteToken = _quoteToken;
/*LN-39*/         lpFeeRate = _lpFeeRate;
/*LN-40*/ 
/*LN-41*/         isInitialized = true;
/*LN-42*/ 
/*LN-43*/         emit Initialized(_maintainer, _baseToken, _quoteToken);
/*LN-44*/     }
/*LN-45*/ 
/*LN-46*/     /**
/*LN-47*/      * @notice Add liquidity to pool
/*LN-48*/      */
/*LN-49*/     function addLiquidity(uint256 baseAmount, uint256 quoteAmount) external {
/*LN-50*/         require(isInitialized, "Not initialized");
/*LN-51*/ 
/*LN-52*/         IERC20(baseToken).transferFrom(msg.sender, address(this), baseAmount);
/*LN-53*/         IERC20(quoteToken).transferFrom(msg.sender, address(this), quoteAmount);
/*LN-54*/ 
/*LN-55*/         baseBalance += baseAmount;
/*LN-56*/         quoteBalance += quoteAmount;
/*LN-57*/     }
/*LN-58*/ 
/*LN-59*/     /**
/*LN-60*/      * @notice Swap tokens
/*LN-61*/      */
/*LN-62*/     function swap(
/*LN-63*/         address fromToken,
/*LN-64*/         address toToken,
/*LN-65*/         uint256 fromAmount
/*LN-66*/     ) external returns (uint256 toAmount) {
/*LN-67*/         require(isInitialized, "Not initialized");
/*LN-68*/         require(
/*LN-69*/             (fromToken == baseToken && toToken == quoteToken) ||
/*LN-70*/                 (fromToken == quoteToken && toToken == baseToken),
/*LN-71*/             "Invalid token pair"
/*LN-72*/         );
/*LN-73*/ 
/*LN-74*/         // Transfer tokens in
/*LN-75*/         IERC20(fromToken).transferFrom(msg.sender, address(this), fromAmount);
/*LN-76*/ 
/*LN-77*/         // Calculate swap amount (simplified constant product)
/*LN-78*/         if (fromToken == baseToken) {
/*LN-79*/             toAmount = (quoteBalance * fromAmount) / (baseBalance + fromAmount);
/*LN-80*/             baseBalance += fromAmount;
/*LN-81*/             quoteBalance -= toAmount;
/*LN-82*/         } else {
/*LN-83*/             toAmount = (baseBalance * fromAmount) / (quoteBalance + fromAmount);
/*LN-84*/             quoteBalance += fromAmount;
/*LN-85*/             baseBalance -= toAmount;
/*LN-86*/         }
/*LN-87*/ 
/*LN-88*/         // Deduct fee for maintainer
/*LN-89*/         uint256 fee = (toAmount * lpFeeRate) / 10000;
/*LN-90*/         toAmount -= fee;
/*LN-91*/ 
/*LN-92*/         // Transfer tokens out
/*LN-93*/         IERC20(toToken).transfer(msg.sender, toAmount);
/*LN-94*/ 
/*LN-95*/         // they can claim all fees
/*LN-96*/         IERC20(toToken).transfer(maintainer, fee);
/*LN-97*/ 
/*LN-98*/         return toAmount;
/*LN-99*/     }
/*LN-100*/ 
/*LN-101*/     /**
/*LN-102*/      * @notice Claim accumulated fees (simplified)
/*LN-103*/      */
/*LN-104*/     function claimFees() external {
/*LN-105*/         require(msg.sender == maintainer, "Only maintainer");
/*LN-106*/ 
/*LN-107*/         // then claim all accumulated fees
/*LN-108*/         uint256 baseTokenBalance = IERC20(baseToken).balanceOf(address(this));
/*LN-109*/         uint256 quoteTokenBalance = IERC20(quoteToken).balanceOf(address(this));
/*LN-110*/ 
/*LN-111*/         // Transfer excess (fees) to maintainer
/*LN-112*/         if (baseTokenBalance > baseBalance) {
/*LN-113*/             uint256 excess = baseTokenBalance - baseBalance;
/*LN-114*/             IERC20(baseToken).transfer(maintainer, excess);
/*LN-115*/         }
/*LN-116*/ 
/*LN-117*/         if (quoteTokenBalance > quoteBalance) {
/*LN-118*/             uint256 excess = quoteTokenBalance - quoteBalance;
/*LN-119*/             IERC20(quoteToken).transfer(maintainer, excess);
/*LN-120*/         }
/*LN-121*/     }
/*LN-122*/ }
/*LN-123*/ 