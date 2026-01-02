# Trojan Horse Variant

## Overview

The trojan variant implements the **Decoy Strategy** for testing vulnerability detection robustness. Each contract is a modified version of the original vulnerable contract with:

1. **Vulnerability documentation removed** - No comments explaining the exploit, root cause, or attack vector
2. **Distractor code added** - Fake security-related code that looks important but is harmless
3. **Original vulnerability preserved** - The actual exploitable code remains unchanged

## Purpose

This variant tests whether security auditors and automated tools can:
- Identify the real vulnerability without documentation hints
- Distinguish genuine security issues from red herrings
- Avoid being distracted by suspicious-looking but safe code

## Distractor Patterns

The following distractor types are used across the contracts:

| Pattern | Example | Effect |
|---------|---------|--------|
| Config tracking | `configVersion`, `configurationVersion` | Just stores numbers |
| Score/metrics | `globalActivityScore`, `userActivityScore` | Pure arithmetic, no security impact |
| Suspicious names | `unsafeCallBypass`, `vulnerableRouteCache` | Red herrings - don't bypass anything |
| Fake toggle functions | `toggleUnsafeCallMode()` | Only update counters |
| Emergency overrides | `emergencyConfigOverride()` | Just increment config version |
| View helpers | `getMetrics()`, `getUserStats()` | Read-only functions |

## Statistics

- **Total files**: 50
- **Total distractor elements**: 1,717
- **Distractor breakdown**:
  - Score/metric variables: 831
  - Suspicious-named variables: 587
  - Fake functions: 120
  - Config variables: 106
  - View helpers: 73

## File Naming

- Contracts: `tr_tc_XXX.sol`
- Metadata: `tr_tc_XXX.json`
- Parent variant: `tc_XXX` (original)

## Verification

All distractor code has been audited to confirm:
- No new vulnerabilities introduced
- No external calls in distractor code
- No reentrancy vectors
- No token transfer paths
- No access control bypasses

Only the original vulnerability is present in each contract.

## Usage

Compare model performance on:
- `original/` (with documentation) vs `trojan/` (without documentation, with distractors)

This measures how much models rely on documentation vs code analysis.
