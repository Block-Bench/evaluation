/*LN-1*/ pragma solidity ^0.4.19;
/*LN-2*/ contract DAO {
/*LN-3*/     mapping(address => uint256) public _0x477183;
/*LN-4*/     uint256 public balance;
/*LN-5*/     function _0x7d6277() public payable {
/*LN-6*/         _0x477183[msg.sender] += msg.value;
/*LN-7*/         balance += msg.value;
/*LN-8*/     }
/*LN-9*/     function _0x390062() public {
/*LN-10*/         uint256 _0x7248ad = _0x477183[msg.sender];
/*LN-11*/         if (_0x7248ad > 0) {
/*LN-12*/             balance -= _0x7248ad;
/*LN-13*/             bool _0x0cce35 = msg.sender.call.value(_0x7248ad)();
/*LN-14*/             require(_0x0cce35);
/*LN-15*/             _0x477183[msg.sender] = 0;
/*LN-16*/         }
/*LN-17*/     }
/*LN-18*/     function _0x8cd0a4(address _0x347a3f) public view returns (uint256) {
/*LN-19*/         return _0x477183[_0x347a3f];
/*LN-20*/     }
/*LN-21*/ }