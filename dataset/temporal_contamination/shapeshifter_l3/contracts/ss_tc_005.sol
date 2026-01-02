/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ contract StablePool {
/*LN-3*/     mapping(uint256 => uint256) public _0x6ff151;
/*LN-4*/     mapping(address => uint256) public _0xd80623;
/*LN-5*/     uint256 public _0x7248ad;
/*LN-6*/     uint256 private _0x70dd97;
/*LN-7*/     uint256 private constant _0x477183 = 1;
/*LN-8*/     uint256 private constant _0xd6cb4d = 2;
/*LN-9*/     event LiquidityAdded(
/*LN-10*/         address indexed _0x0f4194,
/*LN-11*/         uint256[2] _0x51bedd,
/*LN-12*/         uint256 _0x0d961f
/*LN-13*/     );
/*LN-14*/     event LiquidityRemoved(
/*LN-15*/         address indexed _0x0f4194,
/*LN-16*/         uint256 _0x1045d1,
/*LN-17*/         uint256[2] _0x51bedd
/*LN-18*/     );
/*LN-19*/     constructor() {
/*LN-20*/         _0x70dd97 = _0x477183;
/*LN-21*/     }
/*LN-22*/     function _0x7d6277(
/*LN-23*/         uint256[2] memory _0x51bedd,
/*LN-24*/         uint256 _0x8cd0a4
/*LN-25*/     ) external payable returns (uint256) {
/*LN-26*/         require(_0x51bedd[0] == msg.value, "ETH amount mismatch");
/*LN-27*/         uint256 _0x771f54;
/*LN-28*/         if (_0x7248ad == 0) {
/*LN-29*/             _0x771f54 = _0x51bedd[0] + _0x51bedd[1];
/*LN-30*/         } else {
/*LN-31*/             uint256 _0x2c833f = _0x6ff151[0] + _0x6ff151[1];
/*LN-32*/             _0x771f54 = ((_0x51bedd[0] + _0x51bedd[1]) * _0x7248ad) / _0x2c833f;
/*LN-33*/         }
/*LN-34*/         require(_0x771f54 >= _0x8cd0a4, "Slippage");
/*LN-35*/         _0x6ff151[0] += _0x51bedd[0];
/*LN-36*/         _0x6ff151[1] += _0x51bedd[1];
/*LN-37*/         _0xd80623[msg.sender] += _0x771f54;
/*LN-38*/         _0x7248ad += _0x771f54;
/*LN-39*/         if (_0x51bedd[0] > 0) {
/*LN-40*/             _0x390062(_0x51bedd[0]);
/*LN-41*/         }
/*LN-42*/         emit LiquidityAdded(msg.sender, _0x51bedd, _0x771f54);
/*LN-43*/         return _0x771f54;
/*LN-44*/     }
/*LN-45*/     function _0x0cce35(
/*LN-46*/         uint256 _0x2ff8d2,
/*LN-47*/         uint256[2] memory _0x347a3f
/*LN-48*/     ) external {
/*LN-49*/         require(_0xd80623[msg.sender] >= _0x2ff8d2, "Insufficient LP");
/*LN-50*/         uint256 _0xe5feba = (_0x2ff8d2 * _0x6ff151[0]) / _0x7248ad;
/*LN-51*/         uint256 _0x8e6f03 = (_0x2ff8d2 * _0x6ff151[1]) / _0x7248ad;
/*LN-52*/         require(
/*LN-53*/             _0xe5feba >= _0x347a3f[0] && _0x8e6f03 >= _0x347a3f[1],
/*LN-54*/             "Slippage"
/*LN-55*/         );
/*LN-56*/         _0xd80623[msg.sender] -= _0x2ff8d2;
/*LN-57*/         _0x7248ad -= _0x2ff8d2;
/*LN-58*/         _0x6ff151[0] -= _0xe5feba;
/*LN-59*/         _0x6ff151[1] -= _0x8e6f03;
/*LN-60*/         if (_0xe5feba > 0) {
/*LN-61*/             payable(msg.sender).transfer(_0xe5feba);
/*LN-62*/         }
/*LN-63*/         uint256[2] memory _0x51bedd = [_0xe5feba, _0x8e6f03];
/*LN-64*/         emit LiquidityRemoved(msg.sender, _0x2ff8d2, _0x51bedd);
/*LN-65*/     }
/*LN-66*/     function _0x390062(uint256 _0xae3550) internal {
/*LN-67*/         (bool _0x0353ce, ) = msg.sender.call{value: 0}("");
/*LN-68*/         require(_0x0353ce, "Transfer failed");
/*LN-69*/     }
/*LN-70*/     function _0x65ce0c(
/*LN-71*/         int128 i,
/*LN-72*/         int128 j,
/*LN-73*/         uint256 _0xac561e,
/*LN-74*/         uint256 _0xd860ea
/*LN-75*/     ) external payable returns (uint256) {
/*LN-76*/         uint256 _0x8e4527 = uint256(int256(i));
/*LN-77*/         uint256 _0x6e3d9a = uint256(int256(j));
/*LN-78*/         require(_0x8e4527 < 2 && _0x6e3d9a < 2 && _0x8e4527 != _0x6e3d9a, "Invalid indices");
/*LN-79*/         uint256 _0x4f9b02 = (_0xac561e * _0x6ff151[_0x6e3d9a]) / (_0x6ff151[_0x8e4527] + _0xac561e);
/*LN-80*/         require(_0x4f9b02 >= _0xd860ea, "Slippage");
/*LN-81*/         if (_0x8e4527 == 0) {
/*LN-82*/             require(msg.value == _0xac561e, "ETH mismatch");
/*LN-83*/             _0x6ff151[0] += _0xac561e;
/*LN-84*/         }
/*LN-85*/         _0x6ff151[_0x8e4527] += _0xac561e;
/*LN-86*/         _0x6ff151[_0x6e3d9a] -= _0x4f9b02;
/*LN-87*/         if (_0x6e3d9a == 0) {
/*LN-88*/             payable(msg.sender).transfer(_0x4f9b02);
/*LN-89*/         }
/*LN-90*/         return _0x4f9b02;
/*LN-91*/     }
/*LN-92*/     receive() external payable {
/*LN-93*/     }
/*LN-94*/ }