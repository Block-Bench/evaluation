// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
}

contract IndexPool {
    struct Token {
        address addr;
        uint256 balance;
        uint256 weight; // stored as percentage (100 = 100%)
    }

    mapping(address => Token) public tokens;
    address[] public tokenList;
    uint256 public totalWeight;

    constructor() {
        totalWeight = 100;
    }

    function addToken(address token, uint256 initialWeight) external {
        tokens[token] = Token({addr: token, balance: 0, weight: initialWeight});
        tokenList.push(token);
    }

    /**
     * @notice Swap tokens in the pool
     */
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external returns (uint256 amountOut) {
        require(tokens[tokenIn].addr != address(0), "Invalid token");
        require(tokens[tokenOut].addr != address(0), "Invalid token");

        // Transfer tokens in
        IERC20(tokenIn).transfer(address(this), amountIn);
        tokens[tokenIn].balance += amountIn;

        // Calculate amount out based on current weights
        amountOut = calculateSwapAmount(tokenIn, tokenOut, amountIn);

        // Transfer tokens out
        require(
            tokens[tokenOut].balance >= amountOut,
            "Insufficient liquidity"
        );
        tokens[tokenOut].balance -= amountOut;
        IERC20(tokenOut).transfer(msg.sender, amountOut);

        _updateWeights();

        return amountOut;
    }

    /**
     * @notice Calculate swap amount based on token weights
     */
    function calculateSwapAmount(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) public view returns (uint256) {
        uint256 weightIn = tokens[tokenIn].weight;
        uint256 weightOut = tokens[tokenOut].weight;
        uint256 balanceOut = tokens[tokenOut].balance;

        // Simplified constant product with weights: x * y = k * (w1/w2)
        // amountOut = balanceOut * amountIn * weightOut / (balanceIn * weightIn + amountIn * weightOut)

        uint256 numerator = balanceOut * amountIn * weightOut;
        uint256 denominator = tokens[tokenIn].balance *
            weightIn +
            amountIn *
            weightOut;

        return numerator / denominator;
    }

    function _updateWeights() internal {
        uint256 totalValue = 0;

        // Calculate total value in pool
        for (uint256 i = 0; i < tokenList.length; i++) {
            address token = tokenList[i];
            // In real implementation, this would use oracle prices
            // For this simplified version, we use balance as proxy for value
            totalValue += tokens[token].balance;
        }

        // Update each token's weight proportional to its balance
        for (uint256 i = 0; i < tokenList.length; i++) {
            address token = tokenList[i];

           
            tokens[token].weight = (tokens[token].balance * 100) / totalValue;
        }
    }

    /**
     * @notice Get current token weight
     */
    function getWeight(address token) external view returns (uint256) {
        return tokens[token].weight;
    }

    /**
     * @notice Add liquidity to pool
     */
    function addLiquidity(address token, uint256 amount) external {
        require(tokens[token].addr != address(0), "Invalid token");
        IERC20(token).transfer(address(this), amount);
        tokens[token].balance += amount;
        _updateWeights();
    }
}
