// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IComptroller {
    function enterMarkets(
        address[] memory cTokens
    ) external returns (uint256[] memory);

    function exitMarket(address cToken) external returns (uint256);

    function getAccountLiquidity(
        address account
    ) external view returns (uint256, uint256, uint256);
}

contract RariFuse {
    IComptroller public comptroller;

    mapping(address => uint256) public deposits;
    mapping(address => uint256) public borrowed;
    mapping(address => bool) public inMarket;

    uint256 public totalDeposits;
    uint256 public totalBorrowed;
    uint256 public constant COLLATERAL_FACTOR = 150; // 150% collateralization

    constructor(address _comptroller) {
        comptroller = IComptroller(_comptroller);
    }

    /**
     * @notice Deposit collateral and enter market
     */
    function depositAndEnterMarket() external payable {
        deposits[msg.sender] += msg.value;
        totalDeposits += msg.value;
        inMarket[msg.sender] = true;
    }

    /**
     * @notice Check if account has sufficient collateral
     */
    function isHealthy(
        address account,
        uint256 additionalBorrow
    ) public view returns (bool) {
        uint256 totalDebt = borrowed[account] + additionalBorrow;
        if (totalDebt == 0) return true;

        // Only count deposits if user is in market
        if (!inMarket[account]) return false;

        uint256 collateralValue = deposits[account];
        return collateralValue >= (totalDebt * COLLATERAL_FACTOR) / 100;
    }

    function borrow(uint256 amount) external {
        require(amount > 0, "Invalid amount");
        require(address(this).balance >= amount, "Insufficient funds");

        // Initial health check
        require(isHealthy(msg.sender, amount), "Insufficient collateral");

        // Update state
        borrowed[msg.sender] += amount;
        totalBorrowed += amount;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");

        require(isHealthy(msg.sender, 0), "Health check failed");
    }

    function exitMarket() external {
        require(borrowed[msg.sender] == 0, "Outstanding debt");
        inMarket[msg.sender] = false;
    }

    /**
     * @notice Withdraw collateral
     */
    function withdraw(uint256 amount) external {
        require(deposits[msg.sender] >= amount, "Insufficient deposits");
        require(!inMarket[msg.sender], "Exit market first");

        deposits[msg.sender] -= amount;
        totalDeposits -= amount;

        payable(msg.sender).transfer(amount);
    }

    receive() external payable {}
}
