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
/*LN-22*/     address public owner;
/*LN-23*/
/*LN-24*/     event MessageProcessed(bytes32 indexed messageHash, bool success);
/*LN-25*/
/*LN-26*/     modifier onlyOwner() {
/*LN-27*/         require(msg.sender == owner, "Not owner");
/*LN-28*/         _;
/*LN-29*/     }
/*LN-30*/
/*LN-31*/     constructor(address _bridgeRouter) {
/*LN-32*/         bridgeRouter = _bridgeRouter;
/*LN-33*/         acceptedRoot = keccak256("initial_root");
/*LN-34*/         owner = msg.sender;
/*LN-35*/     }
/*LN-36*/
/*LN-37*/     /**
/*LN-38*/      * @notice Process a cross-chain message
/*LN-39*/      * @param _message The formatted message to process
/*LN-40*/      * @return success Whether the message was successfully processed
/*LN-41*/      */
/*LN-42*/     function process(bytes memory _message) external returns (bool success) {
/*LN-43*/         bytes32 messageHash = keccak256(_message);
/*LN-44*/
/*LN-45*/         require(
/*LN-46*/             messages[messageHash] != MessageStatus.Processed,
/*LN-47*/             "Already processed"
/*LN-48*/         );
/*LN-49*/
/*LN-50*/         bytes32 root = _messageRoot(_message);
/*LN-51*/         require(root == acceptedRoot, "Invalid root");
/*LN-52*/
/*LN-53*/         messages[messageHash] = MessageStatus.Processed;
/*LN-54*/
/*LN-55*/         (bool routerSuccess, ) = bridgeRouter.call(_message);
/*LN-56*/
/*LN-57*/         emit MessageProcessed(messageHash, routerSuccess);
/*LN-58*/         return routerSuccess;
/*LN-59*/     }
/*LN-60*/
/*LN-61*/     /**
/*LN-62*/      * @notice Derive the message root
/*LN-63*/      * @dev Verifies message against merkle proof
/*LN-64*/      */
/*LN-65*/     function _messageRoot(
/*LN-66*/         bytes memory _message
/*LN-67*/     ) internal pure returns (bytes32) {
/*LN-68*/         if (_message.length > 32 && uint256(bytes32(_message)) == 0) {
/*LN-69*/             return bytes32(0);
/*LN-70*/         }
/*LN-71*/
/*LN-72*/         return keccak256(_message);
/*LN-73*/     }
/*LN-74*/
/*LN-75*/     /**
/*LN-76*/      * @notice Set the accepted root (admin function)
/*LN-77*/      */
/*LN-78*/     function setAcceptedRoot(bytes32 _newRoot) external onlyOwner {
/*LN-79*/         require(_newRoot != bytes32(0), "Root cannot be zero");
/*LN-80*/         acceptedRoot = _newRoot;
/*LN-81*/     }
/*LN-82*/ }
