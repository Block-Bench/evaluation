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

contract ShezmuCollateralToken is IERC20 {
    string public name = "Shezmu Collateral Token";
    string public symbol = "SCT";
    uint8 public decimals = 18;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    uint256 public totalSupply;

    function mint(address to, uint256 amount) external {
        
        

        // Can mint type(uint128).max worth of tokens

        balanceOf[to] += amount;
        totalSupply += amount;
    }

    function transfer(
        address to,
        uint256 amount
    ) external override returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(
            allowance[from][msg.sender] >= amount,
            "Insufficient allowance"
        );
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        return true;
    }

    function approve(
        address spender,
        uint256 amount
    ) external override returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }
}

contract ShezmuVault {
    IERC20 public collateralToken;
    IERC20 public shezUSD;

    mapping(address => uint256) public collateralBalance;
    mapping(address => uint256) public debtBalance;

    uint256 public constant COLLATERAL_RATIO = 150;
    uint256 public constant BASIS_POINTS = 100;

    constructor(address _collateralToken, address _shezUSD) {
        collateralToken = IERC20(_collateralToken);
        shezUSD = IERC20(_shezUSD);
    }

    /**
     * @notice Add collateral to vault
     */
    function addCollateral(uint256 amount) external {
        collateralToken.transferFrom(msg.sender, address(this), amount);
        collateralBalance[msg.sender] += amount;
    }

    /**
     * @notice Borrow ShezUSD against collateral
     */
    function borrow(uint256 amount) external {
        

        uint256 maxBorrow = (collateralBalance[msg.sender] * BASIS_POINTS) /
            COLLATERAL_RATIO;

        require(
            debtBalance[msg.sender] + amount <= maxBorrow,
            "Insufficient collateral"
        );

        debtBalance[msg.sender] += amount;

        shezUSD.transfer(msg.sender, amount);
    }

    function repay(uint256 amount) external {
        require(debtBalance[msg.sender] >= amount, "Excessive repayment");
        shezUSD.transferFrom(msg.sender, address(this), amount);
        debtBalance[msg.sender] -= amount;
    }

    function withdrawCollateral(uint256 amount) external {
        require(
            collateralBalance[msg.sender] >= amount,
            "Insufficient collateral"
        );
        uint256 remainingCollateral = collateralBalance[msg.sender] - amount;
        uint256 maxDebt = (remainingCollateral * BASIS_POINTS) /
            COLLATERAL_RATIO;
        require(
            debtBalance[msg.sender] <= maxDebt,
            "Would be undercollateralized"
        );

        collateralBalance[msg.sender] -= amount;
        collateralToken.transfer(msg.sender, amount);
    }
}
