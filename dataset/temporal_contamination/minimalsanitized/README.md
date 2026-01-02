# Minimally Sanitized Temporal Contamination Dataset

This directory contains **minimally sanitized** versions of the temporal contamination contracts. These preserve protocol identifiers while removing explicit vulnerability hints.

## Contents

- `contracts/` - 50 Solidity contracts (ms_tc_001.sol - ms_tc_050.sol)
- `metadata/` - Corresponding JSON metadata files
- `index.json` - Dataset index with transformation details

## Transformations Applied

| Transformation | Example |
|----------------|---------|
| Remove "Vulnerable" prefix | `VulnerableNomadReplica` → `NomadReplica` |
| Remove vulnerability comments | Attack vectors, root cause blocks removed |
| Remove hint keywords | "exploit", "attack", "hack" in comments |
| Preserve protocol names | Nomad, Beanstalk, Curve, etc. retained |
| Fresh line markers | Sequential `/*LN-N*/` markers regenerated |

## Characteristics

| Aspect | Description |
|--------|-------------|
| Contract Names | Protocol names kept (e.g., `NomadReplica`) |
| Protocol Names | Preserved in code and identifiers |
| Comments | Normal comments kept, vulnerability hints removed |
| Line Markers | Fresh sequential `/*LN-N*/` markers |

## Use Case

Use this variant when you want to:
- Test if models can identify vulnerabilities without explicit hints
- Evaluate whether protocol name recognition aids vulnerability detection
- Compare detection rates between minimal and full sanitization

## Metadata

Each metadata file includes:
- `variant_type`: "minimalsanitized"
- `variant_parent_id`: Reference to original (e.g., "tc_001")
- `transformation`: Details of changes made
- `vulnerable_lines`: Empty (requires manual annotation for new line numbers)

## Source

Generated from: `dataset/temporal_contamination/original/`

## Regeneration

```bash
python strategies/sanitize/minimal_sanitize.py dataset/temporal_contamination/original dataset/temporal_contamination/minimalsanitized
```
