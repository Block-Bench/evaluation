/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.4.19;
/*LN-3*/ 
/*LN-4*/ contract DAO {
/*LN-5*/     mapping(address => uint256) public credit;
/*LN-6*/     uint256 public balance;
/*LN-7*/ 
/*LN-8*/     /**
/*LN-9*/      * @notice Deposit ETH into the contract
/*LN-10*/      */
/*LN-11*/     function deposit() public payable {
/*LN-12*/         credit[msg.sender] += msg.value;
/*LN-13*/         balance += msg.value;
/*LN-14*/     }
/*LN-15*/ 
/*LN-16*/     /**
/*LN-17*/      * @notice Withdraw all credited ETH
/*LN-18*/      *
/*LN-19*/      *
/*LN-20*/      *
/*LN-21*/      *
/*LN-22*/      *
/*LN-23*/      *
/*LN-24*/      *
/*LN-25*/      *
/*LN-26*/      */
/*LN-27*/     function withdrawAll() public {
/*LN-28*/         uint256 oCredit = credit[msg.sender];
/*LN-29*/         if (oCredit > 0) {
/*LN-30*/             balance -= oCredit;
/*LN-31*/             bool callResult = msg.sender.call.value(oCredit)();
/*LN-32*/             require(callResult);
/*LN-33*/             credit[msg.sender] = 0;
/*LN-34*/         }
/*LN-35*/     }
/*LN-36*/ 
/*LN-37*/     /**
/*LN-38*/      * @notice Get credited amount for an address
/*LN-39*/      */
/*LN-40*/     function getCredit(address user) public view returns (uint256) {
/*LN-41*/         return credit[user];
/*LN-42*/     }
/*LN-43*/ }
/*LN-44*/ 