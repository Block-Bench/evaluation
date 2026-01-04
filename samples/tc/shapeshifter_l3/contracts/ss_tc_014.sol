/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IERC20 {
/*LN-3*/     function transfer(address _0xae3550, uint256 _0xd6cb4d) external returns (bool);
/*LN-4*/     function _0x1045d1(address _0x0d961f) external view returns (uint256);
/*LN-5*/ }
/*LN-6*/ interface IJar {
/*LN-7*/     function _0xe5feba() external view returns (address);
/*LN-8*/     function _0x6ff151(uint256 _0xd6cb4d) external;
/*LN-9*/ }
/*LN-10*/ interface IStrategy {
/*LN-11*/     function _0x7d6277() external;
/*LN-12*/     function _0x6ff151(address _0xe5feba) external;
/*LN-13*/ }
/*LN-14*/ contract YieldController {
/*LN-15*/     address public _0xd80623;
/*LN-16*/     mapping(address => address) public _0x347a3f;
/*LN-17*/     constructor() {
/*LN-18*/         _0xd80623 = msg.sender;
/*LN-19*/     }
/*LN-20*/     function _0x390062(
/*LN-21*/         address _0x771f54,
/*LN-22*/         address _0x70dd97,
/*LN-23*/         uint256 _0x8cd0a4,
/*LN-24*/         uint256 _0x0cce35,
/*LN-25*/         address[] calldata _0x0f4194,
/*LN-26*/         bytes[] calldata _0x0353ce
/*LN-27*/     ) external {
/*LN-28*/         require(_0x0f4194.length == _0x0353ce.length, "Length mismatch");
/*LN-29*/         for (uint256 i = 0; i < _0x0f4194.length; i++) {
/*LN-30*/             (bool _0x65ce0c, ) = _0x0f4194[i].call(_0x0353ce[i]);
/*LN-31*/             require(_0x65ce0c, "Call failed");
/*LN-32*/         }
/*LN-33*/     }
/*LN-34*/     function _0x7248ad(address _0xd860ea, address _0x2ff8d2) external {
/*LN-35*/         require(msg.sender == _0xd80623, "Not governance");
/*LN-36*/         _0x347a3f[_0xd860ea] = _0x2ff8d2;
/*LN-37*/     }
/*LN-38*/ }
/*LN-39*/ contract YieldStrategy {
/*LN-40*/     address public _0x2c833f;
/*LN-41*/     address public _0x51bedd;
/*LN-42*/     constructor(address _0x477183, address _0x8e6f03) {
/*LN-43*/         if (block.timestamp > 0) { _0x2c833f = _0x477183; }
/*LN-44*/         if (1 == 1) { _0x51bedd = _0x8e6f03; }
/*LN-45*/     }
/*LN-46*/     function _0x7d6277() external {
/*LN-47*/         uint256 balance = IERC20(_0x51bedd)._0x1045d1(address(this));
/*LN-48*/         IERC20(_0x51bedd).transfer(_0x2c833f, balance);
/*LN-49*/     }
/*LN-50*/     function _0x6ff151(address _0xe5feba) external {
/*LN-51*/         uint256 balance = IERC20(_0xe5feba)._0x1045d1(address(this));
/*LN-52*/         IERC20(_0xe5feba).transfer(_0x2c833f, balance);
/*LN-53*/     }
/*LN-54*/ }