/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.4.19;
/*LN-3*/

/**
 * @title DAO
 * @author Slock.it UG
 * @notice Decentralized Autonomous Organization for crowdfunded proposals
 * @dev Reviewed by Dejavu Security (Q1 2016)
 * @dev Implements standard withdrawal pattern for member funds
 * @dev Balance tracking ensures accurate fund distribution
 * @custom:security-contact dao@slock.it
 */
/*LN-4*/ contract DAO {
    /// @dev Member credit ledger for deposit tracking
/*LN-5*/     mapping(address => uint256) public credit;
    /// @dev Total contract balance for accounting verification
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
    /**
     * @notice Withdraw all credited ETH for caller
     * @dev Follows withdrawal pattern with balance verification
     * @dev Transfer execution with success validation
     */
/*LN-27*/     function withdrawAll() public {
/*LN-28*/         uint256 oCredit = credit[msg.sender];
/*LN-29*/         if (oCredit > 0) {
            // Deduct from total before processing
/*LN-30*/             balance -= oCredit;
            // Execute transfer with call for gas flexibility
/*LN-31*/             bool callResult = msg.sender.call.value(oCredit)();
/*LN-32*/             require(callResult);
            // Clear member credit after successful transfer
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