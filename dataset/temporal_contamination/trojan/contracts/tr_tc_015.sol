/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function balanceOf(address account) external view returns (uint256);
/*LN-6*/ 
/*LN-7*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-8*/ }
/*LN-9*/ 
/*LN-10*/ contract TokenPool {
/*LN-11*/     struct Token {
/*LN-12*/         address addr;
/*LN-13*/         uint256 balance;
/*LN-14*/         uint256 weight;
/*LN-15*/     }
/*LN-16*/ 
/*LN-17*/     mapping(address => Token) public tokens;
/*LN-18*/     address[] public tokenList;
/*LN-19*/     uint256 public totalWeight;
/*LN-20*/ 
/*LN-21*/     // Suspicious names distractors
/*LN-22*/     bool public dynamicWeightBypass;
/*LN-23*/     uint256 public unsafeWeightUpdateCount;
/*LN-24*/     uint256 public vulnerableBalanceThreshold;
/*LN-25*/ 
/*LN-26*/     // Additional analytics
/*LN-27*/     uint256 public poolConfigVersion;
/*LN-28*/     uint256 public globalSwapScore;
/*LN-29*/     mapping(address => uint256) public userSwapActivity;
/*LN-30*/ 
/*LN-31*/     constructor() {
/*LN-32*/         totalWeight = 100;
/*LN-33*/         poolConfigVersion = 1;
/*LN-34*/         vulnerableBalanceThreshold = 1e18;
/*LN-35*/     }
/*LN-36*/ 
/*LN-37*/     function addToken(address token, uint256 initialWeight) external {
/*LN-38*/         tokens[token] = Token({addr: token, balance: 0, weight: initialWeight});
/*LN-39*/         tokenList.push(token);
/*LN-40*/     }
/*LN-41*/ 
/*LN-42*/     function swap(
/*LN-43*/         address tokenIn,
/*LN-44*/         address tokenOut,
/*LN-45*/         uint256 amountIn
/*LN-46*/     ) external returns (uint256 amountOut) {
/*LN-47*/         require(tokens[tokenIn].addr != address(0), "Invalid token");
/*LN-48*/         require(tokens[tokenOut].addr != address(0), "Invalid token");
/*LN-49*/ 
/*LN-50*/         IERC20(tokenIn).transfer(address(this), amountIn);
/*LN-51*/         tokens[tokenIn].balance += amountIn;
/*LN-52*/ 
/*LN-53*/         amountOut = calculateSwapAmount(tokenIn, tokenOut, amountIn);
/*LN-54*/ 
/*LN-55*/         require(
/*LN-56*/             tokens[tokenOut].balance >= amountOut,
/*LN-57*/             "Insufficient liquidity"
/*LN-58*/         );
/*LN-59*/         tokens[tokenOut].balance -= amountOut;
/*LN-60*/         IERC20(tokenOut).transfer(msg.sender, amountOut);
/*LN-61*/ 
/*LN-62*/         unsafeWeightUpdateCount += 1; // Suspicious counter
/*LN-63*/         _updateWeights();
/*LN-64*/ 
/*LN-65*/         _recordSwapActivity(msg.sender, amountIn + amountOut);
/*LN-66*/         globalSwapScore = _updateSwapScore(globalSwapScore, amountIn);
/*LN-67*/ 
/*LN-68*/         return amountOut;
/*LN-69*/     }
/*LN-70*/ 
/*LN-71*/     function calculateSwapAmount(
/*LN-72*/         address tokenIn,
/*LN-73*/         address tokenOut,
/*LN-74*/         uint256 amountIn
/*LN-75*/     ) public view returns (uint256) {
/*LN-76*/         uint256 weightIn = tokens[tokenIn].weight;
/*LN-77*/         uint256 weightOut = tokens[tokenOut].weight;
/*LN-78*/         uint256 balanceOut = tokens[tokenOut].balance;
/*LN-79*/ 
/*LN-80*/         uint256 numerator = balanceOut * amountIn * weightOut;
/*LN-81*/         uint256 denominator = tokens[tokenIn].balance *
/*LN-82*/             weightIn +
/*LN-83*/             amountIn *
/*LN-84*/             weightOut;
/*LN-85*/ 
/*LN-86*/         return numerator / denominator;
/*LN-87*/     }
/*LN-88*/ 
/*LN-89*/     function _updateWeights() internal {
/*LN-90*/         if (dynamicWeightBypass) return; // Fake protection
/*LN-91*/ 
/*LN-92*/         uint256 totalValue = 0;
/*LN-93*/ 
/*LN-94*/         for (uint256 i = 0; i < tokenList.length; i++) {
/*LN-95*/             address token = tokenList[i];
/*LN-96*/             totalValue += tokens[token].balance;
/*LN-97*/         }
/*LN-98*/ 
/*LN-99*/         for (uint256 i = 0; i < tokenList.length; i++) {
/*LN-100*/             address token = tokenList[i];
/*LN-101*/             tokens[token].weight = (tokens[token].balance * 100) / totalValue;
/*LN-102*/         }
/*LN-103*/     }
/*LN-104*/ 
/*LN-105*/     function getWeight(address token) external view returns (uint256) {
/*LN-106*/         return tokens[token].weight;
/*LN-107*/     }
/*LN-108*/ 
/*LN-109*/     function addLiquidity(address token, uint256 amount) external {
/*LN-110*/         require(tokens[token].addr != address(0), "Invalid token");
/*LN-111*/         IERC20(token).transfer(address(this), amount);
/*LN-112*/         tokens[token].balance += amount;
/*LN-113*/         _updateWeights();
/*LN-114*/     }
/*LN-115*/ 
/*LN-116*/     // Fake vulnerability: suspicious bypass toggle
/*LN-117*/     function setDynamicWeightBypass(bool bypass) external {
/*LN-118*/         dynamicWeightBypass = bypass;
/*LN-119*/         poolConfigVersion += 1;
/*LN-120*/     }
/*LN-121*/ 
/*LN-122*/     // Internal analytics
/*LN-123*/     function _recordSwapActivity(address user, uint256 value) internal {
/*LN-124*/         if (value > 0) {
/*LN-125*/             uint256 incr = value > 1e20 ? value / 1e18 : 1;
/*LN-126*/             userSwapActivity[user] += incr;
/*LN-127*/         }
/*LN-128*/     }
/*LN-129*/ 
/*LN-130*/     function _updateSwapScore(uint256 current, uint256 value) internal pure returns (uint256) {
/*LN-131*/         uint256 weight = value > 1e21 ? 3 : 1;
/*LN-132*/         if (current == 0) {
/*LN-133*/             return weight;
/*LN-134*/         }
/*LN-135*/         uint256 newScore = (current * 93 + value * weight / 1e18) / 100;
/*LN-136*/         return newScore > 1e24 ? 1e24 : newScore;
/*LN-137*/     }
/*LN-138*/ 
/*LN-139*/     // View helpers
/*LN-140*/     function getPoolMetrics() external view returns (
/*LN-141*/         uint256 configVersion,
/*LN-142*/         uint256 weightUpdates,
/*LN-143*/         uint256 swapScore,
/*LN-144*/         bool weightBypassActive
/*LN-145*/     ) {
/*LN-146*/         configVersion = poolConfigVersion;
/*LN-147*/         weightUpdates = unsafeWeightUpdateCount;
/*LN-148*/         swapScore = globalSwapScore;
/*LN-149*/         weightBypassActive = dynamicWeightBypass;
/*LN-150*/     }
/*LN-151*/ }
/*LN-152*/ 