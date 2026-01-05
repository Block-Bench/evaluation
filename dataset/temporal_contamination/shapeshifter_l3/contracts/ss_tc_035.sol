/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IERC20 {
/*LN-3*/     function transfer(address _0xb01af6, uint256 _0x6e3d9a) external returns (bool);
/*LN-4*/     function _0x2c833f(
/*LN-5*/         address from,
/*LN-6*/         address _0xb01af6,
/*LN-7*/         uint256 _0x6e3d9a
/*LN-8*/     ) external returns (bool);
/*LN-9*/     function _0x65ce0c(address _0x51bedd) external view returns (uint256);
/*LN-10*/     function _0xd860ea(address _0x8e4527, uint256 _0x6e3d9a) external returns (bool);
/*LN-11*/ }
/*LN-12*/ interface IPriceOracle {
/*LN-13*/     function _0x70dd97(address _0x3184cf) external view returns (uint256);
/*LN-14*/ }
/*LN-15*/ contract LeveragedLending {
/*LN-16*/     struct Market {
/*LN-17*/         bool _0xe5feba;
/*LN-18*/         uint256 _0x8cd0a4;
/*LN-19*/         mapping(address => uint256) _0x0cce35;
/*LN-20*/         mapping(address => uint256) _0x477183;
/*LN-21*/     }
/*LN-22*/     mapping(address => Market) public _0x4f9b02;
/*LN-23*/     IPriceOracle public _0x2f7c62;
/*LN-24*/     uint256 public constant COLLATERAL_FACTOR = 75;
/*LN-25*/     uint256 public constant BASIS_POINTS = 100;
/*LN-26*/     function _0xd80623(
/*LN-27*/         address[] calldata _0x0353ce
/*LN-28*/     ) external returns (uint256[] memory) {
/*LN-29*/         uint256[] memory _0xae3550 = new uint256[](_0x0353ce.length);
/*LN-30*/         for (uint256 i = 0; i < _0x0353ce.length; i++) {
/*LN-31*/             _0x4f9b02[_0x0353ce[i]]._0xe5feba = true;
/*LN-32*/             _0xae3550[i] = 0;
/*LN-33*/         }
/*LN-34*/         return _0xae3550;
/*LN-35*/     }
/*LN-36*/     function _0xb7cc25(address _0x3184cf, uint256 _0x6e3d9a) external returns (uint256) {
/*LN-37*/         IERC20(_0x3184cf)._0x2c833f(msg.sender, address(this), _0x6e3d9a);
/*LN-38*/         uint256 _0xc285d4 = _0x2f7c62._0x70dd97(_0x3184cf);
/*LN-39*/         _0x4f9b02[_0x3184cf]._0x0cce35[msg.sender] += _0x6e3d9a;
/*LN-40*/         return 0;
/*LN-41*/     }
/*LN-42*/     function _0xac561e(
/*LN-43*/         address _0x2ff8d2,
/*LN-44*/         uint256 _0x347a3f
/*LN-45*/     ) external returns (uint256) {
/*LN-46*/         uint256 _0x390062 = 0;
/*LN-47*/         uint256 _0x6ff151 = _0x2f7c62._0x70dd97(_0x2ff8d2);
/*LN-48*/         uint256 _0x0f4194 = (_0x347a3f * _0x6ff151) / 1e18;
/*LN-49*/         uint256 _0x7248ad = (_0x390062 * COLLATERAL_FACTOR) /
/*LN-50*/             BASIS_POINTS;
/*LN-51*/         require(_0x0f4194 <= _0x7248ad, "Insufficient collateral");
/*LN-52*/         _0x4f9b02[_0x2ff8d2]._0x477183[msg.sender] += _0x347a3f;
/*LN-53*/         IERC20(_0x2ff8d2).transfer(msg.sender, _0x347a3f);
/*LN-54*/         return 0;
/*LN-55*/     }
/*LN-56*/     function _0x0d961f(
/*LN-57*/         address _0xd6cb4d,
/*LN-58*/         address _0x771f54,
/*LN-59*/         uint256 _0x1045d1,
/*LN-60*/         address _0x7d6277
/*LN-61*/     ) external {
/*LN-62*/     }
/*LN-63*/ }
/*LN-64*/ contract TestOracle is IPriceOracle {
/*LN-65*/     mapping(address => uint256) public _0x3454e7;
/*LN-66*/     function _0x70dd97(address _0x3184cf) external view override returns (uint256) {
/*LN-67*/         return _0x3454e7[_0x3184cf];
/*LN-68*/     }
/*LN-69*/     function _0x8e6f03(address _0x3184cf, uint256 _0xc285d4) external {
/*LN-70*/         _0x3454e7[_0x3184cf] = _0xc285d4;
/*LN-71*/     }
/*LN-72*/ }