// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
// Import the SafeCast library
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract SimpleBank {
    mapping(address => uint) private balances;

    function deposit(uint256 amount) public {
        uint8 balance = uint8(amount);

        // store the balance
        balances[msg.sender] = balance;
    }

    function getBalance() public view returns (uint) {
        return balances[msg.sender];
    }
}

contract SimpleBankB {
    using SafeCast for uint256; // Use SafeCast for uint256

    mapping(address => uint) private balances;

    function deposit(uint256 _amount) public {
        // Use the `toUint8()` function from `SafeCast` to safely downcast `amount`.
        // or keep the same uint256 with amount.
        uint8 amount = _amount.toUint8(); // or keep uint256

        // Store the balance
        balances[msg.sender] = amount;
    }

    function getBalance() public view returns (uint) {
        return balances[msg.sender];
    }
}
