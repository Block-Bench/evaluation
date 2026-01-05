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
/*LN-18*/ interface IERC721 {
/*LN-19*/     function transferFrom(address from, address to, uint256 tokenId) external;
/*LN-20*/ 
/*LN-21*/     function ownerOf(uint256 tokenId) external view returns (address);
/*LN-22*/ }
/*LN-23*/ 
/*LN-24*/ contract IsolatedLending {
/*LN-25*/     struct PoolData {
/*LN-26*/         uint256 pseudoTotalPool;
/*LN-27*/         uint256 totalDepositShares;
/*LN-28*/         uint256 totalBorrowShares;
/*LN-29*/         uint256 collateralFactor;
/*LN-30*/     }
/*LN-31*/ 
/*LN-32*/     mapping(address => PoolData) public lendingPoolData;
/*LN-33*/     mapping(uint256 => mapping(address => uint256)) public userLendingShares;
/*LN-34*/     mapping(uint256 => mapping(address => uint256)) public userBorrowShares;
/*LN-35*/ 
/*LN-36*/     IERC721 public positionNFTs;
/*LN-37*/     uint256 public nftIdCounter;
/*LN-38*/ 
/*LN-39*/     /**
/*LN-40*/      * @notice Mint position NFT
/*LN-41*/      */
/*LN-42*/     function mintPosition() external returns (uint256) {
/*LN-43*/         uint256 nftId = ++nftIdCounter;
/*LN-44*/         return nftId;
/*LN-45*/     }
/*LN-46*/ 
/*LN-47*/     /**
/*LN-48*/      * @notice Deposit exact amount of tokens
/*LN-49*/      */
/*LN-50*/     function depositExactAmount(
/*LN-51*/         uint256 _nftId,
/*LN-52*/         address _poolToken,
/*LN-53*/         uint256 _amount
/*LN-54*/     ) external returns (uint256 shareAmount) {
/*LN-55*/         IERC20(_poolToken).transferFrom(msg.sender, address(this), _amount);
/*LN-56*/ 
/*LN-57*/         PoolData storage pool = lendingPoolData[_poolToken];
/*LN-58*/ 
/*LN-59*/         // (e.g., 2 wei and 1 wei), rounding errors become significant
/*LN-60*/ 
/*LN-61*/         if (pool.totalDepositShares == 0) {
/*LN-62*/             shareAmount = _amount;
/*LN-63*/             pool.totalDepositShares = _amount;
/*LN-64*/         } else {
/*LN-65*/ 
/*LN-66*/             shareAmount =
/*LN-67*/                 (_amount * pool.totalDepositShares) /
/*LN-68*/                 pool.pseudoTotalPool;
/*LN-69*/             pool.totalDepositShares += shareAmount;
/*LN-70*/         }
/*LN-71*/ 
/*LN-72*/         pool.pseudoTotalPool += _amount;
/*LN-73*/         userLendingShares[_nftId][_poolToken] += shareAmount;
/*LN-74*/ 
/*LN-75*/         return shareAmount;
/*LN-76*/     }
/*LN-77*/ 
/*LN-78*/     /**
/*LN-79*/      * @notice Withdraw exact shares amount
/*LN-80*/      */
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
/*LN-93*/         // withdrawAmount = (_shares * pseudoTotalPool) / totalDepositShares
/*LN-94*/ 
/*LN-95*/         withdrawAmount =
/*LN-96*/             (_shares * pool.pseudoTotalPool) /
/*LN-97*/             pool.totalDepositShares;
/*LN-98*/ 
/*LN-99*/         userLendingShares[_nftId][_poolToken] -= _shares;
/*LN-100*/         pool.totalDepositShares -= _shares;
/*LN-101*/         pool.pseudoTotalPool -= withdrawAmount;
/*LN-102*/ 
/*LN-103*/         IERC20(_poolToken).transfer(msg.sender, withdrawAmount);
/*LN-104*/ 
/*LN-105*/         return withdrawAmount;
/*LN-106*/     }
/*LN-107*/ 
/*LN-108*/     /**
/*LN-109*/      * @notice Withdraw exact amount of tokens
/*LN-110*/      */
/*LN-111*/     function withdrawExactAmount(
/*LN-112*/         uint256 _nftId,
/*LN-113*/         address _poolToken,
/*LN-114*/         uint256 _withdrawAmount
/*LN-115*/     ) external returns (uint256 shareBurned) {
/*LN-116*/         PoolData storage pool = lendingPoolData[_poolToken];
/*LN-117*/ 
/*LN-118*/         shareBurned =
/*LN-119*/             (_withdrawAmount * pool.totalDepositShares) /
/*LN-120*/             pool.pseudoTotalPool;
/*LN-121*/ 
/*LN-122*/         require(
/*LN-123*/             userLendingShares[_nftId][_poolToken] >= shareBurned,
/*LN-124*/             "Insufficient shares"
/*LN-125*/         );
/*LN-126*/ 
/*LN-127*/         userLendingShares[_nftId][_poolToken] -= shareBurned;
/*LN-128*/         pool.totalDepositShares -= shareBurned;
/*LN-129*/         pool.pseudoTotalPool -= _withdrawAmount;
/*LN-130*/ 
/*LN-131*/         IERC20(_poolToken).transfer(msg.sender, _withdrawAmount);
/*LN-132*/ 
/*LN-133*/         return shareBurned;
/*LN-134*/     }
/*LN-135*/ 
/*LN-136*/     /**
/*LN-137*/      * @notice Get position lending shares
/*LN-138*/      */
/*LN-139*/     function getPositionLendingShares(
/*LN-140*/         uint256 _nftId,
/*LN-141*/         address _poolToken
/*LN-142*/     ) external view returns (uint256) {
/*LN-143*/         return userLendingShares[_nftId][_poolToken];
/*LN-144*/     }
/*LN-145*/ 
/*LN-146*/     /**
/*LN-147*/      * @notice Get total pool balance
/*LN-148*/      */
/*LN-149*/     function getTotalPool(address _poolToken) external view returns (uint256) {
/*LN-150*/         return lendingPoolData[_poolToken].pseudoTotalPool;
/*LN-151*/     }
/*LN-152*/ }
/*LN-153*/ 