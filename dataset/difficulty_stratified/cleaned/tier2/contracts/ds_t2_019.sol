// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

contract ContractTest is Test {
    ArrayDeletion ArrayDeletionContract;
    ArrayDeletionB ArrayDeletionContractB;

    function setUp() public {
        ArrayDeletionContract = new ArrayDeletion();
        ArrayDeletionContractB = new ArrayDeletionB();
    }

    function testArrayDeletionA() public {
        ArrayDeletionContract.myArray(1);
        ArrayDeletionContract.deleteElement(1);
        ArrayDeletionContract.myArray(1);
        ArrayDeletionContract.getLength();
    }

    function testArrayDeletionB() public {
        ArrayDeletionContractB.myArray(1);
        ArrayDeletionContractB.deleteElement(1);
        ArrayDeletionContractB.myArray(1);
        ArrayDeletionContractB.getLength();
    }

    receive() external payable {}
}

contract ArrayDeletion {
    uint[] public myArray = [1, 2, 3, 4, 5];

    function deleteElement(uint index) external {
        require(index < myArray.length, "Invalid index");
        delete myArray[index];
    }

    function getLength() public view returns (uint) {
        return myArray.length;
    }
}

contract ArrayDeletionB {
    uint[] public myArray = [1, 2, 3, 4, 5];

    function deleteElement(uint index) external {
        require(index < myArray.length, "Invalid index");
        myArray[index] = myArray[myArray.length - 1];
        myArray.pop();
    }

    function getLength() public view returns (uint) {
        return myArray.length;
    }
}
