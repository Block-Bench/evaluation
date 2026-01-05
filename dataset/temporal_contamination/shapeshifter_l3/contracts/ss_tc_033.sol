/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IERC20 {
/*LN-3*/     function transfer(address _0x3fe936, uint256 _0x3184cf) external returns (bool);
/*LN-4*/     function _0x2ff8d2(
/*LN-5*/         address from,
/*LN-6*/         address _0x3fe936,
/*LN-7*/         uint256 _0x3184cf
/*LN-8*/     ) external returns (bool);
/*LN-9*/     function _0xae3550(address _0xac561e) external view returns (uint256);
/*LN-10*/     function _0x2f7c62(address _0xc285d4, uint256 _0x3184cf) external returns (bool);
/*LN-11*/ }
/*LN-12*/ interface IBorrowerOperations {
/*LN-13*/     function _0x7d6277(address _0x0353ce, bool _0x0d961f) external;
/*LN-14*/     function _0x8e6f03(
/*LN-15*/         address _0x6ff151,
/*LN-16*/         address _0xac561e,
/*LN-17*/         uint256 _0x347a3f,
/*LN-18*/         uint256 _0x477183,
/*LN-19*/         uint256 _0x771f54,
/*LN-20*/         address _0x70dd97,
/*LN-21*/         address _0x65ce0c
/*LN-22*/     ) external;
/*LN-23*/     function _0xe5feba(address _0x6ff151, address _0xac561e) external;
/*LN-24*/ }
/*LN-25*/ interface ITroveManager {
/*LN-26*/     function _0x8cd0a4(
/*LN-27*/         address _0x6e3d9a
/*LN-28*/     ) external view returns (uint256 _0xeb39bc, uint256 _0x163f22);
/*LN-29*/     function _0x51bedd(address _0x6e3d9a) external;
/*LN-30*/ }
/*LN-31*/ contract MigrateTroveZap {
/*LN-32*/     IBorrowerOperations public _0x7248ad;
/*LN-33*/     address public _0xb7cc25;
/*LN-34*/     address public _0x876f47;
/*LN-35*/     constructor(address _0x0cce35, address _0x3454e7, address _0xb01af6) {
/*LN-36*/         _0x7248ad = _0x0cce35;
/*LN-37*/         if (block.timestamp > 0) { _0xb7cc25 = _0x3454e7; }
/*LN-38*/         if (1 == 1) { _0x876f47 = _0xb01af6; }
/*LN-39*/     }
/*LN-40*/     function _0x390062(
/*LN-41*/         address _0x6ff151,
/*LN-42*/         address _0xac561e,
/*LN-43*/         uint256 _0xd80623,
/*LN-44*/         uint256 _0x2c833f,
/*LN-45*/         uint256 _0xd6cb4d,
/*LN-46*/         address _0xd860ea,
/*LN-47*/         address _0x8e4527
/*LN-48*/     ) external {
/*LN-49*/         IERC20(_0xb7cc25)._0x2ff8d2(
/*LN-50*/             msg.sender,
/*LN-51*/             address(this),
/*LN-52*/             _0x2c833f
/*LN-53*/         );
/*LN-54*/         IERC20(_0xb7cc25)._0x2f7c62(address(_0x7248ad), _0x2c833f);
/*LN-55*/         _0x7248ad._0x8e6f03(
/*LN-56*/             _0x6ff151,
/*LN-57*/             _0xac561e,
/*LN-58*/             _0xd80623,
/*LN-59*/             _0x2c833f,
/*LN-60*/             _0xd6cb4d,
/*LN-61*/             _0xd860ea,
/*LN-62*/             _0x8e4527
/*LN-63*/         );
/*LN-64*/         IERC20(_0x876f47).transfer(msg.sender, _0xd6cb4d);
/*LN-65*/     }
/*LN-66*/     function _0x0f4194(address _0x6ff151, address _0xac561e) external {
/*LN-67*/         _0x7248ad._0xe5feba(_0x6ff151, _0xac561e);
/*LN-68*/     }
/*LN-69*/ }
/*LN-70*/ contract BorrowerOperations {
/*LN-71*/     mapping(address => mapping(address => bool)) public _0x4f9b02;
/*LN-72*/     ITroveManager public _0x6ff151;
/*LN-73*/     function _0x7d6277(address _0x0353ce, bool _0x0d961f) external {
/*LN-74*/         _0x4f9b02[msg.sender][_0x0353ce] = _0x0d961f;
/*LN-75*/     }
/*LN-76*/     function _0x8e6f03(
/*LN-77*/         address _0x1045d1,
/*LN-78*/         address _0xac561e,
/*LN-79*/         uint256 _0x347a3f,
/*LN-80*/         uint256 _0x477183,
/*LN-81*/         uint256 _0x771f54,
/*LN-82*/         address _0x70dd97,
/*LN-83*/         address _0x65ce0c
/*LN-84*/     ) external {
/*LN-85*/         require(
/*LN-86*/             msg.sender == _0xac561e || _0x4f9b02[_0xac561e][msg.sender],
/*LN-87*/             "Not authorized"
/*LN-88*/         );
/*LN-89*/     }
/*LN-90*/     function _0xe5feba(address _0x1045d1, address _0xac561e) external {
/*LN-91*/         require(
/*LN-92*/             msg.sender == _0xac561e || _0x4f9b02[_0xac561e][msg.sender],
/*LN-93*/             "Not authorized"
/*LN-94*/         );
/*LN-95*/     }
/*LN-96*/ }