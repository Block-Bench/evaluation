// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract BankManager {
    struct Bank {
        address bankAddress;
        string bankName;
    }

    Bank[] public banks;

    // Add multiple banks
    function addBanks(
        address[] memory addresses,
        string[] memory names
    ) public {
        require(
            addresses.length == names.length,
            "Arrays must have the same length"
        );

        for (uint i = 0; i < addresses.length; i++) {
            banks.push(Bank(addresses[i], names[i]));
        }
    }

    // Get the number of banks
    function getBankCount() public view returns (uint) {
        return banks.length;
    }

    // Get a specific bank
    function getBank(uint index) public view returns (address, string memory) {
        require(index < banks.length, "Index out of bounds");
        return (banks[index].bankAddress, banks[index].bankName);
    }

    // Helper function to remove a bank at a specific index
    function _removeBank(uint index) internal {
        require(index < banks.length, "Index out of bounds");

        // Move the last element to the deleted position
        if (index < banks.length - 1) {
            banks[index] = banks[banks.length - 1];
        }

        // Remove the last element
        banks.pop();
    }
}

contract BankManagerA is BankManager {
    // Remove all banks in the provided list
    function removeBanksMethodA(address[] memory banksToRemove) public {
        for (uint i = 0; i < banks.length; i++) {
            for (uint j = 0; j < banksToRemove.length; j++) {
                if (banks[i].bankAddress == banksToRemove[j]) {
                    _removeBank(i);
                    return;
                }
            }
        }
    }
}
