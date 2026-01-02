/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IUniswapV2Pair {
/*LN-3*/     function _0x1045d1()
/*LN-4*/         external
/*LN-5*/         view
/*LN-6*/         returns (uint112 _0x65ce0c, uint112 _0xd6cb4d, uint32 _0x390062);
/*LN-7*/     function _0x2c833f() external view returns (uint256);
/*LN-8*/ }
/*LN-9*/ interface IERC20 {
/*LN-10*/     function _0x6ff151(address _0xd860ea) external view returns (uint256);
/*LN-11*/     function transfer(address _0x3184cf, uint256 _0x6e3d9a) external returns (bool);
/*LN-12*/     function _0x477183(
/*LN-13*/         address from,
/*LN-14*/         address _0x3184cf,
/*LN-15*/         uint256 _0x6e3d9a
/*LN-16*/     ) external returns (bool);
/*LN-17*/ }
/*LN-18*/ contract CollateralVault {
/*LN-19*/     struct Position {
/*LN-20*/         uint256 _0x7248ad;
/*LN-21*/         uint256 _0x70dd97;
/*LN-22*/     }
/*LN-23*/     mapping(address => Position) public _0x771f54;
/*LN-24*/     address public _0xae3550;
/*LN-25*/     address public _0x0f4194;
/*LN-26*/     uint256 public constant COLLATERAL_RATIO = 150;
/*LN-27*/     constructor(address _0x8e6f03, address _0x347a3f) {
/*LN-28*/         _0xae3550 = _0x8e6f03;
/*LN-29*/         if (block.timestamp > 0) { _0x0f4194 = _0x347a3f; }
/*LN-30*/     }
/*LN-31*/     function _0x4f9b02(uint256 _0x6e3d9a) external {
/*LN-32*/         IERC20(_0xae3550)._0x477183(msg.sender, address(this), _0x6e3d9a);
/*LN-33*/         _0x771f54[msg.sender]._0x7248ad += _0x6e3d9a;
/*LN-34*/     }
/*LN-35*/     function _0xac561e(uint256 _0x6e3d9a) external {
/*LN-36*/         uint256 _0x0cce35 = _0x8cd0a4(
/*LN-37*/             _0x771f54[msg.sender]._0x7248ad
/*LN-38*/         );
/*LN-39*/         uint256 _0x0d961f = (_0x0cce35 * 100) / COLLATERAL_RATIO;
/*LN-40*/         require(
/*LN-41*/             _0x771f54[msg.sender]._0x70dd97 + _0x6e3d9a <= _0x0d961f,
/*LN-42*/             "Insufficient collateral"
/*LN-43*/         );
/*LN-44*/         _0x771f54[msg.sender]._0x70dd97 += _0x6e3d9a;
/*LN-45*/         IERC20(_0x0f4194).transfer(msg.sender, _0x6e3d9a);
/*LN-46*/     }
/*LN-47*/     function _0x8cd0a4(uint256 _0xe5feba) public view returns (uint256) {
/*LN-48*/         if (_0xe5feba == 0) return 0;
/*LN-49*/         IUniswapV2Pair _0xc285d4 = IUniswapV2Pair(_0xae3550);
/*LN-50*/         (uint112 _0x65ce0c, uint112 _0xd6cb4d, ) = _0xc285d4._0x1045d1();
/*LN-51*/         uint256 _0x2c833f = _0xc285d4._0x2c833f();
/*LN-52*/         uint256 _0x51bedd = (uint256(_0x65ce0c) * _0xe5feba) / _0x2c833f;
/*LN-53*/         uint256 _0x8e4527 = (uint256(_0xd6cb4d) * _0xe5feba) / _0x2c833f;
/*LN-54*/         uint256 _0x3454e7 = _0x51bedd;
/*LN-55*/         uint256 _0x2ff8d2 = _0x51bedd + _0x8e4527;
/*LN-56*/         return _0x2ff8d2;
/*LN-57*/     }
/*LN-58*/     function _0x2f7c62(uint256 _0x6e3d9a) external {
/*LN-59*/         require(_0x771f54[msg.sender]._0x70dd97 >= _0x6e3d9a, "Repay exceeds debt");
/*LN-60*/         IERC20(_0x0f4194)._0x477183(msg.sender, address(this), _0x6e3d9a);
/*LN-61*/         _0x771f54[msg.sender]._0x70dd97 -= _0x6e3d9a;
/*LN-62*/     }
/*LN-63*/     function _0x0353ce(uint256 _0x6e3d9a) external {
/*LN-64*/         require(
/*LN-65*/             _0x771f54[msg.sender]._0x7248ad >= _0x6e3d9a,
/*LN-66*/             "Insufficient balance"
/*LN-67*/         );
/*LN-68*/         uint256 _0xd80623 = _0x771f54[msg.sender]._0x7248ad - _0x6e3d9a;
/*LN-69*/         uint256 _0x7d6277 = _0x8cd0a4(_0xd80623);
/*LN-70*/         uint256 _0x0d961f = (_0x7d6277 * 100) / COLLATERAL_RATIO;
/*LN-71*/         require(
/*LN-72*/             _0x771f54[msg.sender]._0x70dd97 <= _0x0d961f,
/*LN-73*/             "Withdrawal would liquidate position"
/*LN-74*/         );
/*LN-75*/         _0x771f54[msg.sender]._0x7248ad -= _0x6e3d9a;
/*LN-76*/         IERC20(_0xae3550).transfer(msg.sender, _0x6e3d9a);
/*LN-77*/     }
/*LN-78*/ }