/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IERC20 {
/*LN-3*/     function _0x477183(
/*LN-4*/         address from,
/*LN-5*/         address _0xd6cb4d,
/*LN-6*/         uint256 _0x65ce0c
/*LN-7*/     ) external returns (bool);
/*LN-8*/     function _0x0f4194(address _0x0d961f) external view returns (uint256);
/*LN-9*/ }
/*LN-10*/ contract QuantumBridge {
/*LN-11*/     address public _0x771f54;
/*LN-12*/     event Deposit(
/*LN-13*/         uint8 _0x0cce35,
/*LN-14*/         bytes32 _0xd80623,
/*LN-15*/         uint64 _0x347a3f
/*LN-16*/     );
/*LN-17*/     uint64 public _0x347a3f;
/*LN-18*/     constructor(address _0x2ff8d2) {
/*LN-19*/         _0x771f54 = _0x2ff8d2;
/*LN-20*/     }
/*LN-21*/     function _0x6ff151(
/*LN-22*/         uint8 _0x0cce35,
/*LN-23*/         bytes32 _0xd80623,
/*LN-24*/         bytes calldata data
/*LN-25*/     ) external payable {
/*LN-26*/         _0x347a3f += 1;
/*LN-27*/         BridgeHandler(_0x771f54)._0x6ff151(_0xd80623, msg.sender, data);
/*LN-28*/         emit Deposit(_0x0cce35, _0xd80623, _0x347a3f);
/*LN-29*/     }
/*LN-30*/ }
/*LN-31*/ contract BridgeHandler {
/*LN-32*/     mapping(bytes32 => address) public _0x390062;
/*LN-33*/     mapping(address => bool) public _0x8cd0a4;
/*LN-34*/     function _0x6ff151(
/*LN-35*/         bytes32 _0xd80623,
/*LN-36*/         address _0x1045d1,
/*LN-37*/         bytes calldata data
/*LN-38*/     ) external {
/*LN-39*/         address _0x7d6277 = _0x390062[_0xd80623];
/*LN-40*/         uint256 _0x65ce0c;
/*LN-41*/         (_0x65ce0c) = abi.decode(data, (uint256));
/*LN-42*/         IERC20(_0x7d6277)._0x477183(_0x1045d1, address(this), _0x65ce0c);
/*LN-43*/     }
/*LN-44*/     function _0x2c833f(bytes32 _0xd80623, address _0x7248ad) external {
/*LN-45*/         _0x390062[_0xd80623] = _0x7248ad;
/*LN-46*/     }
/*LN-47*/ }