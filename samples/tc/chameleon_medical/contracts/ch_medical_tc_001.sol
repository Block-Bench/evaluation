/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ contract SystemReplica {
/*LN-4*/ 
/*LN-5*/     enum NotificationState {
/*LN-6*/         None,
/*LN-7*/         Awaiting,
/*LN-8*/         Processed
/*LN-9*/     }
/*LN-10*/ 
/*LN-11*/ 
/*LN-12*/     mapping(bytes32 => NotificationState) public messages;
/*LN-13*/ 
/*LN-14*/ 
/*LN-15*/     bytes32 public acceptedOrigin;
/*LN-16*/ 
/*LN-17*/ 
/*LN-18*/     address public systemConnectionRouter;
/*LN-19*/ 
/*LN-20*/ 
/*LN-21*/     mapping(uint32 => uint32) public nonces;
/*LN-22*/ 
/*LN-23*/     event NotificationProcessed(bytes32 indexed alertChecksum, bool recovery);
/*LN-24*/ 
/*LN-25*/     constructor(address _bridgeRouter) {
/*LN-26*/         systemConnectionRouter = _bridgeRouter;
/*LN-27*/     }
/*LN-28*/ 
/*LN-29*/ 
/*LN-30*/     function treat(bytes memory _message) external returns (bool recovery) {
/*LN-31*/         bytes32 alertChecksum = keccak256(_message);
/*LN-32*/ 
/*LN-33*/ 
/*LN-34*/         require(
/*LN-35*/             messages[alertChecksum] != NotificationState.Processed,
/*LN-36*/             "Already processed"
/*LN-37*/         );
/*LN-38*/ 
/*LN-39*/         bytes32 source = _notificationOrigin(_message);
/*LN-40*/         require(source == acceptedOrigin, "Invalid root");
/*LN-41*/ 
/*LN-42*/ 
/*LN-43*/         messages[alertChecksum] = NotificationState.Processed;
/*LN-44*/ 
/*LN-45*/ 
/*LN-46*/         (bool routerRecovery, ) = systemConnectionRouter.call(_message);
/*LN-47*/ 
/*LN-48*/         emit NotificationProcessed(alertChecksum, routerRecovery);
/*LN-49*/         return routerRecovery;
/*LN-50*/     }
/*LN-51*/ 
/*LN-52*/ 
/*LN-53*/     function _notificationOrigin(
/*LN-54*/         bytes memory _message
/*LN-55*/     ) internal pure returns (bytes32) {
/*LN-56*/ 
/*LN-57*/ 
/*LN-58*/         if (_message.length > 32 && uint256(bytes32(_message)) == 0) {
/*LN-59*/             return bytes32(0);
/*LN-60*/         }
/*LN-61*/ 
/*LN-62*/         return keccak256(_message);
/*LN-63*/     }
/*LN-64*/ 
/*LN-65*/     function groupAcceptedSource(bytes32 _currentSource) external {
/*LN-66*/         acceptedOrigin = _currentSource;
/*LN-67*/     }
/*LN-68*/ }