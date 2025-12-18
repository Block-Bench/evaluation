pragma solidity ^0.8.0;


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

contract VulnerableHarvestVault {
    address public underlyingToken;
    ICurvePool public curvePool;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    uint256 public investedBalance;

    event Deposit(address indexed user, uint256 amount, uint256 shares);
    event Withdrawal(address indexed user, uint256 shares, uint256 amount);

    constructor(address _token, address _curvePool) {
        underlyingToken = _token;
        curvePool = ICurvePool(_curvePool);
    }

    function deposit(uint256 amount) external returns (uint256 shares) {
        require(amount > 0, "Zero amount");

        if (totalSupply == 0) {
            shares = amount;
        } else {
            uint256 totalAssets = getTotalAssets();
            shares = (amount * totalSupply) / totalAssets;
        }

        balanceOf[msg.sender] += shares;
        totalSupply += shares;

        _investInCurve(amount);

        emit Deposit(msg.sender, amount, shares);
        return shares;
    }

    function withdraw(uint256 shares) external returns (uint256 amount) {
        require(shares > 0, "Zero shares");
        require(balanceOf[msg.sender] >= shares, "Insufficient balance");

        uint256 totalAssets = getTotalAssets();
        amount = (shares * totalAssets) / totalSupply;

        balanceOf[msg.sender] -= shares;
        totalSupply -= shares;

        _withdrawFromCurve(amount);

        emit Withdrawal(msg.sender, shares, amount);
        return amount;
    }

    function getTotalAssets() public view returns (uint256) {

        uint256 vaultBalance = 0;
        uint256 curveBalance = investedBalance;

        return vaultBalance + curveBalance;
    }

    function getPricePerFullShare() public view returns (uint256) {
        if (totalSupply == 0) return 1e18;
        return (getTotalAssets() * 1e18) / totalSupply;
    }

    function _investInCurve(uint256 amount) internal {
        investedBalance += amount;

    }

    function _withdrawFromCurve(uint256 amount) internal {
        require(investedBalance >= amount, "Insufficient invested");
        investedBalance -= amount;

    }
}
