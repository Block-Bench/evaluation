/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IERC20 {
/*LN-3*/     function _0x0d961f(address _0x0353ce) external view returns (uint256);
/*LN-4*/     function transfer(address _0x3454e7, uint256 _0xae3550) external returns (bool);
/*LN-5*/     function _0x1045d1(
/*LN-6*/         address from,
/*LN-7*/         address _0x3454e7,
/*LN-8*/         uint256 _0xae3550
/*LN-9*/     ) external returns (bool);
/*LN-10*/ }
/*LN-11*/ interface IStablePool {
/*LN-12*/     function _0x0cce35() external view returns (uint256);
/*LN-13*/     function _0x2c833f(
/*LN-14*/         uint256[3] calldata _0xd860ea,
/*LN-15*/         uint256 _0x347a3f
/*LN-16*/     ) external;
/*LN-17*/ }
/*LN-18*/ contract SimplifiedOracle {
/*LN-19*/     IStablePool public _0x771f54;
/*LN-20*/     constructor(address _0x2ff8d2) {
/*LN-21*/         _0x771f54 = IStablePool(_0x2ff8d2);
/*LN-22*/     }
/*LN-23*/     function _0x70dd97() external view returns (uint256) {
/*LN-24*/         return _0x771f54._0x0cce35();
/*LN-25*/     }
/*LN-26*/ }
/*LN-27*/ contract SyntheticLending {
/*LN-28*/     struct Position {
/*LN-29*/         uint256 _0x6ff151;
/*LN-30*/         uint256 _0xe5feba;
/*LN-31*/     }
/*LN-32*/     mapping(address => Position) public _0x65ce0c;
/*LN-33*/     address public _0x7248ad;
/*LN-34*/     address public _0x0f4194;
/*LN-35*/     address public _0x4f9b02;
/*LN-36*/     uint256 public constant COLLATERAL_FACTOR = 80;
/*LN-37*/     constructor(
/*LN-38*/         address _0x7d6277,
/*LN-39*/         address _0xd80623,
/*LN-40*/         address _0x8e6f03
/*LN-41*/     ) {
/*LN-42*/         _0x7248ad = _0x7d6277;
/*LN-43*/         _0x0f4194 = _0xd80623;
/*LN-44*/         _0x4f9b02 = _0x8e6f03;
/*LN-45*/     }
/*LN-46*/     function _0x51bedd(uint256 _0xae3550) external {
/*LN-47*/         IERC20(_0x7248ad)._0x1045d1(msg.sender, address(this), _0xae3550);
/*LN-48*/         _0x65ce0c[msg.sender]._0x6ff151 += _0xae3550;
/*LN-49*/     }
/*LN-50*/     function _0x8e4527(uint256 _0xae3550) external {
/*LN-51*/         uint256 _0x477183 = _0x390062(msg.sender);
/*LN-52*/         uint256 _0xd6cb4d = (_0x477183 * COLLATERAL_FACTOR) / 100;
/*LN-53*/         require(
/*LN-54*/             _0x65ce0c[msg.sender]._0xe5feba + _0xae3550 <= _0xd6cb4d,
/*LN-55*/             "Insufficient collateral"
/*LN-56*/         );
/*LN-57*/         _0x65ce0c[msg.sender]._0xe5feba += _0xae3550;
/*LN-58*/         IERC20(_0x0f4194).transfer(msg.sender, _0xae3550);
/*LN-59*/     }
/*LN-60*/     function _0x390062(address _0xac561e) public view returns (uint256) {
/*LN-61*/         uint256 _0x8cd0a4 = _0x65ce0c[_0xac561e]._0x6ff151;
/*LN-62*/         uint256 _0x6e3d9a = SimplifiedOracle(_0x4f9b02)._0x70dd97();
/*LN-63*/         return (_0x8cd0a4 * _0x6e3d9a) / 1e18;
/*LN-64*/     }
/*LN-65*/ }