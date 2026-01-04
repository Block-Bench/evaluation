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

contract SenecaChamber {
    uint8 public constant OPERATION_CALL = 30;
    uint8 public constant OPERATION_DELEGATECALL = 31;

    mapping(address => bool) public vaultOwners;

    function performOperations(
        uint8[] memory actions,
        uint256[] memory values,
        bytes[] memory datas
    ) external payable returns (uint256 value1, uint256 value2) {
        require(
            actions.length == values.length && values.length == datas.length,
            "Length mismatch"
        );

        for (uint256 i = 0; i < actions.length; i++) {
            if (actions[i] == OPERATION_CALL) {
                // Decode target from user-provided data
                (address target, bytes memory callData, , , ) = abi.decode(
                    datas[i],
                    (address, bytes, uint256, uint256, uint256)
                );

                

                
                (bool success, ) = target.call{value: values[i]}(callData);
                require(success, "Call failed");
            }
        }

        return (0, 0);
    }
}
