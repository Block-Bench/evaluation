# Original Temporal Contamination Dataset

This directory contains the **original** annotated smart contracts from the temporal contamination subset. These contracts are based on real-world exploits and contain full vulnerability documentation.

## Contents

- `contracts/` - 50 Solidity contracts (tc_001.sol - tc_050.sol)
- `metadata/` - Corresponding JSON metadata files
- `index.json` - Dataset index with statistics

## Characteristics

| Aspect | Description |
|--------|-------------|
| Contract Names | Include "Vulnerable" prefix (e.g., `VulnerableNomadReplica`) |
| Protocol Names | Preserved (e.g., Nomad, Beanstalk, Curve) |
| Comments | Full vulnerability documentation including attack vectors, root causes |
| Line Markers | `/*LN-N*/` format for stable line references |

## Use Case

These originals serve as the **source of truth** for vulnerability information and are used to generate sanitized variants. They should NOT be used directly for model evaluation as they contain explicit vulnerability hints.

## Line Markers

Each line is prefixed with `/*LN-N*/` markers (1-indexed) to provide stable line references that persist across transformations. The `vulnerable_lines` field in metadata references these markers.

## Variants

Two sanitized variants are generated from these originals:

1. **minimalsanitized/** - Removes "Vulnerable" prefix and hint comments, keeps protocol names
2. **sanitized/** - Full sanitization including protocol name replacement

## Regeneration

To regenerate sanitized variants from these originals:

```bash
# Minimal sanitization
python strategies/sanitize/minimal_sanitize.py dataset/temporal_contamination/original dataset/temporal_contamination/minimalsanitized

# Full sanitization
python strategies/sanitize/sanitize_originals.py
```
