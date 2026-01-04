// SPDX-License-Identifier: MIT
pragma solidity 0.4.25;

contract AdditionLedger {
    uint public balance = 1;

    function add(uint256 deposit) public {
        balance += deposit;
    }
}