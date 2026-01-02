/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IERC20 {
/*LN-3*/     function transfer(address _0x4f9b02, uint256 _0x0353ce) external returns (bool);
/*LN-4*/     function _0x347a3f(
/*LN-5*/         address from,
/*LN-6*/         address _0x4f9b02,
/*LN-7*/         uint256 _0x0353ce
/*LN-8*/     ) external returns (bool);
/*LN-9*/     function _0x0d961f(address _0x70dd97) external view returns (uint256);
/*LN-10*/ }
/*LN-11*/ contract CompMarket {
/*LN-12*/     IERC20 public _0x6ff151;
/*LN-13*/     string public _0xae3550 = "Sonne WETH";
/*LN-14*/     string public _0x51bedd = "soWETH";
/*LN-15*/     uint8 public _0x65ce0c = 8;
/*LN-16*/     uint256 public _0x1045d1;
/*LN-17*/     mapping(address => uint256) public _0x0d961f;
/*LN-18*/     uint256 public _0x2c833f;
/*LN-19*/     uint256 public _0x7d6277;
/*LN-20*/     event Mint(address _0x8e6f03, uint256 _0x771f54, uint256 _0x2ff8d2);
/*LN-21*/     event Redeem(address _0xd6cb4d, uint256 _0x7248ad, uint256 _0xd80623);
/*LN-22*/     constructor(address _0x0f4194) {
/*LN-23*/         _0x6ff151 = IERC20(_0x0f4194);
/*LN-24*/     }
/*LN-25*/     function _0x477183() public view returns (uint256) {
/*LN-26*/         if (_0x1045d1 == 0) {
/*LN-27*/             return 1e18;
/*LN-28*/         }
/*LN-29*/         uint256 _0x8e4527 = _0x6ff151._0x0d961f(address(this));
/*LN-30*/         uint256 _0x8cd0a4 = _0x8e4527 + _0x2c833f - _0x7d6277;
/*LN-31*/         return (_0x8cd0a4 * 1e18) / _0x1045d1;
/*LN-32*/     }
/*LN-33*/     function _0xd860ea(uint256 _0x771f54) external returns (uint256) {
/*LN-34*/         require(_0x771f54 > 0, "Zero mint");
/*LN-35*/         uint256 _0x390062 = _0x477183();
/*LN-36*/         uint256 _0x2ff8d2 = (_0x771f54 * 1e18) / _0x390062;
/*LN-37*/         _0x1045d1 += _0x2ff8d2;
/*LN-38*/         _0x0d961f[msg.sender] += _0x2ff8d2;
/*LN-39*/         _0x6ff151._0x347a3f(msg.sender, address(this), _0x771f54);
/*LN-40*/         emit Mint(msg.sender, _0x771f54, _0x2ff8d2);
/*LN-41*/         return _0x2ff8d2;
/*LN-42*/     }
/*LN-43*/     function _0xe5feba(uint256 _0xd80623) external returns (uint256) {
/*LN-44*/         require(_0x0d961f[msg.sender] >= _0xd80623, "Insufficient balance");
/*LN-45*/         uint256 _0x390062 = _0x477183();
/*LN-46*/         uint256 _0x7248ad = (_0xd80623 * _0x390062) / 1e18;
/*LN-47*/         _0x0d961f[msg.sender] -= _0xd80623;
/*LN-48*/         _0x1045d1 -= _0xd80623;
/*LN-49*/         _0x6ff151.transfer(msg.sender, _0x7248ad);
/*LN-50*/         emit Redeem(msg.sender, _0x7248ad, _0xd80623);
/*LN-51*/         return _0x7248ad;
/*LN-52*/     }
/*LN-53*/     function _0x0cce35(
/*LN-54*/         address _0x70dd97
/*LN-55*/     ) external view returns (uint256) {
/*LN-56*/         uint256 _0x390062 = _0x477183();
/*LN-57*/         return (_0x0d961f[_0x70dd97] * _0x390062) / 1e18;
/*LN-58*/     }
/*LN-59*/ }