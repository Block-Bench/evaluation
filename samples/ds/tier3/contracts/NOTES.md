# Tier 3 Contract Notes

## ds_t3_022_mythril.sol

This is a Mythril-compatible version of `ds_t3_022.sol` (Parity Wallet).

**Original Issue:** The original contract uses solc 0.4.9 with deprecated assembly syntax (`invalidJumpLabel`) that Mythril cannot parse. Mythril's minimum supported solc version is 0.4.11.

**Changes made for Mythril compatibility:**
1. Changed pragma from `0.4.9` to `^0.4.11`
2. Replaced `sha3()` with `keccak256()`
3. Replaced `throw` with `revert()`
4. Replaced `suicide()` with `selfdestruct()`
5. Rewrote the `create()` function assembly to use `require()` instead of `jumpi(invalidJumpLabel, ...)`
6. Added `pop()` around `delegatecall` in Wallet constructor to balance stack

**Vulnerability preserved:** The access_control vulnerability (`initWallet` is public with no access control) is intact.

**Usage:** For Mythril analysis, use `ds_t3_022_mythril.sol`. For Slither analysis, use the original `ds_t3_022.sol`.
