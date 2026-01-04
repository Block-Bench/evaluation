// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NomadReplica {
    // Message status enum
    enum MessageStatus {
        None,
        Pending,
        Processed
    }

    // Mapping of message hash to status
    
    mapping(bytes32 => MessageStatus) public messages;
   

    // The "confirmed" root for messages
    bytes32 public acceptedRoot;

    // Bridge router that handles the actual token transfers
    address public bridgeRouter;

    // Nonce tracking
    mapping(uint32 => uint32) public nonces;

    event MessageProcessed(bytes32 indexed messageHash, bool success);

    constructor(address _bridgeRouter) {
        bridgeRouter = _bridgeRouter;
    }

    /**
     * @notice Process a cross-chain message
     * @param _message The formatted message to process
     * @return success Whether the message was successfully processed
     *
     * The function checks if acceptedRoot matches the message commitment,
     and processes the message if valid.
     
     */
    function process(bytes memory _message) external returns (bool success) {
        bytes32 messageHash = keccak256(_message);

        // Check if message has already been processed
        require(
            messages[messageHash] != MessageStatus.Processed,
            "Already processed"
        );

        
        
        bytes32 root = _messageRoot(_message);
        require(root == acceptedRoot, "Invalid root");

        // Mark as processed
        messages[messageHash] = MessageStatus.Processed;

        // Forward to bridge router for token transfer
        (bool routerSuccess, ) = bridgeRouter.call(_message);

        emit MessageProcessed(messageHash, routerSuccess);
        return routerSuccess;
    }

    /**
     * @notice Derive the message root (simplified)
     * @dev In the real contract, this was supposed to verify against a merkle root
     */
    function _messageRoot(
        bytes memory _message
    ) internal pure returns (bytes32) {
        // Simplified: In reality, this should verify against a proper merkle proof
        

        // For demonstration: If message starts with zero bytes, return zero root
        if (_message.length > 32 && uint256(bytes32(_message)) == 0) {
            return bytes32(0);
        }

        return keccak256(_message);
    }

    function setAcceptedRoot(bytes32 _newRoot) external {
        acceptedRoot = _newRoot;
    }
}
