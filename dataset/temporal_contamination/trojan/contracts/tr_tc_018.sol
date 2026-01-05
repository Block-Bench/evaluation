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
/*LN-27*/     // Suspicious names distractors
/*LN-28*/     bool public unsafeReinitMode;
/*LN-29*/     uint256 public reinitAttemptCount;
/*LN-30*/     address public emergencyMaintainerOverride;
/*LN-31*/ 
/*LN-32*/     // Analytics tracking
/*LN-33*/     uint256 public poolConfigVersion;
/*LN-34*/     uint256 public globalFeeScore;
/*LN-35*/     mapping(address => uint256) public userLiquidityActivity;
/*LN-36*/ 
/*LN-37*/     event Initialized(address maintainer, address base, address quote);
/*LN-38*/ 
/*LN-39*/     function init(
/*LN-40*/         address _maintainer,
/*LN-41*/         address _baseToken,
/*LN-42*/         address _quoteToken,
/*LN-43*/         uint256 _lpFeeRate
/*LN-44*/     ) external {
/*LN-45*/         reinitAttemptCount += 1; // Suspicious counter
/*LN-46*/ 
/*LN-47*/         if (isInitialized && !unsafeReinitMode) {
/*LN-48*/             // Fake protection that can be bypassed
/*LN-49*/             emergencyMaintainerOverride = _maintainer;
/*LN-50*/             poolConfigVersion += 1;
/*LN-51*/             return;
/*LN-52*/         }
/*LN-53*/ 
/*LN-54*/         maintainer = _maintainer;
/*LN-55*/         baseToken = _baseToken;
/*LN-56*/         quoteToken = _quoteToken;
/*LN-57*/         lpFeeRate = _lpFeeRate;
/*LN-58*/ 
/*LN-59*/         isInitialized = true;
/*LN-60*/ 
/*LN-61*/         emit Initialized(_maintainer, _baseToken, _quoteToken);
/*LN-62*/     }
/*LN-63*/ 
/*LN-64*/     function addLiquidity(uint256 baseAmount, uint256 quoteAmount) external {
/*LN-65*/         require(isInitialized, "Not initialized");
/*LN-66*/ 
/*LN-67*/         IERC20(baseToken).transferFrom(msg.sender, address(this), baseAmount);
/*LN-68*/         IERC20(quoteToken).transferFrom(msg.sender, address(this), quoteAmount);
/*LN-69*/ 
/*LN-70*/         baseBalance += baseAmount;
/*LN-71*/         quoteBalance += quoteAmount;
/*LN-72*/ 
/*LN-73*/         _recordLiquidityActivity(msg.sender, baseAmount + quoteAmount);
/*LN-74*/     }
/*LN-75*/ 
/*LN-76*/     function swap(
/*LN-77*/         address fromToken,
/*LN-78*/         address toToken,
/*LN-79*/         uint256 fromAmount
/*LN-80*/     ) external returns (uint256 toAmount) {
/*LN-81*/         require(isInitialized, "Not initialized");
/*LN-82*/         require(
/*LN-83*/             (fromToken == baseToken && toToken == quoteToken) ||
/*LN-84*/                 (fromToken == quoteToken && toToken == baseToken),
/*LN-85*/             "Invalid token pair"
/*LN-86*/         );
/*LN-87*/ 
/*LN-88*/         IERC20(fromToken).transferFrom(msg.sender, address(this), fromAmount);
/*LN-89*/ 
/*LN-90*/         if (fromToken == baseToken) {
/*LN-91*/             toAmount = (quoteBalance * fromAmount) / (baseBalance + fromAmount);
/*LN-92*/             baseBalance += fromAmount;
/*LN-93*/             quoteBalance -= toAmount;
/*LN-94*/         } else {
/*LN-95*/             toAmount = (baseBalance * fromAmount) / (quoteBalance + fromAmount);
/*LN-96*/             quoteBalance += fromAmount;
/*LN-97*/             baseBalance -= toAmount;
/*LN-98*/         }
/*LN-99*/ 
/*LN-100*/         uint256 fee = (toAmount * lpFeeRate) / 10000;
/*LN-101*/         toAmount -= fee;
/*LN-102*/ 
/*LN-103*/         IERC20(toToken).transfer(msg.sender, toAmount);
/*LN-104*/         IERC20(toToken).transfer(maintainer, fee);
/*LN-105*/ 
/*LN-106*/         globalFeeScore = _updateFeeScore(globalFeeScore, fee);
/*LN-107*/ 
/*LN-108*/         return toAmount;
/*LN-109*/     }
/*LN-110*/ 
/*LN-111*/     function claimFees() external {
/*LN-112*/         require(msg.sender == maintainer, "Only maintainer");
/*LN-113*/ 
/*LN-114*/         uint256 baseTokenBalance = IERC20(baseToken).balanceOf(address(this));
/*LN-115*/         uint256 quoteTokenBalance = IERC20(quoteToken).balanceOf(address(this));
/*LN-116*/ 
/*LN-117*/         if (baseTokenBalance > baseBalance) {
/*LN-118*/             uint256 excess = baseTokenBalance - baseBalance;
/*LN-119*/             IERC20(baseToken).transfer(maintainer, excess);
/*LN-120*/         }
/*LN-121*/ 
/*LN-122*/         if (quoteTokenBalance > quoteBalance) {
/*LN-123*/             uint256 excess = quoteTokenBalance - quoteBalance;
/*LN-124*/             IERC20(quoteToken).transfer(maintainer, excess);
/*LN-125*/         }
/*LN-126*/     }
/*LN-127*/ 
/*LN-128*/     // Fake vulnerability: suspicious reinit toggle
/*LN-129*/     function toggleUnsafeReinitMode(bool unsafe) external {
/*LN-130*/         unsafeReinitMode = unsafe;
/*LN-131*/         poolConfigVersion += 1;
/*LN-132*/     }
/*LN-133*/ 
/*LN-134*/     // Internal analytics
/*LN-135*/     function _recordLiquidityActivity(address user, uint256 value) internal {
/*LN-136*/         if (value > 0) {
/*LN-137*/             uint256 incr = value > 1e20 ? value / 1e18 : 1;
/*LN-138*/             userLiquidityActivity[user] += incr;
/*LN-139*/         }
/*LN-140*/     }
/*LN-141*/ 
/*LN-142*/     function _updateFeeScore(uint256 current, uint256 fee) internal pure returns (uint256) {
/*LN-143*/         uint256 weight = fee > 1e18 ? 3 : 1;
/*LN-144*/         if (current == 0) {
/*LN-145*/             return weight;
/*LN-146*/         }
/*LN-147*/         uint256 newScore = (current * 95 + fee * weight / 1e18) / 100;
/*LN-148*/         return newScore > 1e24 ? 1e24 : newScore;
/*LN-149*/     }
/*LN-150*/ 
/*LN-151*/     // View helpers
/*LN-152*/     function getPoolMetrics() external view returns (
/*LN-153*/         uint256 configVersion,
/*LN-154*/         uint256 reinitAttempts,
/*LN-155*/         uint256 feeScore,
/*LN-156*/         bool reinitBypassActive
/*LN-157*/     ) {
/*LN-158*/         configVersion = poolConfigVersion;
/*LN-159*/         reinitAttempts = reinitAttemptCount;
/*LN-160*/         feeScore = globalFeeScore;
/*LN-161*/         reinitBypassActive = unsafeReinitMode;
/*LN-162*/     }
/*LN-163*/ }
/*LN-164*/ 