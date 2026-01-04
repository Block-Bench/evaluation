/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IERC20 {
/*LN-3*/     function transfer(address _0xd860ea, uint256 _0x8e6f03) external returns (bool);
/*LN-4*/     function _0x477183(
/*LN-5*/         address from,
/*LN-6*/         address _0xd860ea,
/*LN-7*/         uint256 _0x8e6f03
/*LN-8*/     ) external returns (bool);
/*LN-9*/     function _0x1045d1(address _0x771f54) external view returns (uint256);
/*LN-10*/     function _0x0d961f(address _0x70dd97, uint256 _0x8e6f03) external returns (bool);
/*LN-11*/ }
/*LN-12*/ contract BridgeGateway {
/*LN-13*/     mapping(uint32 => address) public _0x0353ce;
/*LN-14*/     mapping(address => bool) public _0x0cce35;
/*LN-15*/     event RouteExecuted(uint32 _0x65ce0c, address _0x51bedd, bytes _0xe5feba);
/*LN-16*/     function _0x7248ad(
/*LN-17*/         uint32 _0x65ce0c,
/*LN-18*/         bytes calldata _0x2c833f
/*LN-19*/     ) external payable returns (bytes memory) {
/*LN-20*/         address _0x347a3f = _0x0353ce[_0x65ce0c];
/*LN-21*/         require(_0x347a3f != address(0), "Invalid route");
/*LN-22*/         require(_0x0cce35[_0x347a3f], "Route not approved");
/*LN-23*/         (bool _0xd6cb4d, bytes memory _0xe5feba) = _0x347a3f.call(_0x2c833f);
/*LN-24*/         require(_0xd6cb4d, "Route execution failed");
/*LN-25*/         emit RouteExecuted(_0x65ce0c, msg.sender, _0xe5feba);
/*LN-26*/         return _0xe5feba;
/*LN-27*/     }
/*LN-28*/     function _0x2ff8d2(uint32 _0x65ce0c, address _0x347a3f) external {
/*LN-29*/         _0x0353ce[_0x65ce0c] = _0x347a3f;
/*LN-30*/         _0x0cce35[_0x347a3f] = true;
/*LN-31*/     }
/*LN-32*/ }
/*LN-33*/ contract Route {
/*LN-34*/     function _0x7d6277(
/*LN-35*/         address _0xd80623,
/*LN-36*/         address _0x6ff151,
/*LN-37*/         uint256 _0x8e6f03,
/*LN-38*/         address _0x390062,
/*LN-39*/         bytes32 _0x0f4194,
/*LN-40*/         bytes calldata _0x8cd0a4
/*LN-41*/     ) external payable returns (uint256) {
/*LN-42*/         if (_0x8cd0a4.length > 0) {
/*LN-43*/             (bool _0xd6cb4d, ) = _0xd80623.call(_0x8cd0a4);
/*LN-44*/             require(_0xd6cb4d, "Swap failed");
/*LN-45*/         }
/*LN-46*/         return _0x8e6f03;
/*LN-47*/     }
/*LN-48*/ }