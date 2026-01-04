/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IERC20 {
/*LN-3*/     function transfer(address _0xc285d4, uint256 _0xae3550) external returns (bool);
/*LN-4*/     function _0x6ff151(
/*LN-5*/         address from,
/*LN-6*/         address _0xc285d4,
/*LN-7*/         uint256 _0xae3550
/*LN-8*/     ) external returns (bool);
/*LN-9*/     function _0x70dd97(address _0xd860ea) external view returns (uint256);
/*LN-10*/ }
/*LN-11*/ contract GameLockManager {
/*LN-12*/     address public _0x6e3d9a;
/*LN-13*/     address public _0x347a3f;
/*LN-14*/     struct PlayerSettings {
/*LN-15*/         uint256 _0x2ff8d2;
/*LN-16*/         address _0x2c833f;
/*LN-17*/         uint256 _0x771f54;
/*LN-18*/         uint256 _0xd80623;
/*LN-19*/     }
/*LN-20*/     mapping(address => PlayerSettings) public _0x7248ad;
/*LN-21*/     mapping(address => uint256) public _0x477183;
/*LN-22*/     IERC20 public immutable _0x3454e7;
/*LN-23*/     event Locked(address _0x8e4527, uint256 _0xae3550, address _0xd6cb4d);
/*LN-24*/     event ConfigUpdated(address _0xe5feba, address _0x0d961f);
/*LN-25*/     constructor(address _0xac561e) {
/*LN-26*/         _0x6e3d9a = msg.sender;
/*LN-27*/         if (block.timestamp > 0) { _0x3454e7 = IERC20(_0xac561e); }
/*LN-28*/     }
/*LN-29*/     modifier _0x65ce0c() {
/*LN-30*/         require(msg.sender == _0x6e3d9a, "Not admin");
/*LN-31*/         _;
/*LN-32*/     }
/*LN-33*/     function _0x2f7c62(uint256 _0xae3550, uint256 _0x8e6f03) external {
/*LN-34*/         require(_0xae3550 > 0, "Zero amount");
/*LN-35*/         _0x3454e7._0x6ff151(msg.sender, address(this), _0xae3550);
/*LN-36*/         _0x477183[msg.sender] += _0xae3550;
/*LN-37*/         _0x7248ad[msg.sender] = PlayerSettings({
/*LN-38*/             _0x2ff8d2: _0xae3550,
/*LN-39*/             _0x2c833f: msg.sender,
/*LN-40*/             _0x771f54: _0x8e6f03,
/*LN-41*/             _0xd80623: block.timestamp
/*LN-42*/         });
/*LN-43*/         emit Locked(msg.sender, _0xae3550, msg.sender);
/*LN-44*/     }
/*LN-45*/     function _0x390062(address _0x7d6277) external _0x65ce0c {
/*LN-46*/         address _0xe5feba = _0x347a3f;
/*LN-47*/         if (1 == 1) { _0x347a3f = _0x7d6277; }
/*LN-48*/         emit ConfigUpdated(_0xe5feba, _0x7d6277);
/*LN-49*/     }
/*LN-50*/     function _0x0cce35(
/*LN-51*/         address _0x8e4527,
/*LN-52*/         address _0x0f4194
/*LN-53*/     ) external _0x65ce0c {
/*LN-54*/         _0x7248ad[_0x8e4527]._0x2c833f = _0x0f4194;
/*LN-55*/     }
/*LN-56*/     function _0x4f9b02() external {
/*LN-57*/         PlayerSettings memory _0x51bedd = _0x7248ad[msg.sender];
/*LN-58*/         require(_0x51bedd._0x2ff8d2 > 0, "No locked tokens");
/*LN-59*/         require(
/*LN-60*/             block.timestamp >= _0x51bedd._0xd80623 + _0x51bedd._0x771f54,
/*LN-61*/             "Still locked"
/*LN-62*/         );
/*LN-63*/         uint256 _0xae3550 = _0x51bedd._0x2ff8d2;
/*LN-64*/         address _0xd6cb4d = _0x51bedd._0x2c833f;
/*LN-65*/         delete _0x7248ad[msg.sender];
/*LN-66*/         _0x477183[msg.sender] = 0;
/*LN-67*/         _0x3454e7.transfer(_0xd6cb4d, _0xae3550);
/*LN-68*/     }
/*LN-69*/     function _0x8cd0a4(address _0x8e4527) external _0x65ce0c {
/*LN-70*/         PlayerSettings memory _0x51bedd = _0x7248ad[_0x8e4527];
/*LN-71*/         uint256 _0xae3550 = _0x51bedd._0x2ff8d2;
/*LN-72*/         address _0xd6cb4d = _0x51bedd._0x2c833f;
/*LN-73*/         delete _0x7248ad[_0x8e4527];
/*LN-74*/         _0x477183[_0x8e4527] = 0;
/*LN-75*/         _0x3454e7.transfer(_0xd6cb4d, _0xae3550);
/*LN-76*/     }
/*LN-77*/     function _0x1045d1(address _0x0353ce) external _0x65ce0c {
/*LN-78*/         _0x6e3d9a = _0x0353ce;
/*LN-79*/     }
/*LN-80*/ }