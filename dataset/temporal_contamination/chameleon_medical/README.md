# Chameleon Medical Theme - Temporal Contamination Dataset

This directory contains temporal contamination contracts transformed with the **medical theme** chameleon strategy. All user-defined identifiers have been renamed using healthcare/medical terminology.

## Contents

- `contracts/` - 46 Solidity contracts (ch_medical_tc_001.sol - ch_medical_tc_046.sol)
- `metadata/` - Corresponding JSON metadata files
- `index.json` - Dataset index with transformation details

## Transformations Applied

| Transformation | Description |
|----------------|-------------|
| Theme application | Medical/healthcare vocabulary |
| Identifier renaming | User-defined names → medical terminology |
| Preserve keywords | Solidity keywords and built-ins unchanged |
| Fresh line markers | Sequential `/*LN-N*/` markers regenerated |

## Example Renames (Medical Theme)

| Original | Medical Theme |
|----------|---------------|
| `MessageStatus` | `NotificationCondition` |
| `process` | `handle` |
| `deposit` | `admission` |
| `withdraw` | `discharge` |
| `vault` | `PatientRecordsVault` |
| `token` | `Credential` |
| `balance` | `allocation` |
| `pending` | `awaiting` |

## Characteristics

| Aspect | Description |
|--------|-------------|
| Contract Names | Mixed (some transformed, some preserved) |
| Function Names | Transformed using medical vocabulary |
| Variable Names | Transformed using medical vocabulary |
| Comments | None (inherited from nocomments source) |
| Line Markers | Fresh sequential `/*LN-N*/` markers |

## Coverage

Average transformation coverage: ~35% of identifiers renamed. Some identifiers don't have medical synonyms in the theme pool and are preserved.

## Use Case

Use this variant when you want to:
- Test if models rely on DeFi-specific terminology patterns
- Evaluate vulnerability detection with domain-shifted vocabulary
- Measure impact of identifier naming on detection accuracy
- Compare with other themes (gaming, social, abstract)

## Metadata

Each metadata file includes:
- `variant_type`: "chameleon_medical"
- `variant_parent_id`: Reference to nocomments (e.g., "nc_tc_001")
- `transformation`: Full details including rename_map and coverage
- `vulnerable_function`: Updated to reflect renamed function name
- `vulnerable_lines`: Line numbers of vulnerable code

## Transformation Chain

```
original (tc_*)
    → sanitized (sn_tc_*)
        → nocomments (nc_tc_*)
            → chameleon_medical (ch_medical_tc_*)
```

## Source

Generated from: `dataset/temporal_contamination/nocomments/`

## Regeneration

```bash
python strategies/chameleon/chameleon_tc.py --theme medical --source nocomments
```

## Other Available Themes

- `gaming` - Game/gaming terminology
- `social` - Social network terminology
- `abstract` - Abstract/generic terminology
- `resource` - Resource management terminology
