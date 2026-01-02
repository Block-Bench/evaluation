/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IERC20 {
/*LN-3*/     function transfer(address _0x876f47, uint256 _0x6e3d9a) external returns (bool);
/*LN-4*/     function _0x347a3f(
/*LN-5*/         address from,
/*LN-6*/         address _0x876f47,
/*LN-7*/         uint256 _0x6e3d9a
/*LN-8*/     ) external returns (bool);
/*LN-9*/     function _0x2ff8d2(address _0x8e6f03) external view returns (uint256);
/*LN-10*/     function _0x0353ce(address _0xae3550, uint256 _0x6e3d9a) external returns (bool);
/*LN-11*/ }
/*LN-12*/ interface IAaveOracle {
/*LN-13*/     function _0x7248ad(address _0xb01af6) external view returns (uint256);
/*LN-14*/     function _0x0cce35(
/*LN-15*/         address[] calldata _0xac561e,
/*LN-16*/         address[] calldata _0x51bedd
/*LN-17*/     ) external;
/*LN-18*/ }
/*LN-19*/ interface IStablePool {
/*LN-20*/     function _0xd6cb4d(
/*LN-21*/         int128 i,
/*LN-22*/         int128 j,
/*LN-23*/         uint256 _0x163f22,
/*LN-24*/         uint256 _0x4f9b02
/*LN-25*/     ) external returns (uint256);
/*LN-26*/     function _0x2f7c62(
/*LN-27*/         int128 i,
/*LN-28*/         int128 j,
/*LN-29*/         uint256 _0x163f22
/*LN-30*/     ) external view returns (uint256);
/*LN-31*/     function _0x771f54(uint256 i) external view returns (uint256);
/*LN-32*/ }
/*LN-33*/ interface ILendingPool {
/*LN-34*/     function _0xd860ea(
/*LN-35*/         address _0xb01af6,
/*LN-36*/         uint256 _0x6e3d9a,
/*LN-37*/         address _0x1045d1,
/*LN-38*/         uint16 _0x477183
/*LN-39*/     ) external;
/*LN-40*/     function _0x3454e7(
/*LN-41*/         address _0xb01af6,
/*LN-42*/         uint256 _0x6e3d9a,
/*LN-43*/         uint256 _0x390062,
/*LN-44*/         uint16 _0x477183,
/*LN-45*/         address _0x1045d1
/*LN-46*/     ) external;
/*LN-47*/     function _0x70dd97(
/*LN-48*/         address _0xb01af6,
/*LN-49*/         uint256 _0x6e3d9a,
/*LN-50*/         address _0x876f47
/*LN-51*/     ) external returns (uint256);
/*LN-52*/ }
/*LN-53*/ contract LendingPool is ILendingPool {
/*LN-54*/     IAaveOracle public _0xc285d4;
/*LN-55*/     mapping(address => uint256) public _0x65ce0c;
/*LN-56*/     mapping(address => uint256) public _0x8e4527;
/*LN-57*/     uint256 public constant LTV = 8500;
/*LN-58*/     uint256 public constant BASIS_POINTS = 10000;
/*LN-59*/     function _0xd860ea(
/*LN-60*/         address _0xb01af6,
/*LN-61*/         uint256 _0x6e3d9a,
/*LN-62*/         address _0x1045d1,
/*LN-63*/         uint16 _0x477183
/*LN-64*/     ) external override {
/*LN-65*/         IERC20(_0xb01af6)._0x347a3f(msg.sender, address(this), _0x6e3d9a);
/*LN-66*/         _0x65ce0c[_0x1045d1] += _0x6e3d9a;
/*LN-67*/     }
/*LN-68*/     function _0x3454e7(
/*LN-69*/         address _0xb01af6,
/*LN-70*/         uint256 _0x6e3d9a,
/*LN-71*/         uint256 _0x390062,
/*LN-72*/         uint16 _0x477183,
/*LN-73*/         address _0x1045d1
/*LN-74*/     ) external override {
/*LN-75*/         uint256 _0x8cd0a4 = _0xc285d4._0x7248ad(msg.sender);
/*LN-76*/         uint256 _0xd80623 = _0xc285d4._0x7248ad(_0xb01af6);
/*LN-77*/         uint256 _0x7d6277 = (_0x65ce0c[msg.sender] * _0x8cd0a4) /
/*LN-78*/             1e18;
/*LN-79*/         uint256 _0x6ff151 = (_0x7d6277 * LTV) / BASIS_POINTS;
/*LN-80*/         uint256 _0x2c833f = (_0x6e3d9a * _0xd80623) / 1e18;
/*LN-81*/         require(_0x2c833f <= _0x6ff151, "Insufficient collateral");
/*LN-82*/         _0x8e4527[msg.sender] += _0x6e3d9a;
/*LN-83*/         IERC20(_0xb01af6).transfer(_0x1045d1, _0x6e3d9a);
/*LN-84*/     }
/*LN-85*/     function _0x70dd97(
/*LN-86*/         address _0xb01af6,
/*LN-87*/         uint256 _0x6e3d9a,
/*LN-88*/         address _0x876f47
/*LN-89*/     ) external override returns (uint256) {
/*LN-90*/         require(_0x65ce0c[msg.sender] >= _0x6e3d9a, "Insufficient balance");
/*LN-91*/         _0x65ce0c[msg.sender] -= _0x6e3d9a;
/*LN-92*/         IERC20(_0xb01af6).transfer(_0x876f47, _0x6e3d9a);
/*LN-93*/         return _0x6e3d9a;
/*LN-94*/     }
/*LN-95*/ }
/*LN-96*/ contract PoolOracle {
/*LN-97*/     IStablePool public _0x0f4194;
/*LN-98*/     constructor(address _0xb7cc25) {
/*LN-99*/         _0x0f4194 = _0xb7cc25;
/*LN-100*/     }
/*LN-101*/     function _0x7248ad(address _0xb01af6) external view returns (uint256) {
/*LN-102*/         uint256 _0x0d961f = _0x0f4194._0x771f54(0);
/*LN-103*/         uint256 _0xe5feba = _0x0f4194._0x771f54(1);
/*LN-104*/         uint256 _0x3184cf = (_0xe5feba * 1e18) / _0x0d961f;
/*LN-105*/         return _0x3184cf;
/*LN-106*/     }
/*LN-107*/ }