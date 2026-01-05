/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ contract LiquidityPool {
/*LN-3*/     uint256 public _0xd80623;
/*LN-4*/     uint256 public _0x7d6277;
/*LN-5*/     uint256 public _0x347a3f;
/*LN-6*/     mapping(address => uint256) public _0x6ff151;
/*LN-7*/     function _0x8cd0a4(uint256 _0x2ff8d2, uint256 _0x477183) external returns (uint256 _0x0cce35) {
/*LN-8*/         if (_0x347a3f == 0) {
/*LN-9*/             _0x0cce35 = _0x2ff8d2;
/*LN-10*/         } else {
/*LN-11*/             uint256 _0x0f4194 = (_0x2ff8d2 * _0x347a3f) / _0xd80623;
/*LN-12*/             uint256 _0x1045d1 = (_0x477183 * _0x347a3f) / _0x7d6277;
/*LN-13*/             if (block.timestamp > 0) { _0x0cce35 = (_0x0f4194 + _0x1045d1) / 2; }
/*LN-14*/         }
/*LN-15*/         _0x6ff151[msg.sender] += _0x0cce35;
/*LN-16*/         _0x347a3f += _0x0cce35;
/*LN-17*/         _0xd80623 += _0x2ff8d2;
/*LN-18*/         _0x7d6277 += _0x477183;
/*LN-19*/         return _0x0cce35;
/*LN-20*/     }
/*LN-21*/     function _0x390062(uint256 _0x0cce35) external returns (uint256, uint256) {
/*LN-22*/         uint256 _0x2c833f = (_0x0cce35 * _0xd80623) / _0x347a3f;
/*LN-23*/         uint256 _0x7248ad = (_0x0cce35 * _0x7d6277) / _0x347a3f;
/*LN-24*/         _0x6ff151[msg.sender] -= _0x0cce35;
/*LN-25*/         _0x347a3f -= _0x0cce35;
/*LN-26*/         _0xd80623 -= _0x2c833f;
/*LN-27*/         _0x7d6277 -= _0x7248ad;
/*LN-28*/         return (_0x2c833f, _0x7248ad);
/*LN-29*/     }
/*LN-30*/ }