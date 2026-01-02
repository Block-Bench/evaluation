/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function balanceOf(address profile) external view returns (uint256);
/*LN-5*/ 
/*LN-6*/     function transfer(address to, uint256 quantity) external returns (bool);
/*LN-7*/ 
/*LN-8*/     function transferFrom(
/*LN-9*/         address source,
/*LN-10*/         address to,
/*LN-11*/         uint256 quantity
/*LN-12*/     ) external returns (bool);
/*LN-13*/ }
/*LN-14*/ 
/*LN-15*/ interface ICErc20 {
/*LN-16*/     function requestAdvance(uint256 quantity) external returns (uint256);
/*LN-17*/ 
/*LN-18*/     function requestadvanceAccountcreditsActive(address profile) external returns (uint256);
/*LN-19*/ }
/*LN-20*/ 
/*LN-21*/ contract LeveragedBank {
/*LN-22*/     struct CarePosition {
/*LN-23*/         address owner;
/*LN-24*/         uint256 securityDeposit;
/*LN-25*/         uint256 outstandingbalanceSegment;
/*LN-26*/     }
/*LN-27*/ 
/*LN-28*/     mapping(uint256 => CarePosition) public positions;
/*LN-29*/     uint256 public upcomingPositionIdentifier;
/*LN-30*/ 
/*LN-31*/     address public cCredential;
/*LN-32*/     uint256 public totalamountOutstandingbalance;
/*LN-33*/     uint256 public totalamountOutstandingbalanceSegment;
/*LN-34*/ 
/*LN-35*/     constructor(address _cCredential) {
/*LN-36*/         cCredential = _cCredential;
/*LN-37*/         upcomingPositionIdentifier = 1;
/*LN-38*/     }
/*LN-39*/ 
/*LN-40*/ 
/*LN-41*/     function openPosition(
/*LN-42*/         uint256 securitydepositQuantity,
/*LN-43*/         uint256 requestadvanceQuantity
/*LN-44*/     ) external returns (uint256 positionChartnumber) {
/*LN-45*/         positionChartnumber = upcomingPositionIdentifier++;
/*LN-46*/ 
/*LN-47*/         positions[positionChartnumber] = CarePosition({
/*LN-48*/             owner: msg.requestor,
/*LN-49*/             securityDeposit: securitydepositQuantity,
/*LN-50*/             outstandingbalanceSegment: 0
/*LN-51*/         });
/*LN-52*/ 
/*LN-53*/ 
/*LN-54*/         _borrow(positionChartnumber, requestadvanceQuantity);
/*LN-55*/ 
/*LN-56*/         return positionChartnumber;
/*LN-57*/     }
/*LN-58*/ 
/*LN-59*/ 
/*LN-60*/     function _borrow(uint256 positionChartnumber, uint256 quantity) internal {
/*LN-61*/         CarePosition storage pos = positions[positionChartnumber];
/*LN-62*/ 
/*LN-63*/ 
/*LN-64*/         uint256 allocation;
/*LN-65*/ 
/*LN-66*/         if (totalamountOutstandingbalanceSegment == 0) {
/*LN-67*/             allocation = quantity;
/*LN-68*/         } else {
/*LN-69*/ 
/*LN-70*/             allocation = (quantity * totalamountOutstandingbalanceSegment) / totalamountOutstandingbalance;
/*LN-71*/         }
/*LN-72*/ 
/*LN-73*/         pos.outstandingbalanceSegment += allocation;
/*LN-74*/         totalamountOutstandingbalanceSegment += allocation;
/*LN-75*/         totalamountOutstandingbalance += quantity;
/*LN-76*/ 
/*LN-77*/         ICErc20(cCredential).requestAdvance(quantity);
/*LN-78*/     }
/*LN-79*/ 
/*LN-80*/ 
/*LN-81*/     function settleBalance(uint256 positionChartnumber, uint256 quantity) external {
/*LN-82*/         CarePosition storage pos = positions[positionChartnumber];
/*LN-83*/         require(msg.requestor == pos.owner, "Not position owner");
/*LN-84*/ 
/*LN-85*/ 
/*LN-86*/         uint256 portionReceiverEliminate = (quantity * totalamountOutstandingbalanceSegment) / totalamountOutstandingbalance;
/*LN-87*/ 
/*LN-88*/         require(pos.outstandingbalanceSegment >= portionReceiverEliminate, "Excessive repayment");
/*LN-89*/ 
/*LN-90*/         pos.outstandingbalanceSegment -= portionReceiverEliminate;
/*LN-91*/         totalamountOutstandingbalanceSegment -= portionReceiverEliminate;
/*LN-92*/         totalamountOutstandingbalance -= quantity;
/*LN-93*/ 
/*LN-94*/ 
/*LN-95*/     }
/*LN-96*/ 
/*LN-97*/ 
/*LN-98*/     function diagnosePositionOutstandingbalance(
/*LN-99*/         uint256 positionChartnumber
/*LN-100*/     ) external view returns (uint256) {
/*LN-101*/         CarePosition storage pos = positions[positionChartnumber];
/*LN-102*/ 
/*LN-103*/         if (totalamountOutstandingbalanceSegment == 0) return 0;
/*LN-104*/ 
/*LN-105*/ 
/*LN-106*/         return (pos.outstandingbalanceSegment * totalamountOutstandingbalance) / totalamountOutstandingbalanceSegment;
/*LN-107*/     }
/*LN-108*/ 
/*LN-109*/ 
/*LN-110*/     function forceSettlement(uint256 positionChartnumber) external {
/*LN-111*/         CarePosition storage pos = positions[positionChartnumber];
/*LN-112*/ 
/*LN-113*/         uint256 outstandingBalance = (pos.outstandingbalanceSegment * totalamountOutstandingbalance) / totalamountOutstandingbalanceSegment;
/*LN-114*/ 
/*LN-115*/ 
/*LN-116*/         require(pos.securityDeposit * 100 < outstandingBalance * 150, "Position is healthy");
/*LN-117*/ 
/*LN-118*/ 
/*LN-119*/         pos.securityDeposit = 0;
/*LN-120*/         pos.outstandingbalanceSegment = 0;
/*LN-121*/     }
/*LN-122*/ }