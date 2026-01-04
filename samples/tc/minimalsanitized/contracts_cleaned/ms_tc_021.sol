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

interface ICurvePool {
    function get_virtual_price() external view returns (uint256);

    function add_liquidity(
        uint256[3] calldata amounts,
        uint256 minMintAmount
    ) external;
}

contract SimplifiedOracle {
    ICurvePool public curvePool;

    constructor(address _curvePool) {
        curvePool = ICurvePool(_curvePool);
    }

    /**
     */
    function getPrice() external view returns (uint256) {
        return curvePool.get_virtual_price();
    }
}

contract InverseLending {
    struct Position {
        uint256 collateral;
        uint256 borrowed;
    }

    mapping(address => Position) public positions;

    address public collateralToken;
    address public borrowToken;
    address public oracle;

    uint256 public constant COLLATERAL_FACTOR = 80;

    constructor(
        address _collateralToken,
        address _borrowToken,
        address _oracle
    ) {
        collateralToken = _collateralToken;
        borrowToken = _borrowToken;
        oracle = _oracle;
    }

    /**
     * @notice Deposit collateral
     */
    function deposit(uint256 amount) external {
        IERC20(collateralToken).transferFrom(msg.sender, address(this), amount);
        positions[msg.sender].collateral += amount;
    }

    /**
     */
    function borrow(uint256 amount) external {
        uint256 collateralValue = getCollateralValue(msg.sender);
        uint256 maxBorrow = (collateralValue * COLLATERAL_FACTOR) / 100;

        require(
            positions[msg.sender].borrowed + amount <= maxBorrow,
            "Insufficient collateral"
        );

        positions[msg.sender].borrowed += amount;
        IERC20(borrowToken).transfer(msg.sender, amount);
    }

    /**
     * @notice Calculate collateral value using oracle price
     */
    function getCollateralValue(address user) public view returns (uint256) {
        uint256 collateralAmount = positions[user].collateral;
        uint256 price = SimplifiedOracle(oracle).getPrice();

        return (collateralAmount * price) / 1e18;
    }
}
