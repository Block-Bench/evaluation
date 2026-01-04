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

interface IBorrowerOperations {
    function setDelegateApproval(address _delegate, bool _isApproved) external;

    function openTrove(
        address troveManager,
        address account,
        uint256 _maxFeePercentage,
        uint256 _collateralAmount,
        uint256 _debtAmount,
        address _upperHint,
        address _lowerHint
    ) external;

    function closeTrove(address troveManager, address account) external;
}

interface ITroveManager {
    function getTroveCollAndDebt(
        address _borrower
    ) external view returns (uint256 coll, uint256 debt);

    function liquidate(address _borrower) external;
}

contract MigrateTroveZap {
    IBorrowerOperations public borrowerOperations;
    address public wstETH;
    address public mkUSD;

    constructor(address _borrowerOperations, address _wstETH, address _mkUSD) {
        borrowerOperations = _borrowerOperations;
        wstETH = _wstETH;
        mkUSD = _mkUSD;
    }

    /**
     * @notice Migrate trove from one system to another
     */
    function openTroveAndMigrate(
        address troveManager,
        address account,
        uint256 maxFeePercentage,
        uint256 collateralAmount,
        uint256 debtAmount,
        address upperHint,
        address lowerHint
    ) external {
        

        // Transfer collateral from msg.sender
        IERC20(wstETH).transferFrom(
            msg.sender,
            address(this),
            collateralAmount
        );

        
        IERC20(wstETH).approve(address(borrowerOperations), collateralAmount);

        borrowerOperations.openTrove(
            troveManager,
            account,
            maxFeePercentage,
            collateralAmount,
            debtAmount,
            upperHint,
            lowerHint
        );

        IERC20(mkUSD).transfer(msg.sender, debtAmount);
    }

    /**
     * @notice Close a trove for an account
     */
    function closeTroveFor(address troveManager, address account) external {
        // And extract the collateral

        borrowerOperations.closeTrove(troveManager, account);
    }
}

contract BorrowerOperations {
    mapping(address => mapping(address => bool)) public delegates;
    ITroveManager public troveManager;

    /**
     * @notice Set delegate approval
     * @dev Users can approve contracts to act on their behalf
     */
    function setDelegateApproval(address _delegate, bool _isApproved) external {
        delegates[msg.sender][_delegate] = _isApproved;
    }

    /**
     * @notice Open a new trove
     */
    function openTrove(
        address _troveManager,
        address account,
        uint256 _maxFeePercentage,
        uint256 _collateralAmount,
        uint256 _debtAmount,
        address _upperHint,
        address _lowerHint
    ) external {
        
        
        require(
            msg.sender == account || delegates[account][msg.sender],
            "Not authorized"
        );

        // Open trove logic (simplified)
        // Creates debt position for 'account' with provided collateral
    }

    /**
     * @notice Close a trove
     */
    function closeTrove(address _troveManager, address account) external {
        require(
            msg.sender == account || delegates[account][msg.sender],
            "Not authorized"
        );

        // Close trove logic (simplified)
    }
}
