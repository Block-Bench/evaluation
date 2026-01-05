# Shapeshifter L3 - Temporal Contamination Dataset

This directory contains temporal contamination contracts transformed with **L3 Shapeshifter obfuscation**. This applies multi-level obfuscation combining hex identifier renaming and control flow complexity.

## Contents

- `contracts/` - 46 Solidity contracts (ss_tc_001.sol - ss_tc_046.sol)
- `metadata/` - Corresponding JSON metadata files
- `index.json` - Dataset index with transformation details

## Transformations Applied

| Level | Transformation | Description |
|-------|----------------|-------------|
| L1 | Tight formatting | All blank lines removed, K&R brace style |
| L2 | Identifier obfuscation | User-defined names → hex style (`_0x1a2b3c`) |
| L3 | Control flow | Always-true conditionals wrapping assignments |

## Obfuscation Details

### L2: Hex Identifier Style

All user-defined identifiers are renamed to hex-style names:

| Original | Obfuscated |
|----------|------------|
| `withdrawAll` | `_0x390062` |
| `deposit` | `_0x7248ad` |
| `balanceOf` | `_0x65ce0c` |
| `liquidityIndex` | `_0x477183` |

### L3: Control Flow Obfuscation

Simple local variable assignments are wrapped in always-true conditionals:

```solidity
// Before
acceptedRoot = _newRoot;

// After
if (block.timestamp > 0) { _0x7248ad = _0xd80623; }
```

Always-true conditions used:
- `true`
- `1 == 1`
- `block.timestamp > 0`
- `msg.sender != address(0) || msg.sender == address(0)`
- `gasleft() > 0`

## Preserved Elements

The following are NOT obfuscated:

| Category | Examples |
|----------|----------|
| Solidity keywords | `function`, `contract`, `require`, `if`, etc. |
| Built-in types | `uint256`, `address`, `bool`, `bytes32`, etc. |
| Built-in functions | `keccak256`, `sha256`, `ecrecover`, etc. |
| Global objects | `msg.sender`, `block.timestamp`, `tx.origin`, etc. |
| Standard interfaces | `IERC20`, `IERC721`, `Ownable`, etc. |
| Contract/struct names | Names starting with uppercase are preserved |

## Characteristics

| Aspect | Description |
|--------|-------------|
| Contract Names | Preserved (e.g., `BasicBridgeReplica`) |
| Function Names | Obfuscated to hex style |
| Variable Names | Obfuscated to hex style |
| Comments | None (inherited from nocomments source) |
| Blank Lines | All removed (tight formatting) |
| Line Markers | Fresh sequential `/*LN-N*/` markers |
| Control Flow | Augmented with always-true conditionals |

## Statistics

- **Total Samples**: 46
- **Average Identifiers Renamed**: 24.7 per contract
- **Obfuscation Intensity**: Medium

## Use Case

Use this variant when you want to:
- Test if models rely on meaningful identifier names
- Evaluate vulnerability detection with obfuscated code
- Measure impact of identifier obfuscation on detection accuracy
- Test resilience to control flow complexity
- Compare with chameleon (themed renaming) vs shapeshifter (hex renaming)

## Metadata

Each metadata file includes:
- `variant_type`: "shapeshifter_l3"
- `variant_parent_id`: Reference to nocomments (e.g., "nc_tc_001")
- `transformation`: Full details including rename_map
- `vulnerable_function`: Updated to reflect renamed function name
- `vulnerable_lines`: Line numbers of vulnerable code

## Transformation Chain

```
original (tc_*)
    → sanitized (sn_tc_*)
        → nocomments (nc_tc_*)
            → shapeshifter_l3 (ss_tc_*)
```

## Source

Generated from: `dataset/temporal_contamination/nocomments/`

## Regeneration

```bash
python strategies/shapeshifter/shapeshifter_tc.py all
```

For a single contract:
```bash
python strategies/shapeshifter/shapeshifter_tc.py one nc_tc_001
```

To preview without saving:
```bash
python strategies/shapeshifter/shapeshifter_tc.py preview nc_tc_001
```

## Other Available Variants

- `original/` - Original contracts with protocol identifiers
- `minimalsanitized/` - Minimal sanitization (hint removal)
- `sanitized/` - Full sanitization (generic names)
- `nocomments/` - All comments removed
- `chameleon_medical/` - Medical theme identifier renaming
