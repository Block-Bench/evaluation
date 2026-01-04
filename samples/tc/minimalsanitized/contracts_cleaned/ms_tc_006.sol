// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    function getUnderlyingPrice(address cToken) external view returns (uint256);
}

interface ICToken {
    function mint(uint256 mintAmount) external;

    function borrow(uint256 borrowAmount) external;

    function redeem(uint256 redeemTokens) external;

    function underlying() external view returns (address);
}

contract CreamLending {
    // Oracle for getting asset prices
    IOracle public oracle;

    // Collateral factors (how much can be borrowed against collateral)
    mapping(address => uint256) public collateralFactors; // e.g., 75% = 0.75e18

    // User deposits (crToken balances)
    mapping(address => mapping(address => uint256)) public userDeposits;

    // User borrows
    mapping(address => mapping(address => uint256)) public userBorrows;

    // Supported markets
    mapping(address => bool) public supportedMarkets;

    event Deposit(address indexed user, address indexed cToken, uint256 amount);
    event Borrow(address indexed user, address indexed cToken, uint256 amount);

    constructor(address _oracle) {
        oracle = IOracle(_oracle);
    }

    /**
     * @notice Mint crTokens by depositing underlying assets
     * @param cToken The crToken to mint
     * @param amount Amount of underlying to deposit
     *
     */
    function mint(address cToken, uint256 amount) external {
        require(supportedMarkets[cToken], "Market not supported");

        // Transfer underlying from user (simplified)
        // address underlying = ICToken(cToken).underlying();
        // IERC20(underlying).transferFrom(msg.sender, address(this), amount);

        // Mint crTokens to user
        userDeposits[msg.sender][cToken] += amount;

        emit Deposit(msg.sender, cToken, amount);
    }

    function borrow(address cToken, uint256 amount) external {
        require(supportedMarkets[cToken], "Market not supported");

        // Calculate user's borrowing power
        uint256 borrowPower = calculateBorrowPower(msg.sender);

        // Calculate current total borrows value
        uint256 currentBorrows = calculateTotalBorrows(msg.sender);

        // Get value of new borrow
        uint256 borrowValue = (oracle.getUnderlyingPrice(cToken) * amount) /
            1e18;

        // Check if user has enough collateral
        require(
            currentBorrows + borrowValue <= borrowPower,
            "Insufficient collateral"
        );

        // Update borrow balance
        userBorrows[msg.sender][cToken] += amount;

        // Transfer tokens to borrower (simplified)
        // address underlying = ICToken(cToken).underlying();
        // IERC20(underlying).transfer(msg.sender, amount);

        emit Borrow(msg.sender, cToken, amount);
    }

    function calculateBorrowPower(address user) public view returns (uint256) {
        uint256 totalPower = 0;

        // Iterate through all supported markets (simplified)
        // In reality, would track user's entered markets
        address[] memory markets = new address[](2); // Placeholder

        for (uint256 i = 0; i < markets.length; i++) {
            address cToken = markets[i];
            uint256 balance = userDeposits[user][cToken];

            if (balance > 0) {
                // Get price from oracle
                uint256 price = oracle.getUnderlyingPrice(cToken);

                // Calculate value
                uint256 value = (balance * price) / 1e18;

                // Apply collateral factor
                uint256 power = (value * collateralFactors[cToken]) / 1e18;

                totalPower += power;
            }
        }

        return totalPower;
    }

    /**
     * @notice Calculate user's total borrow value
     * @param user The user address
     * @return Total borrow value in USD (scaled by 1e18)
     */
    function calculateTotalBorrows(address user) public view returns (uint256) {
        uint256 totalBorrows = 0;

        // Iterate through all supported markets (simplified)
        address[] memory markets = new address[](2); // Placeholder

        for (uint256 i = 0; i < markets.length; i++) {
            address cToken = markets[i];
            uint256 borrowed = userBorrows[user][cToken];

            if (borrowed > 0) {
                uint256 price = oracle.getUnderlyingPrice(cToken);
                uint256 value = (borrowed * price) / 1e18;
                totalBorrows += value;
            }
        }

        return totalBorrows;
    }

    /**
     * @notice Add a supported market
     * @param cToken The crToken to add
     * @param collateralFactor The collateral factor (e.g., 0.75e18 for 75%)
     */
    function addMarket(address cToken, uint256 collateralFactor) external {
        supportedMarkets[cToken] = true;
        collateralFactors[cToken] = collateralFactor;
    }
}
