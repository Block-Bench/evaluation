// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

interface IPendleMarket {
    function getRewardTokens() external view returns (address[] memory);

    function rewardIndexesCurrent() external returns (uint256[] memory);

    function claimRewards(address user) external returns (uint256[] memory);
}

contract PenpieStaking {
    mapping(address => mapping(address => uint256)) public userBalances;
    mapping(address => uint256) public totalStaked;

    /**
     * @notice Deposit tokens into Penpie staking
     */
    function deposit(address market, uint256 amount) external {
        IERC20(market).transferFrom(msg.sender, address(this), amount);
        userBalances[market][msg.sender] += amount;
        totalStaked[market] += amount;
    }

    function claimRewards(address market, address user) external {
        

        

        // Get pending rewards
        uint256[] memory rewards = IPendleMarket(market).claimRewards(user);

        

        // Update user's reward balance
        for (uint256 i = 0; i < rewards.length; i++) {
            // Process rewards
        }
    }

    /**
     * @notice Withdraw staked tokens
     */
    function withdraw(address market, uint256 amount) external {
        require(
            userBalances[market][msg.sender] >= amount,
            "Insufficient balance"
        );

        userBalances[market][msg.sender] -= amount;
        totalStaked[market] -= amount;

        IERC20(market).transfer(msg.sender, amount);
    }
}

contract PendleMarketRegister {
    mapping(address => bool) public registeredMarkets;

    function registerMarket(address market) external {

       
        registeredMarkets[market] = true;
    }
}
