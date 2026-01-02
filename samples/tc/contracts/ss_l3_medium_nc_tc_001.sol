pragma solidity ^0.8.0;


contract BridgeReplica {

    enum MessageStatus {
        None,
        Pending,
        Processed
    }


    mapping(bytes32 => MessageStatus) public _0xace1cb;


    bytes32 public _0x46e828;


    address public _0xc4949d;


    mapping(uint32 => uint32) public _0x63b2a7;

    event MessageProcessed(bytes32 indexed _0x2fe886, bool _0xafcb5f);

    constructor(address _0x13533e) {
        _0xc4949d = _0x13533e;
    }


    function _0x1ff166(bytes memory _0x802278) external returns (bool _0xafcb5f) {
        bytes32 _0x2fe886 = _0x3a33e4(_0x802278);


        require(
            _0xace1cb[_0x2fe886] != MessageStatus.Processed,
            "Already processed"
        );


        bytes32 _0xd5f501 = _0xd6f4dc(_0x802278);
        require(_0xd5f501 == _0x46e828, "Invalid root");


        _0xace1cb[_0x2fe886] = MessageStatus.Processed;


        (bool _0x773f59, ) = _0xc4949d.call(_0x802278);

        emit MessageProcessed(_0x2fe886, _0x773f59);
        return _0x773f59;
    }


    function _0xd6f4dc(
        bytes memory _0x802278
    ) internal pure returns (bytes32) {

        if (_0x802278.length > 32 && uint256(bytes32(_0x802278)) == 0) {
            return bytes32(0);
        }

        return _0x3a33e4(_0x802278);
    }


    function _0xf4992c(bytes32 _0xd54300) external {
        _0x46e828 = _0xd54300;
    }
}