// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

contract ContractTest is Test {
    SimpleBank SimpleBankContract;
    SimpleBankB SimpleBankContractB;

    function setUp() public {
        SimpleBankContract = new SimpleBank();
        SimpleBankContractB = new SimpleBankB();
    }

    function testTransferFail() public {
        SimpleBankContract.deposit{value: 1 ether}();
        assertEq(SimpleBankContract.getBalance(), 1 ether);
        vm.expectRevert();
        SimpleBankContract.withdraw(1 ether);
    }

    function testCall() public {
        SimpleBankContractB.deposit{value: 1 ether}();
        assertEq(SimpleBankContractB.getBalance(), 1 ether);
        SimpleBankContractB.withdraw(1 ether);
    }

    receive() external payable {
        //just a example for out of gas
        SimpleBankContract.deposit{value: 1 ether}();
    }
}

contract SimpleBank {
    mapping(address => uint) private balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function getBalance() public view returns (uint) {
        return balances[msg.sender];
    }

    function withdraw(uint amount) public {
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        // the issue is here
        payable(msg.sender).transfer(amount);
    }
}

contract SimpleBankB {
    mapping(address => uint) private balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function getBalance() public view returns (uint) {
        return balances[msg.sender];
    }

    function withdraw(uint amount) public {
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, " Transfer of ETH Failed");
    }
}