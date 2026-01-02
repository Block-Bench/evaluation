// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

contract ContractTest is Test {
    Target TargetContract;
    FailedOperator FailedOperatorContract;
    Operator OperatorContract;
    TargetB TargetContractB;

    constructor() {
        TargetContract = new Target();
        FailedOperatorContract = new FailedOperator();
        TargetContractB = new TargetB();
    }

    function testFailedContractCheck() public {
        console.log(
            "Before operation",
            TargetContract.completed()
        );
        console.log("operate Failed");
        FailedOperatorContract.execute(address(TargetContract));
    }

    function testContractCheck() public {
        console.log(
            "Before operation",
            TargetContract.completed()
        );
        OperatorContract = new Operator(address(TargetContract));
        console.log(
            "After operation",
            TargetContract.completed()
        );
        console.log("operate completed");
    }

    receive() external payable {}
}

contract Target {
    function isContract(address account) public view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    bool public completed = false;

    function protected() external {
        require(!isContract(msg.sender), "no contract allowed");
        completed = true;
    }
}

contract FailedOperator is Test {
    function execute(address _target) external {
        vm.expectRevert("no contract allowed");
        Target(_target).protected();
    }
}

contract Operator {
    bool public isContract;
    address public addr;

    constructor(address _target) {
        isContract = Target(_target).isContract(address(this));
        addr = address(this);
        Target(_target).protected();
    }
}

contract TargetB {
    function isContract(address account) public view returns (bool) {
        require(tx.origin == msg.sender);
        return account.code.length > 0;
    }

    bool public completed = false;

    function protected() external {
        require(!isContract(msg.sender), "no contract allowed");
        completed = true;
    }
}
