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
}

interface IPancakeRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract HunnyMinter {
    IERC20 public lpToken; // LP token (e.g., CAKE-BNB)
    IERC20 public rewardToken; // HUNNY reward token

    mapping(address => uint256) public depositedLP;
    mapping(address => uint256) public earnedRewards;

    uint256 public constant REWARD_RATE = 100; // 100 reward tokens per LP token

    constructor(address _lpToken, address _rewardToken) {
        lpToken = IERC20(_lpToken);
        rewardToken = IERC20(_rewardToken);
    }

    /**
     * @notice Deposit LP tokens to earn rewards
     */
    function deposit(uint256 amount) external {
        lpToken.transferFrom(msg.sender, address(this), amount);
        depositedLP[msg.sender] += amount;
    }

    /**
     * @notice Calculate and mint rewards for user
     * @param flip The LP token address
     * @param _withdrawalFee Withdrawal fee amount
     * @param _performanceFee Performance fee amount
     * @param to Recipient address
     *
     
     
     *
     * 
     
     * 
     * 
     * 
     * 
     * 
     */
    function mintFor(
        address flip,
        uint256 _withdrawalFee,
        uint256 _performanceFee,
        address to,
        uint256 /* amount - unused */
    ) external {
        require(flip == address(lpToken), "Invalid token");

        // Transfer fees from caller
        uint256 feeSum = _performanceFee + _withdrawalFee;
        lpToken.transferFrom(msg.sender, address(this), feeSum);

       
        uint256 hunnyRewardAmount = tokenToReward(
            lpToken.balanceOf(address(this))
        );

       
        earnedRewards[to] += hunnyRewardAmount;
    }

    /**
     * @notice Convert LP token amount to reward amount
     * @dev This is called with the inflated balance
     */
    function tokenToReward(uint256 lpAmount) internal pure returns (uint256) {
        return lpAmount * REWARD_RATE;
    }

    /**
     * @notice Claim earned rewards
     */
    function getReward() external {
        uint256 reward = earnedRewards[msg.sender];
        require(reward > 0, "No rewards");

        earnedRewards[msg.sender] = 0;
        rewardToken.transfer(msg.sender, reward);
    }

    /**
     * @notice Withdraw deposited LP tokens
     */
    function withdraw(uint256 amount) external {
        require(depositedLP[msg.sender] >= amount, "Insufficient balance");
        depositedLP[msg.sender] -= amount;
        lpToken.transfer(msg.sender, amount);
    }
}
