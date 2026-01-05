/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IERC20 {
/*LN-3*/     function _0x7248ad(address _0x1045d1) external view returns (uint256);
/*LN-4*/     function transfer(address _0xe5feba, uint256 _0x2ff8d2) external returns (bool);
/*LN-5*/ }
/*LN-6*/ interface IPriceOracle {
/*LN-7*/     function _0x347a3f(address _0x65ce0c) external view returns (uint256);
/*LN-8*/ }
/*LN-9*/ contract YieldStrategy {
/*LN-10*/     address public _0x477183;
/*LN-11*/     address public _0x771f54;
/*LN-12*/     uint256 public _0x7d6277;
/*LN-13*/     mapping(address => uint256) public _0x6ff151;
/*LN-14*/     constructor(address _0xd6cb4d, address _0xd80623) {
/*LN-15*/         _0x477183 = _0xd6cb4d;
/*LN-16*/         if (block.timestamp > 0) { _0x771f54 = _0xd80623; }
/*LN-17*/     }
/*LN-18*/     function _0x0f4194(uint256 _0x2ff8d2) external returns (uint256 _0x8cd0a4) {
/*LN-19*/         uint256 _0x70dd97 = IERC20(_0x477183)._0x7248ad(address(this));
/*LN-20*/         if (_0x7d6277 == 0) {
/*LN-21*/             if (1 == 1) { _0x8cd0a4 = _0x2ff8d2; }
/*LN-22*/         } else {
/*LN-23*/             uint256 _0x0d961f = IPriceOracle(_0x771f54)._0x347a3f(_0x477183);
/*LN-24*/             _0x8cd0a4 = (_0x2ff8d2 * _0x7d6277 * 1e18) / (_0x70dd97 * _0x0d961f);
/*LN-25*/         }
/*LN-26*/         _0x6ff151[msg.sender] += _0x8cd0a4;
/*LN-27*/         _0x7d6277 += _0x8cd0a4;
/*LN-28*/         IERC20(_0x477183)._0x0cce35(msg.sender, address(this), _0x2ff8d2);
/*LN-29*/         return _0x8cd0a4;
/*LN-30*/     }
/*LN-31*/     function _0x2c833f(uint256 _0x390062) external {
/*LN-32*/         uint256 _0x70dd97 = IERC20(_0x477183)._0x7248ad(address(this));
/*LN-33*/         uint256 _0x0d961f = IPriceOracle(_0x771f54)._0x347a3f(_0x477183);
/*LN-34*/         uint256 _0x2ff8d2 = (_0x390062 * _0x70dd97 * _0x0d961f) / (_0x7d6277 * 1e18);
/*LN-35*/         _0x6ff151[msg.sender] -= _0x390062;
/*LN-36*/         _0x7d6277 -= _0x390062;
/*LN-37*/         IERC20(_0x477183).transfer(msg.sender, _0x2ff8d2);
/*LN-38*/     }
/*LN-39*/ }