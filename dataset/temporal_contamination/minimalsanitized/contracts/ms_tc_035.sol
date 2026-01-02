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
/*LN-24*/ contract WiseLending {
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
/*LN-66*/             
/*LN-67*/             
/*LN-68*/             shareAmount =
/*LN-69*/                 (_amount * pool.totalDepositShares) /
/*LN-70*/                 pool.pseudoTotalPool;
/*LN-71*/             pool.totalDepositShares += shareAmount;
/*LN-72*/         }
/*LN-73*/ 
/*LN-74*/         pool.pseudoTotalPool += _amount;
/*LN-75*/         userLendingShares[_nftId][_poolToken] += shareAmount;
/*LN-76*/ 
/*LN-77*/         return shareAmount;
/*LN-78*/     }
/*LN-79*/ 
/*LN-80*/     /**
/*LN-81*/      * @notice Withdraw exact shares amount
/*LN-82*/      */
/*LN-83*/     function withdrawExactShares(
/*LN-84*/         uint256 _nftId,
/*LN-85*/         address _poolToken,
/*LN-86*/         uint256 _shares
/*LN-87*/     ) external returns (uint256 withdrawAmount) {
/*LN-88*/         require(
/*LN-89*/             userLendingShares[_nftId][_poolToken] >= _shares,
/*LN-90*/             "Insufficient shares"
/*LN-91*/         );
/*LN-92*/ 
/*LN-93*/         PoolData storage pool = lendingPoolData[_poolToken];
/*LN-94*/ 
/*LN-95*/         // withdrawAmount = (_shares * pseudoTotalPool) / totalDepositShares
/*LN-96*/         
/*LN-97*/         
/*LN-98*/        
/*LN-99*/ 
/*LN-100*/         withdrawAmount =
/*LN-101*/             (_shares * pool.pseudoTotalPool) /
/*LN-102*/             pool.totalDepositShares;
/*LN-103*/ 
/*LN-104*/         userLendingShares[_nftId][_poolToken] -= _shares;
/*LN-105*/         pool.totalDepositShares -= _shares;
/*LN-106*/         pool.pseudoTotalPool -= withdrawAmount;
/*LN-107*/ 
/*LN-108*/         IERC20(_poolToken).transfer(msg.sender, withdrawAmount);
/*LN-109*/ 
/*LN-110*/         return withdrawAmount;
/*LN-111*/     }
/*LN-112*/ 
/*LN-113*/     /**
/*LN-114*/      * @notice Withdraw exact amount of tokens
/*LN-115*/      */
/*LN-116*/     function withdrawExactAmount(
/*LN-117*/         uint256 _nftId,
/*LN-118*/         address _poolToken,
/*LN-119*/         uint256 _withdrawAmount
/*LN-120*/     ) external returns (uint256 shareBurned) {
/*LN-121*/         PoolData storage pool = lendingPoolData[_poolToken];
/*LN-122*/ 
/*LN-123*/         shareBurned =
/*LN-124*/             (_withdrawAmount * pool.totalDepositShares) /
/*LN-125*/             pool.pseudoTotalPool;
/*LN-126*/ 
/*LN-127*/         require(
/*LN-128*/             userLendingShares[_nftId][_poolToken] >= shareBurned,
/*LN-129*/             "Insufficient shares"
/*LN-130*/         );
/*LN-131*/ 
/*LN-132*/         userLendingShares[_nftId][_poolToken] -= shareBurned;
/*LN-133*/         pool.totalDepositShares -= shareBurned;
/*LN-134*/         pool.pseudoTotalPool -= _withdrawAmount;
/*LN-135*/ 
/*LN-136*/         IERC20(_poolToken).transfer(msg.sender, _withdrawAmount);
/*LN-137*/ 
/*LN-138*/         return shareBurned;
/*LN-139*/     }
/*LN-140*/ 
/*LN-141*/     /**
/*LN-142*/      * @notice Get position lending shares
/*LN-143*/      */
/*LN-144*/     function getPositionLendingShares(
/*LN-145*/         uint256 _nftId,
/*LN-146*/         address _poolToken
/*LN-147*/     ) external view returns (uint256) {
/*LN-148*/         return userLendingShares[_nftId][_poolToken];
/*LN-149*/     }
/*LN-150*/ 
/*LN-151*/     /**
/*LN-152*/      * @notice Get total pool balance
/*LN-153*/      */
/*LN-154*/     function getTotalPool(address _poolToken) external view returns (uint256) {
/*LN-155*/         return lendingPoolData[_poolToken].pseudoTotalPool;
/*LN-156*/     }
/*LN-157*/ }
/*LN-158*/ 