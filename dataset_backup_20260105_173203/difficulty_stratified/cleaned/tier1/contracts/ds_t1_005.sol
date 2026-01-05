// SPDX-License-Identifier: MIT
pragma solidity ^0.4.15;

interface IAlice {
    function set(uint new_val) external;
}

contract Alice {
    int public val;

    function set(int new_val){
        val = new_val;
    }

    function(){
        val = 1;
    }
}

contract AliceCaller {
    function callAlice(address alice, uint value) public {
        IAlice(alice).set(value);
    }
}
