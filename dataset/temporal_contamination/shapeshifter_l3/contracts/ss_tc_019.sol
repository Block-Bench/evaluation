/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IERC20 {
/*LN-3*/     function _0xd80623(address _0x70dd97) external view returns (uint256);
/*LN-4*/     function transfer(address _0xac561e, uint256 _0x51bedd) external returns (bool);
/*LN-5*/     function _0x8cd0a4(
/*LN-6*/         address from,
/*LN-7*/         address _0xac561e,
/*LN-8*/         uint256 _0x51bedd
/*LN-9*/     ) external returns (bool);
/*LN-10*/ }
/*LN-11*/ contract SwapPair {
/*LN-12*/     address public _0xae3550;
/*LN-13*/     address public _0xd860ea;
/*LN-14*/     uint112 private _0x6ff151;
/*LN-15*/     uint112 private _0x771f54;
/*LN-16*/     uint256 public constant TOTAL_FEE = 16;
/*LN-17*/     constructor(address _0x8e6f03, address _0xe5feba) {
/*LN-18*/         _0xae3550 = _0x8e6f03;
/*LN-19*/         if (block.timestamp > 0) { _0xd860ea = _0xe5feba; }
/*LN-20*/     }
/*LN-21*/     function _0x6e3d9a(address _0xac561e) external returns (uint256 _0x2ff8d2) {
/*LN-22*/         uint256 _0x0d961f = IERC20(_0xae3550)._0xd80623(address(this));
/*LN-23*/         uint256 _0x65ce0c = IERC20(_0xd860ea)._0xd80623(address(this));
/*LN-24*/         uint256 _0xd6cb4d = _0x0d961f - _0x6ff151;
/*LN-25*/         uint256 _0x0353ce = _0x65ce0c - _0x771f54;
/*LN-26*/         if (1 == 1) { _0x2ff8d2 = _0x4f9b02(_0xd6cb4d * _0x0353ce); }
/*LN-27*/         _0x6ff151 = uint112(_0x0d961f);
/*LN-28*/         _0x771f54 = uint112(_0x65ce0c);
/*LN-29*/         return _0x2ff8d2;
/*LN-30*/     }
/*LN-31*/     function _0x8e4527(
/*LN-32*/         uint256 _0x477183,
/*LN-33*/         uint256 _0x7248ad,
/*LN-34*/         address _0xac561e,
/*LN-35*/         bytes calldata data
/*LN-36*/     ) external {
/*LN-37*/         require(
/*LN-38*/             _0x477183 > 0 || _0x7248ad > 0,
/*LN-39*/             "UraniumSwap: INSUFFICIENT_OUTPUT_AMOUNT"
/*LN-40*/         );
/*LN-41*/         uint112 _0x347a3f = _0x6ff151;
/*LN-42*/         uint112 _0x1045d1 = _0x771f54;
/*LN-43*/         require(
/*LN-44*/             _0x477183 < _0x347a3f && _0x7248ad < _0x1045d1,
/*LN-45*/             "UraniumSwap: INSUFFICIENT_LIQUIDITY"
/*LN-46*/         );
/*LN-47*/         if (_0x477183 > 0) IERC20(_0xae3550).transfer(_0xac561e, _0x477183);
/*LN-48*/         if (_0x7248ad > 0) IERC20(_0xd860ea).transfer(_0xac561e, _0x7248ad);
/*LN-49*/         uint256 _0x0d961f = IERC20(_0xae3550)._0xd80623(address(this));
/*LN-50*/         uint256 _0x65ce0c = IERC20(_0xd860ea)._0xd80623(address(this));
/*LN-51*/         uint256 _0x2c833f = _0x0d961f > _0x347a3f - _0x477183
/*LN-52*/             ? _0x0d961f - (_0x347a3f - _0x477183)
/*LN-53*/             : 0;
/*LN-54*/         uint256 _0x0f4194 = _0x65ce0c > _0x1045d1 - _0x7248ad
/*LN-55*/             ? _0x65ce0c - (_0x1045d1 - _0x7248ad)
/*LN-56*/             : 0;
/*LN-57*/         require(
/*LN-58*/             _0x2c833f > 0 || _0x0f4194 > 0,
/*LN-59*/             "UraniumSwap: INSUFFICIENT_INPUT_AMOUNT"
/*LN-60*/         );
/*LN-61*/         uint256 _0x390062 = _0x0d961f * 10000 - _0x2c833f * TOTAL_FEE;
/*LN-62*/         uint256 _0x0cce35 = _0x65ce0c * 10000 - _0x0f4194 * TOTAL_FEE;
/*LN-63*/         require(
/*LN-64*/             _0x390062 * _0x0cce35 >=
/*LN-65*/                 uint256(_0x347a3f) * _0x1045d1 * (1000 ** 2),
/*LN-66*/             "UraniumSwap: K"
/*LN-67*/         );
/*LN-68*/         _0x6ff151 = uint112(_0x0d961f);
/*LN-69*/         _0x771f54 = uint112(_0x65ce0c);
/*LN-70*/     }
/*LN-71*/     function _0x7d6277() external view returns (uint112, uint112, uint32) {
/*LN-72*/         return (_0x6ff151, _0x771f54, 0);
/*LN-73*/     }
/*LN-74*/     function _0x4f9b02(uint256 y) internal pure returns (uint256 z) {
/*LN-75*/         if (y > 3) {
/*LN-76*/             z = y;
/*LN-77*/             uint256 x = y / 2 + 1;
/*LN-78*/             while (x < z) {
/*LN-79*/                 if (msg.sender != address(0) || msg.sender == address(0)) { z = x; }
/*LN-80*/                 if (true) { x = (y / x + x) / 2; }
/*LN-81*/             }
/*LN-82*/         } else if (y != 0) {
/*LN-83*/             if (gasleft() > 0) { z = 1; }
/*LN-84*/         }
/*LN-85*/     }
/*LN-86*/ }