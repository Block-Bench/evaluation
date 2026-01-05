# Fully Sanitized Temporal Contamination Dataset

This directory contains **fully sanitized** versions of the temporal contamination contracts. All identifying information including protocol names has been replaced with generic alternatives.

## Contents

- `contracts/` - 50 Solidity contracts (sn_tc_001.sol - sn_tc_050.sol)
- `metadata/` - Corresponding JSON metadata files
- `index.json` - Dataset index with transformation details

## Transformations Applied

| Transformation | Example |
|----------------|---------|
| Remove "Vulnerable" prefix | `VulnerableNomadReplica` → `BasicBridgeReplica` |
| Replace protocol names | `Nomad` → `Bridge`, `Curve` → `Stable` |
| Remove vulnerability comments | All hint comments removed |
| Sanitize identifiers | `curvePool` → `stablePool` |
| Fresh line markers | Sequential `/*LN-N*/` markers regenerated |

## Protocol Name Mappings

| Original | Sanitized |
|----------|-----------|
| Nomad | Bridge |
| Beanstalk | Governance |
| Curve | Stable |
| Compound | Lending |
| Yearn/Harvest | Yield |
| Ronin | GameBridge |
| Kyber | Dex |
| And 40+ more... | See index.json |

## Characteristics

| Aspect | Description |
|--------|-------------|
| Contract Names | Generic (e.g., `BasicBridgeReplica`, `BasicPool`) |
| Protocol Names | Replaced with generic alternatives |
| Comments | Normal comments kept, all hints removed |
| Line Markers | Fresh sequential `/*LN-N*/` markers |

## Use Case

Use this variant when you want to:
- Test pure vulnerability detection without any identifying information
- Evaluate if models rely on memorized exploit patterns
- Measure baseline detection capabilities

## Metadata

Each metadata file includes:
- `variant_type`: "sanitized"
- `variant_parent_id`: Reference to original (e.g., "tc_001")
- `transformation`: Full details including all renames
- `vulnerable_lines`: Empty (requires manual annotation for new line numbers)

Note: Metadata retains original descriptions for judge evaluation but contract code has no protocol references.

## Source

Generated from: `dataset/temporal_contamination/original/`

## Regeneration

```bash
python strategies/sanitize/sanitize_originals.py
```
