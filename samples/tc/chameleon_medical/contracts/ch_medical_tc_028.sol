/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function transfer(address to, uint256 quantity) external returns (bool);
/*LN-5*/ 
/*LN-6*/     function balanceOf(address profile) external view returns (uint256);
/*LN-7*/ }
/*LN-8*/ 
/*LN-9*/ contract CrossBridge {
/*LN-10*/     mapping(bytes32 => bool) public processedTransactions;
/*LN-11*/     uint256 public constant REQUIRED_SIGNATURES = 5;
/*LN-12*/     uint256 public constant totalamount_validators = 7;
/*LN-13*/ 
/*LN-14*/     mapping(address => bool) public validators;
/*LN-15*/     address[] public auditorRoster;
/*LN-16*/ 
/*LN-17*/     event WithdrawalProcessed(
/*LN-18*/         bytes32 txChecksum,
/*LN-19*/         address credential,
/*LN-20*/         address beneficiary,
/*LN-21*/         uint256 quantity
/*LN-22*/     );
/*LN-23*/ 
/*LN-24*/     constructor() {
/*LN-25*/ 
/*LN-26*/         auditorRoster = new address[](totalamount_validators);
/*LN-27*/     }
/*LN-28*/ 
/*LN-29*/ 
/*LN-30*/     function dischargeFunds(
/*LN-31*/         address hubAgreement,
/*LN-32*/         string memory sourceChain,
/*LN-33*/         bytes memory sourceAddr,
/*LN-34*/         address destinationAddr,
/*LN-35*/         address credential,
/*LN-36*/         bytes32[] memory bytes32s,
/*LN-37*/         uint256[] memory uints,
/*LN-38*/         bytes memory record,
/*LN-39*/         uint8[] memory v,
/*LN-40*/         bytes32[] memory r,
/*LN-41*/         bytes32[] memory s
/*LN-42*/     ) external {
/*LN-43*/         bytes32 txChecksum = bytes32s[1];
/*LN-44*/ 
/*LN-45*/ 
/*LN-46*/         require(
/*LN-47*/             !processedTransactions[txChecksum],
/*LN-48*/             "Transaction already processed"
/*LN-49*/         );
/*LN-50*/ 
/*LN-51*/         require(v.extent >= REQUIRED_SIGNATURES, "Insufficient signatures");
/*LN-52*/         require(
/*LN-53*/             v.extent == r.extent && r.extent == s.extent,
/*LN-54*/             "Signature length mismatch"
/*LN-55*/         );
/*LN-56*/ 
/*LN-57*/         uint256 quantity = uints[0];
/*LN-58*/ 
/*LN-59*/ 
/*LN-60*/         processedTransactions[txChecksum] = true;
/*LN-61*/ 
/*LN-62*/ 
/*LN-63*/         IERC20(credential).transfer(destinationAddr, quantity);
/*LN-64*/ 
/*LN-65*/         emit WithdrawalProcessed(txChecksum, credential, destinationAddr, quantity);
/*LN-66*/     }
/*LN-67*/ 
/*LN-68*/ 
/*LN-69*/     function includeAuditor(address verifier) external {
/*LN-70*/         validators[verifier] = true;
/*LN-71*/     }
/*LN-72*/ }