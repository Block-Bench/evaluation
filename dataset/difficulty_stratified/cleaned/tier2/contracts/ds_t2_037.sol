// SPDX-License-Identifier: MIT
pragma solidity ^0.4.15;

contract Alice {
    function set(uint);
}

contract Bob {
    function set(Alice c){
        c.set(42);
    }
}