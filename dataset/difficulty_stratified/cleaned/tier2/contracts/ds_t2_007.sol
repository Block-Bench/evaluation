// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract Dirtybytes {
    event ev(uint[], uint);
    bytes s;

    constructor() {
        // The following event emission involves writing to temporary memory at the current location
        // of the free memory pointer. 
        emit ev(new uint[](2), 0);
        bytes memory m = new bytes(63);
        s = m;
    }

    function h() external returns (bytes memory) {
        s.push();
        return s;
    }
}