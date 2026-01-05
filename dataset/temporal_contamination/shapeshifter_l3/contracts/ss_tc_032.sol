/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IERC20 {
/*LN-3*/     function transfer(address _0xb01af6, uint256 _0x2f7c62) external returns (bool);
/*LN-4*/     function _0x65ce0c(
/*LN-5*/         address from,
/*LN-6*/         address _0xb01af6,
/*LN-7*/         uint256 _0x2f7c62
/*LN-8*/     ) external returns (bool);
/*LN-9*/     function _0x51bedd(address _0xd860ea) external view returns (uint256);
/*LN-10*/     function _0x4f9b02(address _0xac561e, uint256 _0x2f7c62) external returns (bool);
/*LN-11*/ }
/*LN-12*/ interface IERC721 {
/*LN-13*/     function _0x65ce0c(address from, address _0xb01af6, uint256 _0x3454e7) external;
/*LN-14*/     function _0xae3550(uint256 _0x3454e7) external view returns (address);
/*LN-15*/ }
/*LN-16*/ contract IsolatedLending {
/*LN-17*/     struct PoolData {
/*LN-18*/         uint256 _0x1045d1;
/*LN-19*/         uint256 _0x7d6277;
/*LN-20*/         uint256 _0x347a3f;
/*LN-21*/         uint256 _0xd80623;
/*LN-22*/     }
/*LN-23*/     mapping(address => PoolData) public _0x0f4194;
/*LN-24*/     mapping(uint256 => mapping(address => uint256)) public _0x477183;
/*LN-25*/     mapping(uint256 => mapping(address => uint256)) public _0x2c833f;
/*LN-26*/     IERC721 public _0x70dd97;
/*LN-27*/     uint256 public _0x0d961f;
/*LN-28*/     function _0x771f54() external returns (uint256) {
/*LN-29*/         uint256 _0x3184cf = ++_0x0d961f;
/*LN-30*/         return _0x3184cf;
/*LN-31*/     }
/*LN-32*/     function _0x7248ad(
/*LN-33*/         uint256 _0xc285d4,
/*LN-34*/         address _0x0353ce,
/*LN-35*/         uint256 _0x6e3d9a
/*LN-36*/     ) external returns (uint256 _0x8e6f03) {
/*LN-37*/         IERC20(_0x0353ce)._0x65ce0c(msg.sender, address(this), _0x6e3d9a);
/*LN-38*/         PoolData storage _0xb7cc25 = _0x0f4194[_0x0353ce];
/*LN-39*/         if (_0xb7cc25._0x7d6277 == 0) {
/*LN-40*/             _0x8e6f03 = _0x6e3d9a;
/*LN-41*/             _0xb7cc25._0x7d6277 = _0x6e3d9a;
/*LN-42*/         } else {
/*LN-43*/             _0x8e6f03 =
/*LN-44*/                 (_0x6e3d9a * _0xb7cc25._0x7d6277) /
/*LN-45*/                 _0xb7cc25._0x1045d1;
/*LN-46*/             _0xb7cc25._0x7d6277 += _0x8e6f03;
/*LN-47*/         }
/*LN-48*/         _0xb7cc25._0x1045d1 += _0x6e3d9a;
/*LN-49*/         _0x477183[_0xc285d4][_0x0353ce] += _0x8e6f03;
/*LN-50*/         return _0x8e6f03;
/*LN-51*/     }
/*LN-52*/     function _0x0cce35(
/*LN-53*/         uint256 _0xc285d4,
/*LN-54*/         address _0x0353ce,
/*LN-55*/         uint256 _0x8e4527
/*LN-56*/     ) external returns (uint256 _0x6ff151) {
/*LN-57*/         require(
/*LN-58*/             _0x477183[_0xc285d4][_0x0353ce] >= _0x8e4527,
/*LN-59*/             "Insufficient shares"
/*LN-60*/         );
/*LN-61*/         PoolData storage _0xb7cc25 = _0x0f4194[_0x0353ce];
/*LN-62*/         _0x6ff151 =
/*LN-63*/             (_0x8e4527 * _0xb7cc25._0x1045d1) /
/*LN-64*/             _0xb7cc25._0x7d6277;
/*LN-65*/         _0x477183[_0xc285d4][_0x0353ce] -= _0x8e4527;
/*LN-66*/         _0xb7cc25._0x7d6277 -= _0x8e4527;
/*LN-67*/         _0xb7cc25._0x1045d1 -= _0x6ff151;
/*LN-68*/         IERC20(_0x0353ce).transfer(msg.sender, _0x6ff151);
/*LN-69*/         return _0x6ff151;
/*LN-70*/     }
/*LN-71*/     function _0x8cd0a4(
/*LN-72*/         uint256 _0xc285d4,
/*LN-73*/         address _0x0353ce,
/*LN-74*/         uint256 _0x2ff8d2
/*LN-75*/     ) external returns (uint256 _0xe5feba) {
/*LN-76*/         PoolData storage _0xb7cc25 = _0x0f4194[_0x0353ce];
/*LN-77*/         _0xe5feba =
/*LN-78*/             (_0x2ff8d2 * _0xb7cc25._0x7d6277) /
/*LN-79*/             _0xb7cc25._0x1045d1;
/*LN-80*/         require(
/*LN-81*/             _0x477183[_0xc285d4][_0x0353ce] >= _0xe5feba,
/*LN-82*/             "Insufficient shares"
/*LN-83*/         );
/*LN-84*/         _0x477183[_0xc285d4][_0x0353ce] -= _0xe5feba;
/*LN-85*/         _0xb7cc25._0x7d6277 -= _0xe5feba;
/*LN-86*/         _0xb7cc25._0x1045d1 -= _0x2ff8d2;
/*LN-87*/         IERC20(_0x0353ce).transfer(msg.sender, _0x2ff8d2);
/*LN-88*/         return _0xe5feba;
/*LN-89*/     }
/*LN-90*/     function _0x390062(
/*LN-91*/         uint256 _0xc285d4,
/*LN-92*/         address _0x0353ce
/*LN-93*/     ) external view returns (uint256) {
/*LN-94*/         return _0x477183[_0xc285d4][_0x0353ce];
/*LN-95*/     }
/*LN-96*/     function _0xd6cb4d(address _0x0353ce) external view returns (uint256) {
/*LN-97*/         return _0x0f4194[_0x0353ce]._0x1045d1;
/*LN-98*/     }
/*LN-99*/ }