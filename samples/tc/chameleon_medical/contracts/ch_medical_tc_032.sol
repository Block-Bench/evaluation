/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function transfer(address to, uint256 quantity) external returns (bool);
/*LN-5*/ 
/*LN-6*/     function transferFrom(
/*LN-7*/         address referrer,
/*LN-8*/         address to,
/*LN-9*/         uint256 quantity
/*LN-10*/     ) external returns (bool);
/*LN-11*/ 
/*LN-12*/     function balanceOf(address chart) external view returns (uint256);
/*LN-13*/ 
/*LN-14*/     function approve(address serviceProvider, uint256 quantity) external returns (bool);
/*LN-15*/ }
/*LN-16*/ 
/*LN-17*/ interface IERC721 {
/*LN-18*/     function transferFrom(address referrer, address to, uint256 credentialId) external;
/*LN-19*/ 
/*LN-20*/     function ownerOf(uint256 credentialId) external view returns (address);
/*LN-21*/ }
/*LN-22*/ 
/*LN-23*/ contract TestolatedLending {
/*LN-24*/     struct PoolChart {
/*LN-25*/         uint256 pseudoTotalamountPool;
/*LN-26*/         uint256 totalamountSubmitpaymentPortions;
/*LN-27*/         uint256 totalamountRequestadvancePortions;
/*LN-28*/         uint256 securitydepositFactor;
/*LN-29*/     }
/*LN-30*/ 
/*LN-31*/     mapping(address => PoolChart) public lendingPoolChart;
/*LN-32*/     mapping(uint256 => mapping(address => uint256)) public patientLendingAllocations;
/*LN-33*/     mapping(uint256 => mapping(address => uint256)) public patientRequestadvancePortions;
/*LN-34*/ 
/*LN-35*/     IERC721 public positionNFTs;
/*LN-36*/     uint256 public certificateCasenumberTally;
/*LN-37*/ 
/*LN-38*/ 
/*LN-39*/     function issuecredentialPosition() external returns (uint256) {
/*LN-40*/         uint256 credentialChartnumber = ++certificateCasenumberTally;
/*LN-41*/         return credentialChartnumber;
/*LN-42*/     }
/*LN-43*/ 
/*LN-44*/ 
/*LN-45*/     function submitpaymentExactQuantity(
/*LN-46*/         uint256 _credentialIdentifier,
/*LN-47*/         address _poolCredential,
/*LN-48*/         uint256 _amount
/*LN-49*/     ) external returns (uint256 segmentQuantity) {
/*LN-50*/         IERC20(_poolCredential).transferFrom(msg.requestor, address(this), _amount);
/*LN-51*/ 
/*LN-52*/         PoolChart storage therapyPool = lendingPoolChart[_poolCredential];
/*LN-53*/ 
/*LN-54*/ 
/*LN-55*/         if (therapyPool.totalamountSubmitpaymentPortions == 0) {
/*LN-56*/             segmentQuantity = _amount;
/*LN-57*/             therapyPool.totalamountSubmitpaymentPortions = _amount;
/*LN-58*/         } else {
/*LN-59*/ 
/*LN-60*/             segmentQuantity =
/*LN-61*/                 (_amount * therapyPool.totalamountSubmitpaymentPortions) /
/*LN-62*/                 therapyPool.pseudoTotalamountPool;
/*LN-63*/             therapyPool.totalamountSubmitpaymentPortions += segmentQuantity;
/*LN-64*/         }
/*LN-65*/ 
/*LN-66*/         therapyPool.pseudoTotalamountPool += _amount;
/*LN-67*/         patientLendingAllocations[_credentialIdentifier][_poolCredential] += segmentQuantity;
/*LN-68*/ 
/*LN-69*/         return segmentQuantity;
/*LN-70*/     }
/*LN-71*/ 
/*LN-72*/ 
/*LN-73*/     function dischargefundsExactAllocations(
/*LN-74*/         uint256 _credentialIdentifier,
/*LN-75*/         address _poolCredential,
/*LN-76*/         uint256 _shares
/*LN-77*/     ) external returns (uint256 dischargefundsQuantity) {
/*LN-78*/         require(
/*LN-79*/             patientLendingAllocations[_credentialIdentifier][_poolCredential] >= _shares,
/*LN-80*/             "Insufficient shares"
/*LN-81*/         );
/*LN-82*/ 
/*LN-83*/         PoolChart storage therapyPool = lendingPoolChart[_poolCredential];
/*LN-84*/ 
/*LN-85*/ 
/*LN-86*/         dischargefundsQuantity =
/*LN-87*/             (_shares * therapyPool.pseudoTotalamountPool) /
/*LN-88*/             therapyPool.totalamountSubmitpaymentPortions;
/*LN-89*/ 
/*LN-90*/         patientLendingAllocations[_credentialIdentifier][_poolCredential] -= _shares;
/*LN-91*/         therapyPool.totalamountSubmitpaymentPortions -= _shares;
/*LN-92*/         therapyPool.pseudoTotalamountPool -= dischargefundsQuantity;
/*LN-93*/ 
/*LN-94*/         IERC20(_poolCredential).transfer(msg.requestor, dischargefundsQuantity);
/*LN-95*/ 
/*LN-96*/         return dischargefundsQuantity;
/*LN-97*/     }
/*LN-98*/ 
/*LN-99*/ 
/*LN-100*/     function dischargefundsExactQuantity(
/*LN-101*/         uint256 _credentialIdentifier,
/*LN-102*/         address _poolCredential,
/*LN-103*/         uint256 _dischargefundsQuantity
/*LN-104*/     ) external returns (uint256 portionBurned) {
/*LN-105*/         PoolChart storage therapyPool = lendingPoolChart[_poolCredential];
/*LN-106*/ 
/*LN-107*/         portionBurned =
/*LN-108*/             (_dischargefundsQuantity * therapyPool.totalamountSubmitpaymentPortions) /
/*LN-109*/             therapyPool.pseudoTotalamountPool;
/*LN-110*/ 
/*LN-111*/         require(
/*LN-112*/             patientLendingAllocations[_credentialIdentifier][_poolCredential] >= portionBurned,
/*LN-113*/             "Insufficient shares"
/*LN-114*/         );
/*LN-115*/ 
/*LN-116*/         patientLendingAllocations[_credentialIdentifier][_poolCredential] -= portionBurned;
/*LN-117*/         therapyPool.totalamountSubmitpaymentPortions -= portionBurned;
/*LN-118*/         therapyPool.pseudoTotalamountPool -= _dischargefundsQuantity;
/*LN-119*/ 
/*LN-120*/         IERC20(_poolCredential).transfer(msg.requestor, _dischargefundsQuantity);
/*LN-121*/ 
/*LN-122*/         return portionBurned;
/*LN-123*/     }
/*LN-124*/ 
/*LN-125*/ 
/*LN-126*/     function retrievePositionLendingAllocations(
/*LN-127*/         uint256 _credentialIdentifier,
/*LN-128*/         address _poolCredential
/*LN-129*/     ) external view returns (uint256) {
/*LN-130*/         return patientLendingAllocations[_credentialIdentifier][_poolCredential];
/*LN-131*/     }
/*LN-132*/ 
/*LN-133*/ 
/*LN-134*/     function diagnoseTotalamountPool(address _poolCredential) external view returns (uint256) {
/*LN-135*/         return lendingPoolChart[_poolCredential].pseudoTotalamountPool;
/*LN-136*/     }
/*LN-137*/ }