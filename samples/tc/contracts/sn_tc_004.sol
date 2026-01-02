// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Yield Aggregator Vault
 * @notice Vault contract that deploys funds to external yield strategies
 * @dev Users deposit tokens and receive vault shares representing their position
 */

interface ICurvePool {
    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);
}

contract YieldVault {
    address public underlyingToken;
    ICurvePool public curvePool;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    // Assets deployed to external protocols
    uint256 public investedBalance;

    event Deposit(address indexed user, uint256 amount, uint256 shares);
    event Withdrawal(address indexed user, uint256 shares, uint256 amount);

    constructor(address _token, address _curvePool) {
        underlyingToken = _token;
        curvePool = ICurvePool(_curvePool);
    }

    /**
     * @notice Deposit tokens and receive vault shares
     * @param amount Amount of underlying tokens to deposit
     * @return shares Amount of vault shares minted
     */
    function deposit(uint256 amount) external returns (uint256 shares) {
        require(amount > 0, "Zero amount");

        // Calculate shares based on current price
        if (totalSupply == 0) {
            shares = amount;
        } else {
            uint256 totalAssets = getTotalAssets();
            shares = (amount * totalSupply) / totalAssets;
        }

        balanceOf[msg.sender] += shares;
        totalSupply += shares;

        // Deploy funds to strategy
        _investInCurve(amount);

        emit Deposit(msg.sender, amount, shares);
        return shares;
    }

    /**
     * @notice Withdraw underlying tokens by burning shares
     * @param shares Amount of vault shares to burn
     * @return amount Amount of underlying tokens received
     */
    function withdraw(uint256 shares) external returns (uint256 amount) {
        require(shares > 0, "Zero shares");
        require(balanceOf[msg.sender] >= shares, "Insufficient balance");

        // Calculate amount based on current price
        uint256 totalAssets = getTotalAssets();
        amount = (shares * totalAssets) / totalSupply;

        balanceOf[msg.sender] -= shares;
        totalSupply -= shares;

        // Withdraw from strategy
        _withdrawFromCurve(amount);

        emit Withdrawal(msg.sender, shares, amount);
        return amount;
    }

    /**
     * @notice Get total assets under management
     * @return Total value of vault assets
     */
    function getTotalAssets() public view returns (uint256) {
        uint256 vaultBalance = 0;
        uint256 curveBalance = investedBalance;

        return vaultBalance + curveBalance;
    }

    /**
     * @notice Get price per share
     * @return Price per vault share
     */
    function getPricePerFullShare() public view returns (uint256) {
        if (totalSupply == 0) return 1e18;
        return (getTotalAssets() * 1e18) / totalSupply;
    }

    /**
     * @notice Internal function to invest in Curve
     */
    function _investInCurve(uint256 amount) internal {
        investedBalance += amount;
    }

    /**
     * @notice Internal function to withdraw from Curve
     */
    function _withdrawFromCurve(uint256 amount) internal {
        require(investedBalance >= amount, "Insufficient invested");
        investedBalance -= amount;
    }
}
