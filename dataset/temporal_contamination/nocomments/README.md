# No-Comments Temporal Contamination Dataset

This directory contains temporal contamination contracts with **all comments removed**. This forces models to rely purely on code structure without any textual hints.

## Contents

- `contracts/` - 46 Solidity contracts (nc_tc_001.sol - nc_tc_046.sol)
- `metadata/` - Corresponding JSON metadata files
- `index.json` - Dataset index with transformation details

## Transformations Applied

| Transformation | Description |
|----------------|-------------|
| Remove single-line comments | All `//` comments removed |
| Remove multi-line comments | All `/* */` comments removed |
| Remove NatSpec comments | All `/** */` documentation removed |
| Clean up blank lines | Excessive blank lines reduced |
| Fresh line markers | Sequential `/*LN-N*/` markers regenerated |

## Characteristics

| Aspect | Description |
|--------|-------------|
| Contract Names | Generic (e.g., `BasicBridgeReplica`) - inherited from sanitized |
| Protocol Names | Removed - inherited from sanitized |
| Comments | **None** - all comments stripped |
| Line Markers | Fresh sequential `/*LN-N*/` markers |

## Example

Before (sanitized):
```solidity
/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/
/*LN-4*/ contract BasicBridgeReplica {
/*LN-5*/     // Message status enum
```

After (nocomments):
```solidity
/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/
/*LN-3*/ contract BasicBridgeReplica {
/*LN-4*/
```

## Use Case

Use this variant when you want to:
- Test pure code-based vulnerability detection
- Eliminate any textual hints from comments
- Evaluate if models can identify vulnerabilities from structure alone
- Compare with sanitized to measure impact of comments on detection

## Metadata

Each metadata file includes:
- `variant_type`: "nocomments"
- `variant_parent_id`: Reference to sanitized (e.g., "sn_tc_001")
- `transformation`: Details including comments_removed count
- `vulnerable_lines`: Line numbers of vulnerable code

## Transformation Chain

```
original (tc_*)
    → sanitized (sn_tc_*)
        → nocomments (nc_tc_*)
```

## Source

Generated from: `dataset/temporal_contamination/sanitized/`

## Regeneration

```bash
python strategies/nocomments/nocomments_tc.py
```
