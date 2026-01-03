// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract Dirtybytes {
    event ev(uint[], uint);
    bytes s;

    constructor() {
        // The following event emission involves writing to temporary memory at the current location
        // of the free memory pointer. Several other operations (e.g. certain keccak256 calls) will
        // use temporary memory in a similar manner.
        // In this particular case, the length of the passed array will be written to temporary memory
        // exactly such that the byte after the 63 bytes allocated below will be 0x02. This dirty byte
        // will then be written to storage during the assignment and become visible with the push in ``h``.
        emit ev(new uint[](2), 0);
        bytes memory m = new bytes(63);
        s = m;
    }

    function h() external returns (bytes memory) {
        s.push();
        return s;
    }
}