/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IERC20 {
/*LN-3*/     function transfer(address _0x163f22, uint256 _0x6e3d9a) external returns (bool);
/*LN-4*/     function _0x1045d1(
/*LN-5*/         address from,
/*LN-6*/         address _0x163f22,
/*LN-7*/         uint256 _0x6e3d9a
/*LN-8*/     ) external returns (bool);
/*LN-9*/     function _0x65ce0c(address _0x0353ce) external view returns (uint256);
/*LN-10*/     function _0x51bedd(address _0x8e4527, uint256 _0x6e3d9a) external returns (bool);
/*LN-11*/ }
/*LN-12*/ interface IFlashLoanReceiver {
/*LN-13*/     function _0x0cce35(
/*LN-14*/         address[] calldata _0x3454e7,
/*LN-15*/         uint256[] calldata _0x4f9b02,
/*LN-16*/         uint256[] calldata _0x70dd97,
/*LN-17*/         address _0x0d961f,
/*LN-18*/         bytes calldata _0xc285d4
/*LN-19*/     ) external returns (bool);
/*LN-20*/ }
/*LN-21*/ contract CrossLendingPool {
/*LN-22*/     uint256 public constant RAY = 1e27;
/*LN-23*/     struct ReserveData {
/*LN-24*/         uint256 _0x477183;
/*LN-25*/         uint256 _0x7248ad;
/*LN-26*/         address _0x2c833f;
/*LN-27*/     }
/*LN-28*/     mapping(address => ReserveData) public _0xe5feba;
/*LN-29*/     function _0xae3550(
/*LN-30*/         address _0x876f47,
/*LN-31*/         uint256 _0x6e3d9a,
/*LN-32*/         address _0x771f54,
/*LN-33*/         uint16 _0xd80623
/*LN-34*/     ) external {
/*LN-35*/         IERC20(_0x876f47)._0x1045d1(msg.sender, address(this), _0x6e3d9a);
/*LN-36*/         ReserveData storage _0xd860ea = _0xe5feba[_0x876f47];
/*LN-37*/         uint256 _0x390062 = _0xd860ea._0x477183;
/*LN-38*/         if (_0x390062 == 0) {
/*LN-39*/             _0x390062 = RAY;
/*LN-40*/         }
/*LN-41*/         _0xd860ea._0x477183 =
/*LN-42*/             _0x390062 +
/*LN-43*/             (_0x6e3d9a * RAY) /
/*LN-44*/             (_0xd860ea._0x7248ad + 1);
/*LN-45*/         _0xd860ea._0x7248ad += _0x6e3d9a;
/*LN-46*/         uint256 _0x0f4194 = _0xac561e(_0x6e3d9a, _0xd860ea._0x477183);
/*LN-47*/         _0x6ff151(_0xd860ea._0x2c833f, _0x771f54, _0x0f4194);
/*LN-48*/     }
/*LN-49*/     function _0x8e6f03(
/*LN-50*/         address _0x876f47,
/*LN-51*/         uint256 _0x6e3d9a,
/*LN-52*/         address _0x163f22
/*LN-53*/     ) external returns (uint256) {
/*LN-54*/         ReserveData storage _0xd860ea = _0xe5feba[_0x876f47];
/*LN-55*/         uint256 _0x347a3f = _0xac561e(_0x6e3d9a, _0xd860ea._0x477183);
/*LN-56*/         _0x2ff8d2(_0xd860ea._0x2c833f, msg.sender, _0x347a3f);
/*LN-57*/         _0xd860ea._0x7248ad -= _0x6e3d9a;
/*LN-58*/         IERC20(_0x876f47).transfer(_0x163f22, _0x6e3d9a);
/*LN-59*/         return _0x6e3d9a;
/*LN-60*/     }
/*LN-61*/     function _0x2f7c62(
/*LN-62*/         address _0x876f47,
/*LN-63*/         uint256 _0x6e3d9a,
/*LN-64*/         uint256 _0x8cd0a4,
/*LN-65*/         uint16 _0xd80623,
/*LN-66*/         address _0x771f54
/*LN-67*/     ) external {
/*LN-68*/         IERC20(_0x876f47).transfer(_0x771f54, _0x6e3d9a);
/*LN-69*/     }
/*LN-70*/     function _0xd6cb4d(
/*LN-71*/         address _0x7d6277,
/*LN-72*/         address[] calldata _0x3454e7,
/*LN-73*/         uint256[] calldata _0x4f9b02,
/*LN-74*/         uint256[] calldata _0xb01af6,
/*LN-75*/         address _0x771f54,
/*LN-76*/         bytes calldata _0xc285d4,
/*LN-77*/         uint16 _0xd80623
/*LN-78*/     ) external {
/*LN-79*/         for (uint256 i = 0; i < _0x3454e7.length; i++) {
/*LN-80*/             IERC20(_0x3454e7[i]).transfer(_0x7d6277, _0x4f9b02[i]);
/*LN-81*/         }
/*LN-82*/         require(
/*LN-83*/             IFlashLoanReceiver(_0x7d6277)._0x0cce35(
/*LN-84*/                 _0x3454e7,
/*LN-85*/                 _0x4f9b02,
/*LN-86*/                 new uint256[](_0x3454e7.length),
/*LN-87*/                 msg.sender,
/*LN-88*/                 _0xc285d4
/*LN-89*/             ),
/*LN-90*/             "Flashloan callback failed"
/*LN-91*/         );
/*LN-92*/         for (uint256 i = 0; i < _0x3454e7.length; i++) {
/*LN-93*/             IERC20(_0x3454e7[i])._0x1045d1(
/*LN-94*/                 _0x7d6277,
/*LN-95*/                 address(this),
/*LN-96*/                 _0x4f9b02[i]
/*LN-97*/             );
/*LN-98*/         }
/*LN-99*/     }
/*LN-100*/     function _0xac561e(uint256 a, uint256 b) internal pure returns (uint256) {
/*LN-101*/         uint256 _0xb7cc25 = b / 2;
/*LN-102*/         require(b != 0, "Division by zero");
/*LN-103*/         return (a * RAY + _0xb7cc25) / b;
/*LN-104*/     }
/*LN-105*/     function _0x6ff151(address _0x3184cf, address _0x163f22, uint256 _0x6e3d9a) internal {
/*LN-106*/     }
/*LN-107*/     function _0x2ff8d2(
/*LN-108*/         address _0x3184cf,
/*LN-109*/         address from,
/*LN-110*/         uint256 _0x6e3d9a
/*LN-111*/     ) internal {
/*LN-112*/     }
/*LN-113*/ }