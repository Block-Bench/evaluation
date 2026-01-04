/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IERC20 {
/*LN-3*/     function _0x1045d1(address _0xe5feba) external view returns (uint256);
/*LN-4*/     function transfer(address _0x6e3d9a, uint256 _0x51bedd) external returns (bool);
/*LN-5*/ }
/*LN-6*/ contract IndexPool {
/*LN-7*/     struct Token {
/*LN-8*/         address _0x8e4527;
/*LN-9*/         uint256 balance;
/*LN-10*/         uint256 _0xd860ea;
/*LN-11*/     }
/*LN-12*/     mapping(address => Token) public _0x0353ce;
/*LN-13*/     address[] public _0x0f4194;
/*LN-14*/     uint256 public _0x477183;
/*LN-15*/     constructor() {
/*LN-16*/         _0x477183 = 100;
/*LN-17*/     }
/*LN-18*/     function _0x65ce0c(address _0xae3550, uint256 _0x8cd0a4) external {
/*LN-19*/         _0x0353ce[_0xae3550] = Token({_0x8e4527: _0xae3550, balance: 0, _0xd860ea: _0x8cd0a4});
/*LN-20*/         _0x0f4194.push(_0xae3550);
/*LN-21*/     }
/*LN-22*/     function _0x4f9b02(
/*LN-23*/         address _0x8e6f03,
/*LN-24*/         address _0xd6cb4d,
/*LN-25*/         uint256 _0x0d961f
/*LN-26*/     ) external returns (uint256 _0x2ff8d2) {
/*LN-27*/         require(_0x0353ce[_0x8e6f03]._0x8e4527 != address(0), "Invalid token");
/*LN-28*/         require(_0x0353ce[_0xd6cb4d]._0x8e4527 != address(0), "Invalid token");
/*LN-29*/         IERC20(_0x8e6f03).transfer(address(this), _0x0d961f);
/*LN-30*/         _0x0353ce[_0x8e6f03].balance += _0x0d961f;
/*LN-31*/         _0x2ff8d2 = _0x390062(_0x8e6f03, _0xd6cb4d, _0x0d961f);
/*LN-32*/         require(
/*LN-33*/             _0x0353ce[_0xd6cb4d].balance >= _0x2ff8d2,
/*LN-34*/             "Insufficient liquidity"
/*LN-35*/         );
/*LN-36*/         _0x0353ce[_0xd6cb4d].balance -= _0x2ff8d2;
/*LN-37*/         IERC20(_0xd6cb4d).transfer(msg.sender, _0x2ff8d2);
/*LN-38*/         _0x0cce35();
/*LN-39*/         return _0x2ff8d2;
/*LN-40*/     }
/*LN-41*/     function _0x390062(
/*LN-42*/         address _0x8e6f03,
/*LN-43*/         address _0xd6cb4d,
/*LN-44*/         uint256 _0x0d961f
/*LN-45*/     ) public view returns (uint256) {
/*LN-46*/         uint256 _0x70dd97 = _0x0353ce[_0x8e6f03]._0xd860ea;
/*LN-47*/         uint256 _0x6ff151 = _0x0353ce[_0xd6cb4d]._0xd860ea;
/*LN-48*/         uint256 _0x347a3f = _0x0353ce[_0xd6cb4d].balance;
/*LN-49*/         uint256 _0xd80623 = _0x347a3f * _0x0d961f * _0x6ff151;
/*LN-50*/         uint256 _0x7248ad = _0x0353ce[_0x8e6f03].balance *
/*LN-51*/             _0x70dd97 +
/*LN-52*/             _0x0d961f *
/*LN-53*/             _0x6ff151;
/*LN-54*/         return _0xd80623 / _0x7248ad;
/*LN-55*/     }
/*LN-56*/     function _0x0cce35() internal {
/*LN-57*/         uint256 _0x2c833f = 0;
/*LN-58*/         for (uint256 i = 0; i < _0x0f4194.length; i++) {
/*LN-59*/             address _0xae3550 = _0x0f4194[i];
/*LN-60*/             _0x2c833f += _0x0353ce[_0xae3550].balance;
/*LN-61*/         }
/*LN-62*/         for (uint256 i = 0; i < _0x0f4194.length; i++) {
/*LN-63*/             address _0xae3550 = _0x0f4194[i];
/*LN-64*/             _0x0353ce[_0xae3550]._0xd860ea = (_0x0353ce[_0xae3550].balance * 100) / _0x2c833f;
/*LN-65*/         }
/*LN-66*/     }
/*LN-67*/     function _0x771f54(address _0xae3550) external view returns (uint256) {
/*LN-68*/         return _0x0353ce[_0xae3550]._0xd860ea;
/*LN-69*/     }
/*LN-70*/     function _0x7d6277(address _0xae3550, uint256 _0x51bedd) external {
/*LN-71*/         require(_0x0353ce[_0xae3550]._0x8e4527 != address(0), "Invalid token");
/*LN-72*/         IERC20(_0xae3550).transfer(address(this), _0x51bedd);
/*LN-73*/         _0x0353ce[_0xae3550].balance += _0x51bedd;
/*LN-74*/         _0x0cce35();
/*LN-75*/     }
/*LN-76*/ }