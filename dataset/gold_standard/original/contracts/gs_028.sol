// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.27;

/**
 * @title Chained signature with checkpoint usage disabled can bypass all checkpointer validation
 * @notice VULNERABLE CONTRACT - Gold Standard Benchmark Item gs_029
 * @dev Source: CODE4RENA - 2025-10-sequence
 *
 * VULNERABILITY INFORMATION:
 * - Type: access_control
 * - Severity: HIGH
 * - Finding ID: H-01
 *
 * DESCRIPTION:
 * When a wallet is behind a checkpointer and a chained signature is used with bit 6
 * (checkpointer usage flag) set to zero, BaseSig.recover skips the checkpointer
 * validation block (BaseSig.sol:88-106). This leaves _checkpointer and snapshot
 * unset (zero-valued). In recoverChained, the checkpointer is ignored, and the
 * signature validation passes even if the checkpointer should be enforced. The final
 * validation succeeds because snapshot.imageHash == bytes32(0) as the checkpointer
 * is ignored.
 *
 * VULNERABLE FUNCTIONS:
 * - recover()
 * - recoverChained()
 *
 * VULNERABLE LINES:
 * - Lines: 88, 89, 90, 91, 92, 93, 94, 95, 96, 97... (+27 more)
 *
 * ATTACK SCENARIO:
 * An evicted signer can sign a payload valid under stale wallet configuration and 
 *
 * RECOMMENDED FIX:
 * Do not permit checkpointer to be disabled (bit 6 unset) if chained signature is
 * used. Revert in this case with custom error. Example fix in BaseSig.sol: if
 * (signatureFlag & 0x40 == 0) { revert MissingCheckpointer(); }
 */


import { LibBytes } from "../../utils/LibBytes.sol";
import { LibOptim } from "../../utils/LibOptim.sol";
import { Payload } from "../Payload.sol";

import { ICheckpointer, Snapshot } from "../interfaces/ICheckpointer.sol";
import { IERC1271, IERC1271_MAGIC_VALUE_HASH } from "../interfaces/IERC1271.sol";
import { ISapient, ISapientCompact } from "../interfaces/ISapient.sol";

using LibBytes for bytes;
using Payload for Payload.Decoded;

