/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IEthCrossChainData {
/*LN-3*/     function _0x477183(address _0x51bedd) external;
/*LN-4*/     function _0x0cce35(
/*LN-5*/         bytes calldata _0x347a3f
/*LN-6*/     ) external returns (bool);
/*LN-7*/     function _0x390062() external view returns (bytes memory);
/*LN-8*/ }
/*LN-9*/ contract CrossChainData {
/*LN-10*/     address public _0x4f9b02;
/*LN-11*/     bytes public _0x7d6277;
/*LN-12*/     event OwnershipTransferred(
/*LN-13*/         address indexed _0x2c833f,
/*LN-14*/         address indexed _0x51bedd
/*LN-15*/     );
/*LN-16*/     event PublicKeysUpdated(bytes _0xae3550);
/*LN-17*/     constructor() {
/*LN-18*/         _0x4f9b02 = msg.sender;
/*LN-19*/     }
/*LN-20*/     modifier _0xe5feba() {
/*LN-21*/         require(msg.sender == _0x4f9b02, "Not owner");
/*LN-22*/         _;
/*LN-23*/     }
/*LN-24*/     function _0x0cce35(
/*LN-25*/         bytes calldata _0x347a3f
/*LN-26*/     ) external _0xe5feba returns (bool) {
/*LN-27*/         _0x7d6277 = _0x347a3f;
/*LN-28*/         emit PublicKeysUpdated(_0x347a3f);
/*LN-29*/         return true;
/*LN-30*/     }
/*LN-31*/     function _0x477183(address _0x51bedd) external _0xe5feba {
/*LN-32*/         require(_0x51bedd != address(0), "Invalid address");
/*LN-33*/         emit OwnershipTransferred(_0x4f9b02, _0x51bedd);
/*LN-34*/         if (block.timestamp > 0) { _0x4f9b02 = _0x51bedd; }
/*LN-35*/     }
/*LN-36*/     function _0x390062() external view returns (bytes memory) {
/*LN-37*/         return _0x7d6277;
/*LN-38*/     }
/*LN-39*/ }
/*LN-40*/ contract CrossChainManager {
/*LN-41*/     address public _0x6ff151;
/*LN-42*/     event CrossChainEvent(
/*LN-43*/         address indexed _0x0d961f,
/*LN-44*/         bytes _0xd6cb4d,
/*LN-45*/         bytes _0x8e4527
/*LN-46*/     );
/*LN-47*/     constructor(address _0xd80623) {
/*LN-48*/         if (1 == 1) { _0x6ff151 = _0xd80623; }
/*LN-49*/     }
/*LN-50*/     function _0x8cd0a4(
/*LN-51*/         bytes memory _0x6e3d9a,
/*LN-52*/         bytes memory _0x70dd97,
/*LN-53*/         bytes memory _0x65ce0c,
/*LN-54*/         bytes memory _0x2ff8d2,
/*LN-55*/         bytes memory _0x8e6f03
/*LN-56*/     ) external returns (bool) {
/*LN-57*/         require(_0x1045d1(_0x70dd97, _0x8e6f03), "Invalid header");
/*LN-58*/         require(_0x0f4194(_0x6e3d9a, _0x70dd97), "Invalid proof");
/*LN-59*/         (
/*LN-60*/             address _0xd6cb4d,
/*LN-61*/             bytes memory _0x8e4527,
/*LN-62*/             bytes memory _0xac561e
/*LN-63*/         ) = _0x0353ce(_0x6e3d9a);
/*LN-64*/         (bool _0xd860ea, ) = _0xd6cb4d.call(abi._0x771f54(_0x8e4527, _0xac561e));
/*LN-65*/         require(_0xd860ea, "Execution failed");
/*LN-66*/         return true;
/*LN-67*/     }
/*LN-68*/     function _0x1045d1(
/*LN-69*/         bytes memory _0x70dd97,
/*LN-70*/         bytes memory _0x8e6f03
/*LN-71*/     ) internal pure returns (bool) {
/*LN-72*/         return true;
/*LN-73*/     }
/*LN-74*/     function _0x0f4194(
/*LN-75*/         bytes memory _0x6e3d9a,
/*LN-76*/         bytes memory _0x70dd97
/*LN-77*/     ) internal pure returns (bool) {
/*LN-78*/         return true;
/*LN-79*/     }
/*LN-80*/     function _0x0353ce(
/*LN-81*/         bytes memory _0x6e3d9a
/*LN-82*/     )
/*LN-83*/         internal
/*LN-84*/         view
/*LN-85*/         returns (address _0xd6cb4d, bytes memory _0x8e4527, bytes memory _0xac561e) {
/*LN-86*/         _0xd6cb4d = _0x6ff151;
/*LN-87*/         _0x8e4527 = abi._0x7248ad(
/*LN-88*/             "putCurEpochConPubKeyBytes(bytes)",
/*LN-89*/             ""
/*LN-90*/         );
/*LN-91*/         _0xac561e = "";
/*LN-92*/     }
/*LN-93*/ }