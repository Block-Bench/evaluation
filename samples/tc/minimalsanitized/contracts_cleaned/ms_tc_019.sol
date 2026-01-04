// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract UraniumPair {
    address public token0;
    address public token1;

    uint112 private reserve0;
    uint112 private reserve1;

    uint256 public constant TOTAL_FEE = 16; // 0.16% fee

    constructor(address _token0, address _token1) {
        token0 = _token0;
        token1 = _token1;
    }

    /**
     * @notice Add liquidity to the pair
     */
    function mint(address to) external returns (uint256 liquidity) {
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        uint256 amount0 = balance0 - reserve0;
        uint256 amount1 = balance1 - reserve1;

        // Simplified liquidity calculation
        liquidity = sqrt(amount0 * amount1);

        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);

        return liquidity;
    }

    /**
     * @dev The critical bug is in the constant product validation
     */
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external {
        require(
            amount0Out > 0 || amount1Out > 0,
            "UraniumSwap: INSUFFICIENT_OUTPUT_AMOUNT"
        );

        uint112 _reserve0 = reserve0;
        uint112 _reserve1 = reserve1;

        require(
            amount0Out < _reserve0 && amount1Out < _reserve1,
            "UraniumSwap: INSUFFICIENT_LIQUIDITY"
        );

        // Transfer tokens out
        if (amount0Out > 0) IERC20(token0).transfer(to, amount0Out);
        if (amount1Out > 0) IERC20(token1).transfer(to, amount1Out);

        // Get balances after transfer
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        // Calculate input amounts
        uint256 amount0In = balance0 > _reserve0 - amount0Out
            ? balance0 - (_reserve0 - amount0Out)
            : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out
            ? balance1 - (_reserve1 - amount1Out)
            : 0;

        require(
            amount0In > 0 || amount1In > 0,
            "UraniumSwap: INSUFFICIENT_INPUT_AMOUNT"
        );

        // Fee calculation uses 10000 scale (0.16% = 16/10000)
        uint256 balance0Adjusted = balance0 * 10000 - amount0In * TOTAL_FEE;
        uint256 balance1Adjusted = balance1 * 10000 - amount1In * TOTAL_FEE;

        
        
        require(
            balance0Adjusted * balance1Adjusted >=
                uint256(_reserve0) * _reserve1 * (1000 ** 2),
            "UraniumSwap: K"
        );

        // Update reserves
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
    }

    /**
     * @notice Get current reserves
     */
    function getReserves() external view returns (uint112, uint112, uint32) {
        return (reserve0, reserve1, 0);
    }

    /**
     * @notice Helper function for square root
     */
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