/// @title BaseSig
/// @author Agustin Aguilar, Michael Standen, William Hua, Shun Kakinoki
/// @notice Library for recovering signatures from the base-auth payload
library BaseSig {

  uint256 internal constant FLAG_SIGNATURE_HASH = 0;
  uint256 internal constant FLAG_ADDRESS = 1;
  uint256 internal constant FLAG_SIGNATURE_ERC1271 = 2;
  uint256 internal constant FLAG_NODE = 3;
  uint256 internal constant FLAG_BRANCH = 4;
  uint256 internal constant FLAG_SUBDIGEST = 5;
  uint256 internal constant FLAG_NESTED = 6;
  uint256 internal constant FLAG_SIGNATURE_ETH_SIGN = 7;
  uint256 internal constant FLAG_SIGNATURE_ANY_ADDRESS_SUBDIGEST = 8;
  uint256 internal constant FLAG_SIGNATURE_SAPIENT = 9;
  uint256 internal constant FLAG_SIGNATURE_SAPIENT_COMPACT = 10;

  /// @notice Error thrown when the weight is too low for a chained signature
  error LowWeightChainedSignature(bytes _signature, uint256 _threshold, uint256 _weight);
  /// @notice Error thrown when the ERC1271 signature is invalid
  error InvalidERC1271Signature(bytes32 _opHash, address _signer, bytes _signature);
  /// @notice Error thrown when the checkpoint order is wrong
  error WrongChainedCheckpointOrder(uint256 _nextCheckpoint, uint256 _checkpoint);
  /// @notice Error thrown when the snapshot is unused
  error UnusedSnapshot(Snapshot _snapshot);
  /// @notice Error thrown when the signature flag is invalid
  error InvalidSignatureFlag(uint256 _flag);

  function _leafForAddressAndWeight(address _addr, uint256 _weight) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked("Sequence signer:\n", _addr, _weight));
  }

  function _leafForNested(bytes32 _node, uint256 _threshold, uint256 _weight) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked("Sequence nested config:\n", _node, _threshold, _weight));
  }

  function _leafForSapient(address _addr, uint256 _weight, bytes32 _imageHash) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked("Sequence sapient config:\n", _addr, _weight, _imageHash));
    // ^^^ VULNERABLE LINE ^^^
  }
  // ^^^ VULNERABLE LINE ^^^

  function _leafForHardcodedSubdigest(
  // ^^^ VULNERABLE LINE ^^^
    bytes32 _subdigest
    // ^^^ VULNERABLE LINE ^^^
  ) internal pure returns (bytes32) {
  // ^^^ VULNERABLE LINE ^^^
    return keccak256(abi.encodePacked("Sequence static digest:\n", _subdigest));
    // ^^^ VULNERABLE LINE ^^^
  }
  // ^^^ VULNERABLE LINE ^^^

  function _leafForAnyAddressSubdigest(
  // ^^^ VULNERABLE LINE ^^^
    bytes32 _anyAddressSubdigest
    // ^^^ VULNERABLE LINE ^^^
  ) internal pure returns (bytes32) {
  // ^^^ VULNERABLE LINE ^^^
    return keccak256(abi.encodePacked("Sequence any address subdigest:\n", _anyAddressSubdigest));
    // ^^^ VULNERABLE LINE ^^^
  }
  // ^^^ VULNERABLE LINE ^^^

    // @audit-issue VULNERABLE FUNCTION: recover
  function recover(
  // ^^^ VULNERABLE LINE ^^^
    Payload.Decoded memory _payload,
    // ^^^ VULNERABLE LINE ^^^
    bytes calldata _signature,
    // ^^^ VULNERABLE LINE ^^^
    bool _ignoreCheckpointer,
    // ^^^ VULNERABLE LINE ^^^
    address _checkpointer
  ) internal view returns (uint256 threshold, uint256 weight, bytes32 imageHash, uint256 checkpoint, bytes32 opHash) {
    // First byte is the signature flag
    (uint256 signatureFlag, uint256 rindex) = _signature.readFirstUint8();

    // The possible flags are:
    // - 0000 00XX (bits [1..0]): signature type (00 = normal, 01/11 = chained, 10 = no chain id)
    // - 000X XX00 (bits [4..2]): checkpoint size (00 = 0 bytes, 001 = 1 byte, 010 = 2 bytes...)
    // - 00X0 0000 (bit [5]): threshold size (0 = 1 byte, 1 = 2 bytes)
    // - 0X00 0000 (bit [6]): set if imageHash checkpointer is used
    // - X000 0000 (bit [7]): reserved by base-auth

    Snapshot memory snapshot;

    // Recover the imageHash checkpointer if any
    // but checkpointer passed as argument takes precedence
    // since it can be defined by the chained signatures
    if (signatureFlag & 0x40 == 0x40 && _checkpointer == address(0)) {
      // Override the checkpointer
      // not ideal, but we don't have much room in the stack
      (_checkpointer, rindex) = _signature.readAddress(rindex);

      if (!_ignoreCheckpointer) {
        // Next 3 bytes determine the checkpointer data size
        uint256 checkpointerDataSize;
        (checkpointerDataSize, rindex) = _signature.readUint24(rindex);

        // Read the checkpointer data
        bytes memory checkpointerData = _signature[rindex:rindex + checkpointerDataSize];

        // Call the middleware
        snapshot = ICheckpointer(_checkpointer).snapshotFor(address(this), checkpointerData);
        // ^^^ VULNERABLE LINE ^^^

        rindex += checkpointerDataSize;
        // ^^^ VULNERABLE LINE ^^^
      }
    }

    // If signature type is 01 or 11 we do a chained signature
    if (signatureFlag & 0x01 == 0x01) {
      return recoverChained(_payload, _checkpointer, snapshot, _signature[rindex:]);
    }

    // If the signature type is 10 we do a no chain id signature
    _payload.noChainId = signatureFlag & 0x02 == 0x02;

    {
      // Recover the checkpoint using the size defined by the flag
      uint256 checkpointSize = (signatureFlag & 0x1c) >> 2;
      (checkpoint, rindex) = _signature.readUintX(rindex, checkpointSize);
    }

    // Recover the threshold, using the flag for the size
    {
      uint256 thresholdSize = ((signatureFlag & 0x20) >> 5) + 1;
      (threshold, rindex) = _signature.readUintX(rindex, thresholdSize);
    }

    // Recover the tree
    opHash = _payload.hash();
    (weight, imageHash) = recoverBranch(_payload, opHash, _signature[rindex:]);

    imageHash = LibOptim.fkeccak256(imageHash, bytes32(threshold));
    imageHash = LibOptim.fkeccak256(imageHash, bytes32(checkpoint));
    imageHash = LibOptim.fkeccak256(imageHash, bytes32(uint256(uint160(_checkpointer))));

    // If the snapshot is used, either the imageHash must match
    // or the checkpoint must be greater than the snapshot checkpoint
    if (snapshot.imageHash != bytes32(0) && snapshot.imageHash != imageHash && checkpoint <= snapshot.checkpoint) {
      revert UnusedSnapshot(snapshot);
    }
  }

    // @audit-issue VULNERABLE FUNCTION: recoverChained
  function recoverChained(
  // ^^^ VULNERABLE LINE ^^^
    Payload.Decoded memory _payload,
    // ^^^ VULNERABLE LINE ^^^
    address _checkpointer,
    // ^^^ VULNERABLE LINE ^^^
    Snapshot memory _snapshot,
    // ^^^ VULNERABLE LINE ^^^
    bytes calldata _signature
    // ^^^ VULNERABLE LINE ^^^
  ) internal view returns (uint256 threshold, uint256 weight, bytes32 imageHash, uint256 checkpoint, bytes32 opHash) {
  // ^^^ VULNERABLE LINE ^^^
    Payload.Decoded memory linkedPayload;
    // ^^^ VULNERABLE LINE ^^^
    linkedPayload.kind = Payload.KIND_CONFIG_UPDATE;
    // ^^^ VULNERABLE LINE ^^^

    uint256 rindex;
    // ^^^ VULNERABLE LINE ^^^
    uint256 prevCheckpoint = type(uint256).max;
    // ^^^ VULNERABLE LINE ^^^

    while (rindex < _signature.length) {
    // ^^^ VULNERABLE LINE ^^^
      uint256 nrindex;
      // ^^^ VULNERABLE LINE ^^^

      {
        uint256 sigSize;
        (sigSize, rindex) = _signature.readUint24(rindex);
        nrindex = sigSize + rindex;
      }

      address checkpointer = nrindex == _signature.length ? _checkpointer : address(0);

      if (prevCheckpoint == type(uint256).max) {
        (threshold, weight, imageHash, checkpoint, opHash) =
          recover(_payload, _signature[rindex:nrindex], true, checkpointer);
      } else {
        (threshold, weight, imageHash, checkpoint,) =
          recover(linkedPayload, _signature[rindex:nrindex], true, checkpointer);
      }

      if (weight < threshold) {
        revert LowWeightChainedSignature(_signature[rindex:nrindex], threshold, weight);
      }
      rindex = nrindex;

      if (_snapshot.imageHash == imageHash) {
        _snapshot.imageHash = bytes32(0);
      }

      if (checkpoint >= prevCheckpoint) {
        revert WrongChainedCheckpointOrder(checkpoint, prevCheckpoint);
      }

      linkedPayload.imageHash = imageHash;
      prevCheckpoint = checkpoint;
    }

    if (_snapshot.imageHash != bytes32(0) && checkpoint <= _snapshot.checkpoint) {
      revert UnusedSnapshot(_snapshot);
    }
  }

  function recoverBranch(
    Payload.Decoded memory _payload,
    bytes32 _opHash,
    bytes calldata _signature
  ) internal view returns (uint256 weight, bytes32 root) {
    unchecked {
      uint256 rindex;

      // Iterate until the image is completed
      while (rindex < _signature.length) {
        // The first byte is half flag (the top nibble)
        // and the second set of 4 bits can freely be used by the part

        // Read next item type
        uint256 firstByte;
        (firstByte, rindex) = _signature.readUint8(rindex);

        // The top 4 bits are the flag
        uint256 flag = (firstByte & 0xf0) >> 4;

        // Signature hash (0x00)
        if (flag == FLAG_SIGNATURE_HASH) {
          // Free bits layout:
          // - bits [3..0]: Weight (0000 = dynamic, 0001 = 1, ..., 1111 = 15)
          // We read 64 bytes for an ERC-2098 compact signature (r, yParityAndS).
          // The top bit of yParityAndS is yParity, the remaining 255 bits are s.

          uint8 addrWeight = uint8(firstByte & 0x0f);
          if (addrWeight == 0) {
            (addrWeight, rindex) = _signature.readUint8(rindex);
          }

          bytes32 r;
          bytes32 s;
          uint8 v;
          (r, s, v, rindex) = _signature.readRSVCompact(rindex);

          address addr = ecrecover(_opHash, v, r, s);

          weight += addrWeight;
          bytes32 node = _leafForAddressAndWeight(addr, addrWeight);
          root = root != bytes32(0) ? LibOptim.fkeccak256(root, node) : node;
          continue;
        }

        // Address (0x01) (without signature)
        if (flag == FLAG_ADDRESS) {
          // Free bits layout:
          // - bits [3..0]: Weight (0000 = dynamic, 0001 = 1, 0010 = 2, ...)

          // Read weight
          uint8 addrWeight = uint8(firstByte & 0x0f);
          if (addrWeight == 0) {
            (addrWeight, rindex) = _signature.readUint8(rindex);
          }

          // Read address
          address addr;
          (addr, rindex) = _signature.readAddress(rindex);

          // Compute the merkle root WITHOUT adding the weight
          bytes32 node = _leafForAddressAndWeight(addr, addrWeight);
          root = root != bytes32(0) ? LibOptim.fkeccak256(root, node) : node;
          continue;
        }

        // Signature ERC1271 (0x02)
        if (flag == FLAG_SIGNATURE_ERC1271) {
          // Free bits layout:
          // - XX00 : Signature size size (00 = 0 byte, 01 = 1 byte, 10 = 2 bytes, 11 = 3 bytes)
          // - 00XX : Weight (00 = dynamic, 01 = 1, 10 = 2, 11 = 3)

          // Read weight
          uint8 addrWeight = uint8(firstByte & 0x03);
          if (addrWeight == 0) {
            (addrWeight, rindex) = _signature.readUint8(rindex);
          }

          // Read signer
          address addr;
          (addr, rindex) = _signature.readAddress(rindex);

          // Read signature size
          uint256 sizeSize = uint8(firstByte & 0x0c) >> 2;
          uint256 size;
          (size, rindex) = _signature.readUintX(rindex, sizeSize);

          // Read dynamic size signature
          uint256 nrindex = rindex + size;

          // Call the ERC1271 contract to check if the signature is valid
          if (IERC1271(addr).isValidSignature(_opHash, _signature[rindex:nrindex]) != IERC1271_MAGIC_VALUE_HASH) {
            revert InvalidERC1271Signature(_opHash, addr, _signature[rindex:nrindex]);
          }
          rindex = nrindex;
          // Add the weight and compute the merkle root
          weight += addrWeight;
          bytes32 node = _leafForAddressAndWeight(addr, addrWeight);
          root = root != bytes32(0) ? LibOptim.fkeccak256(root, node) : node;
          continue;
        }

        // Node (0x03)
        if (flag == FLAG_NODE) {
          // Free bits left unused

          // Read node hash
          bytes32 node;
          (node, rindex) = _signature.readBytes32(rindex);
          root = root != bytes32(0) ? LibOptim.fkeccak256(root, node) : node;
          continue;
        }

        // Branch (0x04)
        if (flag == FLAG_BRANCH) {
          // Free bits layout:
          // - XXXX : Size size (0000 = 0 byte, 0001 = 1 byte, 0010 = 2 bytes, ...)

          // Read size
          uint256 sizeSize = uint8(firstByte & 0x0f);
          uint256 size;
          (size, rindex) = _signature.readUintX(rindex, sizeSize);

          // Enter a branch of the signature merkle tree
          uint256 nrindex = rindex + size;

          (uint256 nweight, bytes32 node) = recoverBranch(_payload, _opHash, _signature[rindex:nrindex]);
          rindex = nrindex;

          weight += nweight;
          root = LibOptim.fkeccak256(root, node);
          continue;
        }

        // Nested (0x06)
        if (flag == FLAG_NESTED) {
          // Unused free bits:
          // - XX00 : Weight (00 = dynamic, 01 = 1, 10 = 2, 11 = 3)
          // - 00XX : Threshold (00 = dynamic, 01 = 1, 10 = 2, 11 = 3)

          // Enter a branch of the signature merkle tree
          // but with an internal threshold and an external fixed weight
          uint256 externalWeight = uint8(firstByte & 0x0c) >> 2;
          if (externalWeight == 0) {
            (externalWeight, rindex) = _signature.readUint8(rindex);
          }

          uint256 internalThreshold = uint8(firstByte & 0x03);
          if (internalThreshold == 0) {
            (internalThreshold, rindex) = _signature.readUint16(rindex);
          }

          uint256 size;
          (size, rindex) = _signature.readUint24(rindex);
          uint256 nrindex = rindex + size;

          (uint256 internalWeight, bytes32 internalRoot) = recoverBranch(_payload, _opHash, _signature[rindex:nrindex]);
          rindex = nrindex;

          if (internalWeight >= internalThreshold) {
            weight += externalWeight;
          }

          bytes32 node = _leafForNested(internalRoot, internalThreshold, externalWeight);
          root = root != bytes32(0) ? LibOptim.fkeccak256(root, node) : node;
          continue;
        }

        // Subdigest (0x05)
        if (flag == FLAG_SUBDIGEST) {
          // Free bits left unused

          // A hardcoded always accepted digest
          // it pushes the weight to the maximum
          bytes32 hardcoded;
          (hardcoded, rindex) = _signature.readBytes32(rindex);
          if (hardcoded == _opHash) {
            weight = type(uint256).max;
          }

          bytes32 node = _leafForHardcodedSubdigest(hardcoded);
          root = root != bytes32(0) ? LibOptim.fkeccak256(root, node) : node;
          continue;
        }

        // Signature ETH Sign (0x07)
        if (flag == FLAG_SIGNATURE_ETH_SIGN) {
          // Free bits layout:
          // - bits [3..0]: Weight (0000 = dynamic, 0001 = 1, ..., 1111 = 15)
          // We read 64 bytes for an ERC-2098 compact signature (r, yParityAndS).
          // The top bit of yParityAndS is yParity, the remaining 255 bits are s.

          uint8 addrWeight = uint8(firstByte & 0x0f);
          if (addrWeight == 0) {
            (addrWeight, rindex) = _signature.readUint8(rindex);
          }

          bytes32 r;
          bytes32 s;
          uint8 v;
          (r, s, v, rindex) = _signature.readRSVCompact(rindex);

          address addr = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _opHash)), v, r, s);

          weight += addrWeight;
          bytes32 node = _leafForAddressAndWeight(addr, addrWeight);
          root = root != bytes32(0) ? LibOptim.fkeccak256(root, node) : node;
          continue;
        }

        // Signature Any address subdigest (0x08)
        // similar to subdigest, but allows for counter-factual payloads
        if (flag == FLAG_SIGNATURE_ANY_ADDRESS_SUBDIGEST) {
          // Free bits left unused

          // A hardcoded always accepted digest
          // it pushes the weight to the maximum
          bytes32 hardcoded;
          (hardcoded, rindex) = _signature.readBytes32(rindex);
          bytes32 anyAddressOpHash = _payload.hashFor(address(0));
          if (hardcoded == anyAddressOpHash) {
            weight = type(uint256).max;
          }

          bytes32 node = _leafForAnyAddressSubdigest(hardcoded);
          root = root != bytes32(0) ? LibOptim.fkeccak256(root, node) : node;
          continue;
        }

        // Signature Sapient (0x09)
        if (flag == FLAG_SIGNATURE_SAPIENT) {
          // Free bits layout:
          // - XX00 : Signature size size (00 = 0 byte, 01 = 1 byte, 10 = 2 bytes, 11 = 3 bytes)
          // - 00XX : Weight (00 = dynamic, 01 = 1, 10 = 2, 11 = 3)

          // Read signer and weight
          uint8 addrWeight = uint8(firstByte & 0x03);
          if (addrWeight == 0) {
            (addrWeight, rindex) = _signature.readUint8(rindex);
          }

          address addr;
          (addr, rindex) = _signature.readAddress(rindex);

          // Read signature size
          uint256 size;
          {
            uint256 sizeSize = uint8(firstByte & 0x0c) >> 2;
            (size, rindex) = _signature.readUintX(rindex, sizeSize);
          }

          // Read dynamic size signature
          uint256 nrindex = rindex + size;

          // Call the ERC1271 contract to check if the signature is valid
          bytes32 sapientImageHash = ISapient(addr).recoverSapientSignature(_payload, _signature[rindex:nrindex]);
          rindex = nrindex;

          // Add the weight and compute the merkle root
          weight += addrWeight;
          bytes32 node = _leafForSapient(addr, addrWeight, sapientImageHash);
          root = root != bytes32(0) ? LibOptim.fkeccak256(root, node) : node;
          continue;
        }

        // Signature Sapient Compact (0x0A)
        if (flag == FLAG_SIGNATURE_SAPIENT_COMPACT) {
          // Free bits layout:
          // - XX00 : Signature size size (00 = 0 byte, 01 = 1 byte, 10 = 2 bytes, 11 = 3 bytes)
          // - 00XX : Weight (00 = dynamic, 01 = 1, 10 = 2, 11 = 3)

          // Read signer and weight
          uint8 addrWeight = uint8(firstByte & 0x03);
          if (addrWeight == 0) {
            (addrWeight, rindex) = _signature.readUint8(rindex);
          }

          address addr;
          (addr, rindex) = _signature.readAddress(rindex);

          // Read signature size
          uint256 sizeSize = uint8(firstByte & 0x0c) >> 2;
          uint256 size;
          (size, rindex) = _signature.readUintX(rindex, sizeSize);

          // Read dynamic size signature
          uint256 nrindex = rindex + size;

          // Call the Sapient contract to check if the signature is valid
          bytes32 sapientImageHash =
            ISapientCompact(addr).recoverSapientSignatureCompact(_opHash, _signature[rindex:nrindex]);
          rindex = nrindex;
          // Add the weight and compute the merkle root
          weight += addrWeight;
          bytes32 node = _leafForSapient(addr, addrWeight, sapientImageHash);
          root = root != bytes32(0) ? LibOptim.fkeccak256(root, node) : node;
          continue;
        }

        revert InvalidSignatureFlag(flag);
      }
    }
  }

}