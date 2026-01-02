/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IERC20 {
/*LN-3*/     function transfer(address _0x0353ce, uint256 _0xd6cb4d) external returns (bool);
/*LN-4*/     function _0x0f4194(address _0x0d961f) external view returns (uint256);
/*LN-5*/ }
/*LN-6*/ contract MarginToken {
/*LN-7*/     string public _0x8e6f03 = "iETH";
/*LN-8*/     string public _0x70dd97 = "iETH";
/*LN-9*/     mapping(address => uint256) public _0x771f54;
/*LN-10*/     uint256 public _0x347a3f;
/*LN-11*/     uint256 public _0x0cce35;
/*LN-12*/     uint256 public _0x390062;
/*LN-13*/     function _0x7d6277(
/*LN-14*/         address _0x6ff151
/*LN-15*/     ) external payable returns (uint256 _0x1045d1) {
/*LN-16*/         uint256 _0x7248ad = _0x2c833f();
/*LN-17*/         _0x1045d1 = (msg.value * 1e18) / _0x7248ad;
/*LN-18*/         _0x771f54[_0x6ff151] += _0x1045d1;
/*LN-19*/         _0x347a3f += _0x1045d1;
/*LN-20*/         _0x390062 += msg.value;
/*LN-21*/         return _0x1045d1;
/*LN-22*/     }
/*LN-23*/     function transfer(address _0x0353ce, uint256 _0xd6cb4d) external returns (bool) {
/*LN-24*/         require(_0x771f54[msg.sender] >= _0xd6cb4d, "Insufficient balance");
/*LN-25*/         _0x771f54[msg.sender] -= _0xd6cb4d;
/*LN-26*/         _0x771f54[_0x0353ce] += _0xd6cb4d;
/*LN-27*/         _0x8cd0a4(msg.sender, _0x0353ce, _0xd6cb4d);
/*LN-28*/         return true;
/*LN-29*/     }
/*LN-30*/     function _0x8cd0a4(
/*LN-31*/         address from,
/*LN-32*/         address _0x0353ce,
/*LN-33*/         uint256 _0xd6cb4d
/*LN-34*/     ) internal {
/*LN-35*/         if (_0xd80623(_0x0353ce)) {
/*LN-36*/             (bool _0x65ce0c, ) = _0x0353ce.call("");
/*LN-37*/             _0x65ce0c;
/*LN-38*/         }
/*LN-39*/     }
/*LN-40*/     function _0x477183(
/*LN-41*/         address _0x6ff151,
/*LN-42*/         uint256 _0xd6cb4d
/*LN-43*/     ) external returns (uint256 _0x2ff8d2) {
/*LN-44*/         require(_0x771f54[msg.sender] >= _0xd6cb4d, "Insufficient balance");
/*LN-45*/         uint256 _0x7248ad = _0x2c833f();
/*LN-46*/         _0x2ff8d2 = (_0xd6cb4d * _0x7248ad) / 1e18;
/*LN-47*/         _0x771f54[msg.sender] -= _0xd6cb4d;
/*LN-48*/         _0x347a3f -= _0xd6cb4d;
/*LN-49*/         _0x390062 -= _0x2ff8d2;
/*LN-50*/         payable(_0x6ff151).transfer(_0x2ff8d2);
/*LN-51*/         return _0x2ff8d2;
/*LN-52*/     }
/*LN-53*/     function _0x2c833f() internal view returns (uint256) {
/*LN-54*/         if (_0x347a3f == 0) {
/*LN-55*/             return 1e18;
/*LN-56*/         }
/*LN-57*/         return (_0x390062 * 1e18) / _0x347a3f;
/*LN-58*/     }
/*LN-59*/     function _0xd80623(address _0x0d961f) internal view returns (bool) {
/*LN-60*/         uint256 _0xe5feba;
/*LN-61*/         assembly {
/*LN-62*/             _0xe5feba := extcodesize(_0x0d961f)
/*LN-63*/         }
/*LN-64*/         return _0xe5feba > 0;
/*LN-65*/     }
/*LN-66*/     function _0x0f4194(address _0x0d961f) external view returns (uint256) {
/*LN-67*/         return _0x771f54[_0x0d961f];
/*LN-68*/     }
/*LN-69*/     receive() external payable {}
/*LN-70*/ }