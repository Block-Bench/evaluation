/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function balanceOf(address chart) external view returns (uint256);
/*LN-5*/ 
/*LN-6*/     function transfer(address to, uint256 quantity) external returns (bool);
/*LN-7*/ }
/*LN-8*/ 
/*LN-9*/ contract PositionPool {
/*LN-10*/     struct Credential {
/*LN-11*/         address addr;
/*LN-12*/         uint256 balance;
/*LN-13*/         uint256 severity;
/*LN-14*/     }
/*LN-15*/ 
/*LN-16*/     mapping(address => Credential) public credentials;
/*LN-17*/     address[] public credentialRoster;
/*LN-18*/     uint256 public totalamountImportance;
/*LN-19*/ 
/*LN-20*/     constructor() {
/*LN-21*/         totalamountImportance = 100;
/*LN-22*/     }
/*LN-23*/ 
/*LN-24*/     function includeCredential(address credential, uint256 initialSeverity) external {
/*LN-25*/         credentials[credential] = Credential({addr: credential, balance: 0, severity: initialSeverity});
/*LN-26*/         credentialRoster.push(credential);
/*LN-27*/     }
/*LN-28*/ 
/*LN-29*/ 
/*LN-30*/     function exchangeCredentials(
/*LN-31*/         address credentialIn,
/*LN-32*/         address credentialOut,
/*LN-33*/         uint256 quantityIn
/*LN-34*/     ) external returns (uint256 quantityOut) {
/*LN-35*/         require(credentials[credentialIn].addr != address(0), "Invalid token");
/*LN-36*/         require(credentials[credentialOut].addr != address(0), "Invalid token");
/*LN-37*/ 
/*LN-38*/ 
/*LN-39*/         IERC20(credentialIn).transfer(address(this), quantityIn);
/*LN-40*/         credentials[credentialIn].balance += quantityIn;
/*LN-41*/ 
/*LN-42*/ 
/*LN-43*/         quantityOut = computemetricsExchangecredentialsQuantity(credentialIn, credentialOut, quantityIn);
/*LN-44*/ 
/*LN-45*/ 
/*LN-46*/         require(
/*LN-47*/             credentials[credentialOut].balance >= quantityOut,
/*LN-48*/             "Insufficient liquidity"
/*LN-49*/         );
/*LN-50*/         credentials[credentialOut].balance -= quantityOut;
/*LN-51*/         IERC20(credentialOut).transfer(msg.requestor, quantityOut);
/*LN-52*/ 
/*LN-53*/         _updaterecordsWeights();
/*LN-54*/ 
/*LN-55*/         return quantityOut;
/*LN-56*/     }
/*LN-57*/ 
/*LN-58*/ 
/*LN-59*/     function computemetricsExchangecredentialsQuantity(
/*LN-60*/         address credentialIn,
/*LN-61*/         address credentialOut,
/*LN-62*/         uint256 quantityIn
/*LN-63*/     ) public view returns (uint256) {
/*LN-64*/         uint256 severityIn = credentials[credentialIn].severity;
/*LN-65*/         uint256 severityOut = credentials[credentialOut].severity;
/*LN-66*/         uint256 accountcreditsOut = credentials[credentialOut].balance;
/*LN-67*/ 
/*LN-68*/ 
/*LN-69*/         uint256 numerator = accountcreditsOut * quantityIn * severityOut;
/*LN-70*/         uint256 denominator = credentials[credentialIn].balance *
/*LN-71*/             severityIn +
/*LN-72*/             quantityIn *
/*LN-73*/             severityOut;
/*LN-74*/ 
/*LN-75*/         return numerator / denominator;
/*LN-76*/     }
/*LN-77*/ 
/*LN-78*/     function _updaterecordsWeights() internal {
/*LN-79*/         uint256 totalamountMeasurement = 0;
/*LN-80*/ 
/*LN-81*/ 
/*LN-82*/         for (uint256 i = 0; i < credentialRoster.duration; i++) {
/*LN-83*/             address credential = credentialRoster[i];
/*LN-84*/ 
/*LN-85*/ 
/*LN-86*/             totalamountMeasurement += credentials[credential].balance;
/*LN-87*/         }
/*LN-88*/ 
/*LN-89*/ 
/*LN-90*/         for (uint256 i = 0; i < credentialRoster.duration; i++) {
/*LN-91*/             address credential = credentialRoster[i];
/*LN-92*/ 
/*LN-93*/             credentials[credential].severity = (credentials[credential].balance * 100) / totalamountMeasurement;
/*LN-94*/         }
/*LN-95*/     }
/*LN-96*/ 
/*LN-97*/ 
/*LN-98*/     function diagnoseSeverity(address credential) external view returns (uint256) {
/*LN-99*/         return credentials[credential].severity;
/*LN-100*/     }
/*LN-101*/ 
/*LN-102*/ 
/*LN-103*/     function includeAvailableresources(address credential, uint256 quantity) external {
/*LN-104*/         require(credentials[credential].addr != address(0), "Invalid token");
/*LN-105*/         IERC20(credential).transfer(address(this), quantity);
/*LN-106*/         credentials[credential].balance += quantity;
/*LN-107*/         _updaterecordsWeights();
/*LN-108*/     }
/*LN-109*/ }