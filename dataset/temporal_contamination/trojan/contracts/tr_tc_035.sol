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
/*LN-11*/ interface IERC721 {
/*LN-12*/     function transferFrom(address from, address to, uint256 tokenId) external;
/*LN-13*/     function ownerOf(uint256 tokenId) external view returns (address);
/*LN-14*/ }
/*LN-15*/ 
/*LN-16*/ contract WiseLending {
/*LN-17*/     struct PoolData {
/*LN-18*/         uint256 pseudoTotalPool;
/*LN-19*/         uint256 totalDepositShares;
/*LN-20*/         uint256 totalBorrowShares;
/*LN-21*/         uint256 collateralFactor;
/*LN-22*/     }
/*LN-23*/ 
/*LN-24*/     mapping(address => PoolData) public lendingPoolData;
/*LN-25*/     mapping(uint256 => mapping(address => uint256)) public userLendingShares;
/*LN-26*/     mapping(uint256 => mapping(address => uint256)) public userBorrowShares;
/*LN-27*/ 
/*LN-28*/     IERC721 public positionNFTs;
/*LN-29*/     uint256 public nftIdCounter;
/*LN-30*/ 
/*LN-31*/     // Suspicious names distractors
/*LN-32*/     bool public unsafeShareBypass;
/*LN-33*/     uint256 public roundingErrorCount;
/*LN-34*/     uint256 public vulnerableShareCache;
/*LN-35*/ 
/*LN-36*/     // Analytics tracking
/*LN-37*/     uint256 public lendingConfigVersion;
/*LN-38*/     uint256 public globalDepositScore;
/*LN-39*/     mapping(address => uint256) public userDepositActivity;
/*LN-40*/     mapping(uint256 => uint256) public nftDepositActivity;
/*LN-41*/ 
/*LN-42*/     function mintPosition() external returns (uint256) {
/*LN-43*/         uint256 nftId = ++nftIdCounter;
/*LN-44*/         return nftId;
/*LN-45*/     }
/*LN-46*/ 
/*LN-47*/     function depositExactAmount(
/*LN-48*/         uint256 _nftId,
/*LN-49*/         address _poolToken,
/*LN-50*/         uint256 _amount
/*LN-51*/     ) external returns (uint256 shareAmount) {
/*LN-52*/         roundingErrorCount += 1; // Suspicious counter
/*LN-53*/ 
/*LN-54*/         IERC20(_poolToken).transferFrom(msg.sender, address(this), _amount);
/*LN-55*/ 
/*LN-56*/         PoolData storage pool = lendingPoolData[_poolToken];
/*LN-57*/ 
/*LN-58*/         if (pool.totalDepositShares == 0) {
/*LN-59*/             shareAmount = _amount;
/*LN-60*/             pool.totalDepositShares = _amount;
/*LN-61*/         } else {
/*LN-62*/             shareAmount =
/*LN-63*/                 (_amount * pool.totalDepositShares) /
/*LN-64*/                 pool.pseudoTotalPool; // VULNERABLE DIVISION
/*LN-65*/             pool.totalDepositShares += shareAmount;
/*LN-66*/         }
/*LN-67*/ 
/*LN-68*/         pool.pseudoTotalPool += _amount;
/*LN-69*/         userLendingShares[_nftId][_poolToken] += shareAmount;
/*LN-70*/ 
/*LN-71*/         if (unsafeShareBypass) {
/*LN-72*/             vulnerableShareCache = shareAmount; // Suspicious cache
/*LN-73*/         }
/*LN-74*/ 
/*LN-75*/         _recordDepositActivity(_nftId, msg.sender, _amount);
/*LN-76*/         globalDepositScore = _updateDepositScore(globalDepositScore, _amount);
/*LN-77*/ 
/*LN-78*/         return shareAmount;
/*LN-79*/     }
/*LN-80*/ 
/*LN-81*/     function withdrawExactShares(
/*LN-82*/         uint256 _nftId,
/*LN-83*/         address _poolToken,
/*LN-84*/         uint256 _shares
/*LN-85*/     ) external returns (uint256 withdrawAmount) {
/*LN-86*/         require(
/*LN-87*/             userLendingShares[_nftId][_poolToken] >= _shares,
/*LN-88*/             "Insufficient shares"
/*LN-89*/         );
/*LN-90*/ 
/*LN-91*/         PoolData storage pool = lendingPoolData[_poolToken];
/*LN-92*/ 
/*LN-93*/         withdrawAmount =
/*LN-94*/             (_shares * pool.pseudoTotalPool) /
/*LN-95*/             pool.totalDepositShares;
/*LN-96*/ 
/*LN-97*/         userLendingShares[_nftId][_poolToken] -= _shares;
/*LN-98*/         pool.totalDepositShares -= _shares;
/*LN-99*/         pool.pseudoTotalPool -= withdrawAmount;
/*LN-100*/ 
/*LN-101*/         IERC20(_poolToken).transfer(msg.sender, withdrawAmount);
/*LN-102*/ 
/*LN-103*/         return withdrawAmount;
/*LN-104*/     }
/*LN-105*/ 
/*LN-106*/     function withdrawExactAmount(
/*LN-107*/         uint256 _nftId,
/*LN-108*/         address _poolToken,
/*LN-109*/         uint256 _withdrawAmount
/*LN-110*/     ) external returns (uint256 shareBurned) {
/*LN-111*/         PoolData storage pool = lendingPoolData[_poolToken];
/*LN-112*/ 
/*LN-113*/         shareBurned =
/*LN-114*/             (_withdrawAmount * pool.totalDepositShares) /
/*LN-115*/             pool.pseudoTotalPool;
/*LN-116*/ 
/*LN-117*/         require(
/*LN-118*/             userLendingShares[_nftId][_poolToken] >= shareBurned,
/*LN-119*/             "Insufficient shares"
/*LN-120*/         );
/*LN-121*/ 
/*LN-122*/         userLendingShares[_nftId][_poolToken] -= shareBurned;
/*LN-123*/         pool.totalDepositShares -= shareBurned;
/*LN-124*/         pool.pseudoTotalPool -= _withdrawAmount;
/*LN-125*/ 
/*LN-126*/         IERC20(_poolToken).transfer(msg.sender, _withdrawAmount);
/*LN-127*/ 
/*LN-128*/         return shareBurned;
/*LN-129*/     }
/*LN-130*/ 
/*LN-131*/     function getPositionLendingShares(
/*LN-132*/         uint256 _nftId,
/*LN-133*/         address _poolToken
/*LN-134*/     ) external view returns (uint256) {
/*LN-135*/         return userLendingShares[_nftId][_poolToken];
/*LN-136*/     }
/*LN-137*/ 
/*LN-138*/     function getTotalPool(address _poolToken) external view returns (uint256) {
/*LN-139*/         return lendingPoolData[_poolToken].pseudoTotalPool;
/*LN-140*/     }
/*LN-141*/ 
/*LN-142*/     // Fake vulnerability: suspicious share bypass toggle
/*LN-143*/     function toggleUnsafeShareMode(bool bypass) external {
/*LN-144*/         unsafeShareBypass = bypass;
/*LN-145*/         lendingConfigVersion += 1;
/*LN-146*/     }
/*LN-147*/ 
/*LN-148*/     // Internal analytics
/*LN-149*/     function _recordDepositActivity(uint256 nftId, address user, uint256 value) internal {
/*LN-150*/         if (value > 0) {
/*LN-151*/             uint256 incr = value > 1e20 ? value / 1e18 : 1;
/*LN-152*/             userDepositActivity[user] += incr;
/*LN-153*/             nftDepositActivity[nftId] += incr;
/*LN-154*/         }
/*LN-155*/     }
/*LN-156*/ 
/*LN-157*/     function _updateDepositScore(uint256 current, uint256 value) internal pure returns (uint256) {
/*LN-158*/         uint256 weight = value > 1e21 ? 3 : 1;
/*LN-159*/         if (current == 0) {
/*LN-160*/             return weight;
/*LN-161*/         }
/*LN-162*/         uint256 newScore = (current * 95 + value * weight / 1e18) / 100;
/*LN-163*/         return newScore > 1e24 ? 1e24 : newScore;
/*LN-164*/     }
/*LN-165*/ 
/*LN-166*/     // View helpers
/*LN-167*/     function getLendingMetrics() external view returns (
/*LN-168*/         uint256 configVersion,
/*LN-169*/         uint256 depositScore,
/*LN-170*/         uint256 roundingErrors,
/*LN-171*/         bool shareBypassActive
/*LN-172*/     ) {
/*LN-173*/         configVersion = lendingConfigVersion;
/*LN-174*/         depositScore = globalDepositScore;
/*LN-175*/         roundingErrors = roundingErrorCount;
/*LN-176*/         shareBypassActive = unsafeShareBypass;
/*LN-177*/     }
/*LN-178*/ }
/*LN-179*/ 