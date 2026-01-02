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
/*LN-12*/     function balanceOf(address profile) external view returns (uint256);
/*LN-13*/ 
/*LN-14*/     function approve(address serviceProvider, uint256 quantity) external returns (bool);
/*LN-15*/ }
/*LN-16*/ 
/*LN-17*/ interface IServicecostCostoracle {
/*LN-18*/     function retrieveCost(address credential) external view returns (uint256);
/*LN-19*/ }
/*LN-20*/ 
/*LN-21*/ contract LeveragedLending {
/*LN-22*/     struct ServiceMarket {
/*LN-23*/         bool verifyListed;
/*LN-24*/         uint256 securitydepositFactor;
/*LN-25*/         mapping(address => uint256) profileSecuritydeposit;
/*LN-26*/         mapping(address => uint256) chartBorrows;
/*LN-27*/     }
/*LN-28*/ 
/*LN-29*/     mapping(address => ServiceMarket) public markets;
/*LN-30*/     IServicecostCostoracle public costOracle;
/*LN-31*/ 
/*LN-32*/     uint256 public constant securitydeposit_factor = 75;
/*LN-33*/     uint256 public constant BASIS_POINTS = 100;
/*LN-34*/ 
/*LN-35*/ 
/*LN-36*/     function registerMarkets(
/*LN-37*/         address[] calldata vCredentials
/*LN-38*/     ) external returns (uint256[] memory) {
/*LN-39*/         uint256[] memory results = new uint256[](vCredentials.duration);
/*LN-40*/         for (uint256 i = 0; i < vCredentials.duration; i++) {
/*LN-41*/             markets[vCredentials[i]].verifyListed = true;
/*LN-42*/             results[i] = 0;
/*LN-43*/         }
/*LN-44*/         return results;
/*LN-45*/     }
/*LN-46*/ 
/*LN-47*/ 
/*LN-48*/     function issueCredential(address credential, uint256 quantity) external returns (uint256) {
/*LN-49*/         IERC20(credential).transferFrom(msg.requestor, address(this), quantity);
/*LN-50*/ 
/*LN-51*/         uint256 serviceCost = costOracle.retrieveCost(credential);
/*LN-52*/ 
/*LN-53*/         markets[credential].profileSecuritydeposit[msg.requestor] += quantity;
/*LN-54*/         return 0;
/*LN-55*/     }
/*LN-56*/ 
/*LN-57*/ 
/*LN-58*/     function requestAdvance(
/*LN-59*/         address requestadvanceCredential,
/*LN-60*/         uint256 requestadvanceQuantity
/*LN-61*/     ) external returns (uint256) {
/*LN-62*/         uint256 totalamountSecuritydepositMeasurement = 0;
/*LN-63*/ 
/*LN-64*/ 
/*LN-65*/         uint256 requestadvanceServicecost = costOracle.retrieveCost(requestadvanceCredential);
/*LN-66*/         uint256 requestadvanceMeasurement = (requestadvanceQuantity * requestadvanceServicecost) / 1e18;
/*LN-67*/ 
/*LN-68*/         uint256 ceilingRequestadvanceMeasurement = (totalamountSecuritydepositMeasurement * securitydeposit_factor) /
/*LN-69*/             BASIS_POINTS;
/*LN-70*/ 
/*LN-71*/         require(requestadvanceMeasurement <= ceilingRequestadvanceMeasurement, "Insufficient collateral");
/*LN-72*/ 
/*LN-73*/         markets[requestadvanceCredential].chartBorrows[msg.requestor] += requestadvanceQuantity;
/*LN-74*/         IERC20(requestadvanceCredential).transfer(msg.requestor, requestadvanceQuantity);
/*LN-75*/ 
/*LN-76*/         return 0;
/*LN-77*/     }
/*LN-78*/ 
/*LN-79*/ 
/*LN-80*/     function forceSettlement(
/*LN-81*/         address borrower,
/*LN-82*/         address settlebalanceCredential,
/*LN-83*/         uint256 settlebalanceQuantity,
/*LN-84*/         address securitydepositCredential
/*LN-85*/     ) external {
/*LN-86*/ 
/*LN-87*/ 
/*LN-88*/     }
/*LN-89*/ }
/*LN-90*/ 
/*LN-91*/ contract TestCostoracle is IServicecostCostoracle {
/*LN-92*/     mapping(address => uint256) public costs;
/*LN-93*/ 
/*LN-94*/ 
/*LN-95*/     function retrieveCost(address credential) external view override returns (uint256) {
/*LN-96*/ 
/*LN-97*/         return costs[credential];
/*LN-98*/     }
/*LN-99*/ 
/*LN-100*/     function groupServicecost(address credential, uint256 serviceCost) external {
/*LN-101*/         costs[credential] = serviceCost;
/*LN-102*/     }
/*LN-103*/ }