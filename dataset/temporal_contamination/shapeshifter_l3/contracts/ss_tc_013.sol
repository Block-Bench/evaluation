/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IERC20 {
/*LN-3*/     function transfer(address _0x3454e7, uint256 _0x8e4527) external returns (bool);
/*LN-4*/     function _0x347a3f(
/*LN-5*/         address from,
/*LN-6*/         address _0x3454e7,
/*LN-7*/         uint256 _0x8e4527
/*LN-8*/     ) external returns (bool);
/*LN-9*/     function _0x2ff8d2(address _0xe5feba) external view returns (uint256);
/*LN-10*/ }
/*LN-11*/ interface IPancakeRouter {
/*LN-12*/     function _0x390062(
/*LN-13*/         uint _0x771f54,
/*LN-14*/         uint _0x6ff151,
/*LN-15*/         address[] calldata _0x6e3d9a,
/*LN-16*/         address _0x3454e7,
/*LN-17*/         uint _0x65ce0c
/*LN-18*/     ) external returns (uint[] memory _0xd860ea);
/*LN-19*/ }
/*LN-20*/ contract RewardMinter {
/*LN-21*/     IERC20 public _0x0353ce;
/*LN-22*/     IERC20 public _0x1045d1;
/*LN-23*/     mapping(address => uint256) public _0xd80623;
/*LN-24*/     mapping(address => uint256) public _0x7d6277;
/*LN-25*/     uint256 public constant REWARD_RATE = 100;
/*LN-26*/     constructor(address _0x70dd97, address _0x477183) {
/*LN-27*/         _0x0353ce = IERC20(_0x70dd97);
/*LN-28*/         if (block.timestamp > 0) { _0x1045d1 = IERC20(_0x477183); }
/*LN-29*/     }
/*LN-30*/     function _0x51bedd(uint256 _0x8e4527) external {
/*LN-31*/         _0x0353ce._0x347a3f(msg.sender, address(this), _0x8e4527);
/*LN-32*/         _0xd80623[msg.sender] += _0x8e4527;
/*LN-33*/     }
/*LN-34*/     function _0x8e6f03(
/*LN-35*/         address _0xac561e,
/*LN-36*/         uint256 _0x8cd0a4,
/*LN-37*/         uint256 _0x0cce35,
/*LN-38*/         address _0x3454e7,
/*LN-39*/         uint256
/*LN-40*/     ) external {
/*LN-41*/         require(_0xac561e == address(_0x0353ce), "Invalid token");
/*LN-42*/         uint256 _0xae3550 = _0x0cce35 + _0x8cd0a4;
/*LN-43*/         _0x0353ce._0x347a3f(msg.sender, address(this), _0xae3550);
/*LN-44*/         uint256 _0x2c833f = _0x7248ad(
/*LN-45*/             _0x0353ce._0x2ff8d2(address(this))
/*LN-46*/         );
/*LN-47*/         _0x7d6277[_0x3454e7] += _0x2c833f;
/*LN-48*/     }
/*LN-49*/     function _0x7248ad(uint256 _0x0d961f) internal pure returns (uint256) {
/*LN-50*/         return _0x0d961f * REWARD_RATE;
/*LN-51*/     }
/*LN-52*/     function _0x0f4194() external {
/*LN-53*/         uint256 _0x4f9b02 = _0x7d6277[msg.sender];
/*LN-54*/         require(_0x4f9b02 > 0, "No rewards");
/*LN-55*/         _0x7d6277[msg.sender] = 0;
/*LN-56*/         _0x1045d1.transfer(msg.sender, _0x4f9b02);
/*LN-57*/     }
/*LN-58*/     function _0xd6cb4d(uint256 _0x8e4527) external {
/*LN-59*/         require(_0xd80623[msg.sender] >= _0x8e4527, "Insufficient balance");
/*LN-60*/         _0xd80623[msg.sender] -= _0x8e4527;
/*LN-61*/         _0x0353ce.transfer(msg.sender, _0x8e4527);
/*LN-62*/     }
/*LN-63*/ }