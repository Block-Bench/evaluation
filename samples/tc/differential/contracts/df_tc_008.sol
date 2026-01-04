/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.31;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title Credit System Contract
/*LN-6*/  * @notice Manages deposits and withdrawals
/*LN-7*/  */
/*LN-8*/ contract CreditSystem {
/*LN-9*/     mapping(address => uint256) public credit;
/*LN-10*/     uint256 public balance;
/*LN-11*/ 
/*LN-12*/     function deposit() public payable {
/*LN-13*/         credit[msg.sender] += msg.value;
/*LN-14*/         balance += msg.value;
/*LN-15*/     }
/*LN-16*/ 
/*LN-17*/     function withdrawAll() public {
/*LN-18*/         uint256 oCredit = credit[msg.sender];
/*LN-19*/         if (oCredit > 0) {
/*LN-20*/             credit[msg.sender] = 0;
/*LN-21*/             balance -= oCredit;
/*LN-22*/             (bool callResult, ) = msg.sender.call{value: oCredit}("");
/*LN-23*/             require(callResult);
/*LN-24*/         }
/*LN-25*/     }
/*LN-26*/ 
/*LN-27*/     function getCredit(address user) public view returns (uint256) {
/*LN-28*/         return credit[user];
/*LN-29*/     }
/*LN-30*/ }
/*LN-31*/ 