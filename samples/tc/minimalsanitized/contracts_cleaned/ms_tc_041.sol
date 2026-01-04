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

interface ISmartLoan {
    function swapDebtParaSwap(
        bytes32 _fromAsset,
        bytes32 _toAsset,
        uint256 _repayAmount,
        uint256 _borrowAmount,
        bytes4 selector,
        bytes memory data
    ) external;

    function claimReward(address pair, uint256[] calldata ids) external;
}

contract SmartLoansFactory {
    address public admin;

    constructor() {
        admin = msg.sender;
    }

    function createLoan() external returns (address) {
        SmartLoan loan = new SmartLoan();
        return address(loan);
    }

    function upgradePool(
        address poolProxy,
        address newImplementation
    ) external {
        
        
        require(msg.sender == admin, "Not admin");

       

        // Upgrade the proxy to point to new implementation
        // (Simplified - actual upgrade uses proxy pattern)
    }
}

contract SmartLoan is ISmartLoan {
    mapping(bytes32 => uint256) public deposits;
    mapping(bytes32 => uint256) public debts;

    function swapDebtParaSwap(
        bytes32 _fromAsset,
        bytes32 _toAsset,
        uint256 _repayAmount,
        uint256 _borrowAmount,
        bytes4 selector,
        bytes memory data
    ) external override {
        // Simplified swap logic
    }

    /**
     * @notice Claim rewards from staking pairs
     */
    function claimReward(
        address pair,
        uint256[] calldata ids
    ) external override {

        // Call to pair contract to claim rewards
        (bool success, ) = pair.call(
            abi.encodeWithSignature("claimRewards(address)", msg.sender)
        );

    }
}
