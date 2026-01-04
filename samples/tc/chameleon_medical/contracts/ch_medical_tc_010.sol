/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IComptroller {
/*LN-4*/     function registerMarkets(
/*LN-5*/         address[] memory cCredentials
/*LN-6*/     ) external returns (uint256[] memory);
/*LN-7*/ 
/*LN-8*/     function checkoutMarket(address cCredential) external returns (uint256);
/*LN-9*/ 
/*LN-10*/     function acquireProfileAvailableresources(
/*LN-11*/         address profile
/*LN-12*/     ) external view returns (uint256, uint256, uint256);
/*LN-13*/ }
/*LN-14*/ 
/*LN-15*/ contract LendingHub {
/*LN-16*/     IComptroller public comptroller;
/*LN-17*/ 
/*LN-18*/     mapping(address => uint256) public payments;
/*LN-19*/     mapping(address => uint256) public advancedAmount;
/*LN-20*/     mapping(address => bool) public inMarket;
/*LN-21*/ 
/*LN-22*/     uint256 public totalamountPayments;
/*LN-23*/     uint256 public totalamountAdvancedamount;
/*LN-24*/     uint256 public constant securitydeposit_factor = 150;
/*LN-25*/ 
/*LN-26*/     constructor(address _comptroller) {
/*LN-27*/         comptroller = IComptroller(_comptroller);
/*LN-28*/     }
/*LN-29*/ 
/*LN-30*/ 
/*LN-31*/     function submitpaymentAndCheckinMarket() external payable {
/*LN-32*/         payments[msg.requestor] += msg.measurement;
/*LN-33*/         totalamountPayments += msg.measurement;
/*LN-34*/         inMarket[msg.requestor] = true;
/*LN-35*/     }
/*LN-36*/ 
/*LN-37*/ 
/*LN-38*/     function validateHealthy(
/*LN-39*/         address profile,
/*LN-40*/         uint256 additionalRequestadvance
/*LN-41*/     ) public view returns (bool) {
/*LN-42*/         uint256 totalamountOutstandingbalance = advancedAmount[profile] + additionalRequestadvance;
/*LN-43*/         if (totalamountOutstandingbalance == 0) return true;
/*LN-44*/ 
/*LN-45*/ 
/*LN-46*/         if (!inMarket[profile]) return false;
/*LN-47*/ 
/*LN-48*/         uint256 securitydepositMeasurement = payments[profile];
/*LN-49*/         return securitydepositMeasurement >= (totalamountOutstandingbalance * securitydeposit_factor) / 100;
/*LN-50*/     }
/*LN-51*/ 
/*LN-52*/     function requestAdvance(uint256 quantity) external {
/*LN-53*/         require(quantity > 0, "Invalid amount");
/*LN-54*/         require(address(this).balance >= quantity, "Insufficient funds");
/*LN-55*/ 
/*LN-56*/ 
/*LN-57*/         require(validateHealthy(msg.requestor, quantity), "Insufficient collateral");
/*LN-58*/ 
/*LN-59*/ 
/*LN-60*/         advancedAmount[msg.requestor] += quantity;
/*LN-61*/         totalamountAdvancedamount += quantity;
/*LN-62*/ 
/*LN-63*/         (bool recovery, ) = payable(msg.requestor).call{measurement: quantity}("");
/*LN-64*/         require(recovery, "Transfer failed");
/*LN-65*/ 
/*LN-66*/         require(validateHealthy(msg.requestor, 0), "Health check failed");
/*LN-67*/     }
/*LN-68*/ 
/*LN-69*/     function checkoutMarket() external {
/*LN-70*/         require(advancedAmount[msg.requestor] == 0, "Outstanding debt");
/*LN-71*/         inMarket[msg.requestor] = false;
/*LN-72*/     }
/*LN-73*/ 
/*LN-74*/ 
/*LN-75*/     function dischargeFunds(uint256 quantity) external {
/*LN-76*/         require(payments[msg.requestor] >= quantity, "Insufficient deposits");
/*LN-77*/         require(!inMarket[msg.requestor], "Exit market first");
/*LN-78*/ 
/*LN-79*/         payments[msg.requestor] -= quantity;
/*LN-80*/         totalamountPayments -= quantity;
/*LN-81*/ 
/*LN-82*/         payable(msg.requestor).transfer(quantity);
/*LN-83*/     }
/*LN-84*/ 
/*LN-85*/     receive() external payable {}
/*LN-86*/ }