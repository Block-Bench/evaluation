/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title Nomad Bridge Replica Contract (Vulnerable Version)
/*LN-6*/  * @notice This contract demonstrates the vulnerability that led to the $190M Nomad Bridge hack
/*LN-7*/  * @dev August 1, 2022 - One of the largest bridge hacks in history
/*LN-8*/  *
/*LN-9*/  * VULNERABILITY: Improper message validation in cross-chain bridge
/*LN-10*/  *
/*LN-11*/  * ROOT CAUSE:
/*LN-12*/  * The Replica contract's process() function relies on messages() mapping to check if
/*LN-13*/  * a message has been processed. During an upgrade, the messages mapping wasn't properly
/*LN-14*/  * initialized, leaving the zero-value hash (0x0000...0000) as "accepted".
/*LN-15*/  *
/*LN-16*/  * Attackers could craft messages with a zero hash, bypassing the validation that
/*LN-17*/  * messages must be committed before being processed.
/*LN-18*/  *
/*LN-19*/  * ATTACK VECTOR:
/*LN-20*/  * 1. Attacker copies a legitimate bridge transaction's message structure
/*LN-21*/  * 2. Modifies the recipient address to their own address
/*LN-22*/  * 3. Ensures the message hashes to zero OR uses zero as acceptedRoot
/*LN-23*/  * 4. Calls process() which accepts the message as valid
/*LN-24*/  * 5. Bridge transfers tokens to attacker without any actual deposit
/*LN-25*/  *
/*LN-26*/  * The vulnerability allowed anyone to replay messages and claim tokens without
/*LN-27*/  * having made corresponding deposits on the source chain.
/*LN-28*/  */
/*LN-29*/ 
/*LN-30*/ contract VulnerableNomadReplica {
/*LN-31*/     // Message status enum
/*LN-32*/     enum MessageStatus {
/*LN-33*/         None,
/*LN-34*/         Pending,
/*LN-35*/         Processed
/*LN-36*/     }
/*LN-37*/ 
/*LN-38*/     // Mapping of message hash to status
/*LN-39*/     // VULNERABILITY: After contract upgrade, this was not properly initialized
/*LN-40*/     // The zero hash (0x00...00) was implicitly treated as "Processed" due to
/*LN-41*/     // how the confirmation logic worked
/*LN-42*/     mapping(bytes32 => MessageStatus) public messages;
/*LN-43*/ 
/*LN-44*/     // The "confirmed" root for messages
/*LN-45*/     // VULNERABILITY: This was set to 0x00...00 after upgrade, accepting all zero-hash messages
/*LN-46*/     bytes32 public acceptedRoot;
/*LN-47*/ 
/*LN-48*/     // Bridge router that handles the actual token transfers
/*LN-49*/     address public bridgeRouter;
/*LN-50*/ 
/*LN-51*/     // Nonce tracking
/*LN-52*/     mapping(uint32 => uint32) public nonces;
/*LN-53*/ 
/*LN-54*/     event MessageProcessed(bytes32 indexed messageHash, bool success);
/*LN-55*/ 
/*LN-56*/     constructor(address _bridgeRouter) {
/*LN-57*/         bridgeRouter = _bridgeRouter;
/*LN-58*/     }
/*LN-59*/ 
/*LN-60*/     /**
/*LN-61*/      * @notice Process a cross-chain message
/*LN-62*/      * @param _message The formatted message to process
/*LN-63*/      * @return success Whether the message was successfully processed
/*LN-64*/      *
/*LN-65*/      * VULNERABILITY IS HERE:
/*LN-66*/      * The function checks if acceptedRoot matches the message commitment,
/*LN-67*/      * but after the upgrade, acceptedRoot was 0x00...00, and messages
/*LN-68*/      * could be crafted to match this zero value, bypassing proper validation.
/*LN-69*/      */
/*LN-70*/     function process(bytes memory _message) external returns (bool success) {
/*LN-71*/         bytes32 messageHash = keccak256(_message);
/*LN-72*/ 
/*LN-73*/         // Check if message has already been processed
/*LN-74*/         require(
/*LN-75*/             messages[messageHash] != MessageStatus.Processed,
/*LN-76*/             "Already processed"
/*LN-77*/         );
/*LN-78*/ 
/*LN-79*/         // VULNERABILITY: This check is insufficient!
/*LN-80*/         // After the upgrade, acceptedRoot was 0x00...00
/*LN-81*/         // Attackers could craft messages where _messageRoot() returns 0x00...00
/*LN-82*/         // or simply ensure the message passes this check
/*LN-83*/         bytes32 root = _messageRoot(_message);
/*LN-84*/         require(root == acceptedRoot, "Invalid root");
/*LN-85*/ 
/*LN-86*/         // Mark as processed
/*LN-87*/         messages[messageHash] = MessageStatus.Processed;
/*LN-88*/ 
/*LN-89*/         // Forward to bridge router for token transfer
/*LN-90*/         (bool routerSuccess, ) = bridgeRouter.call(_message);
/*LN-91*/ 
/*LN-92*/         emit MessageProcessed(messageHash, routerSuccess);
/*LN-93*/         return routerSuccess;
/*LN-94*/     }
/*LN-95*/ 
/*LN-96*/     /**
/*LN-97*/      * @notice Derive the message root (simplified)
/*LN-98*/      * @dev In the real contract, this was supposed to verify against a merkle root
/*LN-99*/      * @dev In the vulnerable version, this could return 0x00..00 for crafted messages
/*LN-100*/      */
/*LN-101*/     function _messageRoot(
/*LN-102*/         bytes memory _message
/*LN-103*/     ) internal pure returns (bytes32) {
/*LN-104*/         // Simplified: In reality, this should verify against a proper merkle proof
/*LN-105*/         // The vulnerability was that messages could be crafted to match acceptedRoot
/*LN-106*/         // when acceptedRoot was incorrectly set to 0x00...00
/*LN-107*/ 
/*LN-108*/         // For demonstration: If message starts with zero bytes, return zero root
/*LN-109*/         if (_message.length > 32 && uint256(bytes32(_message)) == 0) {
/*LN-110*/             return bytes32(0);
/*LN-111*/         }
/*LN-112*/ 
/*LN-113*/         return keccak256(_message);
/*LN-114*/     }
/*LN-115*/ 
/*LN-116*/     /**
/*LN-117*/      * @notice Set the accepted root (admin function)
/*LN-118*/      * @dev VULNERABILITY: After upgrade, this was mistakenly set to 0x00...00
/*LN-119*/      */
/*LN-120*/     function setAcceptedRoot(bytes32 _newRoot) external {
/*LN-121*/         acceptedRoot = _newRoot;
/*LN-122*/     }
/*LN-123*/ }
/*LN-124*/ 
/*LN-125*/ /**
/*LN-126*/  * REAL-WORLD IMPACT:
/*LN-127*/  * - $190M stolen in August 2022
/*LN-128*/  * - One of the largest bridge hacks ever
/*LN-129*/  * - Hundreds of copycats repeated the attack within hours
/*LN-130*/  * - 41 different tokens drained
/*LN-131*/  *
/*LN-132*/  * FIX:
/*LN-133*/  * The fix required:
/*LN-134*/  * 1. Proper initialization of the messages mapping after upgrades
/*LN-135*/  * 2. Ensuring acceptedRoot is never 0x00...00 unless explicitly intended
/*LN-136*/  * 3. Additional validation that messages are properly committed before processing
/*LN-137*/  * 4. Implementing emergency pause mechanisms
/*LN-138*/  *
/*LN-139*/  * KEY LESSON:
/*LN-140*/  * Contract upgrades must carefully preserve and re-initialize state.
/*LN-141*/  * A single uninitialized storage slot (acceptedRoot = 0x00...00) led to
/*LN-142*/  * one of the largest DeFi hacks in history.
/*LN-143*/  *
/*LN-144*/  */
/*LN-145*/ 