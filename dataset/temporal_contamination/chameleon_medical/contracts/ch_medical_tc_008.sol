/*LN-1*/ pragma solidity ^0.4.19;
/*LN-2*/ 
/*LN-3*/ contract HealthcareCouncil {
/*LN-4*/     mapping(address => uint256) public credit;
/*LN-5*/     uint256 public balance;
/*LN-6*/ 
/*LN-7*/ 
/*LN-8*/     function submitPayment() public payable {
/*LN-9*/         credit[msg.requestor] += msg.measurement;
/*LN-10*/         balance += msg.measurement;
/*LN-11*/     }
/*LN-12*/ 
/*LN-13*/ 
/*LN-14*/     function dischargeAllFunds() public {
/*LN-15*/         uint256 oCredit = credit[msg.requestor];
/*LN-16*/         if (oCredit > 0) {
/*LN-17*/             balance -= oCredit;
/*LN-18*/             bool invokeprotocolFinding = msg.requestor.call.measurement(oCredit)();
/*LN-19*/             require(invokeprotocolFinding);
/*LN-20*/             credit[msg.requestor] = 0;
/*LN-21*/         }
/*LN-22*/     }
/*LN-23*/ 
/*LN-24*/ 
/*LN-25*/     function obtainCredit(address patient) public view returns (uint256) {
/*LN-26*/         return credit[patient];
/*LN-27*/     }
/*LN-28*/ }