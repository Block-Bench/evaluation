# TODO: Front-Running Detection Test

## Purpose
Add additional front-running samples to confirm if LLMs have a gap in detecting front-running vulnerabilities.

## Samples to Add (all tier 2, nocomments versions)

| ID | Contract | Function | Source |
|----|----------|----------|--------|
| nc_ds_156 | ERC20.sol | approve (line 110) | raw/data/nocomments/contracts/nc_ds_156.sol |
| nc_ds_157 | FindThisHash.sol | solve (line 17) | raw/data/nocomments/contracts/nc_ds_157.sol |
| nc_ds_158 | eth_tx_order_dependence_minimal.sol | setReward (line 23) | raw/data/nocomments/contracts/nc_ds_158.sol |
| nc_ds_159 | odds_and_evens.sol | play (line 25) | raw/data/nocomments/contracts/nc_ds_159.sol |

## Front-Running Patterns

1. **ds_156 (ERC20 approve)** - Classic approve race condition
   - Attack: When user changes approval from X to Y, attacker front-runs to use X, then uses Y after
   - Result: Attacker gets X + Y instead of just Y

2. **ds_157 (FindThisHash)** - Hash puzzle front-running
   - Attack: Attacker sees solution in mempool, submits with higher gas
   - Result: Attacker steals the 1000 ETH reward

3. **ds_158 (EthTxOrderDependenceMinimal)** - Reward claiming race
   - Attack: Attacker sees valid claimReward submission, front-runs it
   - Result: Attacker claims the reward instead of legitimate submitter

4. **ds_159 (OddsAndEvens)** - Gambling game front-running
   - Attack: Player 2 sees Player 1's number in mempool, chooses winning number
   - Result: Player 2 always wins

## Current Findings
- ds_207 (TokenExchange) front-running: 0/6 models detected it
- These 4 samples are more obvious patterns (tier 2 vs tier 3)
- Testing these will confirm if front-running is a systematic gap

## Commands to Add Later
```bash
# Copy contracts
cp raw/data/nocomments/contracts/nc_ds_156.sol samples/contracts/
cp raw/data/nocomments/contracts/nc_ds_157.sol samples/contracts/
cp raw/data/nocomments/contracts/nc_ds_158.sol samples/contracts/
cp raw/data/nocomments/contracts/nc_ds_159.sol samples/contracts/

# Copy ground truth
cp raw/data/nocomments/metadata/nc_ds_156.json samples/ground_truth/
cp raw/data/nocomments/metadata/nc_ds_157.json samples/ground_truth/
cp raw/data/nocomments/metadata/nc_ds_158.json samples/ground_truth/
cp raw/data/nocomments/metadata/nc_ds_159.json samples/ground_truth/

# Update manifest.json to include new samples
```
