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
/*LN-21*/     mapping(address => uint256) public lastBalance;
/*LN-22*/     mapping(address => uint256) public lastUpdate;
/*LN-23*/     uint256 public constant WEIGHT_UPDATE_INTERVAL = 1 hours;
/*LN-24*/ 
/*LN-25*/     constructor() {
/*LN-26*/         totalWeight = 100;
/*LN-27*/     }
/*LN-28*/ 
/*LN-29*/     function addToken(address token, uint256 initialWeight) external {
/*LN-30*/         tokens[token] = Token({addr: token, balance: 0, weight: initialWeight});
/*LN-31*/         tokenList.push(token);
/*LN-32*/         lastBalance[token] = 0;
/*LN-33*/         lastUpdate[token] = block.timestamp;
/*LN-34*/     }
/*LN-35*/ 
/*LN-36*/     function swap(
/*LN-37*/         address tokenIn,
/*LN-38*/         address tokenOut,
/*LN-39*/         uint256 amountIn
/*LN-40*/     ) external returns (uint256 amountOut) {
/*LN-41*/         require(tokens[tokenIn].addr != address(0), "Invalid token");
/*LN-42*/         require(tokens[tokenOut].addr != address(0), "Invalid token");
/*LN-43*/ 
/*LN-44*/         IERC20(tokenIn).transfer(address(this), amountIn);
/*LN-45*/         tokens[tokenIn].balance += amountIn;
/*LN-46*/ 
/*LN-47*/         amountOut = calculateSwapAmount(tokenIn, tokenOut, amountIn);
/*LN-48*/ 
/*LN-49*/         require(
/*LN-50*/             tokens[tokenOut].balance >= amountOut,
/*LN-51*/             "Insufficient liquidity"
/*LN-52*/         );
/*LN-53*/         tokens[tokenOut].balance -= amountOut;
/*LN-54*/         IERC20(tokenOut).transfer(msg.sender, amountOut);
/*LN-55*/ 
/*LN-56*/         return amountOut;
/*LN-57*/     }
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
/*LN-68*/         uint256 numerator = balanceOut * amountIn * weightOut;
/*LN-69*/         uint256 denominator = tokens[tokenIn].balance *
/*LN-70*/             weightIn +
/*LN-71*/             amountIn *
/*LN-72*/             weightOut;
/*LN-73*/ 
/*LN-74*/         return numerator / denominator;
/*LN-75*/     }
/*LN-76*/ 
/*LN-77*/     function updateWeights() external {
/*LN-78*/         require(block.timestamp - lastUpdate[msg.sender] >= WEIGHT_UPDATE_INTERVAL, "Wait for update interval");
/*LN-79*/ 
/*LN-80*/         uint256 totalValue = 0;
/*LN-81*/ 
/*LN-82*/         for (uint256 i = 0; i < tokenList.length; i++) {
/*LN-83*/             address token = tokenList[i];
/*LN-84*/             totalValue += (tokens[token].balance + lastBalance[token]) / 2;
/*LN-85*/         }
/*LN-86*/ 
/*LN-87*/         for (uint256 i = 0; i < tokenList.length; i++) {
/*LN-88*/             address token = tokenList[i];
/*LN-89*/             tokens[token].weight = ((tokens[token].balance + lastBalance[token]) / 2 * 100) / totalValue;
/*LN-90*/             lastBalance[token] = tokens[token].balance;
/*LN-91*/             lastUpdate[token] = block.timestamp;
/*LN-92*/         }
/*LN-93*/     }
/*LN-94*/ 
/*LN-95*/     function getWeight(address token) external view returns (uint256) {
/*LN-96*/         return tokens[token].weight;
/*LN-97*/     }
/*LN-98*/ 
/*LN-99*/     function addLiquidity(address token, uint256 amount) external {
/*LN-100*/         require(tokens[token].addr != address(0), "Invalid token");
/*LN-101*/         IERC20(token).transfer(address(this), amount);
/*LN-102*/         tokens[token].balance += amount;
/*LN-103*/     }
/*LN-104*/ }
/*LN-105*/ 