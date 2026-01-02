// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

contract ContractTest is Test {
    Array ArrayContract;

    function testDataLocation() public {
        address alice = vm.addr(1);
        address bob = vm.addr(2);
        vm.deal(address(alice), 1 ether);
        vm.deal(address(bob), 1 ether);
        ArrayContract = new Array();
        ArrayContract.updaterewardDebt(100);
        (uint amount, uint rewardDebt) = ArrayContract.userInfo(address(this));
        console.log("rewardDebt after first update", rewardDebt);

        console.log("Calling second update method");
        ArrayContract.updaterewardDebtB(100);
        (uint newamount, uint newrewardDebt) = ArrayContract.userInfo(
            address(this)
        );
        console.log("rewardDebt after second update", newrewardDebt);
    }

    receive() external payable {}
}

contract Array is Test {
    mapping(address => UserInfo) public userInfo;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    function updaterewardDebt(uint amount) public {
        UserInfo memory user = userInfo[msg.sender];
        user.rewardDebt = amount;
    }

    function updaterewardDebtB(uint amount) public {
        UserInfo storage user = userInfo[msg.sender];
        user.rewardDebt = amount;
    }
}
