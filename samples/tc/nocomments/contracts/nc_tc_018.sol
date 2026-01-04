/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function balanceOf(address account) external view returns (uint256);
/*LN-5*/ 
/*LN-6*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-7*/ 
/*LN-8*/     function transferFrom(
/*LN-9*/         address from,
/*LN-10*/         address to,
/*LN-11*/         uint256 amount
/*LN-12*/     ) external returns (bool);
/*LN-13*/ }
/*LN-14*/ 
/*LN-15*/ contract LiquidityPool {
/*LN-16*/     address public maintainer;
/*LN-17*/     address public baseToken;
/*LN-18*/     address public quoteToken;
/*LN-19*/ 
/*LN-20*/     uint256 public lpFeeRate;
/*LN-21*/     uint256 public baseBalance;
/*LN-22*/     uint256 public quoteBalance;
/*LN-23*/ 
/*LN-24*/     bool public isInitialized;
/*LN-25*/ 
/*LN-26*/     event Initialized(address maintainer, address base, address quote);
/*LN-27*/ 
/*LN-28*/     function init(
/*LN-29*/         address _maintainer,
/*LN-30*/         address _baseToken,
/*LN-31*/         address _quoteToken,
/*LN-32*/         uint256 _lpFeeRate
/*LN-33*/     ) external {
/*LN-34*/ 
/*LN-35*/         maintainer = _maintainer;
/*LN-36*/         baseToken = _baseToken;
/*LN-37*/         quoteToken = _quoteToken;
/*LN-38*/         lpFeeRate = _lpFeeRate;
/*LN-39*/ 
/*LN-40*/         isInitialized = true;
/*LN-41*/ 
/*LN-42*/         emit Initialized(_maintainer, _baseToken, _quoteToken);
/*LN-43*/     }
/*LN-44*/ 
/*LN-45*/ 
/*LN-46*/     function addLiquidity(uint256 baseAmount, uint256 quoteAmount) external {
/*LN-47*/         require(isInitialized, "Not initialized");
/*LN-48*/ 
/*LN-49*/         IERC20(baseToken).transferFrom(msg.sender, address(this), baseAmount);
/*LN-50*/         IERC20(quoteToken).transferFrom(msg.sender, address(this), quoteAmount);
/*LN-51*/ 
/*LN-52*/         baseBalance += baseAmount;
/*LN-53*/         quoteBalance += quoteAmount;
/*LN-54*/     }
/*LN-55*/ 
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
/*LN-69*/ 
/*LN-70*/         IERC20(fromToken).transferFrom(msg.sender, address(this), fromAmount);
/*LN-71*/ 
/*LN-72*/ 
/*LN-73*/         if (fromToken == baseToken) {
/*LN-74*/             toAmount = (quoteBalance * fromAmount) / (baseBalance + fromAmount);
/*LN-75*/             baseBalance += fromAmount;
/*LN-76*/             quoteBalance -= toAmount;
/*LN-77*/         } else {
/*LN-78*/             toAmount = (baseBalance * fromAmount) / (quoteBalance + fromAmount);
/*LN-79*/             quoteBalance += fromAmount;
/*LN-80*/             baseBalance -= toAmount;
/*LN-81*/         }
/*LN-82*/ 
/*LN-83*/ 
/*LN-84*/         uint256 fee = (toAmount * lpFeeRate) / 10000;
/*LN-85*/         toAmount -= fee;
/*LN-86*/ 
/*LN-87*/ 
/*LN-88*/         IERC20(toToken).transfer(msg.sender, toAmount);
/*LN-89*/ 
/*LN-90*/ 
/*LN-91*/         IERC20(toToken).transfer(maintainer, fee);
/*LN-92*/ 
/*LN-93*/         return toAmount;
/*LN-94*/     }
/*LN-95*/ 
/*LN-96*/ 
/*LN-97*/     function claimFees() external {
/*LN-98*/         require(msg.sender == maintainer, "Only maintainer");
/*LN-99*/ 
/*LN-100*/ 
/*LN-101*/         uint256 baseTokenBalance = IERC20(baseToken).balanceOf(address(this));
/*LN-102*/         uint256 quoteTokenBalance = IERC20(quoteToken).balanceOf(address(this));
/*LN-103*/ 
/*LN-104*/ 
/*LN-105*/         if (baseTokenBalance > baseBalance) {
/*LN-106*/             uint256 excess = baseTokenBalance - baseBalance;
/*LN-107*/             IERC20(baseToken).transfer(maintainer, excess);
/*LN-108*/         }
/*LN-109*/ 
/*LN-110*/         if (quoteTokenBalance > quoteBalance) {
/*LN-111*/             uint256 excess = quoteTokenBalance - quoteBalance;
/*LN-112*/             IERC20(quoteToken).transfer(maintainer, excess);
/*LN-113*/         }
/*LN-114*/     }
/*LN-115*/ }