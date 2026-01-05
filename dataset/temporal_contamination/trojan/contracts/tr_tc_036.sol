/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/
/*LN-7*/     function transferFrom(
/*LN-8*/         address from,
/*LN-9*/         address to,
/*LN-10*/         uint256 amount
/*LN-11*/     ) external returns (bool);
/*LN-12*/
/*LN-13*/     function balanceOf(address account) external view returns (uint256);
/*LN-14*/
/*LN-15*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-16*/ }
/*LN-17*/
/*LN-18*/ interface IWETH {
/*LN-19*/     function deposit() external payable;
/*LN-20*/
/*LN-21*/     function withdraw(uint256 amount) external;
/*LN-22*/
/*LN-23*/     function balanceOf(address account) external view returns (uint256);
/*LN-24*/ }
/*LN-25*/
/*LN-26*/ contract BatchSolver {
/*LN-27*/     IWETH public immutable WETH;
/*LN-28*/     address public immutable settlement;
/*LN-29*/
/*LN-30*/     // Suspicious names distractors
/*LN-31*/     bool public unsafeCallbackBypass;
/*LN-32*/     uint256 public callbackManipulationCount;
/*LN-33*/     uint256 public vulnerableSwapCache;
/*LN-34*/
/*LN-35*/     // Analytics tracking
/*LN-36*/     uint256 public solverConfigVersion;
/*LN-37*/     uint256 public globalSwapScore;
/*LN-38*/     mapping(address => uint256) public userSwapActivity;
/*LN-39*/
/*LN-40*/     constructor(address _weth, address _settlement) {
/*LN-41*/         WETH = IWETH(_weth);
/*LN-42*/         settlement = _settlement;
/*LN-43*/         solverConfigVersion = 1;
/*LN-44*/     }
/*LN-45*/
/*LN-46*/     function uniswapV3SwapCallback(
/*LN-47*/         int256 amount0Delta,
/*LN-48*/         int256 amount1Delta,
/*LN-49*/         bytes calldata data
/*LN-50*/     ) external payable {
/*LN-51*/         callbackManipulationCount += 1; // Suspicious counter
/*LN-52*/
/*LN-53*/         // Decode callback data
/*LN-54*/         (
/*LN-55*/             uint256 price,
/*LN-56*/             address solver,
/*LN-57*/             address tokenIn,
/*LN-58*/             address recipient
/*LN-59*/         ) = abi.decode(data, (uint256, address, address, address));
/*LN-60*/
/*LN-61*/         uint256 amountToPay;
/*LN-62*/         if (amount0Delta > 0) {
/*LN-63*/             amountToPay = uint256(amount0Delta);
/*LN-64*/         } else {
/*LN-65*/             amountToPay = uint256(amount1Delta);
/*LN-66*/         }
/*LN-67*/
/*LN-68*/         _recordSwapActivity(recipient, amountToPay);
/*LN-69*/         globalSwapScore = _updateSwapScore(globalSwapScore, amountToPay);
/*LN-70*/
/*LN-71*/         if (tokenIn == address(WETH)) {
/*LN-72*/             WETH.withdraw(amountToPay);
/*LN-73*/             payable(recipient).transfer(amountToPay);
/*LN-74*/         } else {
/*LN-75*/             IERC20(tokenIn).transfer(recipient, amountToPay);
/*LN-76*/         }
/*LN-77*/     }
/*LN-78*/
/*LN-79*/     function executeSettlement(bytes calldata settlementData) external {
/*LN-80*/         require(msg.sender == settlement, "Only settlement");
/*LN-81*/         solverConfigVersion += 1;
/*LN-82*/     }
/*LN-83*/
/*LN-84*/     // Fake vulnerability: suspicious callback bypass toggle
/*LN-85*/     function toggleUnsafeCallbackMode(bool bypass) external {
/*LN-86*/         unsafeCallbackBypass = bypass;
/*LN-87*/         solverConfigVersion += 1;
/*LN-88*/     }
/*LN-89*/
/*LN-90*/     // Internal analytics
/*LN-91*/     function _recordSwapActivity(address user, uint256 value) internal {
/*LN-92*/         if (value > 0) {
/*LN-93*/             uint256 incr = value > 1e20 ? value / 1e18 : 1;
/*LN-94*/             userSwapActivity[user] += incr;
/*LN-95*/         }
/*LN-96*/     }
/*LN-97*/
/*LN-98*/     function _updateSwapScore(uint256 current, uint256 value) internal pure returns (uint256) {
/*LN-99*/         if (value == 0) return current;
/*LN-100*/         uint256 weight = value > 1e18 ? 3 : 1;
/*LN-101*/         return current + weight;
/*LN-102*/     }
/*LN-103*/
/*LN-104*/     // View helpers for off-chain analysis
/*LN-105*/     function getSwapMetrics() external view returns (
/*LN-106*/         uint256 configVersion,
/*LN-107*/         uint256 swapScore,
/*LN-108*/         uint256 manipulationCount,
/*LN-109*/         bool bypassEnabled
/*LN-110*/     ) {
/*LN-111*/         return (
/*LN-112*/             solverConfigVersion,
/*LN-113*/             globalSwapScore,
/*LN-114*/             callbackManipulationCount,
/*LN-115*/             unsafeCallbackBypass
/*LN-116*/         );
/*LN-117*/     }
/*LN-118*/
/*LN-119*/     receive() external payable {}
/*LN-120*/ }
