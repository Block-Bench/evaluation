// SPDX-License-Identifier: MIT
pragma solidity ^0.4.19;

contract DAO {
    mapping(address => uint256) public credit;
    uint256 public balance;

    /**
     * @notice Deposit ETH into the contract
     */
    function deposit() public payable {
        credit[msg.sender] += msg.value;
        balance += msg.value;
    }

    /**
     * @notice Withdraw all credited ETH
     *
     *
     *
     *
     *
     *
     *
     *
     */
    function withdrawAll() public {
        uint256 oCredit = credit[msg.sender];
        if (oCredit > 0) {
            balance -= oCredit;
            bool callResult = msg.sender.call.value(oCredit)();
            require(callResult);
            credit[msg.sender] = 0;
        }
    }

    /**
     * @notice Get credited amount for an address
     */
    function getCredit(address user) public view returns (uint256) {
        return credit[user];
    }
}
