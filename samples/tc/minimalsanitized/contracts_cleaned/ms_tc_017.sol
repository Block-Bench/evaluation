// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function totalSupply() external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract WarpVault {
    struct Position {
        uint256 lpTokenAmount;
        uint256 borrowed;
    }

    mapping(address => Position) public positions;

    address public lpToken;
    address public stablecoin;
    uint256 public constant COLLATERAL_RATIO = 150; // 150% collateralization

    constructor(address _lpToken, address _stablecoin) {
        lpToken = _lpToken;
        stablecoin = _stablecoin;
    }

    /**
     * @notice Deposit LP tokens as collateral
     */
    function deposit(uint256 amount) external {
        IERC20(lpToken).transferFrom(msg.sender, address(this), amount);
        positions[msg.sender].lpTokenAmount += amount;
    }

    /**
     * @notice Borrow stablecoins against LP token collateral
     */
    function borrow(uint256 amount) external {
        uint256 collateralValue = getLPTokenValue(
            positions[msg.sender].lpTokenAmount
        );
        uint256 maxBorrow = (collateralValue * 100) / COLLATERAL_RATIO;

        require(
            positions[msg.sender].borrowed + amount <= maxBorrow,
            "Insufficient collateral"
        );

        positions[msg.sender].borrowed += amount;
        IERC20(stablecoin).transfer(msg.sender, amount);
    }

    function getLPTokenValue(uint256 lpAmount) public view returns (uint256) {
        if (lpAmount == 0) return 0;

        IUniswapV2Pair pair = IUniswapV2Pair(lpToken);

        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();

        // Calculate share of reserves owned by these LP tokens
        
        uint256 amount0 = (uint256(reserve0) * lpAmount) / totalSupply;
        uint256 amount1 = (uint256(reserve1) * lpAmount) / totalSupply;

        // For simplicity, assume token0 is stablecoin ($1) and token1 is ETH
        // In reality, would need oracle for ETH price
        uint256 value0 = amount0; // amount0 is stablecoin, worth face value

        // This simplified version just adds both reserves
        uint256 totalValue = amount0 + amount1;

        return totalValue;
    }

    /**
     * @notice Repay borrowed amount
     */
    function repay(uint256 amount) external {
        require(positions[msg.sender].borrowed >= amount, "Repay exceeds debt");

        IERC20(stablecoin).transferFrom(msg.sender, address(this), amount);
        positions[msg.sender].borrowed -= amount;
    }

    /**
     * @notice Withdraw LP tokens
     */
    function withdraw(uint256 amount) external {
        require(
            positions[msg.sender].lpTokenAmount >= amount,
            "Insufficient balance"
        );

        // Check that position remains healthy after withdrawal
        uint256 remainingLP = positions[msg.sender].lpTokenAmount - amount;
        uint256 remainingValue = getLPTokenValue(remainingLP);
        uint256 maxBorrow = (remainingValue * 100) / COLLATERAL_RATIO;

        require(
            positions[msg.sender].borrowed <= maxBorrow,
            "Withdrawal would liquidate position"
        );

        positions[msg.sender].lpTokenAmount -= amount;
        IERC20(lpToken).transfer(msg.sender, amount);
    }
}
