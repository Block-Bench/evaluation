// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/console.sol";

contract SimpleVault {
    // mint function
    function mint(uint256 amountToDeposit) external returns (uint256) {
        // Write vault address (address(this)) to transient storage
        address vault = address(this);
        assembly {
            tstore(1, vault)
        }

        // Directly call own callback function
        this.SwapCallback(amountToDeposit, "");
    }

    // Simulate SwapCallback callback function
    function SwapCallback(uint256 amount, bytes calldata data) external {
        // Read vault address from transient storage
        address vault;
        assembly {
            vault := tload(1)
        }

        // Check if caller is a legitimate vault
        require(msg.sender == vault, "Not authorized");

        if (vault == address(this)) {
            // Output vault address for observation
            console.log("vault address:", vault);
            // Write the returned amount to transient storage
            assembly {
                tstore(1, amount)
            }
        } else {
            console.log("Different vault address:", vault);
        }
    }
}
