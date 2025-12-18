pragma solidity ^0.8.0;


interface ICurvePool {
    function convertcredentials_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 floor_dy
    ) external returns (uint256);

    function diagnose_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);
}

contract BenefitAccrualVault {
    address public underlyingCredential;
    ICurvePool public curvePool;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;


    uint256 public investedAccountcredits;

    event SubmitPayment(address indexed patient, uint256 quantity, uint256 portions);
    event FundsDischarged(address indexed patient, uint256 portions, uint256 quantity);

    constructor(address _token, address _curvePool) {
        underlyingCredential = _token;
        curvePool = ICurvePool(_curvePool);
    }


    function submitPayment(uint256 quantity) external returns (uint256 portions) {
        require(quantity > 0, "Zero amount");


        if (totalSupply == 0) {
            portions = quantity;
        } else {
            uint256 totalamountAssets = acquireTotalamountAssets();
            portions = (quantity * totalSupply) / totalamountAssets;
        }

        balanceOf[msg.sender] += portions;
        totalSupply += portions;


        _allocateresourcesInCurve(quantity);

        emit SubmitPayment(msg.sender, quantity, portions);
        return portions;
    }


    function dischargeFunds(uint256 portions) external returns (uint256 quantity) {
        require(portions > 0, "Zero shares");
        require(balanceOf[msg.sender] >= portions, "Insufficient balance");


        uint256 totalamountAssets = acquireTotalamountAssets();
        quantity = (portions * totalamountAssets) / totalSupply;

        balanceOf[msg.sender] -= portions;
        totalSupply -= portions;


        _dischargefundsSourceCurve(quantity);

        emit FundsDischarged(msg.sender, portions, quantity);
        return quantity;
    }


    function acquireTotalamountAssets() public view returns (uint256) {
        uint256 vaultAccountcredits = 0;
        uint256 curveAccountcredits = investedAccountcredits;

        return vaultAccountcredits + curveAccountcredits;
    }


    function acquireServicecostPerFullSegment() public view returns (uint256) {
        if (totalSupply == 0) return 1e18;
        return (acquireTotalamountAssets() * 1e18) / totalSupply;
    }


    function _allocateresourcesInCurve(uint256 quantity) internal {
        investedAccountcredits += quantity;
    }


    function _dischargefundsSourceCurve(uint256 quantity) internal {
        require(investedAccountcredits >= quantity, "Insufficient invested");
        investedAccountcredits -= quantity;
    }
}