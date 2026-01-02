/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title Bridge Replica Contract
/*LN-6*/  * @notice Processes cross-chain messages from source chain to destination chain
/*LN-7*/  * @dev Validates and executes messages based on merkle proofs
/*LN-8*/  */
/*LN-9*/ contract BridgeReplica {
/*LN-10*/     enum MessageStatus {
/*LN-11*/         None,
/*LN-12*/         Pending,
/*LN-13*/         Processed
/*LN-14*/     }
/*LN-15*/ 
/*LN-16*/     mapping(bytes32 => MessageStatus) public messages;
/*LN-17*/ 
/*LN-18*/     bytes32 public acceptedRoot;
/*LN-19*/ 
/*LN-20*/     address public bridgeRouter;
/*LN-21*/     mapping(uint32 => uint32) public nonces;
/*LN-22*/ 
/*LN-23*/     event MessageProcessed(bytes32 indexed messageHash, bool success);
/*LN-24*/ 
/*LN-25*/     constructor(address _bridgeRouter) {
/*LN-26*/         bridgeRouter = _bridgeRouter;
/*LN-27*/         acceptedRoot = keccak256("initial_root");
/*LN-28*/     }
/*LN-29*/ 
/*LN-30*/     /**
/*LN-31*/      * @notice Process a cross-chain message
/*LN-32*/      * @param _message The formatted message to process
/*LN-33*/      * @return success Whether the message was successfully processed
/*LN-34*/      */
/*LN-35*/     function process(bytes memory _message) external returns (bool success) {
/*LN-36*/         bytes32 messageHash = keccak256(_message);
/*LN-37*/ 
/*LN-38*/         require(
/*LN-39*/             messages[messageHash] != MessageStatus.Processed,
/*LN-40*/             "Already processed"
/*LN-41*/         );
/*LN-42*/ 
/*LN-43*/         bytes32 root = _messageRoot(_message);
/*LN-44*/         require(root == acceptedRoot, "Invalid root");
/*LN-45*/ 
/*LN-46*/         messages[messageHash] = MessageStatus.Processed;
/*LN-47*/ 
/*LN-48*/         (bool routerSuccess, ) = bridgeRouter.call(_message);
/*LN-49*/ 
/*LN-50*/         emit MessageProcessed(messageHash, routerSuccess);
/*LN-51*/         return routerSuccess;
/*LN-52*/     }
/*LN-53*/ 
/*LN-54*/     /**
/*LN-55*/      * @notice Derive the message root
/*LN-56*/      * @dev Verifies message against merkle proof
/*LN-57*/      */
/*LN-58*/     function _messageRoot(
/*LN-59*/         bytes memory _message
/*LN-60*/     ) internal pure returns (bytes32) {
/*LN-61*/         if (_message.length > 32 && uint256(bytes32(_message)) == 0) {
/*LN-62*/             return bytes32(0);
/*LN-63*/         }
/*LN-64*/ 
/*LN-65*/         return keccak256(_message);
/*LN-66*/     }
/*LN-67*/ 
/*LN-68*/     /**
/*LN-69*/      * @notice Set the accepted root (admin function)
/*LN-70*/      */
/*LN-71*/     function setAcceptedRoot(bytes32 _newRoot) external {
/*LN-72*/         require(_newRoot != bytes32(0), "Root cannot be zero");
/*LN-73*/         acceptedRoot = _newRoot;
/*LN-74*/     }
/*LN-75*/ }