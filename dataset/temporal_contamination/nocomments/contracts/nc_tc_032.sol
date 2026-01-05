/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-5*/ 
/*LN-6*/     function transferFrom(
/*LN-7*/         address from,
/*LN-8*/         address to,
/*LN-9*/         uint256 amount
/*LN-10*/     ) external returns (bool);
/*LN-11*/ 
/*LN-12*/     function balanceOf(address account) external view returns (uint256);
/*LN-13*/ 
/*LN-14*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-15*/ }
/*LN-16*/ 
/*LN-17*/ interface IERC721 {
/*LN-18*/     function transferFrom(address from, address to, uint256 tokenId) external;
/*LN-19*/ 
/*LN-20*/     function ownerOf(uint256 tokenId) external view returns (address);
/*LN-21*/ }
/*LN-22*/ 
/*LN-23*/ contract IsolatedLending {
/*LN-24*/     struct PoolData {
/*LN-25*/         uint256 pseudoTotalPool;
/*LN-26*/         uint256 totalDepositShares;
/*LN-27*/         uint256 totalBorrowShares;
/*LN-28*/         uint256 collateralFactor;
/*LN-29*/     }
/*LN-30*/ 
/*LN-31*/     mapping(address => PoolData) public lendingPoolData;
/*LN-32*/     mapping(uint256 => mapping(address => uint256)) public userLendingShares;
/*LN-33*/     mapping(uint256 => mapping(address => uint256)) public userBorrowShares;
/*LN-34*/ 
/*LN-35*/     IERC721 public positionNFTs;
/*LN-36*/     uint256 public nftIdCounter;
/*LN-37*/ 
/*LN-38*/ 
/*LN-39*/     function mintPosition() external returns (uint256) {
/*LN-40*/         uint256 nftId = ++nftIdCounter;
/*LN-41*/         return nftId;
/*LN-42*/     }
/*LN-43*/ 
/*LN-44*/ 
/*LN-45*/     function depositExactAmount(
/*LN-46*/         uint256 _nftId,
/*LN-47*/         address _poolToken,
/*LN-48*/         uint256 _amount
/*LN-49*/     ) external returns (uint256 shareAmount) {
/*LN-50*/         IERC20(_poolToken).transferFrom(msg.sender, address(this), _amount);
/*LN-51*/ 
/*LN-52*/         PoolData storage pool = lendingPoolData[_poolToken];
/*LN-53*/ 
/*LN-54*/ 
/*LN-55*/         if (pool.totalDepositShares == 0) {
/*LN-56*/             shareAmount = _amount;
/*LN-57*/             pool.totalDepositShares = _amount;
/*LN-58*/         } else {
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
/*LN-72*/ 
/*LN-73*/     function withdrawExactShares(
/*LN-74*/         uint256 _nftId,
/*LN-75*/         address _poolToken,
/*LN-76*/         uint256 _shares
/*LN-77*/     ) external returns (uint256 withdrawAmount) {
/*LN-78*/         require(
/*LN-79*/             userLendingShares[_nftId][_poolToken] >= _shares,
/*LN-80*/             "Insufficient shares"
/*LN-81*/         );
/*LN-82*/ 
/*LN-83*/         PoolData storage pool = lendingPoolData[_poolToken];
/*LN-84*/ 
/*LN-85*/ 
/*LN-86*/         withdrawAmount =
/*LN-87*/             (_shares * pool.pseudoTotalPool) /
/*LN-88*/             pool.totalDepositShares;
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
/*LN-99*/ 
/*LN-100*/     function withdrawExactAmount(
/*LN-101*/         uint256 _nftId,
/*LN-102*/         address _poolToken,
/*LN-103*/         uint256 _withdrawAmount
/*LN-104*/     ) external returns (uint256 shareBurned) {
/*LN-105*/         PoolData storage pool = lendingPoolData[_poolToken];
/*LN-106*/ 
/*LN-107*/         shareBurned =
/*LN-108*/             (_withdrawAmount * pool.totalDepositShares) /
/*LN-109*/             pool.pseudoTotalPool;
/*LN-110*/ 
/*LN-111*/         require(
/*LN-112*/             userLendingShares[_nftId][_poolToken] >= shareBurned,
/*LN-113*/             "Insufficient shares"
/*LN-114*/         );
/*LN-115*/ 
/*LN-116*/         userLendingShares[_nftId][_poolToken] -= shareBurned;
/*LN-117*/         pool.totalDepositShares -= shareBurned;
/*LN-118*/         pool.pseudoTotalPool -= _withdrawAmount;
/*LN-119*/ 
/*LN-120*/         IERC20(_poolToken).transfer(msg.sender, _withdrawAmount);
/*LN-121*/ 
/*LN-122*/         return shareBurned;
/*LN-123*/     }
/*LN-124*/ 
/*LN-125*/ 
/*LN-126*/     function getPositionLendingShares(
/*LN-127*/         uint256 _nftId,
/*LN-128*/         address _poolToken
/*LN-129*/     ) external view returns (uint256) {
/*LN-130*/         return userLendingShares[_nftId][_poolToken];
/*LN-131*/     }
/*LN-132*/ 
/*LN-133*/ 
/*LN-134*/     function getTotalPool(address _poolToken) external view returns (uint256) {
/*LN-135*/         return lendingPoolData[_poolToken].pseudoTotalPool;
/*LN-136*/     }
/*LN-137*/ }