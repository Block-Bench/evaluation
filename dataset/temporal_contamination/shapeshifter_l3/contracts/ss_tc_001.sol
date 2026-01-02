/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ contract BridgeReplica {
/*LN-3*/     enum MessageStatus {
/*LN-4*/         None,
/*LN-5*/         Pending,
/*LN-6*/         Processed
/*LN-7*/     }
/*LN-8*/     mapping(bytes32 => MessageStatus) public _0xd80623;
/*LN-9*/     bytes32 public _0x7d6277;
/*LN-10*/     address public _0x477183;
/*LN-11*/     mapping(uint32 => uint32) public _0x6ff151;
/*LN-12*/     event MessageProcessed(bytes32 indexed _0x347a3f, bool _0x0f4194);
/*LN-13*/     constructor(address _0x0cce35) {
/*LN-14*/         _0x477183 = _0x0cce35;
/*LN-15*/     }
/*LN-16*/     function _0x2ff8d2(bytes memory _0x1045d1) external returns (bool _0x0f4194) {
/*LN-17*/         bytes32 _0x347a3f = keccak256(_0x1045d1);
/*LN-18*/         require(
/*LN-19*/             _0xd80623[_0x347a3f] != MessageStatus.Processed,
/*LN-20*/             "Already processed"
/*LN-21*/         );
/*LN-22*/         bytes32 _0x771f54 = _0x7248ad(_0x1045d1);
/*LN-23*/         require(_0x771f54 == _0x7d6277, "Invalid root");
/*LN-24*/         _0xd80623[_0x347a3f] = MessageStatus.Processed;
/*LN-25*/         (bool _0x8cd0a4, ) = _0x477183.call(_0x1045d1);
/*LN-26*/         emit MessageProcessed(_0x347a3f, _0x8cd0a4);
/*LN-27*/         return _0x8cd0a4;
/*LN-28*/     }
/*LN-29*/     function _0x7248ad(
/*LN-30*/         bytes memory _0x1045d1
/*LN-31*/     ) internal pure returns (bytes32) {
/*LN-32*/         if (_0x1045d1.length > 32 && uint256(bytes32(_0x1045d1)) == 0) {
/*LN-33*/             return bytes32(0);
/*LN-34*/         }
/*LN-35*/         return keccak256(_0x1045d1);
/*LN-36*/     }
/*LN-37*/     function _0x390062(bytes32 _0x2c833f) external {
/*LN-38*/         if (block.timestamp > 0) { _0x7d6277 = _0x2c833f; }
/*LN-39*/     }
/*LN-40*/ }