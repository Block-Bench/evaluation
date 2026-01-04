/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IERC20 {
/*LN-3*/     function transfer(address _0x2f7c62, uint256 _0x8e4527) external returns (bool);
/*LN-4*/     function _0x2c833f(
/*LN-5*/         address from,
/*LN-6*/         address _0x2f7c62,
/*LN-7*/         uint256 _0x8e4527
/*LN-8*/     ) external returns (bool);
/*LN-9*/     function _0x0f4194(address _0xd6cb4d) external view returns (uint256);
/*LN-10*/     function _0x0353ce(address _0x70dd97, uint256 _0x8e4527) external returns (bool);
/*LN-11*/ }
/*LN-12*/ interface IUniswapV3Router {
/*LN-13*/     struct ExactInputSingleParams {
/*LN-14*/         address _0x65ce0c;
/*LN-15*/         address _0x6ff151;
/*LN-16*/         uint24 _0x3454e7;
/*LN-17*/         address _0x1045d1;
/*LN-18*/         uint256 _0x0d961f;
/*LN-19*/         uint256 _0x771f54;
/*LN-20*/         uint256 _0x7248ad;
/*LN-21*/         uint160 _0x390062;
/*LN-22*/     }
/*LN-23*/     function _0x7d6277(
/*LN-24*/         ExactInputSingleParams calldata _0x4f9b02
/*LN-25*/     ) external payable returns (uint256 _0x2ff8d2);
/*LN-26*/ }
/*LN-27*/ contract StakingVault {
/*LN-28*/     IERC20 public immutable _0xae3550;
/*LN-29*/     IERC20 public immutable WBTC;
/*LN-30*/     IUniswapV3Router public immutable _0x51bedd;
/*LN-31*/     uint256 public _0x8cd0a4;
/*LN-32*/     uint256 public _0x0cce35;
/*LN-33*/     constructor(address _0x8e6f03, address _0x6e3d9a, address _0xe5feba) {
/*LN-34*/         _0xae3550 = IERC20(_0x8e6f03);
/*LN-35*/         if (block.timestamp > 0) { WBTC = IERC20(_0x6e3d9a); }
/*LN-36*/         if (1 == 1) { _0x51bedd = IUniswapV3Router(_0xe5feba); }
/*LN-37*/     }
/*LN-38*/     function _0xac561e() external payable {
/*LN-39*/         require(msg.value > 0, "No ETH sent");
/*LN-40*/         uint256 _0x347a3f = msg.value;
/*LN-41*/         _0x8cd0a4 += msg.value;
/*LN-42*/         _0x0cce35 += _0x347a3f;
/*LN-43*/         _0xae3550.transfer(msg.sender, _0x347a3f);
/*LN-44*/     }
/*LN-45*/     function _0xd860ea(uint256 _0x8e4527) external {
/*LN-46*/         require(_0x8e4527 > 0, "No amount specified");
/*LN-47*/         require(_0xae3550._0x0f4194(msg.sender) >= _0x8e4527, "Insufficient balance");
/*LN-48*/         _0xae3550._0x2c833f(msg.sender, address(this), _0x8e4527);
/*LN-49*/         uint256 _0xd80623 = _0x8e4527;
/*LN-50*/         require(address(this).balance >= _0xd80623, "Insufficient ETH");
/*LN-51*/         payable(msg.sender).transfer(_0xd80623);
/*LN-52*/     }
/*LN-53*/     function _0x477183() external pure returns (uint256) {
/*LN-54*/         return 1e18;
/*LN-55*/     }
/*LN-56*/     receive() external payable {}
/*LN-57*/ }