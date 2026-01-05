// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


contract Array {
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
