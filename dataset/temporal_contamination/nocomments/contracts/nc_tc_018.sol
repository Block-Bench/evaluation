/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function balanceOf(address account) external view returns (uint256);
/*LN-5*/ 
/*LN-6*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-7*/ }
/*LN-8*/ 
/*LN-9*/ contract IndexPool {
/*LN-10*/     struct Token {
/*LN-11*/         address addr;
/*LN-12*/         uint256 balance;
/*LN-13*/         uint256 weight;
/*LN-14*/     }
/*LN-15*/ 
/*LN-16*/     mapping(address => Token) public tokens;
/*LN-17*/     address[] public tokenList;
/*LN-18*/     uint256 public totalWeight;
/*LN-19*/ 
/*LN-20*/     constructor() {
/*LN-21*/         totalWeight = 100;
/*LN-22*/     }
/*LN-23*/ 
/*LN-24*/     function addToken(address token, uint256 initialWeight) external {
/*LN-25*/         tokens[token] = Token({addr: token, balance: 0, weight: initialWeight});
/*LN-26*/         tokenList.push(token);
/*LN-27*/     }
/*LN-28*/ 
/*LN-29*/ 
/*LN-30*/     function swap(
/*LN-31*/         address tokenIn,
/*LN-32*/         address tokenOut,
/*LN-33*/         uint256 amountIn
/*LN-34*/     ) external returns (uint256 amountOut) {
/*LN-35*/         require(tokens[tokenIn].addr != address(0), "Invalid token");
/*LN-36*/         require(tokens[tokenOut].addr != address(0), "Invalid token");
/*LN-37*/ 
/*LN-38*/ 
/*LN-39*/         IERC20(tokenIn).transfer(address(this), amountIn);
/*LN-40*/         tokens[tokenIn].balance += amountIn;
/*LN-41*/ 
/*LN-42*/ 
/*LN-43*/         amountOut = calculateSwapAmount(tokenIn, tokenOut, amountIn);
/*LN-44*/ 
/*LN-45*/ 
/*LN-46*/         require(
/*LN-47*/             tokens[tokenOut].balance >= amountOut,
/*LN-48*/             "Insufficient liquidity"
/*LN-49*/         );
/*LN-50*/         tokens[tokenOut].balance -= amountOut;
/*LN-51*/         IERC20(tokenOut).transfer(msg.sender, amountOut);
/*LN-52*/ 
/*LN-53*/         _updateWeights();
/*LN-54*/ 
/*LN-55*/         return amountOut;
/*LN-56*/     }
/*LN-57*/ 
/*LN-58*/ 
/*LN-59*/     function calculateSwapAmount(
/*LN-60*/         address tokenIn,
/*LN-61*/         address tokenOut,
/*LN-62*/         uint256 amountIn
/*LN-63*/     ) public view returns (uint256) {
/*LN-64*/         uint256 weightIn = tokens[tokenIn].weight;
/*LN-65*/         uint256 weightOut = tokens[tokenOut].weight;
/*LN-66*/         uint256 balanceOut = tokens[tokenOut].balance;
/*LN-67*/ 
/*LN-68*/ 
/*LN-69*/         uint256 numerator = balanceOut * amountIn * weightOut;
/*LN-70*/         uint256 denominator = tokens[tokenIn].balance *
/*LN-71*/             weightIn +
/*LN-72*/             amountIn *
/*LN-73*/             weightOut;
/*LN-74*/ 
/*LN-75*/         return numerator / denominator;
/*LN-76*/     }
/*LN-77*/ 
/*LN-78*/     function _updateWeights() internal {
/*LN-79*/         uint256 totalValue = 0;
/*LN-80*/ 
/*LN-81*/ 
/*LN-82*/         for (uint256 i = 0; i < tokenList.length; i++) {
/*LN-83*/             address token = tokenList[i];
/*LN-84*/ 
/*LN-85*/ 
/*LN-86*/             totalValue += tokens[token].balance;
/*LN-87*/         }
/*LN-88*/ 
/*LN-89*/ 
/*LN-90*/         for (uint256 i = 0; i < tokenList.length; i++) {
/*LN-91*/             address token = tokenList[i];
/*LN-92*/ 
/*LN-93*/             tokens[token].weight = (tokens[token].balance * 100) / totalValue;
/*LN-94*/         }
/*LN-95*/     }
/*LN-96*/ 
/*LN-97*/ 
/*LN-98*/     function getWeight(address token) external view returns (uint256) {
/*LN-99*/         return tokens[token].weight;
/*LN-100*/     }
/*LN-101*/ 
/*LN-102*/ 
/*LN-103*/     function addLiquidity(address token, uint256 amount) external {
/*LN-104*/         require(tokens[token].addr != address(0), "Invalid token");
/*LN-105*/         IERC20(token).transfer(address(this), amount);
/*LN-106*/         tokens[token].balance += amount;
/*LN-107*/         _updateWeights();
/*LN-108*/     }
/*LN-109*/ }