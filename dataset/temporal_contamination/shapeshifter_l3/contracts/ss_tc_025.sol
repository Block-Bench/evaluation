/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IERC20 {
/*LN-3*/     function _0x7248ad(address _0xd80623) external view returns (uint256);
/*LN-4*/     function transfer(address _0x771f54, uint256 _0x1045d1) external returns (bool);
/*LN-5*/     function _0x0cce35(address from, address _0x771f54, uint256 _0x1045d1) external returns (bool);
/*LN-6*/ }
/*LN-7*/ contract DeflatToken {
/*LN-8*/     mapping(address => uint256) public _0x7248ad;
/*LN-9*/     uint256 public _0x8cd0a4;
/*LN-10*/     uint256 public _0x7d6277 = 10;
/*LN-11*/     function transfer(address _0x771f54, uint256 _0x1045d1) external returns (bool) {
/*LN-12*/         uint256 _0x6ff151 = (_0x1045d1 * _0x7d6277) / 100;
/*LN-13*/         uint256 _0x390062 = _0x1045d1 - _0x6ff151;
/*LN-14*/         _0x7248ad[msg.sender] -= _0x1045d1;
/*LN-15*/         _0x7248ad[_0x771f54] += _0x390062;
/*LN-16*/         _0x8cd0a4 -= _0x6ff151;
/*LN-17*/         return true;
/*LN-18*/     }
/*LN-19*/     function _0x0cce35(address from, address _0x771f54, uint256 _0x1045d1) external returns (bool) {
/*LN-20*/         uint256 _0x6ff151 = (_0x1045d1 * _0x7d6277) / 100;
/*LN-21*/         uint256 _0x390062 = _0x1045d1 - _0x6ff151;
/*LN-22*/         _0x7248ad[from] -= _0x1045d1;
/*LN-23*/         _0x7248ad[_0x771f54] += _0x390062;
/*LN-24*/         _0x8cd0a4 -= _0x6ff151;
/*LN-25*/         return true;
/*LN-26*/     }
/*LN-27*/ }
/*LN-28*/ contract Vault {
/*LN-29*/     address public _0x2ff8d2;
/*LN-30*/     mapping(address => uint256) public _0x477183;
/*LN-31*/     constructor(address _0x0f4194) {
/*LN-32*/         _0x2ff8d2 = _0x0f4194;
/*LN-33*/     }
/*LN-34*/     function _0x2c833f(uint256 _0x1045d1) external {
/*LN-35*/         IERC20(_0x2ff8d2)._0x0cce35(msg.sender, address(this), _0x1045d1);
/*LN-36*/         _0x477183[msg.sender] += _0x1045d1;
/*LN-37*/     }
/*LN-38*/     function _0x347a3f(uint256 _0x1045d1) external {
/*LN-39*/         require(_0x477183[msg.sender] >= _0x1045d1, "Insufficient");
/*LN-40*/         _0x477183[msg.sender] -= _0x1045d1;
/*LN-41*/         IERC20(_0x2ff8d2).transfer(msg.sender, _0x1045d1);
/*LN-42*/     }
/*LN-43*/ }