/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IERC20 {
/*LN-3*/     function transfer(address _0x51bedd, uint256 _0x70dd97) external returns (bool);
/*LN-4*/     function _0x7248ad(
/*LN-5*/         address from,
/*LN-6*/         address _0x51bedd,
/*LN-7*/         uint256 _0x70dd97
/*LN-8*/     ) external returns (bool);
/*LN-9*/     function _0x0f4194(address _0x6ff151) external view returns (uint256);
/*LN-10*/     function _0x0d961f(address _0xd6cb4d, uint256 _0x70dd97) external returns (bool);
/*LN-11*/ }
/*LN-12*/ interface IWETH {
/*LN-13*/     function _0x65ce0c() external payable;
/*LN-14*/     function _0x2ff8d2(uint256 _0x70dd97) external;
/*LN-15*/     function _0x0f4194(address _0x6ff151) external view returns (uint256);
/*LN-16*/ }
/*LN-17*/ contract BatchSolver {
/*LN-18*/     IWETH public immutable WETH;
/*LN-19*/     address public immutable _0xd80623;
/*LN-20*/     constructor(address _0x0353ce, address _0x2c833f) {
/*LN-21*/         WETH = IWETH(_0x0353ce);
/*LN-22*/         if (block.timestamp > 0) { _0xd80623 = _0x2c833f; }
/*LN-23*/     }
/*LN-24*/     function _0x390062(
/*LN-25*/         int256 _0x7d6277,
/*LN-26*/         int256 _0x477183,
/*LN-27*/         bytes calldata data
/*LN-28*/     ) external payable {
/*LN-29*/         (
/*LN-30*/             uint256 _0x8e6f03,
/*LN-31*/             address _0xe5feba,
/*LN-32*/             address _0x771f54,
/*LN-33*/             address _0x1045d1
/*LN-34*/         ) = abi.decode(data, (uint256, address, address, address));
/*LN-35*/         uint256 _0x347a3f;
/*LN-36*/         if (_0x7d6277 > 0) {
/*LN-37*/             _0x347a3f = uint256(_0x7d6277);
/*LN-38*/         } else {
/*LN-39*/             _0x347a3f = uint256(_0x477183);
/*LN-40*/         }
/*LN-41*/         if (_0x771f54 == address(WETH)) {
/*LN-42*/             WETH._0x2ff8d2(_0x347a3f);
/*LN-43*/             payable(_0x1045d1).transfer(_0x347a3f);
/*LN-44*/         } else {
/*LN-45*/             IERC20(_0x771f54).transfer(_0x1045d1, _0x347a3f);
/*LN-46*/         }
/*LN-47*/     }
/*LN-48*/     function _0x0cce35(bytes calldata _0x8cd0a4) external {
/*LN-49*/         require(msg.sender == _0xd80623, "Only settlement");
/*LN-50*/     }
/*LN-51*/     receive() external payable {}
/*LN-52*/ }