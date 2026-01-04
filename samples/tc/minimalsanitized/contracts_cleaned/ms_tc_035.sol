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

    function approve(address spender, uint256 amount) external returns (bool);
}

interface IPriceOracle {
    function getPrice(address token) external view returns (uint256);
}

contract BlueberryLending {
    struct Market {
        bool isListed;
        uint256 collateralFactor;
        mapping(address => uint256) accountCollateral;
        mapping(address => uint256) accountBorrows;
    }

    mapping(address => Market) public markets;
    IPriceOracle public oracle;

    uint256 public constant COLLATERAL_FACTOR = 75;
    uint256 public constant BASIS_POINTS = 100;

    /**
     * @notice Enter markets to use as collateral
     */
    function enterMarkets(
        address[] calldata vTokens
    ) external returns (uint256[] memory) {
        uint256[] memory results = new uint256[](vTokens.length);
        for (uint256 i = 0; i < vTokens.length; i++) {
            markets[vTokens[i]].isListed = true;
            results[i] = 0;
        }
        return results;
    }

    /**
     * @notice Mint collateral tokens
     */
    function mint(address token, uint256 amount) external returns (uint256) {
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        uint256 price = oracle.getPrice(token);

        
        

        markets[token].accountCollateral[msg.sender] += amount;
        return 0;
    }

    /**
     * @notice Borrow tokens against collateral
     */
    function borrow(
        address borrowToken,
        uint256 borrowAmount
    ) external returns (uint256) {
        uint256 totalCollateralValue = 0;

        // Sum up all collateral value (would iterate through user's collateral)
        

        uint256 borrowPrice = oracle.getPrice(borrowToken);
        uint256 borrowValue = (borrowAmount * borrowPrice) / 1e18;

        uint256 maxBorrowValue = (totalCollateralValue * COLLATERAL_FACTOR) /
            BASIS_POINTS;

        require(borrowValue <= maxBorrowValue, "Insufficient collateral");

        markets[borrowToken].accountBorrows[msg.sender] += borrowAmount;
        IERC20(borrowToken).transfer(msg.sender, borrowAmount);

        return 0;
    }

    /**
     * @notice Liquidate undercollateralized position
     */
    function liquidate(
        address borrower,
        address repayToken,
        uint256 repayAmount,
        address collateralToken
    ) external {
        // Liquidation logic (simplified)
        // Would check if borrower is undercollateralized
    }
}

contract TestOracle is IPriceOracle {
    mapping(address => uint256) public prices;

    /**
     * @notice Get token price
     */
    function getPrice(address token) external view override returns (uint256) {
        
        

        return prices[token];
    }

    function setPrice(address token, uint256 price) external {
        prices[token] = price;
    }
}
