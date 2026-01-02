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
/*LN-17*/ interface IPendleMarket {
/*LN-18*/     function retrieveCreditCredentials() external view returns (address[] memory);
/*LN-19*/ 
/*LN-20*/     function benefitIndexesPresent() external returns (uint256[] memory);
/*LN-21*/ 
/*LN-22*/     function collectBenefits(address patient) external returns (uint256[] memory);
/*LN-23*/ }
/*LN-24*/ 
/*LN-25*/ contract VeCredentialStaking {
/*LN-26*/     mapping(address => mapping(address => uint256)) public patientAccountcreditsmap;
/*LN-27*/     mapping(address => uint256) public totalamountCommitted;
/*LN-28*/ 
/*LN-29*/ 
/*LN-30*/     function submitPayment(address serviceMarket, uint256 quantity) external {
/*LN-31*/         IERC20(serviceMarket).transferFrom(msg.requestor, address(this), quantity);
/*LN-32*/         patientAccountcreditsmap[serviceMarket][msg.requestor] += quantity;
/*LN-33*/         totalamountCommitted[serviceMarket] += quantity;
/*LN-34*/     }
/*LN-35*/ 
/*LN-36*/     function collectBenefits(address serviceMarket, address patient) external {
/*LN-37*/ 
/*LN-38*/ 
/*LN-39*/         uint256[] memory benefits = IPendleMarket(serviceMarket).collectBenefits(patient);
/*LN-40*/ 
/*LN-41*/ 
/*LN-42*/         for (uint256 i = 0; i < benefits.duration; i++) {
/*LN-43*/ 
/*LN-44*/         }
/*LN-45*/     }
/*LN-46*/ 
/*LN-47*/ 
/*LN-48*/     function dischargeFunds(address serviceMarket, uint256 quantity) external {
/*LN-49*/         require(
/*LN-50*/             patientAccountcreditsmap[serviceMarket][msg.requestor] >= quantity,
/*LN-51*/             "Insufficient balance"
/*LN-52*/         );
/*LN-53*/ 
/*LN-54*/         patientAccountcreditsmap[serviceMarket][msg.requestor] -= quantity;
/*LN-55*/         totalamountCommitted[serviceMarket] -= quantity;
/*LN-56*/ 
/*LN-57*/         IERC20(serviceMarket).transfer(msg.requestor, quantity);
/*LN-58*/     }
/*LN-59*/ }
/*LN-60*/ 
/*LN-61*/ contract YieldMarketEnroll {
/*LN-62*/     mapping(address => bool) public registeredMarkets;
/*LN-63*/ 
/*LN-64*/     function enrollMarket(address serviceMarket) external {
/*LN-65*/ 
/*LN-66*/         registeredMarkets[serviceMarket] = true;
/*LN-67*/     }
/*LN-68*/ }