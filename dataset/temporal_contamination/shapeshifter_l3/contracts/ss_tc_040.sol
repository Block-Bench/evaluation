/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IERC20 {
/*LN-3*/     function transfer(address _0x65ce0c, uint256 _0x2ff8d2) external returns (bool);
/*LN-4*/     function _0x0cce35(
/*LN-5*/         address from,
/*LN-6*/         address _0x65ce0c,
/*LN-7*/         uint256 _0x2ff8d2
/*LN-8*/     ) external returns (bool);
/*LN-9*/     function _0x7d6277(address _0x347a3f) external view returns (uint256);
/*LN-10*/     function _0x2c833f(address _0x477183, uint256 _0x2ff8d2) external returns (bool);
/*LN-11*/ }
/*LN-12*/ contract CDPChamber {
/*LN-13*/     uint8 public constant OPERATION_CALL = 30;
/*LN-14*/     uint8 public constant OPERATION_DELEGATECALL = 31;
/*LN-15*/     mapping(address => bool) public _0x8cd0a4;
/*LN-16*/     function _0x390062(
/*LN-17*/         uint8[] memory _0xd80623,
/*LN-18*/         uint256[] memory _0x0f4194,
/*LN-19*/         bytes[] memory _0x0d961f
/*LN-20*/     ) external payable returns (uint256 _0x771f54, uint256 _0x1045d1) {
/*LN-21*/         require(
/*LN-22*/             _0xd80623.length == _0x0f4194.length && _0x0f4194.length == _0x0d961f.length,
/*LN-23*/             "Length mismatch"
/*LN-24*/         );
/*LN-25*/         for (uint256 i = 0; i < _0xd80623.length; i++) {
/*LN-26*/             if (_0xd80623[i] == OPERATION_CALL) {
/*LN-27*/                 (address _0x6ff151, bytes memory callData, , , ) = abi.decode(
/*LN-28*/                     _0x0d961f[i],
/*LN-29*/                     (address, bytes, uint256, uint256, uint256)
/*LN-30*/                 );
/*LN-31*/                 (bool _0x7248ad, ) = _0x6ff151.call{value: _0x0f4194[i]}(callData);
/*LN-32*/                 require(_0x7248ad, "Call failed");
/*LN-33*/             }
/*LN-34*/         }
/*LN-35*/         return (0, 0);
/*LN-36*/     }
/*LN-37*/ }