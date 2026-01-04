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
/*LN-13*/ 
/*LN-14*/     function approve(address serviceProvider, uint256 quantity) external returns (bool);
/*LN-15*/ }
/*LN-16*/ 
/*LN-17*/ interface IBorrowerOperations {
/*LN-18*/     function groupAssignproxyApproval(address _delegate, bool _isApproved) external;
/*LN-19*/ 
/*LN-20*/     function openTrove(
/*LN-21*/         address troveHandler,
/*LN-22*/         address chart,
/*LN-23*/         uint256 _maximumConsultationfeePercentage,
/*LN-24*/         uint256 _securitydepositQuantity,
/*LN-25*/         uint256 _outstandingbalanceQuantity,
/*LN-26*/         address _upperHint,
/*LN-27*/         address _lowerHint
/*LN-28*/     ) external;
/*LN-29*/ 
/*LN-30*/     function closeTrove(address troveHandler, address chart) external;
/*LN-31*/ }
/*LN-32*/ 
/*LN-33*/ interface ITroveCoordinator {
/*LN-34*/     function retrieveTroveCollAndOutstandingbalance(
/*LN-35*/         address _borrower
/*LN-36*/     ) external view returns (uint256 coll, uint256 outstandingBalance);
/*LN-37*/ 
/*LN-38*/     function forceSettlement(address _borrower) external;
/*LN-39*/ }
/*LN-40*/ 
/*LN-41*/ contract TransferrecordsTroveZap {
/*LN-42*/     IBorrowerOperations public patientFinanceOperations;
/*LN-43*/     address public wstETH;
/*LN-44*/     address public mkUSD;
/*LN-45*/ 
/*LN-46*/     constructor(address _borrowerOperations, address _wstETH, address _mkUSD) {
/*LN-47*/         patientFinanceOperations = _borrowerOperations;
/*LN-48*/         wstETH = _wstETH;
/*LN-49*/         mkUSD = _mkUSD;
/*LN-50*/     }
/*LN-51*/ 
/*LN-52*/ 
/*LN-53*/     function openTroveAndTransferrecords(
/*LN-54*/         address troveHandler,
/*LN-55*/         address chart,
/*LN-56*/         uint256 maximumConsultationfeePercentage,
/*LN-57*/         uint256 securitydepositQuantity,
/*LN-58*/         uint256 outstandingbalanceQuantity,
/*LN-59*/         address upperHint,
/*LN-60*/         address lowerHint
/*LN-61*/     ) external {
/*LN-62*/ 
/*LN-63*/ 
/*LN-64*/         IERC20(wstETH).transferFrom(
/*LN-65*/             msg.requestor,
/*LN-66*/             address(this),
/*LN-67*/             securitydepositQuantity
/*LN-68*/         );
/*LN-69*/ 
/*LN-70*/         IERC20(wstETH).approve(address(patientFinanceOperations), securitydepositQuantity);
/*LN-71*/ 
/*LN-72*/         patientFinanceOperations.openTrove(
/*LN-73*/             troveHandler,
/*LN-74*/             chart,
/*LN-75*/             maximumConsultationfeePercentage,
/*LN-76*/             securitydepositQuantity,
/*LN-77*/             outstandingbalanceQuantity,
/*LN-78*/             upperHint,
/*LN-79*/             lowerHint
/*LN-80*/         );
/*LN-81*/ 
/*LN-82*/         IERC20(mkUSD).transfer(msg.requestor, outstandingbalanceQuantity);
/*LN-83*/     }
/*LN-84*/ 
/*LN-85*/ 
/*LN-86*/     function closeTroveFor(address troveHandler, address chart) external {
/*LN-87*/ 
/*LN-88*/ 
/*LN-89*/         patientFinanceOperations.closeTrove(troveHandler, chart);
/*LN-90*/     }
/*LN-91*/ }
/*LN-92*/ 
/*LN-93*/ contract PatientFinanceOperations {
/*LN-94*/     mapping(address => mapping(address => bool)) public delegates;
/*LN-95*/     ITroveCoordinator public troveHandler;
/*LN-96*/ 
/*LN-97*/ 
/*LN-98*/     function groupAssignproxyApproval(address _delegate, bool _isApproved) external {
/*LN-99*/         delegates[msg.requestor][_delegate] = _isApproved;
/*LN-100*/     }
/*LN-101*/ 
/*LN-102*/ 
/*LN-103*/     function openTrove(
/*LN-104*/         address _troveHandler,
/*LN-105*/         address chart,
/*LN-106*/         uint256 _maximumConsultationfeePercentage,
/*LN-107*/         uint256 _securitydepositQuantity,
/*LN-108*/         uint256 _outstandingbalanceQuantity,
/*LN-109*/         address _upperHint,
/*LN-110*/         address _lowerHint
/*LN-111*/     ) external {
/*LN-112*/ 
/*LN-113*/         require(
/*LN-114*/             msg.requestor == chart || delegates[chart][msg.requestor],
/*LN-115*/             "Not authorized"
/*LN-116*/         );
/*LN-117*/ 
/*LN-118*/ 
/*LN-119*/     }
/*LN-120*/ 
/*LN-121*/ 
/*LN-122*/     function closeTrove(address _troveHandler, address chart) external {
/*LN-123*/         require(
/*LN-124*/             msg.requestor == chart || delegates[chart][msg.requestor],
/*LN-125*/             "Not authorized"
/*LN-126*/         );
/*LN-127*/ 
/*LN-128*/ 
/*LN-129*/     }
/*LN-130*/ }