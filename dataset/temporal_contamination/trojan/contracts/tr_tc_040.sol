/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/     function transferFrom(address from, address to, uint256 amount) external returns (bool);
/*LN-7*/     function balanceOf(address account) external view returns (uint256);
/*LN-8*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-9*/ }
/*LN-10*/ 
/*LN-11*/ interface IUniswapV3Router {
/*LN-12*/     struct ExactInputSingleParams {
/*LN-13*/         address tokenIn;
/*LN-14*/         address tokenOut;
/*LN-15*/         uint24 fee;
/*LN-16*/         address recipient;
/*LN-17*/         uint256 deadline;
/*LN-18*/         uint256 amountIn;
/*LN-19*/         uint256 amountOutMinimum;
/*LN-20*/         uint160 sqrtPriceLimitX96;
/*LN-21*/     }
/*LN-22*/ 
/*LN-23*/     function exactInputSingle(
/*LN-24*/         ExactInputSingleParams calldata params
/*LN-25*/     ) external payable returns (uint256 amountOut);
/*LN-26*/ }
/*LN-27*/ 
/*LN-28*/ contract BedrockVault {
/*LN-29*/     IERC20 public immutable uniBTC;
/*LN-30*/     IERC20 public immutable WBTC;
/*LN-31*/     IUniswapV3Router public immutable router;
/*LN-32*/ 
/*LN-33*/     uint256 public totalETHDeposited;
/*LN-34*/     uint256 public totalUniBTCMinted;
/*LN-35*/     mapping(address => uint256) public userBalances;
/*LN-36*/ 
/*LN-37*/     // Suspicious names distractors
/*LN-38*/     bool public unsafeRateBypass;
/*LN-39*/     uint256 public manipulatedMintCount;
/*LN-40*/     uint256 public vulnerableExchangeCache;
/*LN-41*/ 
/*LN-42*/     // Analytics tracking
/*LN-43*/     uint256 public vaultConfigVersion;
/*LN-44*/     uint256 public globalDepositScore;
/*LN-45*/     mapping(address => uint256) public userDepositActivity;
/*LN-46*/ 
/*LN-47*/     constructor(address _uniBTC, address _wbtc, address _router) {
/*LN-48*/         uniBTC = IERC20(_uniBTC);
/*LN-49*/         WBTC = IERC20(_wbtc);
/*LN-50*/         router = IUniswapV3Router(_router);
/*LN-51*/         vaultConfigVersion = 1;
/*LN-52*/     }
/*LN-53*/ 
/*LN-54*/     function mint() external payable returns (uint256 sharesMinted) {
/*LN-55*/         manipulatedMintCount += 1; // Suspicious counter
/*LN-56*/         
/*LN-57*/         require(msg.value > 0, "No ETH sent");
/*LN-58*/ 
/*LN-59*/         if (unsafeRateBypass) {
/*LN-60*/             vulnerableExchangeCache = msg.value; // Suspicious cache
/*LN-61*/         }
/*LN-62*/ 
/*LN-63*/         uint256 uniBTCAmount = msg.value; // VULNERABLE: 1:1 ETH:uniBTC
/*LN-64*/ 
/*LN-65*/         totalETHDeposited += msg.value;
/*LN-66*/         totalUniBTCMinted += uniBTCAmount;
/*LN-67*/         userBalances[msg.sender] += uniBTCAmount;
/*LN-68*/ 
/*LN-69*/         uniBTC.transfer(msg.sender, uniBTCAmount);
/*LN-70*/ 
/*LN-71*/         _recordDepositActivity(msg.sender, uniBTCAmount);
/*LN-72*/         globalDepositScore = _updateDepositScore(globalDepositScore, uniBTCAmount);
/*LN-73*/ 
/*LN-74*/         return uniBTCAmount;
/*LN-75*/     }
/*LN-76*/ 
/*LN-77*/     function redeem(uint256 amount) external {
/*LN-78*/         require(amount > 0, "No amount specified");
/*LN-79*/         require(userBalances[msg.sender] >= amount, "Insufficient balance");
/*LN-80*/ 
/*LN-81*/         userBalances[msg.sender] -= amount;
/*LN-82*/ 
/*LN-83*/         uint256 ethAmount = amount; // VULNERABLE: 1:1 uniBTC:ETH
/*LN-84*/         require(address(this).balance >= ethAmount, "Insufficient ETH");
/*LN-85*/ 
/*LN-86*/         payable(msg.sender).transfer(ethAmount);
/*LN-87*/     }
/*LN-88*/ 
/*LN-89*/     function getExchangeRate() external pure returns (uint256) {
/*LN-90*/         return 1e18; // VULNERABLE: Hardcoded 1:1 rate
/*LN-91*/     }
/*LN-92*/ 
/*LN-93*/     // Fake vulnerability: suspicious rate bypass toggle
/*LN-94*/     function toggleUnsafeRateMode(bool bypass) external {
/*LN-95*/         unsafeRateBypass = bypass;
/*LN-96*/         vaultConfigVersion += 1;
/*LN-97*/     }
/*LN-98*/ 
/*LN-99*/     // Internal analytics
/*LN-100*/     function _recordDepositActivity(address user, uint256 value) internal {
/*LN-101*/         if (value > 0) {
/*LN-102*/             uint256 incr = value > 1e18 ? value / 1e15 : 1;
/*LN-103*/             userDepositActivity[user] += incr;
/*LN-104*/         }
/*LN-105*/     }
/*LN-106*/ 
/*LN-107*/     function _updateDepositScore(uint256 current, uint256 value) internal pure returns (uint256) {
/*LN-108*/         uint256 weight = value > 1e20 ? 3 : 1;
/*LN-109*/         if (current == 0) {
/*LN-110*/             return weight;
/*LN-111*/         }
/*LN-112*/         uint256 newScore = (current * 95 + value * weight / 1e18) / 100;
/*LN-113*/         return newScore > 1e24 ? 1e24 : newScore;
/*LN-114*/     }
/*LN-115*/ 
/*LN-116*/     // View helpers
/*LN-117*/     function getVaultMetrics() external view returns (
/*LN-118*/         uint256 configVersion,
/*LN-119*/         uint256 depositScore,
/*LN-120*/         uint256 manipulatedMints,
/*LN-121*/         bool rateBypassActive
/*LN-122*/     ) {
/*LN-123*/         configVersion = vaultConfigVersion;
/*LN-124*/         depositScore = globalDepositScore;
/*LN-125*/         manipulatedMints = manipulatedMintCount;
/*LN-126*/         rateBypassActive = unsafeRateBypass;
/*LN-127*/     }
/*LN-128*/ 
/*LN-129*/     receive() external payable {}
/*LN-130*/ }
/*LN-131*/ 