/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IERC20 {
/*LN-3*/     function _0xe5feba(address _0xae3550) external view returns (uint256);
/*LN-4*/     function transfer(address _0x3184cf, uint256 _0x8e4527) external returns (bool);
/*LN-5*/     function _0x477183(
/*LN-6*/         address from,
/*LN-7*/         address _0x3184cf,
/*LN-8*/         uint256 _0x8e4527
/*LN-9*/     ) external returns (bool);
/*LN-10*/ }
/*LN-11*/ contract LiquidityPool {
/*LN-12*/     address public _0x6ff151;
/*LN-13*/     address public _0x70dd97;
/*LN-14*/     address public _0x65ce0c;
/*LN-15*/     uint256 public _0xd6cb4d;
/*LN-16*/     uint256 public _0x2c833f;
/*LN-17*/     uint256 public _0x7248ad;
/*LN-18*/     bool public _0x8cd0a4;
/*LN-19*/     event Initialized(address _0x6ff151, address _0x3454e7, address _0x6e3d9a);
/*LN-20*/     function _0x2f7c62(
/*LN-21*/         address _0xd80623,
/*LN-22*/         address _0x0d961f,
/*LN-23*/         address _0x347a3f,
/*LN-24*/         uint256 _0x2ff8d2
/*LN-25*/     ) external {
/*LN-26*/         _0x6ff151 = _0xd80623;
/*LN-27*/         _0x70dd97 = _0x0d961f;
/*LN-28*/         _0x65ce0c = _0x347a3f;
/*LN-29*/         _0xd6cb4d = _0x2ff8d2;
/*LN-30*/         _0x8cd0a4 = true;
/*LN-31*/         emit Initialized(_0xd80623, _0x0d961f, _0x347a3f);
/*LN-32*/     }
/*LN-33*/     function _0x7d6277(uint256 _0x0f4194, uint256 _0x1045d1) external {
/*LN-34*/         require(_0x8cd0a4, "Not initialized");
/*LN-35*/         IERC20(_0x70dd97)._0x477183(msg.sender, address(this), _0x0f4194);
/*LN-36*/         IERC20(_0x65ce0c)._0x477183(msg.sender, address(this), _0x1045d1);
/*LN-37*/         _0x2c833f += _0x0f4194;
/*LN-38*/         _0x7248ad += _0x1045d1;
/*LN-39*/     }
/*LN-40*/     function _0xac561e(
/*LN-41*/         address _0x8e6f03,
/*LN-42*/         address _0xd860ea,
/*LN-43*/         uint256 _0x771f54
/*LN-44*/     ) external returns (uint256 _0x51bedd) {
/*LN-45*/         require(_0x8cd0a4, "Not initialized");
/*LN-46*/         require(
/*LN-47*/             (_0x8e6f03 == _0x70dd97 && _0xd860ea == _0x65ce0c) ||
/*LN-48*/                 (_0x8e6f03 == _0x65ce0c && _0xd860ea == _0x70dd97),
/*LN-49*/             "Invalid token pair"
/*LN-50*/         );
/*LN-51*/         IERC20(_0x8e6f03)._0x477183(msg.sender, address(this), _0x771f54);
/*LN-52*/         if (_0x8e6f03 == _0x70dd97) {
/*LN-53*/             _0x51bedd = (_0x7248ad * _0x771f54) / (_0x2c833f + _0x771f54);
/*LN-54*/             _0x2c833f += _0x771f54;
/*LN-55*/             _0x7248ad -= _0x51bedd;
/*LN-56*/         } else {
/*LN-57*/             _0x51bedd = (_0x2c833f * _0x771f54) / (_0x7248ad + _0x771f54);
/*LN-58*/             _0x7248ad += _0x771f54;
/*LN-59*/             _0x2c833f -= _0x51bedd;
/*LN-60*/         }
/*LN-61*/         uint256 _0xc285d4 = (_0x51bedd * _0xd6cb4d) / 10000;
/*LN-62*/         _0x51bedd -= _0xc285d4;
/*LN-63*/         IERC20(_0xd860ea).transfer(msg.sender, _0x51bedd);
/*LN-64*/         IERC20(_0xd860ea).transfer(_0x6ff151, _0xc285d4);
/*LN-65*/         return _0x51bedd;
/*LN-66*/     }
/*LN-67*/     function _0x0353ce() external {
/*LN-68*/         require(msg.sender == _0x6ff151, "Only maintainer");
/*LN-69*/         uint256 _0x0cce35 = IERC20(_0x70dd97)._0xe5feba(address(this));
/*LN-70*/         uint256 _0x390062 = IERC20(_0x65ce0c)._0xe5feba(address(this));
/*LN-71*/         if (_0x0cce35 > _0x2c833f) {
/*LN-72*/             uint256 _0x4f9b02 = _0x0cce35 - _0x2c833f;
/*LN-73*/             IERC20(_0x70dd97).transfer(_0x6ff151, _0x4f9b02);
/*LN-74*/         }
/*LN-75*/         if (_0x390062 > _0x7248ad) {
/*LN-76*/             uint256 _0x4f9b02 = _0x390062 - _0x7248ad;
/*LN-77*/             IERC20(_0x65ce0c).transfer(_0x6ff151, _0x4f9b02);
/*LN-78*/         }
/*LN-79*/     }
/*LN-80*/ }