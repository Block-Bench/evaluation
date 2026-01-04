# DS Operations Scripts

Scripts for working with the DS (Difficulty Stratified) dataset in BlockBench.

## Scripts

### sample_ds_dataset.py

Reproducible stratified sampling script for selecting a subset of DS samples.

**Purpose**: Select a representative subset (default: 100) from the full DS dataset (235 samples) while ensuring:

- Coverage across all difficulty tiers
- Representation of major vulnerability types
- Reproducibility via fixed random seed

**Sampling Strategy**:

| Tier | Name           | Target | Rationale                         |
| ---- | -------------- | ------ | --------------------------------- |
| 1    | Textbook       | 20     | LLMs perform well, light sampling |
| 2    | Clear Audit    | 30     | Moderate difficulty               |
| 3    | Subtle Audit   | 35     | Harder cases, heavy sampling      |
| 4    | Multi-Contract | 15     | Hardest tier, take all available  |

**Usage**:

```bash
# Basic usage with defaults (seed=42, target=100)
python sample_ds_dataset.py --data-dir /path/to/raw/data --output sampled_ids.json

# Custom seed and target
python sample_ds_dataset.py --data-dir /path/to/raw/data --seed 123 --target 80

# Custom tier weights
python sample_ds_dataset.py --data-dir /path/to/raw/data \
    --tier-weights '{"1": 25, "2": 25, "3": 25, "4": 25}'

# List IDs only (no file output)
python sample_ds_dataset.py --data-dir /path/to/raw/data --list-only
```

**Output Format** (JSON):

```json
{
  "sampling_config": {
    "seed": 42,
    "target": 100,
    "tier_targets": {"1": 20, "2": 30, "3": 35, "4": 15},
    "data_dir": "/path/to/raw/data"
  },
  "total_selected": 100,
  "selected_ids": ["ds_001", "ds_002", ...]
}
```

**Reproducibility**: Running with the same `--seed` value will always produce identical results.

---

## Adding New Scripts

When adding new scripts to this folder:

1. Follow the naming convention: `<action>_ds_<purpose>.py`
2. Include argparse for CLI arguments
3. Add documentation to this README
4. Ensure reproducibility where applicable (use seeds for randomness)
