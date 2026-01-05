/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ contract ConcentratedPool {
/*LN-3*/     address public _0xb92839;
/*LN-4*/     address public _0x961b76;
/*LN-5*/     uint160 public _0xd6cb4d;
/*LN-6*/     int24 public _0xd860ea;
/*LN-7*/     uint128 public _0xb01af6;
/*LN-8*/     mapping(int24 => int128) public _0x8e6f03;
/*LN-9*/     struct Position {
/*LN-10*/         uint128 _0xb01af6;
/*LN-11*/         int24 _0x3184cf;
/*LN-12*/         int24 _0x6e3d9a;
/*LN-13*/     }
/*LN-14*/     mapping(bytes32 => Position) public _0x3454e7;
/*LN-15*/     event Swap(
/*LN-16*/         address indexed sender,
/*LN-17*/         uint256 _0xac561e,
/*LN-18*/         uint256 _0xc285d4,
/*LN-19*/         uint256 _0x4f9b02,
/*LN-20*/         uint256 _0x8e4527
/*LN-21*/     );
/*LN-22*/     event LiquidityAdded(
/*LN-23*/         address indexed _0x163f22,
/*LN-24*/         int24 _0x3184cf,
/*LN-25*/         int24 _0x6e3d9a,
/*LN-26*/         uint128 _0xb01af6
/*LN-27*/     );
/*LN-28*/     function _0x70dd97(
/*LN-29*/         int24 _0x3184cf,
/*LN-30*/         int24 _0x6e3d9a,
/*LN-31*/         uint128 _0x771f54
/*LN-32*/     ) external returns (uint256 _0xc1cf42, uint256 _0x28587f) {
/*LN-33*/         require(_0x3184cf < _0x6e3d9a, "Invalid ticks");
/*LN-34*/         require(_0x771f54 > 0, "Zero liquidity");
/*LN-35*/         bytes32 _0x0353ce = keccak256(
/*LN-36*/             abi._0xe5feba(msg.sender, _0x3184cf, _0x6e3d9a)
/*LN-37*/         );
/*LN-38*/         Position storage _0xeb39bc = _0x3454e7[_0x0353ce];
/*LN-39*/         _0xeb39bc._0xb01af6 += _0x771f54;
/*LN-40*/         _0xeb39bc._0x3184cf = _0x3184cf;
/*LN-41*/         _0xeb39bc._0x6e3d9a = _0x6e3d9a;
/*LN-42*/         _0x8e6f03[_0x3184cf] += int128(_0x771f54);
/*LN-43*/         _0x8e6f03[_0x6e3d9a] -= int128(_0x771f54);
/*LN-44*/         if (_0xd860ea >= _0x3184cf && _0xd860ea < _0x6e3d9a) {
/*LN-45*/             _0xb01af6 += _0x771f54;
/*LN-46*/         }
/*LN-47*/         (_0xc1cf42, _0x28587f) = _0x477183(
/*LN-48*/             _0xd6cb4d,
/*LN-49*/             _0x3184cf,
/*LN-50*/             _0x6e3d9a,
/*LN-51*/             int128(_0x771f54)
/*LN-52*/         );
/*LN-53*/         emit LiquidityAdded(msg.sender, _0x3184cf, _0x6e3d9a, _0x771f54);
/*LN-54*/     }
/*LN-55*/     function _0x6273a6(
/*LN-56*/         bool _0xae3550,
/*LN-57*/         int256 _0x2ff8d2,
/*LN-58*/         uint160 _0x347a3f
/*LN-59*/     ) external returns (int256 _0xc1cf42, int256 _0x28587f) {
/*LN-60*/         require(_0x2ff8d2 != 0, "Zero amount");
/*LN-61*/         uint160 _0x0f4194 = _0xd6cb4d;
/*LN-62*/         uint128 _0x0d961f = _0xb01af6;
/*LN-63*/         int24 _0x3fe936 = _0xd860ea;
/*LN-64*/         while (_0x2ff8d2 != 0) {
/*LN-65*/             (
/*LN-66*/                 uint256 _0x876f47,
/*LN-67*/                 uint256 _0xb7cc25,
/*LN-68*/                 uint160 _0x7248ad
/*LN-69*/             ) = _0xd80623(
/*LN-70*/                     _0x0f4194,
/*LN-71*/                     _0x347a3f,
/*LN-72*/                     _0x0d961f,
/*LN-73*/                     _0x2ff8d2
/*LN-74*/                 );
/*LN-75*/             _0x0f4194 = _0x7248ad;
/*LN-76*/             int24 _0x51bedd = _0x0cce35(_0x0f4194);
/*LN-77*/             if (_0x51bedd != _0x3fe936) {
/*LN-78*/                 int128 _0x8cd0a4 = _0x8e6f03[_0x51bedd];
/*LN-79*/                 if (_0xae3550) {
/*LN-80*/                     _0x8cd0a4 = -_0x8cd0a4;
/*LN-81*/                 }
/*LN-82*/                 _0x0d961f = _0x65ce0c(
/*LN-83*/                     _0x0d961f,
/*LN-84*/                     _0x8cd0a4
/*LN-85*/                 );
/*LN-86*/                 _0x3fe936 = _0x51bedd;
/*LN-87*/             }
/*LN-88*/             if (_0x2ff8d2 > 0) {
/*LN-89*/                 _0x2ff8d2 -= int256(_0x876f47);
/*LN-90*/             } else {
/*LN-91*/                 _0x2ff8d2 += int256(_0xb7cc25);
/*LN-92*/             }
/*LN-93*/         }
/*LN-94*/         _0xd6cb4d = _0x0f4194;
/*LN-95*/         _0xb01af6 = _0x0d961f;
/*LN-96*/         _0xd860ea = _0x3fe936;
/*LN-97*/         return (_0xc1cf42, _0x28587f);
/*LN-98*/     }
/*LN-99*/     function _0x65ce0c(
/*LN-100*/         uint128 x,
/*LN-101*/         int128 y
/*LN-102*/     ) internal pure returns (uint128 z) {
/*LN-103*/         if (y < 0) {
/*LN-104*/             z = x - uint128(-y);
/*LN-105*/         } else {
/*LN-106*/             z = x + uint128(y);
/*LN-107*/         }
/*LN-108*/     }
/*LN-109*/     function _0x477183(
/*LN-110*/         uint160 _0x2f7c62,
/*LN-111*/         int24 _0x3184cf,
/*LN-112*/         int24 _0x6e3d9a,
/*LN-113*/         int128 _0x771f54
/*LN-114*/     ) internal pure returns (uint256 _0xc1cf42, uint256 _0x28587f) {
/*LN-115*/         _0xc1cf42 = uint256(uint128(_0x771f54)) / 2;
/*LN-116*/         _0x28587f = uint256(uint128(_0x771f54)) / 2;
/*LN-117*/     }
/*LN-118*/     function _0xd80623(
/*LN-119*/         uint160 _0x390062,
/*LN-120*/         uint160 _0x7d6277,
/*LN-121*/         uint128 _0x1045d1,
/*LN-122*/         int256 _0x6ff151
/*LN-123*/     )
/*LN-124*/         internal
/*LN-125*/         pure
/*LN-126*/         returns (uint256 _0x876f47, uint256 _0xb7cc25, uint160 _0x2c833f) {
/*LN-127*/         _0x876f47 =
/*LN-128*/             uint256(_0x6ff151 > 0 ? _0x6ff151 : -_0x6ff151) /
/*LN-129*/             2;
/*LN-130*/         _0xb7cc25 = _0x876f47;
/*LN-131*/         _0x2c833f = _0x390062;
/*LN-132*/     }
/*LN-133*/     function _0x0cce35(
/*LN-134*/         uint160 _0xd6cb4d
/*LN-135*/     ) internal pure returns (int24 _0x239cbb) {
/*LN-136*/         return int24(int256(uint256(_0xd6cb4d >> 96)));
/*LN-137*/     }
/*LN-138*/ }