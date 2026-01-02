# Differential Variant (Fixed Contracts)

## Overview

The differential variant contains **fixed versions** of the original vulnerable contracts. Each contract has had its vulnerability properly patched using minimal, targeted fixes.

## Purpose

This variant enables:
- **Pairwise comparison**: Compare vulnerable (original) vs fixed (differential) versions
- **Fix verification**: Test if tools can identify that vulnerabilities are no longer present
- **Patch quality assessment**: Evaluate if proposed fixes are complete and correct

## Fix Categories

| Category | Description | Example |
|----------|-------------|---------|
| Initialization | Proper variable initialization | `acceptedRoot = keccak256("initial")` |
| Access Control | Admin/owner modifiers added | `onlyAdmin`, `onlyOwner` |
| Reentrancy Guard | Mutex lock pattern | `nonReentrant` modifier |
| Input Validation | Zero address/value checks | `require(addr != address(0))` |
| CEI Pattern | Check-Effects-Interactions order | State update before external call |
| Timelock | Delayed execution for sensitive ops | `ADMIN_TRANSFER_DELAY = 48 hours` |
| Virtual Reserves | Donation attack prevention | `VIRTUAL_RESERVE`, `trackedUnderlying` |

## File Naming

- Contracts: `df_tc_XXX.sol`
- Metadata: `df_tc_XXX.json`
- Parent variant: `tc_XXX` (original vulnerable version)

## Metadata Structure

Each metadata file includes:
- `is_vulnerable: false` - Indicates fixed version
- `transformation.fix_type` - Category of fix applied
- `transformation.fix_description` - Detailed explanation of changes
- `transformation.exact_changes` - Specific code modifications

## Key Fixes Applied

1. **df_tc_001** (Nomad Bridge): Added `acceptedRoot` initialization and zero-root validation
2. **df_tc_010** (The DAO): CEI pattern - state update before external call
3. **df_tc_042** (Hedgey): Access control on `addApprovedTokenLocker()`
4. **df_tc_046** (FixedFloat): Timelock applies to emergency withdrawals
5. **df_tc_048** (Sonne): Virtual reserves + tracked underlying balance
6. **df_tc_050** (Munchables): Two-step admin transfer with 48-hour timelock

## Verification

All fixes have been verified to:
- Address the root cause of the original vulnerability
- Include proper access control where required
- Initialize state variables in constructors
- Apply timelocks to sensitive operations
- Not introduce new vulnerabilities

## Usage

### Pair Comparison
```
original/tc_001.sol  (vulnerable)
differential/df_tc_001.sol  (fixed)
```

### Expected Results
- Vulnerability scanners should flag `tc_XXX` but NOT `df_tc_XXX`
- Code diff between pairs should highlight the minimal fix

## Statistics

- **Total files**: 50
- **Files with access control fixes**: 15
- **Files with CEI pattern fixes**: 12
- **Files with initialization fixes**: 8
- **Files with timelock additions**: 5
