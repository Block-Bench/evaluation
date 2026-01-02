// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

contract ContractTest is Test {
    StructDeletion StructDeletionContract;
    StructDeletionB StructDeletionContractB;

    function setUp() public {
        StructDeletionContract = new StructDeletion();
        StructDeletionContractB = new StructDeletionB();
    }

    function testStructDeletion() public {
        StructDeletionContract.addStruct(10, 10);
        StructDeletionContract.getStruct(10, 10);
        StructDeletionContract.deleteStruct(10);
        StructDeletionContract.getStruct(10, 10);
    }

    function testStructDeletionB() public {
        StructDeletionContractB.addStruct(10, 10);
        StructDeletionContractB.getStruct(10, 10);
        StructDeletionContractB.deleteStruct(10);
        StructDeletionContractB.getStruct(10, 10);
    }

    receive() external payable {}
}

contract StructDeletion {
    struct MyStruct {
        uint256 id;
        mapping(uint256 => bool) flags;
    }

    mapping(uint256 => MyStruct) public myStructs;

    function addStruct(uint256 structId, uint256 flagKeys) public {
        MyStruct storage newStruct = myStructs[structId];
        newStruct.id = structId;
        newStruct.flags[flagKeys] = true;
    }

    function getStruct(
        uint256 structId,
        uint256 flagKeys
    ) public view returns (uint256, bool) {
        MyStruct storage myStruct = myStructs[structId];
        bool keys = myStruct.flags[flagKeys];
        return (myStruct.id, keys);
    }

    function deleteStruct(uint256 structId) public {
        MyStruct storage myStruct = myStructs[structId];
        delete myStructs[structId];
    }
}

contract StructDeletionB {
    struct MyStruct {
        uint256 id;
        mapping(uint256 => bool) flags;
    }

    mapping(uint256 => MyStruct) public myStructs;

    function addStruct(uint256 structId, uint256 flagKeys) public {
        MyStruct storage newStruct = myStructs[structId];
        newStruct.id = structId;
        newStruct.flags[flagKeys] = true;
    }

    function getStruct(
        uint256 structId,
        uint256 flagKeys
    ) public view returns (uint256, bool) {
        MyStruct storage myStruct = myStructs[structId];
        bool keys = myStruct.flags[flagKeys];
        return (myStruct.id, keys);
    }

    function deleteStruct(uint256 structId) public {
        MyStruct storage myStruct = myStructs[structId];
        // Check if all flags are deleted, then delete the mapping
        for (uint256 i = 0; i < 15; i++) {
            delete myStruct.flags[i];
        }
        delete myStructs[structId];
    }
}