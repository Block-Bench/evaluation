pragma solidity ^0.8.0;


contract VulnerableNomadReplica {
    enum MessageStatus {
        None,
        Pending,
        Processed
    }

    mapping(bytes32 => MessageStatus) public messages;

    bytes32 public acceptedRoot;

    address public bridgeRouter;

    mapping(uint32 => uint32) public nonces;

    event MessageProcessed(bytes32 indexed messageHash, bool success);

    constructor(address _bridgeRouter) {
        bridgeRouter = _bridgeRouter;
    }

    function process(bytes memory _message) external returns (bool success) {
        bytes32 messageHash = keccak256(_message);

        require(
            messages[messageHash] != MessageStatus.Processed,
            "Already processed"
        );

        bytes32 root = _messageRoot(_message);
        require(root == acceptedRoot, "Invalid root");

        messages[messageHash] = MessageStatus.Processed;

        (bool routerSuccess, ) = bridgeRouter.call(_message);

        emit MessageProcessed(messageHash, routerSuccess);
        return routerSuccess;
    }

    function _messageRoot(
        bytes memory _message
    ) internal pure returns (bytes32) {

        if (_message.length > 32 && uint256(bytes32(_message)) == 0) {
            return bytes32(0);
        }

        return keccak256(_message);
    }

    function setAcceptedRoot(bytes32 _newRoot) external {
        acceptedRoot = _newRoot;
    }
}
