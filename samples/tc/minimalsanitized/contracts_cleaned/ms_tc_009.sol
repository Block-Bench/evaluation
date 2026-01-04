// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC777 {
    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

interface IERC1820Registry {
    function setInterfaceImplementer(
        address account,
        bytes32 interfaceHash,
        address implementer
    ) external;
}

contract LendingPool {
    mapping(address => mapping(address => uint256)) public supplied;
    mapping(address => uint256) public totalSupplied;

    /**
     * @notice Supply tokens to the lending pool
     * @param asset The ERC-777 token to supply
     * @param amount Amount to supply
     */
    function supply(address asset, uint256 amount) external returns (uint256) {
        IERC777 token = IERC777(asset);

        // Transfer tokens from user
        require(token.transfer(address(this), amount), "Transfer failed");

        // Update balances
        supplied[msg.sender][asset] += amount;
        totalSupplied[asset] += amount;

        return amount;
    }

    /**
     * @notice Withdraw supplied tokens
     * @param asset The token to withdraw
     * @param requestedAmount Amount to withdraw (type(uint256).max for all)
     *
     *
     *
     *
     *
     *
     *
     *
     */
    function withdraw(
        address asset,
        uint256 requestedAmount
    ) external returns (uint256) {
        uint256 userBalance = supplied[msg.sender][asset];
        require(userBalance > 0, "No balance");

        // Determine actual withdrawal amount
        uint256 withdrawAmount = requestedAmount;
        if (requestedAmount == type(uint256).max) {
            withdrawAmount = userBalance;
        }
        require(withdrawAmount <= userBalance, "Insufficient balance");

        // For ERC-777, this triggers tokensToSend() callback
        IERC777(asset).transfer(msg.sender, withdrawAmount);

        // Update state
        supplied[msg.sender][asset] -= withdrawAmount;
        totalSupplied[asset] -= withdrawAmount;

        return withdrawAmount;
    }

    /**
     * @notice Get user's supplied balance
     */
    function getSupplied(
        address user,
        address asset
    ) external view returns (uint256) {
        return supplied[user][asset];
    }
}
