// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CurvePool {
    // Token balances in the pool
    mapping(uint256 => uint256) public balances; // 0 = ETH, 1 = pETH

    // LP token
    mapping(address => uint256) public lpBalances;
    uint256 public totalLPSupply;

    uint256 private _status;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    event LiquidityAdded(
        address indexed provider,
        uint256[2] amounts,
        uint256 lpMinted
    );
    event LiquidityRemoved(
        address indexed provider,
        uint256 lpBurned,
        uint256[2] amounts
    );

    constructor() {
        _status = _NOT_ENTERED;
    }

    function add_liquidity(
        uint256[2] memory amounts,
        uint256 min_mint_amount
    ) external payable returns (uint256) {
        

        require(amounts[0] == msg.value, "ETH amount mismatch");

        // Calculate LP tokens to mint
        uint256 lpToMint;
        if (totalLPSupply == 0) {
            lpToMint = amounts[0] + amounts[1];
        } else {
            // Simplified: real formula is more complex
            uint256 totalValue = balances[0] + balances[1];
            lpToMint = ((amounts[0] + amounts[1]) * totalLPSupply) / totalValue;
        }

        require(lpToMint >= min_mint_amount, "Slippage");

        
        
        balances[0] += amounts[0];
        balances[1] += amounts[1];

        // Mint LP tokens
        lpBalances[msg.sender] += lpToMint;
        totalLPSupply += lpToMint;

        
        
        if (amounts[0] > 0) {
            // Simulate pool's internal operations that involve ETH transfer
            // In reality, Curve pools update internal state during this
            _handleETHTransfer(amounts[0]);
        }

        emit LiquidityAdded(msg.sender, amounts, lpToMint);
        return lpToMint;
    }

    /**
     * @notice Remove liquidity from the pool
     * @param lpAmount Amount of LP tokens to burn
     * @param min_amounts Minimum amounts to receive [ETH, pETH]
     */
    function remove_liquidity(
        uint256 lpAmount,
        uint256[2] memory min_amounts
    ) external {
        require(lpBalances[msg.sender] >= lpAmount, "Insufficient LP");

        // Calculate amounts to return
        uint256 amount0 = (lpAmount * balances[0]) / totalLPSupply;
        uint256 amount1 = (lpAmount * balances[1]) / totalLPSupply;

        require(
            amount0 >= min_amounts[0] && amount1 >= min_amounts[1],
            "Slippage"
        );

        // Burn LP tokens
        lpBalances[msg.sender] -= lpAmount;
        totalLPSupply -= lpAmount;

        // Update balances
        balances[0] -= amount0;
        balances[1] -= amount1;

        // Transfer tokens
        if (amount0 > 0) {
            payable(msg.sender).transfer(amount0);
        }

        uint256[2] memory amounts = [amount0, amount1];
        emit LiquidityRemoved(msg.sender, lpAmount, amounts);
    }

    function _handleETHTransfer(uint256 amount) internal {
       
     

        // Simulate operations that trigger external call
        
        (bool success, ) = msg.sender.call{value: 0}("");
        require(success, "Transfer failed");
    }

    /**
     * @notice Exchange tokens (simplified)
     * @param i Index of input token
     * @param j Index of output token
     * @param dx Input amount
     * @param min_dy Minimum output amount
     */
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external payable returns (uint256) {
        uint256 ui = uint256(int256(i));
        uint256 uj = uint256(int256(j));

        require(ui < 2 && uj < 2 && ui != uj, "Invalid indices");

        // Simplified exchange logic
        uint256 dy = (dx * balances[uj]) / (balances[ui] + dx);
        require(dy >= min_dy, "Slippage");

        if (ui == 0) {
            require(msg.value == dx, "ETH mismatch");
            balances[0] += dx;
        }

        balances[ui] += dx;
        balances[uj] -= dy;

        if (uj == 0) {
            payable(msg.sender).transfer(dy);
        }

        return dy;
    }

    receive() external payable {
    }
}
