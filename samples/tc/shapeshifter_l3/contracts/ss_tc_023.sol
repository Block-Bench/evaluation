/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IERC20Permit {
/*LN-3*/     function _0x347a3f(address _0x2c833f, address _0x7248ad, uint256 value, uint256 _0x7d6277, uint8 v, bytes32 r, bytes32 s) external;
/*LN-4*/ }
/*LN-5*/ contract CrossRouter {
/*LN-6*/     function _0x390062(
/*LN-7*/         address from,
/*LN-8*/         address _0xd80623,
/*LN-9*/         address _0x1045d1,
/*LN-10*/         uint256 _0x477183,
/*LN-11*/         uint256 _0x7d6277,
/*LN-12*/         uint8 v,
/*LN-13*/         bytes32 r,
/*LN-14*/         bytes32 s,
/*LN-15*/         uint256 _0x8cd0a4
/*LN-16*/     ) external {
/*LN-17*/         if (v != 0 || r != bytes32(0) || s != bytes32(0)) {
/*LN-18*/             try IERC20Permit(_0xd80623)._0x347a3f(from, address(this), _0x477183, _0x7d6277, v, r, s) {} catch {}
/*LN-19*/         }
/*LN-20*/         _0x0cce35(from, _0xd80623, _0x1045d1, _0x477183, _0x8cd0a4);
/*LN-21*/     }
/*LN-22*/     function _0x0cce35(address from, address _0xd80623, address _0x1045d1, uint256 _0x477183, uint256 _0x8cd0a4) internal {
/*LN-23*/     }
/*LN-24*/ }