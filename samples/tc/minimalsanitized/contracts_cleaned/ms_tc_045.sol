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

interface IMarket {
    function getAccountSnapshot(
        address account
    )
        external
        view
        returns (uint256 collateral, uint256 borrows, uint256 exchangeRate);
}

contract DebtPreviewer {
    function previewDebt(
        address market,
        address account
    )
        external
        view
        returns (
            uint256 collateralValue,
            uint256 debtValue,
            uint256 healthFactor
        )
    {

        // Query market for account snapshot
        (uint256 collateral, uint256 borrows, uint256 exchangeRate) = IMarket(
            market
        ).getAccountSnapshot(account);

        collateralValue = (collateral * exchangeRate) / 1e18;
        debtValue = borrows;

        if (debtValue == 0) {
            healthFactor = type(uint256).max;
        } else {
            healthFactor = (collateralValue * 1e18) / debtValue;
        }

        return (collateralValue, debtValue, healthFactor);
    }

    /**
     */
    function previewMultipleMarkets(
        address[] calldata markets,
        address account
    )
        external
        view
        returns (
            uint256 totalCollateral,
            uint256 totalDebt,
            uint256 overallHealth
        )
    {
        for (uint256 i = 0; i < markets.length; i++) {
            (uint256 collateral, uint256 debt, ) = this.previewDebt(
                markets[i],
                account
            );

            totalCollateral += collateral;
            totalDebt += debt;
        }

        if (totalDebt == 0) {
            overallHealth = type(uint256).max;
        } else {
            overallHealth = (totalCollateral * 1e18) / totalDebt;
        }

        return (totalCollateral, totalDebt, overallHealth);
    }
}

/**
 * Exactly Protocol Lending Market
 */
contract ExactlyMarket {
    IERC20 public asset;
    DebtPreviewer public previewer;

    mapping(address => uint256) public deposits;
    mapping(address => uint256) public borrows;

    uint256 public constant COLLATERAL_FACTOR = 80; // 80%

    constructor(address _asset, address _previewer) {
        asset = IERC20(_asset);
        previewer = DebtPreviewer(_previewer);
    }

    function deposit(uint256 amount) external {
        asset.transferFrom(msg.sender, address(this), amount);
        deposits[msg.sender] += amount;
    }

    /**
     * @dev Internal function to borrow funds
     */
    function borrow(uint256 amount, address[] calldata markets) external {
        (uint256 totalCollateral, uint256 totalDebt, ) = previewer
            .previewMultipleMarkets(markets, msg.sender);

        // Calculate new debt after this borrow
        uint256 newDebt = totalDebt + amount;

        uint256 maxBorrow = (totalCollateral * COLLATERAL_FACTOR) / 100;
        require(newDebt <= maxBorrow, "Insufficient collateral");

        borrows[msg.sender] += amount;
        asset.transfer(msg.sender, amount);
    }

    function getAccountSnapshot(
        address account
    )
        external
        view
        returns (uint256 collateral, uint256 borrowed, uint256 exchangeRate)
    {
        return (deposits[account], borrows[account], 1e18);
    }
}
