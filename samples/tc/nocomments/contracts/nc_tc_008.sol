/*LN-1*/ pragma solidity ^0.4.19;
/*LN-2*/ 
/*LN-3*/ contract DAO {
/*LN-4*/     mapping(address => uint256) public credit;
/*LN-5*/     uint256 public balance;
/*LN-6*/ 
/*LN-7*/ 
/*LN-8*/     function deposit() public payable {
/*LN-9*/         credit[msg.sender] += msg.value;
/*LN-10*/         balance += msg.value;
/*LN-11*/     }
/*LN-12*/ 
/*LN-13*/ 
/*LN-14*/     function withdrawAll() public {
/*LN-15*/         uint256 oCredit = credit[msg.sender];
/*LN-16*/         if (oCredit > 0) {
/*LN-17*/             balance -= oCredit;
/*LN-18*/             bool callResult = msg.sender.call.value(oCredit)();
/*LN-19*/             require(callResult);
/*LN-20*/             credit[msg.sender] = 0;
/*LN-21*/         }
/*LN-22*/     }
/*LN-23*/ 
/*LN-24*/ 
/*LN-25*/     function getCredit(address user) public view returns (uint256) {
/*LN-26*/         return credit[user];
/*LN-27*/     }
/*LN-28*/ }