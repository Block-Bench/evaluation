/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IERC20 {
/*LN-3*/     function transfer(address _0x6ff151, uint256 _0xd80623) external returns (bool);
/*LN-4*/     function _0x7d6277(address from, address _0x6ff151, uint256 _0xd80623) external returns (bool);
/*LN-5*/ }
/*LN-6*/ interface ILendToken {
/*LN-7*/     function _0x0f4194(uint256 _0xd80623) external;
/*LN-8*/     function _0x7248ad(uint256 _0xd80623) external;
/*LN-9*/     function _0x2c833f(uint256 _0x1045d1) external;
/*LN-10*/     function _0x2ff8d2(uint256 _0xd80623) external;
/*LN-11*/ }
/*LN-12*/ contract LendingMarket {
/*LN-13*/     mapping(address => uint256) public _0x390062;
/*LN-14*/     mapping(address => uint256) public _0x0cce35;
/*LN-15*/     address public _0x347a3f;
/*LN-16*/     uint256 public _0x8cd0a4;
/*LN-17*/     constructor(address _0x477183) {
/*LN-18*/         _0x347a3f = _0x477183;
/*LN-19*/     }
/*LN-20*/     function _0x0f4194(uint256 _0xd80623) external {
/*LN-21*/         _0x390062[msg.sender] += _0xd80623;
/*LN-22*/         _0x8cd0a4 += _0xd80623;
/*LN-23*/         IERC20(_0x347a3f).transfer(msg.sender, _0xd80623);
/*LN-24*/     }
/*LN-25*/     function _0x7248ad(uint256 _0xd80623) external {
/*LN-26*/         IERC20(_0x347a3f)._0x7d6277(msg.sender, address(this), _0xd80623);
/*LN-27*/         _0x390062[msg.sender] -= _0xd80623;
/*LN-28*/         _0x8cd0a4 -= _0xd80623;
/*LN-29*/     }
/*LN-30*/ }