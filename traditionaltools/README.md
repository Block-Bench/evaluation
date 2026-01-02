# Traditional Security Analysis Tools

## Setup

Both tools are installed in separate virtual environments to avoid dependency conflicts.

## Slither (v0.11.3)

Static analysis framework for Solidity.

```bash
# Activate
source traditionaltools/slither/venv/bin/activate

# Run on a contract
slither path/to/contract.sol

# Or use directly
./traditionaltools/slither/venv/bin/slither path/to/contract.sol
```

**Detects**: Reentrancy, unchecked return values, variable shadowing, uninitialized storage, etc.

## Mythril (v0.24.8)

Symbolic execution tool for EVM bytecode analysis.

```bash
# Activate
source traditionaltools/mythril/venv/bin/activate

# Run on a contract
myth analyze path/to/contract.sol

# Or use directly
./traditionaltools/mythril/venv/bin/myth analyze path/to/contract.sol
```

**Detects**: Integer overflow/underflow, reentrancy, unprotected selfdestruct, etc.

## Notes

- Slither requires `solc` (Solidity compiler) - install via `solc-select`
- Mythril may need specific solc versions for different contracts
- Both tools work best on non-obfuscated code (original contracts, not transformed variants)
