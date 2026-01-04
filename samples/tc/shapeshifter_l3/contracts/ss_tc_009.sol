/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IERC777 {
/*LN-3*/     function transfer(address _0xe5feba, uint256 _0x6ff151) external returns (bool);
/*LN-4*/     function _0xd80623(address _0x2ff8d2) external view returns (uint256);
/*LN-5*/ }
/*LN-6*/ interface IERC1820Registry {
/*LN-7*/     function _0x390062(
/*LN-8*/         address _0x2ff8d2,
/*LN-9*/         bytes32 _0x7248ad,
/*LN-10*/         address _0x2c833f
/*LN-11*/     ) external;
/*LN-12*/ }
/*LN-13*/ contract LendingPool {
/*LN-14*/     mapping(address => mapping(address => uint256)) public _0x1045d1;
/*LN-15*/     mapping(address => uint256) public _0x7d6277;
/*LN-16*/     function _0x771f54(address _0x65ce0c, uint256 _0x6ff151) external returns (uint256) {
/*LN-17*/         IERC777 _0x0d961f = IERC777(_0x65ce0c);
/*LN-18*/         require(_0x0d961f.transfer(address(this), _0x6ff151), "Transfer failed");
/*LN-19*/         _0x1045d1[msg.sender][_0x65ce0c] += _0x6ff151;
/*LN-20*/         _0x7d6277[_0x65ce0c] += _0x6ff151;
/*LN-21*/         return _0x6ff151;
/*LN-22*/     }
/*LN-23*/     function _0x0f4194(
/*LN-24*/         address _0x65ce0c,
/*LN-25*/         uint256 _0x0cce35
/*LN-26*/     ) external returns (uint256) {
/*LN-27*/         uint256 _0x477183 = _0x1045d1[msg.sender][_0x65ce0c];
/*LN-28*/         require(_0x477183 > 0, "No balance");
/*LN-29*/         uint256 _0x8cd0a4 = _0x0cce35;
/*LN-30*/         if (_0x0cce35 == type(uint256)._0x70dd97) {
/*LN-31*/             _0x8cd0a4 = _0x477183;
/*LN-32*/         }
/*LN-33*/         require(_0x8cd0a4 <= _0x477183, "Insufficient balance");
/*LN-34*/         IERC777(_0x65ce0c).transfer(msg.sender, _0x8cd0a4);
/*LN-35*/         _0x1045d1[msg.sender][_0x65ce0c] -= _0x8cd0a4;
/*LN-36*/         _0x7d6277[_0x65ce0c] -= _0x8cd0a4;
/*LN-37*/         return _0x8cd0a4;
/*LN-38*/     }
/*LN-39*/     function _0x347a3f(
/*LN-40*/         address _0xd6cb4d,
/*LN-41*/         address _0x65ce0c
/*LN-42*/     ) external view returns (uint256) {
/*LN-43*/         return _0x1045d1[_0xd6cb4d][_0x65ce0c];
/*LN-44*/     }
/*LN-45*/ }