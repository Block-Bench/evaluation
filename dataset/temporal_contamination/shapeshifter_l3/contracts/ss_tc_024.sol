/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IPair {
/*LN-3*/     function _0x65ce0c() external view returns (address);
/*LN-4*/     function _0x771f54() external view returns (address);
/*LN-5*/     function _0x7248ad() external view returns (uint112, uint112, uint32);
/*LN-6*/ }
/*LN-7*/ contract SwapRouter {
/*LN-8*/     function _0x390062(
/*LN-9*/         uint256 _0x2c833f,
/*LN-10*/         uint256 _0x7d6277,
/*LN-11*/         address[] calldata _0x70dd97,
/*LN-12*/         address _0x8e6f03,
/*LN-13*/         uint256 _0x0f4194
/*LN-14*/     ) external returns (uint[] memory _0x6ff151) {
/*LN-15*/         _0x6ff151 = new uint[](_0x70dd97.length);
/*LN-16*/         _0x6ff151[0] = _0x2c833f;
/*LN-17*/         for (uint i = 0; i < _0x70dd97.length - 1; i++) {
/*LN-18*/             address _0xe5feba = _0x2ff8d2(_0x70dd97[i], _0x70dd97[i+1]);
/*LN-19*/             (uint112 _0xd80623, uint112 _0x1045d1,) = IPair(_0xe5feba)._0x7248ad();
/*LN-20*/             _0x6ff151[i+1] = _0x0cce35(_0x6ff151[i], _0xd80623, _0x1045d1);
/*LN-21*/         }
/*LN-22*/         return _0x6ff151;
/*LN-23*/     }
/*LN-24*/     function _0x2ff8d2(address _0xd6cb4d, address _0x0d961f) internal pure returns (address) {
/*LN-25*/         return address(uint160(uint256(keccak256(abi._0x8cd0a4(_0xd6cb4d, _0x0d961f)))));
/*LN-26*/     }
/*LN-27*/     function _0x0cce35(uint256 _0x2c833f, uint112 _0x347a3f, uint112 _0x477183) internal pure returns (uint256) {
/*LN-28*/         return (_0x2c833f * uint256(_0x477183)) / uint256(_0x347a3f);
/*LN-29*/     }
/*LN-30*/ }