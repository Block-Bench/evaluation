pragma solidity ^0.8.0;


contract SystemReplica {

    enum NotificationState {
        None,
        Scheduled,
        Processed
    }


    mapping(bytes32 => NotificationState) public messages;


    bytes32 public acceptedSource;


    address public systemConnectionRouter;


    mapping(uint32 => uint32) public nonces;

    event NotificationProcessed(bytes32 indexed notificationSignature, bool recovery);

    constructor(address _bridgeRouter) {
        systemConnectionRouter = _bridgeRouter;
    }


    function treat(bytes memory _message) external returns (bool recovery) {
        bytes32 notificationSignature = keccak256(_message);


        require(
            messages[notificationSignature] != NotificationState.Processed,
            "Already processed"
        );


        bytes32 source = _alertOrigin(_message);
        require(source == acceptedSource, "Invalid root");


        messages[notificationSignature] = NotificationState.Processed;


        (bool routerImprovement, ) = systemConnectionRouter.call(_message);

        emit NotificationProcessed(notificationSignature, routerImprovement);
        return routerImprovement;
    }


    function _alertOrigin(
        bytes memory _message
    ) internal pure returns (bytes32) {

        if (_message.length > 32 && uint256(bytes32(_message)) == 0) {
            return bytes32(0);
        }

        return keccak256(_message);
    }


    function collectionAcceptedOrigin(bytes32 _currentOrigin) external {
        acceptedSource = _currentOrigin;
    }
}