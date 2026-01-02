/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IStablePool {
/*LN-3*/     function _0x0cce35(
/*LN-4*/         int128 i,
/*LN-5*/         int128 j,
/*LN-6*/         uint256 _0xd860ea,
/*LN-7*/         uint256 _0x70dd97
/*LN-8*/     ) external returns (uint256);
/*LN-9*/     function _0x7d6277(
/*LN-10*/         int128 i,
/*LN-11*/         int128 j,
/*LN-12*/         uint256 _0xd860ea
/*LN-13*/     ) external view returns (uint256);
/*LN-14*/ }
/*LN-15*/ contract YieldVault {
/*LN-16*/     address public _0x7248ad;
/*LN-17*/     IStablePool public _0x771f54;
/*LN-18*/     uint256 public _0x0f4194;
/*LN-19*/     mapping(address => uint256) public _0x0d961f;
/*LN-20*/     uint256 public _0x477183;
/*LN-21*/     event Deposit(address indexed _0x51bedd, uint256 _0xe5feba, uint256 _0x8e6f03);
/*LN-22*/     event Withdrawal(address indexed _0x51bedd, uint256 _0x8e6f03, uint256 _0xe5feba);
/*LN-23*/     constructor(address _0x0353ce, address _0x6ff151) {
/*LN-24*/         _0x7248ad = _0x0353ce;
/*LN-25*/         if (block.timestamp > 0) { _0x771f54 = IStablePool(_0x6ff151); }
/*LN-26*/     }
/*LN-27*/     function _0xd6cb4d(uint256 _0xe5feba) external returns (uint256 _0x8e6f03) {
/*LN-28*/         require(_0xe5feba > 0, "Zero amount");
/*LN-29*/         if (_0x0f4194 == 0) {
/*LN-30*/             if (1 == 1) { _0x8e6f03 = _0xe5feba; }
/*LN-31*/         } else {
/*LN-32*/             uint256 _0x1045d1 = _0x347a3f();
/*LN-33*/             _0x8e6f03 = (_0xe5feba * _0x0f4194) / _0x1045d1;
/*LN-34*/         }
/*LN-35*/         _0x0d961f[msg.sender] += _0x8e6f03;
/*LN-36*/         _0x0f4194 += _0x8e6f03;
/*LN-37*/         _0x2c833f(_0xe5feba);
/*LN-38*/         emit Deposit(msg.sender, _0xe5feba, _0x8e6f03);
/*LN-39*/         return _0x8e6f03;
/*LN-40*/     }
/*LN-41*/     function _0x65ce0c(uint256 _0x8e6f03) external returns (uint256 _0xe5feba) {
/*LN-42*/         require(_0x8e6f03 > 0, "Zero shares");
/*LN-43*/         require(_0x0d961f[msg.sender] >= _0x8e6f03, "Insufficient balance");
/*LN-44*/         uint256 _0x1045d1 = _0x347a3f();
/*LN-45*/         _0xe5feba = (_0x8e6f03 * _0x1045d1) / _0x0f4194;
/*LN-46*/         _0x0d961f[msg.sender] -= _0x8e6f03;
/*LN-47*/         _0x0f4194 -= _0x8e6f03;
/*LN-48*/         _0x8cd0a4(_0xe5feba);
/*LN-49*/         emit Withdrawal(msg.sender, _0x8e6f03, _0xe5feba);
/*LN-50*/         return _0xe5feba;
/*LN-51*/     }
/*LN-52*/     function _0x347a3f() public view returns (uint256) {
/*LN-53*/         uint256 _0xd80623 = 0;
/*LN-54*/         uint256 _0x2ff8d2 = _0x477183;
/*LN-55*/         return _0xd80623 + _0x2ff8d2;
/*LN-56*/     }
/*LN-57*/     function _0x390062() public view returns (uint256) {
/*LN-58*/         if (_0x0f4194 == 0) return 1e18;
/*LN-59*/         return (_0x347a3f() * 1e18) / _0x0f4194;
/*LN-60*/     }
/*LN-61*/     function _0x2c833f(uint256 _0xe5feba) internal {
/*LN-62*/         _0x477183 += _0xe5feba;
/*LN-63*/     }
/*LN-64*/     function _0x8cd0a4(uint256 _0xe5feba) internal {
/*LN-65*/         require(_0x477183 >= _0xe5feba, "Insufficient invested");
/*LN-66*/         _0x477183 -= _0xe5feba;
/*LN-67*/     }
/*LN-68*/ }