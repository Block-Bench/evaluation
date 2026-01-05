# Manual Aggregation Validation Guide

This guide explains how to manually validate the aggregated metrics in our evaluation results.

## Key Principle: Micro-Average (Sample-Weighted)

All our aggregate metrics use **micro-averaging**, where each sample counts equally regardless of which tier it belongs to. This is the statistically correct approach when tiers have different sample sizes.

**Correct:**
```
Overall TDR = Total Found Across All Tiers / Total Samples Across All Tiers
```

**Incorrect (do NOT use):**
```
Overall TDR = (Tier1_TDR + Tier2_TDR + Tier3_TDR + Tier4_TDR) / 4
```

The incorrect method gives equal weight to each tier, artificially inflating results when smaller tiers have higher performance.

---

## Sample Sizes by Tier

| Tier | Samples |
|------|---------|
| Tier 1 | 20 |
| Tier 2 | 37 |
| Tier 3 | 30 |
| Tier 4 | 13 |
| **Total** | **100** |

---

## How to Validate Each Metric

### 1. Target Detection Rate (TDR)

**Source files:**
```
results/detection_evaluation/llm-judge/{judge}/{detector}/ds/tier{1-4}/_tier_summary.json
```

**Fields to extract:**
- `detection_metrics.target_found_count`
- `sample_counts.total`

**Calculation:**
```
TDR = SUM(target_found_count for all tiers) / SUM(total samples for all tiers)
```

**Example for mimo-v2-flash / claude-opus-4-5:**
```
Tier 1: 20 found / 20 samples
Tier 2: 30 found / 37 samples
Tier 3: 25 found / 30 samples
Tier 4: 12 found / 13 samples
-----------------------------------
Total:  87 found / 100 samples = 0.87 (87%)
```

### 2. Verdict Accuracy

**Fields to extract:**
- `detection_metrics.verdict_correct_count`
- `sample_counts.total`

**Calculation:**
```
Verdict Accuracy = SUM(verdict_correct_count) / SUM(total samples)
```

### 3. Precision

**Fields to extract:**
- `detection_metrics.true_positives`
- `detection_metrics.false_positives`

**Calculation:**
```
Precision = SUM(true_positives) / (SUM(true_positives) + SUM(false_positives))
```

### 4. F1 Score

**Calculation:**
```
F1 = 2 * (Precision * TDR) / (Precision + TDR)
```

Note: TDR serves as recall in our context (did we find the target vulnerability?).

### 5. Quality Scores (RCIR, AVA, FSV)

**Fields to extract:**
- `quality_scores.avg_rcir`
- `quality_scores.avg_ava`
- `quality_scores.avg_fsv`
- `quality_scores.count`

**Calculation:**
These are weighted averages by the count of samples with quality scores:
```
Overall RCIR = SUM(avg_rcir * count) / SUM(count)
```

### 6. Classification Totals

**Fields to extract:**
- `classification_totals.target_matches`
- `classification_totals.partial_matches`
- `classification_totals.bonus_valid`
- `classification_totals.hallucinated`
- `classification_totals.mischaracterized`
- etc.

**Calculation:**
Simply sum across all tiers:
```
Total Target Matches = SUM(target_matches for all tiers)
```

### 7. Type Match Distribution

**Fields to extract:**
- `type_match_distribution.exact`
- `type_match_distribution.semantic`
- `type_match_distribution.partial`
- `type_match_distribution.wrong`
- `type_match_distribution.not_mentioned`

**Calculation:**
Simply sum across all tiers.

---

## Validation Shell Commands

### Quick validation for a specific judge/detector:

```bash
# Replace {judge} and {detector} with actual values
judge="mimo-v2-flash"
detector="claude-opus-4-5"

echo "=== Manual TDR Calculation ==="
total_found=0
total_samples=0
for tier in 1 2 3 4; do
    file="results/detection_evaluation/llm-judge/$judge/$detector/ds/tier${tier}/_tier_summary.json"
    found=$(jq '.detection_metrics.target_found_count' "$file")
    samples=$(jq '.sample_counts.total' "$file")
    echo "Tier $tier: $found / $samples"
    total_found=$((total_found + found))
    total_samples=$((total_samples + samples))
done
echo "Total: $total_found / $total_samples"
echo "TDR = $(echo "scale=4; $total_found / $total_samples" | bc)"
```

### Validate against aggregated file:

```bash
judge="mimo-v2-flash"
detector="claude-opus-4-5"

echo "=== Aggregated Value ==="
jq ".by_detector[\"$detector\"].detection_metrics.target_detection_rate" \
    "results/detection_evaluation/ds_aggregated/all_metrics_${judge}.json"
```

---

## Common Mistakes to Avoid

1. **Averaging tier TDRs**: Do NOT compute `(TDR1 + TDR2 + TDR3 + TDR4) / 4`. This gives incorrect results when tiers have different sample sizes.

2. **Ignoring sample weights**: Quality scores must be weighted by the number of samples with valid scores, not simple averages.

3. **Mixing judges**: Each judge's results must be aggregated separately. Do not combine results across different judges.

4. **Double counting**: Ensure each sample is counted exactly once across all tiers.

---

## File Locations

| Data | Path |
|------|------|
| Tier summaries | `results/detection_evaluation/llm-judge/{judge}/{detector}/ds/tier{N}/_tier_summary.json` |
| Aggregated results | `results/detection_evaluation/ds_aggregated/all_metrics_{judge}.json` |
| By vulnerability type | `results/detection_evaluation/ds_aggregated/by_vulnerability_{judge}.json` |

---

## Verification Checklist

- [ ] Total samples across all tiers equals 100 (20+37+30+13)
- [ ] TDR = total_found / 100, not average of tier TDRs
- [ ] Precision uses sum of TP and FP, not average of tier precisions
- [ ] Quality scores are weighted by sample count
- [ ] Classification totals are simple sums
- [ ] Each judge is aggregated independently
