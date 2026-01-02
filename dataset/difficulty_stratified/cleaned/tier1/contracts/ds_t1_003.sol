// SPDX-License-Identifier: MIT
pragma solidity ^0.4.15;

contract Ledger {
    uint private sellerBalance=0;

    function add(uint value) returns (bool){
        sellerBalance += value;
    }

}