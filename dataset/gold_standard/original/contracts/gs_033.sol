// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.27;

/**
 * @title Factory deploy reverts instead of returning address when account already exists
 * @notice VULNERABLE CONTRACT - Gold Standard Benchmark Item gs_034
 * @dev Source: CODE4RENA - 
 *
 * VULNERABILITY INFORMATION:
 * - Type: dos
 * - Severity: MEDIUM
 * - Finding ID: M-04
 *
 * DESCRIPTION:
 * Factory.deploy uses create2 but reverts with CreateCollision if address exists,
 * violating ERC-4337 expectation to return address. Breaks simulations and bundler
 * logic.
 *
 * VULNERABLE FUNCTIONS:
 * - deploy()
 *
 * VULNERABLE LINES:
 * - Lines: 18, 19, 20, 21, 22, 23, 24, 25, 26
 *
 * ATTACK SCENARIO:
 * Deploy wallet once, call deploy again → reverts. Attacker can front-run to cause
 *
 * RECOMMENDED FIX:
 * Check if address exists via predicted.code.length, return it if so.
 */


import "./Wallet.sol";

/// @title Factory
/// @author Agustin Aguilar, Michael Standen
/// @notice Factory for deploying wallets
contract Factory {

  /// @notice Error thrown when the deployment fails
  error DeployFailed(address _mainModule, bytes32 _salt);

  /// @notice Deploy a new wallet instance
  /// @param _mainModule Address of the main module to be used by the wallet
  /// @param _salt Salt used to generate the wallet, which is the imageHash of the wallet's configuration.
  /// @dev It is recommended to not have more than 200 signers as opcode repricing could make transactions impossible to execute as all the signers must be passed for each transaction.
    // @audit-issue VULNERABLE FUNCTION: deploy
  function deploy(address _mainModule, bytes32 _salt) public payable returns (address _contract) {
    bytes memory code = abi.encodePacked(Wallet.creationCode, uint256(uint160(_mainModule)));
    assembly {
      _contract := create2(callvalue(), add(code, 32), mload(code), _salt)
    }
    if (_contract == address(0)) {
      revert DeployFailed(_mainModule, _salt);
    }
  }

}