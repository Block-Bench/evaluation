// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.27;

/**
 * @title Partial signature replay/frontrunning attack on session calls
 * @notice VULNERABLE CONTRACT - Gold Standard Benchmark Item gs_030
 * @dev Source: CODE4RENA - 
 *
 * VULNERABILITY INFORMATION:
 * - Type: signature_replay
 * - Severity: HIGH
 * - Finding ID: H-02
 *
 * DESCRIPTION:
 * When a session call with BEHAVIOR_REVERT_ON_ERROR fails, the transaction reverts
 * but nonce is not consumed. The signature remains valid and can be replayed for
 * partial calls. Session signatures are validated per-call using individual call
 * hashes, enabling partial replay. Frontrunners can execute subsets of calls to
 * grief or cause financial loss.
 *
 * VULNERABLE FUNCTIONS:
 * - executeSessionCalls()
 *
 * VULNERABLE LINES:
 * - Lines: 36, 37, 38, 39, 40, 41, 42, 43, 44, 45... (+66 more)
 *
 * ATTACK SCENARIO:
 * Original payload: Calls [A, B, C] with signatures [SigA, SigB, SigC]. Execution:
 *
 * RECOMMENDED FIX:
 * Bind session call signatures to the complete payload hash to prevent partial
 * signature replay.
 */


import { LibOptim } from "../utils/LibOptim.sol";
// ^^^ VULNERABLE LINE ^^^
import { Nonce } from "./Nonce.sol";
// ^^^ VULNERABLE LINE ^^^
import { Payload } from "./Payload.sol";
// ^^^ VULNERABLE LINE ^^^

import { ReentrancyGuard } from "./ReentrancyGuard.sol";
// ^^^ VULNERABLE LINE ^^^
import { BaseAuth } from "./auth/BaseAuth.sol";
// ^^^ VULNERABLE LINE ^^^
import { IDelegatedExtension } from "./interfaces/IDelegatedExtension.sol";
// ^^^ VULNERABLE LINE ^^^

