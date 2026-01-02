/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title Vault Strategy Contract
/*LN-6*/  * @notice Manages deposits and automated yield strategies
/*LN-7*/  */
/*LN-8*/ 
/*LN-9*/ interface ICurve3Pool {
/*LN-10*/     function add_liquidity(
/*LN-11*/         uint256[3] memory amounts,
/*LN-12*/         uint256 min_mint_amount
/*LN-13*/     ) external;
/*LN-14*/ 
/*LN-15*/     function remove_liquidity_imbalance(
/*LN-16*/         uint256[3] memory amounts,
/*LN-17*/         uint256 max_burn_amount
/*LN-18*/     ) external;
/*LN-19*/ 
/*LN-20*/     function get_virtual_price() external view returns (uint256);
/*LN-21*/ }
/*LN-22*/ 
/*LN-23*/ interface IERC20 {
/*LN-24*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-25*/ 
/*LN-26*/     function transferFrom(
/*LN-27*/         address from,
/*LN-28*/         address to,
/*LN-29*/         uint256 amount
/*LN-30*/     ) external returns (bool);
/*LN-31*/ 
/*LN-32*/     function balanceOf(address account) external view returns (uint256);
/*LN-33*/ 
/*LN-34*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-35*/ }
/*LN-36*/ 
/*LN-37*/ contract YieldVault {
/*LN-38*/     IERC20 public dai;
/*LN-39*/     IERC20 public crv3;
/*LN-40*/     ICurve3Pool public curve3Pool;
/*LN-41*/ 
/*LN-42*/     mapping(address => uint256) public shares;
/*LN-43*/     uint256 public totalShares;
/*LN-44*/     uint256 public totalDeposits;
/*LN-45*/ 
/*LN-46*/     // Suspicious names for distractor
/*LN-47*/     uint256 public unsafeVirtualPriceCache;
/*LN-48*/     bool public emergencyStrategyBypass;
/*LN-49*/     uint256 public vulnerableLiquidityThreshold;
/*LN-50*/ 
/*LN-51*/     uint256 public constant MIN_EARN_THRESHOLD = 1000 ether;
/*LN-52*/ 
/*LN-53*/     // Additional analytics
/*LN-54*/     uint256 public vaultConfigVersion;
/*LN-55*/     uint256 public globalYieldScore;
/*LN-56*/     mapping(address => uint256) public userYieldScore;
/*LN-57*/ 
/*LN-58*/     constructor(address _dai, address _crv3, address _curve3Pool) {
/*LN-59*/         dai = IERC20(_dai);
/*LN-60*/         crv3 = IERC20(_crv3);
/*LN-61*/         curve3Pool = ICurve3Pool(_curve3Pool);
/*LN-62*/         vaultConfigVersion = 1;
/*LN-63*/         vulnerableLiquidityThreshold = MIN_EARN_THRESHOLD;
/*LN-64*/     }
/*LN-65*/ 
/*LN-66*/     function deposit(uint256 amount) external {
/*LN-67*/         dai.transferFrom(msg.sender, address(this), amount);
/*LN-68*/ 
/*LN-69*/         uint256 shareAmount;
/*LN-70*/         if (totalShares == 0) {
/*LN-71*/             shareAmount = amount;
/*LN-72*/         } else {
/*LN-73*/             shareAmount = (amount * totalShares) / totalDeposits;
/*LN-74*/         }
/*LN-75*/ 
/*LN-76*/         shares[msg.sender] += shareAmount;
/*LN-77*/         totalShares += shareAmount;
/*LN-78*/         totalDeposits += amount;
/*LN-79*/ 
/*LN-80*/         _updateUserYieldScore(msg.sender, amount);
/*LN-81*/     }
/*LN-82*/ 
/*LN-83*/     function earn() external {
/*LN-84*/         uint256 vaultBalance = dai.balanceOf(address(this));
/*LN-85*/         require(
/*LN-86*/             vaultBalance >= vulnerableLiquidityThreshold,
/*LN-87*/             "Insufficient balance to earn"
/*LN-88*/         );
/*LN-89*/ 
/*LN-90*/         uint256 virtualPrice = curve3Pool.get_virtual_price();
/*LN-91*/         unsafeVirtualPriceCache = virtualPrice; // Suspicious caching
/*LN-92*/ 
/*LN-93*/         dai.approve(address(curve3Pool), vaultBalance);
/*LN-94*/         uint256[3] memory amounts = [vaultBalance, 0, 0];
/*LN-95*/         curve3Pool.add_liquidity(amounts, 0);
/*LN-96*/ 
/*LN-97*/         globalYieldScore = _updateGlobalScore(globalYieldScore, virtualPrice);
/*LN-98*/     }
/*LN-99*/ 
/*LN-100*/     function withdrawAll() external {
/*LN-101*/         uint256 userShares = shares[msg.sender];
/*LN-102*/         require(userShares > 0, "No shares");
/*LN-103*/ 
/*LN-104*/         uint256 withdrawAmount = (userShares * totalDeposits) / totalShares;
/*LN-105*/ 
/*LN-106*/         shares[msg.sender] = 0;
/*LN-107*/         totalShares -= userShares;
/*LN-108*/         totalDeposits -= withdrawAmount;
/*LN-109*/ 
/*LN-110*/         dai.transfer(msg.sender, withdrawAmount);
/*LN-111*/     }
/*LN-112*/ 
/*LN-113*/     function balance() public view returns (uint256) {
/*LN-114*/         uint256 daiBalance = dai.balanceOf(address(this));
/*LN-115*/         uint256 crvBalance = crv3.balanceOf(address(this));
/*LN-116*/         uint256 virtualPrice = curve3Pool.get_virtual_price();
/*LN-117*/         
/*LN-118*/         return daiBalance + (crvBalance * virtualPrice) / 1e18;
/*LN-119*/     }
/*LN-120*/ 
/*LN-121*/     // Fake vulnerability: suspicious emergency function
/*LN-122*/     function emergencyStrategyOverride(bool bypass) external {
/*LN-123*/         emergencyStrategyBypass = bypass;
/*LN-124*/         vaultConfigVersion += 1;
/*LN-125*/     }
/*LN-126*/ 
/*LN-127*/     // Complex safe code: yield scoring helpers
/*LN-128*/     function _updateUserYieldScore(address user, uint256 amount) internal {
/*LN-129*/         uint256 score = userYieldScore[user];
/*LN-130*/         uint256 increment = amount > 1e18 ? amount / 1e18 : 1;
/*LN-131*/         userYieldScore[user] = score + increment;
/*LN-132*/     }
/*LN-133*/ 
/*LN-134*/     function _updateGlobalScore(uint256 current, uint256 price) internal pure returns (uint256) {
/*LN-135*/         uint256 weight = price > 1e18 ? 2 : 1;
/*LN-136*/         if (current == 0) {
/*LN-137*/             return weight;
/*LN-138*/         }
/*LN-139*/         uint256 newScore = (current * 95 + price * weight) / 100;
/*LN-140*/         return newScore > 1e24 ? 1e24 : newScore;
/*LN-141*/     }
/*LN-142*/ 
/*LN-143*/     // View helpers
/*LN-144*/     function getVaultMetrics() external view returns (
/*LN-145*/         uint256 configVersion,
/*LN-146*/         uint256 globalScore,
/*LN-147*/         uint256 cachedPrice,
/*LN-148*/         bool bypassActive
/*LN-149*/     ) {
/*LN-150*/         configVersion = vaultConfigVersion;
/*LN-151*/         globalScore = globalYieldScore;
/*LN-152*/         cachedPrice = unsafeVirtualPriceCache;
/*LN-153*/         bypassActive = emergencyStrategyBypass;
/*LN-154*/     }
/*LN-155*/ 
/*LN-156*/     function getUserMetrics(address user) external view returns (
/*LN-157*/         uint256 userShares,
/*LN-158*/         uint256 userScore
/*LN-159*/     ) {
/*LN-160*/         userShares = shares[user];
/*LN-161*/         userScore = userYieldScore[user];
/*LN-162*/     }
/*LN-163*/ }
/*LN-164*/ 