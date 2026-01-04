// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract SimplePool {
    uint public totalDebt;
    uint public lastAccrueInterestTime;
    uint public loanTokenBalance;

    constructor() {
        totalDebt = 10000e6; //debt token is USDC and has 6 digit decimals.
        lastAccrueInterestTime = block.timestamp - 1;
        loanTokenBalance = 500e18;
    }

    function getCurrentReward() public view returns (uint _reward) {
        // Get the time passed since the last interest accrual
        uint _timeDelta = block.timestamp - lastAccrueInterestTime;

        // If the time passed is 0, return 0 reward
        if (_timeDelta == 0) return 0;

        // Calculate the supplied value
        // uint _supplied = totalDebt + loanTokenBalance;
        //console.log(_supplied);
        // Calculate the reward
        _reward = (totalDebt * _timeDelta) / (365 days * 1e18);

        // 31536000 is the number of seconds in a year
        // 365 days * 1e18 = 31_536_000_000_000_000_000_000_000
        //_totalDebt * _timeDelta / 31_536_000_000_000_000_000_000_000

        _reward;
    }
}
