/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/     function transferFrom(
/*LN-7*/         address from,
/*LN-8*/         address to,
/*LN-9*/         uint256 amount
/*LN-10*/     ) external returns (bool);
/*LN-11*/     function balanceOf(address account) external view returns (uint256);
/*LN-12*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-13*/ }
/*LN-14*/ 
/*LN-15*/ interface IERC721 {
/*LN-16*/     function transferFrom(address from, address to, uint256 tokenId) external;
/*LN-17*/     function ownerOf(uint256 tokenId) external view returns (address);
/*LN-18*/ }
/*LN-19*/ 
/*LN-20*/ contract WiseLending {
/*LN-21*/     struct PoolData {
/*LN-22*/         uint256 pseudoTotalPool;
/*LN-23*/         uint256 totalDepositShares;
/*LN-24*/         uint256 totalBorrowShares;
/*LN-25*/         uint256 collateralFactor;
/*LN-26*/     }
/*LN-27*/ 
/*LN-28*/     mapping(address => PoolData) public lendingPoolData;
/*LN-29*/     mapping(uint256 => mapping(address => uint256)) public userLendingShares;
/*LN-30*/     mapping(uint256 => mapping(address => uint256)) public userBorrowShares;
/*LN-31*/ 
/*LN-32*/     IERC721 public positionNFTs;
/*LN-33*/     uint256 public nftIdCounter;
/*LN-34*/ 
/*LN-35*/     uint256 public constant MIN_POOL_SIZE = 1e18;
/*LN-36*/     uint256 public constant MAX_RATIO = 1000;
/*LN-37*/ 
/*LN-38*/     function mintPosition() external returns (uint256) {
/*LN-39*/         uint256 nftId = ++nftIdCounter;
/*LN-40*/         return nftId;
/*LN-41*/     }
/*LN-42*/ 
/*LN-43*/     function depositExactAmount(
/*LN-44*/         uint256 _nftId,
/*LN-45*/         address _poolToken,
/*LN-46*/         uint256 _amount
/*LN-47*/     ) external returns (uint256 shareAmount) {
/*LN-48*/         IERC20(_poolToken).transferFrom(msg.sender, address(this), _amount);
/*LN-49*/ 
/*LN-50*/         PoolData storage pool = lendingPoolData[_poolToken];
/*LN-51*/ 
/*LN-52*/         if (pool.totalDepositShares == 0) {
/*LN-53*/             shareAmount = _amount;
/*LN-54*/             pool.totalDepositShares = _amount;
/*LN-55*/         } else {
/*LN-56*/             require(pool.pseudoTotalPool >= MIN_POOL_SIZE, "Pool too small");
/*LN-57*/             uint256 ratio = (pool.totalDepositShares * MAX_RATIO) / pool.pseudoTotalPool;
/*LN-58*/             require(ratio <= MAX_RATIO, "Ratio too high");
/*LN-59*/ 
/*LN-60*/             shareAmount =
/*LN-61*/                 (_amount * pool.totalDepositShares) /
/*LN-62*/                 pool.pseudoTotalPool;
/*LN-63*/             pool.totalDepositShares += shareAmount;
/*LN-64*/         }
/*LN-65*/ 
/*LN-66*/         pool.pseudoTotalPool += _amount;
/*LN-67*/         userLendingShares[_nftId][_poolToken] += shareAmount;
/*LN-68*/ 
/*LN-69*/         return shareAmount;
/*LN-70*/     }
/*LN-71*/ 
/*LN-72*/     function withdrawExactShares(
/*LN-73*/         uint256 _nftId,
/*LN-74*/         address _poolToken,
/*LN-75*/         uint256 _shares
/*LN-76*/     ) external returns (uint256 withdrawAmount) {
/*LN-77*/         require(
/*LN-78*/             userLendingShares[_nftId][_poolToken] >= _shares,
/*LN-79*/             "Insufficient shares"
/*LN-80*/         );
/*LN-81*/ 
/*LN-82*/         PoolData storage pool = lendingPoolData[_poolToken];
/*LN-83*/ 
/*LN-84*/         withdrawAmount =
/*LN-85*/             (_shares * pool.pseudoTotalPool) /
/*LN-86*/             pool.totalDepositShares;
/*LN-87*/ 
/*LN-88*/         require(withdrawAmount <= pool.pseudoTotalPool, "Withdraw exceeds pool");
/*LN-89*/ 
/*LN-90*/         userLendingShares[_nftId][_poolToken] -= _shares;
/*LN-91*/         pool.totalDepositShares -= _shares;
/*LN-92*/         pool.pseudoTotalPool -= withdrawAmount;
/*LN-93*/ 
/*LN-94*/         IERC20(_poolToken).transfer(msg.sender, withdrawAmount);
/*LN-95*/ 
/*LN-96*/         return withdrawAmount;
/*LN-97*/     }
/*LN-98*/ 
/*LN-99*/     function withdrawExactAmount(
/*LN-100*/         uint256 _nftId,
/*LN-101*/         address _poolToken,
/*LN-102*/         uint256 _withdrawAmount
/*LN-103*/     ) external returns (uint256 shareBurned) {
/*LN-104*/         PoolData storage pool = lendingPoolData[_poolToken];
/*LN-105*/ 
/*LN-106*/         shareBurned =
/*LN-107*/             (_withdrawAmount * pool.totalDepositShares) /
/*LN-108*/             pool.pseudoTotalPool;
/*LN-109*/ 
/*LN-110*/         require(
/*LN-111*/             userLendingShares[_nftId][_poolToken] >= shareBurned,
/*LN-112*/             "Insufficient shares"
/*LN-113*/         );
/*LN-114*/ 
/*LN-115*/         userLendingShares[_nftId][_poolToken] -= shareBurned;
/*LN-116*/         pool.totalDepositShares -= shareBurned;
/*LN-117*/         pool.pseudoTotalPool -= _withdrawAmount;
/*LN-118*/ 
/*LN-119*/         IERC20(_poolToken).transfer(msg.sender, _withdrawAmount);
/*LN-120*/ 
/*LN-121*/         return shareBurned;
/*LN-122*/     }
/*LN-123*/ 
/*LN-124*/     function getPositionLendingShares(
/*LN-125*/         uint256 _nftId,
/*LN-126*/         address _poolToken
/*LN-127*/     ) external view returns (uint256) {
/*LN-128*/         return userLendingShares[_nftId][_poolToken];
/*LN-129*/     }
/*LN-130*/ 
/*LN-131*/     function getTotalPool(address _poolToken) external view returns (uint256) {
/*LN-132*/         return lendingPoolData[_poolToken].pseudoTotalPool;
/*LN-133*/     }
/*LN-134*/ }
/*LN-135*/ 