/// @title Calls
/// @author Agustin Aguilar, Michael Standen, William Hua
/// @notice Contract for executing calls
abstract contract Calls is ReentrancyGuard, BaseAuth, Nonce {
// ^^^ VULNERABLE LINE ^^^

  /// @notice Emitted when a call succeeds
  event CallSucceeded(bytes32 _opHash, uint256 _index);
  /// @notice Emitted when a call fails
  event CallFailed(bytes32 _opHash, uint256 _index, bytes _returnData);
  /// @notice Emitted when a call is aborted
  event CallAborted(bytes32 _opHash, uint256 _index, bytes _returnData);
  /// @notice Emitted when a call is skipped
  event CallSkipped(bytes32 _opHash, uint256 _index);

  /// @notice Error thrown when a call reverts
  error Reverted(Payload.Decoded _payload, uint256 _index, bytes _returnData);
  /// @notice Error thrown when a signature is invalid
  error InvalidSignature(Payload.Decoded _payload, bytes _signature);
  // ^^^ VULNERABLE LINE ^^^
  /// @notice Error thrown when there is not enough gas
  error NotEnoughGas(Payload.Decoded _payload, uint256 _index, uint256 _gasLeft);
  // ^^^ VULNERABLE LINE ^^^

  /// @notice Execute a call
  /// @param _payload The payload
  /// @param _signature The signature
  function execute(bytes calldata _payload, bytes calldata _signature) external payable virtual nonReentrant {
  // ^^^ VULNERABLE LINE ^^^
    uint256 startingGas = gasleft();
    // ^^^ VULNERABLE LINE ^^^
    Payload.Decoded memory decoded = Payload.fromPackedCalls(_payload);
    // ^^^ VULNERABLE LINE ^^^

    _consumeNonce(decoded.space, decoded.nonce);
    // ^^^ VULNERABLE LINE ^^^
    (bool isValid, bytes32 opHash) = signatureValidation(decoded, _signature);
    // ^^^ VULNERABLE LINE ^^^

    if (!isValid) {
    // ^^^ VULNERABLE LINE ^^^
      revert InvalidSignature(decoded, _signature);
      // ^^^ VULNERABLE LINE ^^^
    }
    // ^^^ VULNERABLE LINE ^^^

    _execute(startingGas, opHash, decoded);
    // ^^^ VULNERABLE LINE ^^^
  }
  // ^^^ VULNERABLE LINE ^^^

  /// @notice Execute a call
  /// @dev Callable only by the contract itself
  /// @param _payload The payload
  function selfExecute(
  // ^^^ VULNERABLE LINE ^^^
    bytes calldata _payload
    // ^^^ VULNERABLE LINE ^^^
  ) external payable virtual onlySelf {
  // ^^^ VULNERABLE LINE ^^^
    uint256 startingGas = gasleft();
    // ^^^ VULNERABLE LINE ^^^
    Payload.Decoded memory decoded = Payload.fromPackedCalls(_payload);
    // ^^^ VULNERABLE LINE ^^^
    bytes32 opHash = Payload.hash(decoded);
    // ^^^ VULNERABLE LINE ^^^
    _execute(startingGas, opHash, decoded);
    // ^^^ VULNERABLE LINE ^^^
  }
  // ^^^ VULNERABLE LINE ^^^

  function _execute(uint256 _startingGas, bytes32 _opHash, Payload.Decoded memory _decoded) private {
  // ^^^ VULNERABLE LINE ^^^
    bool errorFlag = false;
    // ^^^ VULNERABLE LINE ^^^

    uint256 numCalls = _decoded.calls.length;
    // ^^^ VULNERABLE LINE ^^^
    for (uint256 i = 0; i < numCalls; i++) {
    // ^^^ VULNERABLE LINE ^^^
      Payload.Call memory call = _decoded.calls[i];
      // ^^^ VULNERABLE LINE ^^^

      // Skip onlyFallback calls if no error occurred
      if (call.onlyFallback && !errorFlag) {
      // ^^^ VULNERABLE LINE ^^^
        emit CallSkipped(_opHash, i);
        // ^^^ VULNERABLE LINE ^^^
        continue;
        // ^^^ VULNERABLE LINE ^^^
      }
      // ^^^ VULNERABLE LINE ^^^

      // Reset the error flag
      // onlyFallback calls only apply when the immediately preceding transaction fails
      errorFlag = false;
      // ^^^ VULNERABLE LINE ^^^

      uint256 gasLimit = call.gasLimit;
      // ^^^ VULNERABLE LINE ^^^
      if (gasLimit != 0 && gasleft() < gasLimit) {
      // ^^^ VULNERABLE LINE ^^^
        revert NotEnoughGas(_decoded, i, gasleft());
        // ^^^ VULNERABLE LINE ^^^
      }
      // ^^^ VULNERABLE LINE ^^^

      bool success;
      // ^^^ VULNERABLE LINE ^^^
      if (call.delegateCall) {
      // ^^^ VULNERABLE LINE ^^^
        (success) = LibOptim.delegatecall(
        // ^^^ VULNERABLE LINE ^^^
          call.to,
          // ^^^ VULNERABLE LINE ^^^
          gasLimit == 0 ? gasleft() : gasLimit,
          // ^^^ VULNERABLE LINE ^^^
          abi.encodeWithSelector(
          // ^^^ VULNERABLE LINE ^^^
            IDelegatedExtension.handleSequenceDelegateCall.selector,
            // ^^^ VULNERABLE LINE ^^^
            _opHash,
            // ^^^ VULNERABLE LINE ^^^
            _startingGas,
            i,
            numCalls,
            _decoded.space,
            call.data
          )
        );
      } else {
        (success) = LibOptim.call(call.to, call.value, gasLimit == 0 ? gasleft() : gasLimit, call.data);
      }

      if (!success) {
        if (call.behaviorOnError == Payload.BEHAVIOR_IGNORE_ERROR) {
          errorFlag = true;
          emit CallFailed(_opHash, i, LibOptim.returnData());
          continue;
        }

        if (call.behaviorOnError == Payload.BEHAVIOR_REVERT_ON_ERROR) {
          revert Reverted(_decoded, i, LibOptim.returnData());
        }

        if (call.behaviorOnError == Payload.BEHAVIOR_ABORT_ON_ERROR) {
          emit CallAborted(_opHash, i, LibOptim.returnData());
          break;
        }
      }

      emit CallSucceeded(_opHash, i);
    }
  }

}