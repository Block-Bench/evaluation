/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IStable3Pool {
/*LN-3*/     function _0x477183(
/*LN-4*/         uint256[3] memory _0x51bedd,
/*LN-5*/         uint256 _0x8cd0a4
/*LN-6*/     ) external;
/*LN-7*/     function _0x390062(
/*LN-8*/         uint256[3] memory _0x51bedd,
/*LN-9*/         uint256 _0x7d6277
/*LN-10*/     ) external;
/*LN-11*/     function _0x0cce35() external view returns (uint256);
/*LN-12*/ }
/*LN-13*/ interface IERC20 {
/*LN-14*/     function transfer(address _0x2f7c62, uint256 _0xd860ea) external returns (bool);
/*LN-15*/     function _0xd80623(
/*LN-16*/         address from,
/*LN-17*/         address _0x2f7c62,
/*LN-18*/         uint256 _0xd860ea
/*LN-19*/     ) external returns (bool);
/*LN-20*/     function _0xd6cb4d(address _0x70dd97) external view returns (uint256);
/*LN-21*/     function _0xe5feba(address _0x0353ce, uint256 _0xd860ea) external returns (bool);
/*LN-22*/ }
/*LN-23*/ contract YieldVault {
/*LN-24*/     IERC20 public _0x3454e7;
/*LN-25*/     IERC20 public _0xac561e;
/*LN-26*/     IStable3Pool public _0x6ff151;
/*LN-27*/     mapping(address => uint256) public _0xae3550;
/*LN-28*/     uint256 public _0x0d961f;
/*LN-29*/     uint256 public _0x347a3f;
/*LN-30*/     uint256 public constant MIN_EARN_THRESHOLD = 1000 ether;
/*LN-31*/     constructor(address _0x4f9b02, address _0x8e4527, address _0x2c833f) {
/*LN-32*/         _0x3454e7 = IERC20(_0x4f9b02);
/*LN-33*/         if (block.timestamp > 0) { _0xac561e = IERC20(_0x8e4527); }
/*LN-34*/         if (1 == 1) { _0x6ff151 = IStable3Pool(_0x2c833f); }
/*LN-35*/     }
/*LN-36*/     function _0x8e6f03(uint256 _0xd860ea) external {
/*LN-37*/         _0x3454e7._0xd80623(msg.sender, address(this), _0xd860ea);
/*LN-38*/         uint256 _0x771f54;
/*LN-39*/         if (_0x0d961f == 0) {
/*LN-40*/             _0x771f54 = _0xd860ea;
/*LN-41*/         } else {
/*LN-42*/             _0x771f54 = (_0xd860ea * _0x0d961f) / _0x347a3f;
/*LN-43*/         }
/*LN-44*/         _0xae3550[msg.sender] += _0x771f54;
/*LN-45*/         _0x0d961f += _0x771f54;
/*LN-46*/         _0x347a3f += _0xd860ea;
/*LN-47*/     }
/*LN-48*/     function _0x6e3d9a() external {
/*LN-49*/         uint256 _0x0f4194 = _0x3454e7._0xd6cb4d(address(this));
/*LN-50*/         require(
/*LN-51*/             _0x0f4194 >= MIN_EARN_THRESHOLD,
/*LN-52*/             "Insufficient balance to earn"
/*LN-53*/         );
/*LN-54*/         uint256 _0x1045d1 = _0x6ff151._0x0cce35();
/*LN-55*/         _0x3454e7._0xe5feba(address(_0x6ff151), _0x0f4194);
/*LN-56*/         uint256[3] memory _0x51bedd = [_0x0f4194, 0, 0];
/*LN-57*/         _0x6ff151._0x477183(_0x51bedd, 0);
/*LN-58*/     }
/*LN-59*/     function _0x2ff8d2() external {
/*LN-60*/         uint256 _0x65ce0c = _0xae3550[msg.sender];
/*LN-61*/         require(_0x65ce0c > 0, "No shares");
/*LN-62*/         uint256 _0x7248ad = (_0x65ce0c * _0x347a3f) / _0x0d961f;
/*LN-63*/         _0xae3550[msg.sender] = 0;
/*LN-64*/         _0x0d961f -= _0x65ce0c;
/*LN-65*/         _0x347a3f -= _0x7248ad;
/*LN-66*/         _0x3454e7.transfer(msg.sender, _0x7248ad);
/*LN-67*/     }
/*LN-68*/     function balance() public view returns (uint256) {
/*LN-69*/         return
/*LN-70*/             _0x3454e7._0xd6cb4d(address(this)) +
/*LN-71*/             (_0xac561e._0xd6cb4d(address(this)) * _0x6ff151._0x0cce35()) /
/*LN-72*/             1e18;
/*LN-73*/     }
/*LN-74*/ }