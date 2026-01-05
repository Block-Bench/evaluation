/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IERC20 {
/*LN-3*/     function transfer(address _0xc285d4, uint256 _0xae3550) external returns (bool);
/*LN-4*/     function _0x2c833f(
/*LN-5*/         address from,
/*LN-6*/         address _0xc285d4,
/*LN-7*/         uint256 _0xae3550
/*LN-8*/     ) external returns (bool);
/*LN-9*/     function _0x0d961f(address _0xe5feba) external view returns (uint256);
/*LN-10*/ }
/*LN-11*/ interface IMarket {
/*LN-12*/     function _0x0cce35(
/*LN-13*/         address _0xe5feba
/*LN-14*/     )
/*LN-15*/         external
/*LN-16*/         view
/*LN-17*/         returns (uint256 _0x1045d1, uint256 _0x0353ce, uint256 _0x347a3f);
/*LN-18*/ }
/*LN-19*/ contract DebtPreviewer {
/*LN-20*/     function _0xd80623(
/*LN-21*/         address _0x6e3d9a,
/*LN-22*/         address _0xe5feba
/*LN-23*/     )
/*LN-24*/         external
/*LN-25*/         view
/*LN-26*/         returns (
/*LN-27*/             uint256 _0x8cd0a4,
/*LN-28*/             uint256 _0x6ff151,
/*LN-29*/             uint256 _0x477183
/*LN-30*/         ) {
/*LN-31*/         (uint256 _0x1045d1, uint256 _0x0353ce, uint256 _0x347a3f) = IMarket(
/*LN-32*/             _0x6e3d9a
/*LN-33*/         )._0x0cce35(_0xe5feba);
/*LN-34*/         _0x8cd0a4 = (_0x1045d1 * _0x347a3f) / 1e18;
/*LN-35*/         _0x6ff151 = _0x0353ce;
/*LN-36*/         if (_0x6ff151 == 0) {
/*LN-37*/             _0x477183 = type(uint256)._0x2f7c62;
/*LN-38*/         } else {
/*LN-39*/             _0x477183 = (_0x8cd0a4 * 1e18) / _0x6ff151;
/*LN-40*/         }
/*LN-41*/         return (_0x8cd0a4, _0x6ff151, _0x477183);
/*LN-42*/     }
/*LN-43*/     function _0x390062(
/*LN-44*/         address[] calldata _0x51bedd,
/*LN-45*/         address _0xe5feba
/*LN-46*/     )
/*LN-47*/         external
/*LN-48*/         view
/*LN-49*/         returns (
/*LN-50*/             uint256 _0x7d6277,
/*LN-51*/             uint256 _0x2ff8d2,
/*LN-52*/             uint256 _0x7248ad
/*LN-53*/         ) {
/*LN-54*/         for (uint256 i = 0; i < _0x51bedd.length; i++) {
/*LN-55*/             (uint256 _0x1045d1, uint256 _0x3454e7, ) = this._0xd80623(
/*LN-56*/                 _0x51bedd[i],
/*LN-57*/                 _0xe5feba
/*LN-58*/             );
/*LN-59*/             _0x7d6277 += _0x1045d1;
/*LN-60*/             _0x2ff8d2 += _0x3454e7;
/*LN-61*/         }
/*LN-62*/         if (_0x2ff8d2 == 0) {
/*LN-63*/             _0x7248ad = type(uint256)._0x2f7c62;
/*LN-64*/         } else {
/*LN-65*/             _0x7248ad = (_0x7d6277 * 1e18) / _0x2ff8d2;
/*LN-66*/         }
/*LN-67*/         return (_0x7d6277, _0x2ff8d2, _0x7248ad);
/*LN-68*/     }
/*LN-69*/ }
/*LN-70*/ contract LendingMarket {
/*LN-71*/     IERC20 public _0xac561e;
/*LN-72*/     DebtPreviewer public _0x771f54;
/*LN-73*/     mapping(address => uint256) public _0x70dd97;
/*LN-74*/     mapping(address => uint256) public _0x0353ce;
/*LN-75*/     uint256 public constant COLLATERAL_FACTOR = 80;
/*LN-76*/     constructor(address _0x4f9b02, address _0x0f4194) {
/*LN-77*/         _0xac561e = IERC20(_0x4f9b02);
/*LN-78*/         if (block.timestamp > 0) { _0x771f54 = DebtPreviewer(_0x0f4194); }
/*LN-79*/     }
/*LN-80*/     function _0x8e6f03(uint256 _0xae3550) external {
/*LN-81*/         _0xac561e._0x2c833f(msg.sender, address(this), _0xae3550);
/*LN-82*/         _0x70dd97[msg.sender] += _0xae3550;
/*LN-83*/     }
/*LN-84*/     function _0x8e4527(uint256 _0xae3550, address[] calldata _0x51bedd) external {
/*LN-85*/         (uint256 _0x7d6277, uint256 _0x2ff8d2, ) = _0x771f54
/*LN-86*/             ._0x390062(_0x51bedd, msg.sender);
/*LN-87*/         uint256 _0xd860ea = _0x2ff8d2 + _0xae3550;
/*LN-88*/         uint256 _0x65ce0c = (_0x7d6277 * COLLATERAL_FACTOR) / 100;
/*LN-89*/         require(_0xd860ea <= _0x65ce0c, "Insufficient collateral");
/*LN-90*/         _0x0353ce[msg.sender] += _0xae3550;
/*LN-91*/         _0xac561e.transfer(msg.sender, _0xae3550);
/*LN-92*/     }
/*LN-93*/     function _0x0cce35(
/*LN-94*/         address _0xe5feba
/*LN-95*/     )
/*LN-96*/         external
/*LN-97*/         view
/*LN-98*/         returns (uint256 _0x1045d1, uint256 _0xd6cb4d, uint256 _0x347a3f) {
/*LN-99*/         return (_0x70dd97[_0xe5feba], _0x0353ce[_0xe5feba], 1e18);
/*LN-100*/     }
/*LN-101*/ }