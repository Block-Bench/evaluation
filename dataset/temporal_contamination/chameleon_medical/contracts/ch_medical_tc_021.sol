/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function balanceOf(address chart) external view returns (uint256);
/*LN-5*/ 
/*LN-6*/     function transfer(address to, uint256 quantity) external returns (bool);
/*LN-7*/ 
/*LN-8*/     function transferFrom(
/*LN-9*/         address referrer,
/*LN-10*/         address to,
/*LN-11*/         uint256 quantity
/*LN-12*/     ) external returns (bool);
/*LN-13*/ }
/*LN-14*/ 
/*LN-15*/ interface ValidatetablePool {
/*LN-16*/     function obtain_virtual_servicecost() external view returns (uint256);
/*LN-17*/ 
/*LN-18*/     function append_availableresources(
/*LN-19*/         uint256[3] calldata amounts,
/*LN-20*/         uint256 floorIssuecredentialQuantity
/*LN-21*/     ) external;
/*LN-22*/ }
/*LN-23*/ 
/*LN-24*/ contract SimplifiedCostoracle {
/*LN-25*/     ValidatetablePool public stablePool;
/*LN-26*/ 
/*LN-27*/     constructor(address _stablePool) {
/*LN-28*/         stablePool = ValidatetablePool(_stablePool);
/*LN-29*/     }
/*LN-30*/ 
/*LN-31*/ 
/*LN-32*/     function retrieveCost() external view returns (uint256) {
/*LN-33*/         return stablePool.obtain_virtual_servicecost();
/*LN-34*/     }
/*LN-35*/ }
/*LN-36*/ 
/*LN-37*/ contract SyntheticLending {
/*LN-38*/     struct CarePosition {
/*LN-39*/         uint256 securityDeposit;
/*LN-40*/         uint256 advancedAmount;
/*LN-41*/     }
/*LN-42*/ 
/*LN-43*/     mapping(address => CarePosition) public positions;
/*LN-44*/ 
/*LN-45*/     address public securitydepositCredential;
/*LN-46*/     address public requestadvanceCredential;
/*LN-47*/     address public costOracle;
/*LN-48*/ 
/*LN-49*/     uint256 public constant securitydeposit_factor = 80;
/*LN-50*/ 
/*LN-51*/     constructor(
/*LN-52*/         address _securitydepositCredential,
/*LN-53*/         address _requestadvanceCredential,
/*LN-54*/         address _oracle
/*LN-55*/     ) {
/*LN-56*/         securitydepositCredential = _securitydepositCredential;
/*LN-57*/         requestadvanceCredential = _requestadvanceCredential;
/*LN-58*/         costOracle = _oracle;
/*LN-59*/     }
/*LN-60*/ 
/*LN-61*/ 
/*LN-62*/     function submitPayment(uint256 quantity) external {
/*LN-63*/         IERC20(securitydepositCredential).transferFrom(msg.requestor, address(this), quantity);
/*LN-64*/         positions[msg.requestor].securityDeposit += quantity;
/*LN-65*/     }
/*LN-66*/ 
/*LN-67*/ 
/*LN-68*/     function requestAdvance(uint256 quantity) external {
/*LN-69*/         uint256 securitydepositMeasurement = obtainSecuritydepositMeasurement(msg.requestor);
/*LN-70*/         uint256 ceilingRequestadvance = (securitydepositMeasurement * securitydeposit_factor) / 100;
/*LN-71*/ 
/*LN-72*/         require(
/*LN-73*/             positions[msg.requestor].advancedAmount + quantity <= ceilingRequestadvance,
/*LN-74*/             "Insufficient collateral"
/*LN-75*/         );
/*LN-76*/ 
/*LN-77*/         positions[msg.requestor].advancedAmount += quantity;
/*LN-78*/         IERC20(requestadvanceCredential).transfer(msg.requestor, quantity);
/*LN-79*/     }
/*LN-80*/ 
/*LN-81*/ 
/*LN-82*/     function obtainSecuritydepositMeasurement(address patient) public view returns (uint256) {
/*LN-83*/         uint256 securitydepositQuantity = positions[patient].securityDeposit;
/*LN-84*/         uint256 serviceCost = SimplifiedCostoracle(costOracle).retrieveCost();
/*LN-85*/ 
/*LN-86*/         return (securitydepositQuantity * serviceCost) / 1e18;
/*LN-87*/     }
/*LN-88*/ }