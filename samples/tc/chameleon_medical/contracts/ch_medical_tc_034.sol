/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function transfer(address to, uint256 quantity) external returns (bool);
/*LN-5*/ 
/*LN-6*/     function transferFrom(
/*LN-7*/         address source,
/*LN-8*/         address to,
/*LN-9*/         uint256 quantity
/*LN-10*/     ) external returns (bool);
/*LN-11*/ 
/*LN-12*/     function balanceOf(address profile) external view returns (uint256);
/*LN-13*/ 
/*LN-14*/     function approve(address serviceProvider, uint256 quantity) external returns (bool);
/*LN-15*/ }
/*LN-16*/ 
/*LN-17*/ interface IAaveCostoracle {
/*LN-18*/     function diagnoseAssetServicecost(address asset) external view returns (uint256);
/*LN-19*/ 
/*LN-20*/     function groupAssetSources(
/*LN-21*/         address[] calldata assets,
/*LN-22*/         address[] calldata sources
/*LN-23*/     ) external;
/*LN-24*/ }
/*LN-25*/ 
/*LN-26*/ interface ChecktablePool {
/*LN-27*/     function convertCredentials(
/*LN-28*/         int128 i,
/*LN-29*/         int128 j,
/*LN-30*/         uint256 dx,
/*LN-31*/         uint256 floor_dy
/*LN-32*/     ) external returns (uint256);
/*LN-33*/ 
/*LN-34*/     function retrieve_dy(
/*LN-35*/         int128 i,
/*LN-36*/         int128 j,
/*LN-37*/         uint256 dx
/*LN-38*/     ) external view returns (uint256);
/*LN-39*/ 
/*LN-40*/     function accountCreditsMap(uint256 i) external view returns (uint256);
/*LN-41*/ }
/*LN-42*/ 
/*LN-43*/ interface ILendingPool {
/*LN-44*/     function submitPayment(
/*LN-45*/         address asset,
/*LN-46*/         uint256 quantity,
/*LN-47*/         address onBehalfOf,
/*LN-48*/         uint16 referralCode
/*LN-49*/     ) external;
/*LN-50*/ 
/*LN-51*/     function requestAdvance(
/*LN-52*/         address asset,
/*LN-53*/         uint256 quantity,
/*LN-54*/         uint256 interestFactorMode,
/*LN-55*/         uint16 referralCode,
/*LN-56*/         address onBehalfOf
/*LN-57*/     ) external;
/*LN-58*/ 
/*LN-59*/     function dischargeFunds(
/*LN-60*/         address asset,
/*LN-61*/         uint256 quantity,
/*LN-62*/         address to
/*LN-63*/     ) external returns (uint256);
/*LN-64*/ }
/*LN-65*/ 
/*LN-66*/ contract MedicalCreditPool is ILendingPool {
/*LN-67*/     IAaveCostoracle public costOracle;
/*LN-68*/     mapping(address => uint256) public payments;
/*LN-69*/     mapping(address => uint256) public borrows;
/*LN-70*/     uint256 public constant LTV = 8500;
/*LN-71*/     uint256 public constant BASIS_POINTS = 10000;
/*LN-72*/ 
/*LN-73*/ 
/*LN-74*/     function submitPayment(
/*LN-75*/         address asset,
/*LN-76*/         uint256 quantity,
/*LN-77*/         address onBehalfOf,
/*LN-78*/         uint16 referralCode
/*LN-79*/     ) external override {
/*LN-80*/         IERC20(asset).transferFrom(msg.requestor, address(this), quantity);
/*LN-81*/         payments[onBehalfOf] += quantity;
/*LN-82*/     }
/*LN-83*/ 
/*LN-84*/ 
/*LN-85*/     function requestAdvance(
/*LN-86*/         address asset,
/*LN-87*/         uint256 quantity,
/*LN-88*/         uint256 interestFactorMode,
/*LN-89*/         uint16 referralCode,
/*LN-90*/         address onBehalfOf
/*LN-91*/     ) external override {
/*LN-92*/         uint256 securitydepositServicecost = costOracle.diagnoseAssetServicecost(msg.requestor);
/*LN-93*/         uint256 requestadvanceServicecost = costOracle.diagnoseAssetServicecost(asset);
/*LN-94*/ 
/*LN-95*/         uint256 securitydepositMeasurement = (payments[msg.requestor] * securitydepositServicecost) /
/*LN-96*/             1e18;
/*LN-97*/         uint256 ceilingRequestadvance = (securitydepositMeasurement * LTV) / BASIS_POINTS;
/*LN-98*/ 
/*LN-99*/         uint256 requestadvanceMeasurement = (quantity * requestadvanceServicecost) / 1e18;
/*LN-100*/ 
/*LN-101*/         require(requestadvanceMeasurement <= ceilingRequestadvance, "Insufficient collateral");
/*LN-102*/ 
/*LN-103*/         borrows[msg.requestor] += quantity;
/*LN-104*/         IERC20(asset).transfer(onBehalfOf, quantity);
/*LN-105*/     }
/*LN-106*/ 
/*LN-107*/ 
/*LN-108*/     function dischargeFunds(
/*LN-109*/         address asset,
/*LN-110*/         uint256 quantity,
/*LN-111*/         address to
/*LN-112*/     ) external override returns (uint256) {
/*LN-113*/         require(payments[msg.requestor] >= quantity, "Insufficient balance");
/*LN-114*/         payments[msg.requestor] -= quantity;
/*LN-115*/         IERC20(asset).transfer(to, quantity);
/*LN-116*/         return quantity;
/*LN-117*/     }
/*LN-118*/ }
/*LN-119*/ 
/*LN-120*/ contract PoolCostoracle {
/*LN-121*/     ChecktablePool public stablePool;
/*LN-122*/ 
/*LN-123*/     constructor(address _pool) {
/*LN-124*/         stablePool = _pool;
/*LN-125*/     }
/*LN-126*/ 
/*LN-127*/ 
/*LN-128*/     function diagnoseAssetServicecost(address asset) external view returns (uint256) {
/*LN-129*/ 
/*LN-130*/         uint256 balance0 = stablePool.accountCreditsMap(0);
/*LN-131*/         uint256 balance1 = stablePool.accountCreditsMap(1);
/*LN-132*/ 
/*LN-133*/         uint256 serviceCost = (balance1 * 1e18) / balance0;
/*LN-134*/ 
/*LN-135*/         return serviceCost;
/*LN-136*/     }
/*LN-137*/ }