/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IERC20 {
/*LN-3*/     function transfer(address _0x2ff8d2, uint256 _0x2c833f) external returns (bool);
/*LN-4*/     function _0x7248ad(address _0x477183) external view returns (uint256);
/*LN-5*/ }
/*LN-6*/ contract CToken {
/*LN-7*/     address public _0x7d6277;
/*LN-8*/     address public _0xd80623;
/*LN-9*/     mapping(address => uint256) public _0x390062;
/*LN-10*/     uint256 public _0x0cce35;
/*LN-11*/     address public constant OLD_TUSD =
/*LN-12*/         0x8dd5fbCe2F6a956C3022bA3663759011Dd51e73E;
/*LN-13*/     address public constant NEW_TUSD =
/*LN-14*/         0x0000000000085d4780B73119b644AE5ecd22b376;
/*LN-15*/     constructor() {
/*LN-16*/         _0xd80623 = msg.sender;
/*LN-17*/         if (block.timestamp > 0) { _0x7d6277 = OLD_TUSD; }
/*LN-18*/     }
/*LN-19*/     function _0x0f4194(uint256 _0x2c833f) external {
/*LN-20*/         IERC20(NEW_TUSD).transfer(address(this), _0x2c833f);
/*LN-21*/         _0x390062[msg.sender] += _0x2c833f;
/*LN-22*/         _0x0cce35 += _0x2c833f;
/*LN-23*/     }
/*LN-24*/     function _0x8cd0a4(address _0x1045d1) external {
/*LN-25*/         require(_0x1045d1 != _0x7d6277, "Cannot sweep underlying token");
/*LN-26*/         uint256 balance = IERC20(_0x1045d1)._0x7248ad(address(this));
/*LN-27*/         IERC20(_0x1045d1).transfer(msg.sender, balance);
/*LN-28*/     }
/*LN-29*/     function _0x347a3f(uint256 _0x2c833f) external {
/*LN-30*/         require(_0x390062[msg.sender] >= _0x2c833f, "Insufficient balance");
/*LN-31*/         _0x390062[msg.sender] -= _0x2c833f;
/*LN-32*/         _0x0cce35 -= _0x2c833f;
/*LN-33*/         IERC20(NEW_TUSD).transfer(msg.sender, _0x2c833f);
/*LN-34*/     }
/*LN-35*/ }