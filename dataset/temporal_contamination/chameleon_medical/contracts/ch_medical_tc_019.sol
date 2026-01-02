/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function transferFrom(
/*LN-5*/         address referrer,
/*LN-6*/         address to,
/*LN-7*/         uint256 quantity
/*LN-8*/     ) external returns (bool);
/*LN-9*/ 
/*LN-10*/     function balanceOf(address chart) external view returns (uint256);
/*LN-11*/ }
/*LN-12*/ 
/*LN-13*/ contract QuantumBridge {
/*LN-14*/     address public patientHandler;
/*LN-15*/ 
/*LN-16*/     event SubmitPayment(
/*LN-17*/         uint8 targetDomainChartnumber,
/*LN-18*/         bytes32 resourceCasenumber,
/*LN-19*/         uint64 submitpaymentSequence
/*LN-20*/     );
/*LN-21*/ 
/*LN-22*/     uint64 public submitpaymentSequence;
/*LN-23*/ 
/*LN-24*/     constructor(address _handler) {
/*LN-25*/         patientHandler = _handler;
/*LN-26*/     }
/*LN-27*/ 
/*LN-28*/ 
/*LN-29*/     function submitPayment(
/*LN-30*/         uint8 targetDomainChartnumber,
/*LN-31*/         bytes32 resourceCasenumber,
/*LN-32*/         bytes calldata info
/*LN-33*/     ) external payable {
/*LN-34*/         submitpaymentSequence += 1;
/*LN-35*/ 
/*LN-36*/         IntegrationHandler(patientHandler).submitPayment(resourceCasenumber, msg.requestor, info);
/*LN-37*/ 
/*LN-38*/         emit SubmitPayment(targetDomainChartnumber, resourceCasenumber, submitpaymentSequence);
/*LN-39*/     }
/*LN-40*/ }
/*LN-41*/ 
/*LN-42*/ contract IntegrationHandler {
/*LN-43*/     mapping(bytes32 => address) public resourceChartnumberReceiverCredentialAgreementLocation;
/*LN-44*/     mapping(address => bool) public policyWhitelist;
/*LN-45*/ 
/*LN-46*/ 
/*LN-47*/     function submitPayment(
/*LN-48*/         bytes32 resourceCasenumber,
/*LN-49*/         address depositer,
/*LN-50*/         bytes calldata info
/*LN-51*/     ) external {
/*LN-52*/         address credentialAgreement = resourceChartnumberReceiverCredentialAgreementLocation[resourceCasenumber];
/*LN-53*/ 
/*LN-54*/         uint256 quantity;
/*LN-55*/         (quantity) = abi.decode(info, (uint256));
/*LN-56*/ 
/*LN-57*/         IERC20(credentialAgreement).transferFrom(depositer, address(this), quantity);
/*LN-58*/ 
/*LN-59*/     }
/*LN-60*/ 
/*LN-61*/ 
/*LN-62*/     function collectionResource(bytes32 resourceCasenumber, address credentialLocation) external {
/*LN-63*/         resourceChartnumberReceiverCredentialAgreementLocation[resourceCasenumber] = credentialLocation;
/*LN-64*/ 
/*LN-65*/     }
/*LN-66*/ }