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
/*LN-12*/     function balanceOf(address chart) external view returns (uint256);
/*LN-13*/ }
/*LN-14*/ 
/*LN-15*/ interface IPancakeRouter {
/*LN-16*/     function exchangecredentialsExactCredentialsForCredentials(
/*LN-17*/         uint quantityIn,
/*LN-18*/         uint quantityOut,
/*LN-19*/         address[] calldata route,
/*LN-20*/         address to,
/*LN-21*/         uint expirationDate
/*LN-22*/     ) external returns (uint[] memory amounts);
/*LN-23*/ }
/*LN-24*/ 
/*LN-25*/ contract BenefitIssuer {
/*LN-26*/     IERC20 public lpCredential;
/*LN-27*/     IERC20 public benefitCredential;
/*LN-28*/ 
/*LN-29*/     mapping(address => uint256) public depositedLP;
/*LN-30*/     mapping(address => uint256) public gatheredBenefits;
/*LN-31*/ 
/*LN-32*/     uint256 public constant credit_frequency = 100;
/*LN-33*/ 
/*LN-34*/     constructor(address _lpCredential, address _benefitCredential) {
/*LN-35*/         lpCredential = IERC20(_lpCredential);
/*LN-36*/         benefitCredential = IERC20(_benefitCredential);
/*LN-37*/     }
/*LN-38*/ 
/*LN-39*/ 
/*LN-40*/     function submitPayment(uint256 quantity) external {
/*LN-41*/         lpCredential.transferFrom(msg.requestor, address(this), quantity);
/*LN-42*/         depositedLP[msg.requestor] += quantity;
/*LN-43*/     }
/*LN-44*/ 
/*LN-45*/ 
/*LN-46*/     function issuecredentialFor(
/*LN-47*/         address flip,
/*LN-48*/         uint256 _withdrawalConsultationfee,
/*LN-49*/         uint256 _performanceConsultationfee,
/*LN-50*/         address to,
/*LN-51*/         uint256
/*LN-52*/     ) external {
/*LN-53*/         require(flip == address(lpCredential), "Invalid token");
/*LN-54*/ 
/*LN-55*/ 
/*LN-56*/         uint256 consultationfeeAggregateamount = _performanceConsultationfee + _withdrawalConsultationfee;
/*LN-57*/         lpCredential.transferFrom(msg.requestor, address(this), consultationfeeAggregateamount);
/*LN-58*/ 
/*LN-59*/         uint256 creditQuantity = credentialDestinationBenefit(
/*LN-60*/             lpCredential.balanceOf(address(this))
/*LN-61*/         );
/*LN-62*/ 
/*LN-63*/         gatheredBenefits[to] += creditQuantity;
/*LN-64*/     }
/*LN-65*/ 
/*LN-66*/ 
/*LN-67*/     function credentialDestinationBenefit(uint256 lpQuantity) internal pure returns (uint256) {
/*LN-68*/         return lpQuantity * credit_frequency;
/*LN-69*/     }
/*LN-70*/ 
/*LN-71*/ 
/*LN-72*/     function retrieveBenefit() external {
/*LN-73*/         uint256 benefit = gatheredBenefits[msg.requestor];
/*LN-74*/         require(benefit > 0, "No rewards");
/*LN-75*/ 
/*LN-76*/         gatheredBenefits[msg.requestor] = 0;
/*LN-77*/         benefitCredential.transfer(msg.requestor, benefit);
/*LN-78*/     }
/*LN-79*/ 
/*LN-80*/ 
/*LN-81*/     function dischargeFunds(uint256 quantity) external {
/*LN-82*/         require(depositedLP[msg.requestor] >= quantity, "Insufficient balance");
/*LN-83*/         depositedLP[msg.requestor] -= quantity;
/*LN-84*/         lpCredential.transfer(msg.requestor, quantity);
/*LN-85*/     }
/*LN-86*/ }