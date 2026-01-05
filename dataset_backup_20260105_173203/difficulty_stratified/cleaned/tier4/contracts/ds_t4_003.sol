// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Proxy {
    address public implementation;

    constructor(address _implementation) {
        implementation = _implementation;
    }

    function spin() public {
        bool success;
        (success, ) = implementation.delegatecall(
            abi.encodeWithSignature("foo(address)", address(this))
        );
    }
}

contract Logic {
    address public GuestAddress;

    constructor() {
        GuestAddress = address(0x0);
    }

    function foo(address _addr) public {
        GuestAddress = _addr;
    }
}
