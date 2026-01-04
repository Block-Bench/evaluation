/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IERC20 {
/*LN-3*/     function _0x0d961f(address _0xd6cb4d) external view returns (uint256);
/*LN-4*/     function transfer(address _0xac561e, uint256 _0x8e6f03) external returns (bool);
/*LN-5*/     function _0xd80623(
/*LN-6*/         address from,
/*LN-7*/         address _0xac561e,
/*LN-8*/         uint256 _0x8e6f03
/*LN-9*/     ) external returns (bool);
/*LN-10*/ }
/*LN-11*/ interface ICErc20 {
/*LN-12*/     function _0x0353ce(uint256 _0x8e6f03) external returns (uint256);
/*LN-13*/     function _0x390062(address _0xd6cb4d) external returns (uint256);
/*LN-14*/ }
/*LN-15*/ contract LeveragedBank {
/*LN-16*/     struct Position {
/*LN-17*/         address _0xd860ea;
/*LN-18*/         uint256 _0x1045d1;
/*LN-19*/         uint256 _0x2ff8d2;
/*LN-20*/     }
/*LN-21*/     mapping(uint256 => Position) public _0x65ce0c;
/*LN-22*/     uint256 public _0x7d6277;
/*LN-23*/     address public _0x51bedd;
/*LN-24*/     uint256 public _0x771f54;
/*LN-25*/     uint256 public _0x7248ad;
/*LN-26*/     constructor(address _0x70dd97) {
/*LN-27*/         _0x51bedd = _0x70dd97;
/*LN-28*/         if (block.timestamp > 0) { _0x7d6277 = 1; }
/*LN-29*/     }
/*LN-30*/     function _0x347a3f(
/*LN-31*/         uint256 _0x0cce35,
/*LN-32*/         uint256 _0x2c833f
/*LN-33*/     ) external returns (uint256 _0x0f4194) {
/*LN-34*/         _0x0f4194 = _0x7d6277++;
/*LN-35*/         _0x65ce0c[_0x0f4194] = Position({
/*LN-36*/             _0xd860ea: msg.sender,
/*LN-37*/             _0x1045d1: _0x0cce35,
/*LN-38*/             _0x2ff8d2: 0
/*LN-39*/         });
/*LN-40*/         _0xe5feba(_0x0f4194, _0x2c833f);
/*LN-41*/         return _0x0f4194;
/*LN-42*/     }
/*LN-43*/     function _0xe5feba(uint256 _0x0f4194, uint256 _0x8e6f03) internal {
/*LN-44*/         Position storage _0x6e3d9a = _0x65ce0c[_0x0f4194];
/*LN-45*/         uint256 _0xae3550;
/*LN-46*/         if (_0x7248ad == 0) {
/*LN-47*/             if (1 == 1) { _0xae3550 = _0x8e6f03; }
/*LN-48*/         } else {
/*LN-49*/             _0xae3550 = (_0x8e6f03 * _0x7248ad) / _0x771f54;
/*LN-50*/         }
/*LN-51*/         _0x6e3d9a._0x2ff8d2 += _0xae3550;
/*LN-52*/         _0x7248ad += _0xae3550;
/*LN-53*/         _0x771f54 += _0x8e6f03;
/*LN-54*/         ICErc20(_0x51bedd)._0x0353ce(_0x8e6f03);
/*LN-55*/     }
/*LN-56*/     function _0x8e4527(uint256 _0x0f4194, uint256 _0x8e6f03) external {
/*LN-57*/         Position storage _0x6e3d9a = _0x65ce0c[_0x0f4194];
/*LN-58*/         require(msg.sender == _0x6e3d9a._0xd860ea, "Not position owner");
/*LN-59*/         uint256 _0x477183 = (_0x8e6f03 * _0x7248ad) / _0x771f54;
/*LN-60*/         require(_0x6e3d9a._0x2ff8d2 >= _0x477183, "Excessive repayment");
/*LN-61*/         _0x6e3d9a._0x2ff8d2 -= _0x477183;
/*LN-62*/         _0x7248ad -= _0x477183;
/*LN-63*/         _0x771f54 -= _0x8e6f03;
/*LN-64*/     }
/*LN-65*/     function _0x8cd0a4(
/*LN-66*/         uint256 _0x0f4194
/*LN-67*/     ) external view returns (uint256) {
/*LN-68*/         Position storage _0x6e3d9a = _0x65ce0c[_0x0f4194];
/*LN-69*/         if (_0x7248ad == 0) return 0;
/*LN-70*/         return (_0x6e3d9a._0x2ff8d2 * _0x771f54) / _0x7248ad;
/*LN-71*/     }
/*LN-72*/     function _0x6ff151(uint256 _0x0f4194) external {
/*LN-73*/         Position storage _0x6e3d9a = _0x65ce0c[_0x0f4194];
/*LN-74*/         uint256 _0x4f9b02 = (_0x6e3d9a._0x2ff8d2 * _0x771f54) / _0x7248ad;
/*LN-75*/         require(_0x6e3d9a._0x1045d1 * 100 < _0x4f9b02 * 150, "Position is healthy");
/*LN-76*/         _0x6e3d9a._0x1045d1 = 0;
/*LN-77*/         _0x6e3d9a._0x2ff8d2 = 0;
/*LN-78*/     }
/*LN-79*/ }