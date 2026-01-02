// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

contract ContractTest is Test {
    BankManagerA managerA;
    BankManagerB managerB;

    function setUp() public {
        managerA = new BankManagerA();
        managerB = new BankManagerB();

        // Initialize both managers with the same 3 banks
        address[] memory initialBanks = new address[](3);
        string[] memory initialNames = new string[](3);

        initialBanks[0] = address(0x1);
        initialNames[0] = "ABC Bank";

        initialBanks[1] = address(0x2);
        initialNames[1] = "XYZ Bank";

        initialBanks[2] = address(0x3);
        initialNames[2] = "Global Bank";

        managerA.addBanks(initialBanks, initialNames);
        managerB.addBanks(initialBanks, initialNames);

        // Verify initial state
        emit log_string("Initial state of both bank managers:");
        emit log_named_uint("Manager A bank count", managerA.getBankCount());
        emit log_named_uint("Manager B bank count", managerB.getBankCount());
    }

    function testRemoveBanks() public {
        // Try to remove all banks marked for removal
        emit log_string("\nRemoving banks marked for removal");

        // Mark all banks for removal
        address[] memory banksToRemove = new address[](3);
        banksToRemove[0] = address(0x1); // ABC Bank
        banksToRemove[1] = address(0x2); // XYZ Bank
        banksToRemove[2] = address(0x3); // Global Bank
        console.log("------------Testing Manager A---------------");
        managerA.removeBanksMethodA(banksToRemove);
        emit log_named_uint("Manager A bank count after removal", managerA.getBankCount());
        managerA.listBanks();

        console.log("------------Testing Manager B---------------");
        managerB.removeBanksMethodB(banksToRemove);
        emit log_named_uint("Manager B bank count after removal", managerB.getBankCount());
        managerB.listBanks();
    }
}

// Base contract with common functionality
contract BankManager {
    struct Bank {
        address bankAddress;
        string bankName;
    }

    Bank[] public banks;

    // Add multiple banks
    function addBanks(address[] memory addresses, string[] memory names) public {
        require(addresses.length == names.length, "Arrays must have the same length");

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

// Implementation A
contract BankManagerA is BankManager, Test {
    // Remove all banks in the provided list

    function removeBanksMethodA(address[] memory banksToRemove) public {
        for (uint i = 0; i < banks.length; i++) {
            for (uint j = 0; j < banksToRemove.length; j++) {
                if (banks[i].bankAddress == banksToRemove[j]) {
                    emit log_string(string(abi.encodePacked(
                        "Removing bank: ", banks[i].bankName,
                        " (Address: ", toHexString(uint160(banks[i].bankAddress)), ")"
                    )));

                    _removeBank(i);
                    return;
                }
            }
        }
    }

    // Helper function to list all banks in this manager
    function listBanks() public {
        emit log_string("Banks in manager A:");
        for (uint i = 0; i < banks.length; i++) {
            emit log_string(string(abi.encodePacked(
                "Bank ", toString(i), ": ",
                banks[i].bankName, " (Address: ",
                toHexString(uint160(banks[i].bankAddress)), ")"
            )));
        }
    }

    // Helper function to convert uint to string
    function toString(uint value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint temp = value;
        uint digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // Helper function to convert address to hex string
    function toHexString(uint value) internal pure returns (string memory) {
        bytes16 hexSymbols = "0123456789abcdef";
        uint length = 40; // 20 bytes * 2 characters per byte
        bytes memory buffer = new bytes(2 + length);
        buffer[0] = '0';
        buffer[1] = 'x';
        for (uint i = 2 + length - 1; i >= 2; i--) {
            buffer[i] = hexSymbols[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }
}

// Implementation B
contract BankManagerB is BankManager, Test {
    // Remove all banks in the provided list

    function removeBanksMethodB(address[] memory banksToRemove) public {
        for (int i = int(banks.length) - 1; i >= 0; i--) {
            for (uint j = 0; j < banksToRemove.length; j++) {
                if (banks[uint(i)].bankAddress == banksToRemove[j]) {
                    emit log_string(string(abi.encodePacked(
                        "Removing bank: ", banks[uint(i)].bankName,
                        " (Address: ", toHexString(uint160(banks[uint(i)].bankAddress)), ")"
                    )));

                    _removeBank(uint(i));
                    break;
                }
            }
        }
    }

    // Helper function to list all banks in this manager
    function listBanks() public {
        emit log_string("Banks in manager B:");
        for (uint i = 0; i < banks.length; i++) {
            emit log_string(string(abi.encodePacked(
                "Bank ", toString(i), ": ",
                banks[i].bankName, " (Address: ",
                toHexString(uint160(banks[i].bankAddress)), ")"
            )));
        }
    }

    // Helper function to convert uint to string
    function toString(uint value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint temp = value;
        uint digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // Helper function to convert address to hex string
    function toHexString(uint value) internal pure returns (string memory) {
        bytes16 hexSymbols = "0123456789abcdef";
        uint length = 40; // 20 bytes * 2 characters per byte
        bytes memory buffer = new bytes(2 + length);
        buffer[0] = '0';
        buffer[1] = 'x';
        for (uint i = 2 + length - 1; i >= 2; i--) {
            buffer[i] = hexSymbols[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }
}
