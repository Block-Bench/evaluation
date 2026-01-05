# DS Tier Summary Issues (LLM-Judge Aggregation)

Audience: **Paul (developer)**  
Author: Dave (via Cursor agent)  
Date: 2026-01-05

## Context

We validated the stored DS tier aggregation files:

- Location: `results/detection_evaluation/llm-judge/**/ds/tier*/_tier_summary.json`
- Source of truth for recomputation:
  - per-sample judge outputs: `.../ds/tier*/j_*.json`
  - DS ground truth: `samples/ds/tier*/ground_truth/*.json`

Validation is done by recomputing the full tier summary from the `j_*.json` files and diffing against `_tier_summary.json`.

## TL;DR Result

- **Total tier summaries checked**: 86
- **PASS (exact match)**: 69
- **FAIL (mismatched)**: **17** ⚠️

**Status Update (2026-01-05):**
- ✅ **2 fixed**: `codestral/deepseek-v3-2/ds/tier1`, `mimo-v2-flash/grok-4-fast/ds/tier1`
- ❌ **17 REMAINING FAILURES** — **These have NOT been fixed and still need attention**

Artifacts:

- Consolidated report: `quickvalidation/all_tier_summaries/report.md`
- Full JSON results (all diffs): `quickvalidation/all_tier_summaries/all_results.json`
- Validator scripts:
  - Batch: `quickvalidation/validate_all_tier_summaries.py`
  - Single: `quickvalidation/validate_tier_summary.py`

## What “FAIL” typically means

Failures are overwhelmingly **count mismatches**, not float tolerance issues.

Most common diff families (count of diff keys across all failing summaries):

- **by_vulnerability_type**: 195
- **detection_metrics**: 144
- **classification_totals**: 20
- **sample_counts**: 16
- **quality_scores**: 12
- **type_match_distribution**: 9
- **performance**: 2

This strongly suggests that at least some stored `_tier_summary.json` files are **stale** relative to the current `j_*.json` contents, and/or some tier summaries were generated with **different inclusion/exclusion rules** than what the per-sample folder currently contains.

## ✅ Fixed (2)

The following tier summaries have been **fixed** and now pass validation:

1. ✅ `results/detection_evaluation/llm-judge/codestral/deepseek-v3-2/ds/tier1/_tier_summary.json`
2. ✅ `results/detection_evaluation/llm-judge/mimo-v2-flash/grok-4-fast/ds/tier1/_tier_summary.json`

---

## ❌ Remaining Failures (17) — **NOT FIXED**

**These 17 `_tier_summary.json` files still do NOT match recomputation and require attention:**

1. `results/detection_evaluation/llm-judge/codestral/gemini-3-pro/ds/tier1/_tier_summary.json`
2. `results/detection_evaluation/llm-judge/codestral/gpt-5.2/ds/tier3/_tier_summary.json`
3. `results/detection_evaluation/llm-judge/codestral/grok-4-fast/ds/tier2/_tier_summary.json`
4. `results/detection_evaluation/llm-judge/codestral/grok-4-fast/ds/tier3/_tier_summary.json`
5. `results/detection_evaluation/llm-judge/codestral/llama-4-maverick/ds/tier2/_tier_summary.json`
6. `results/detection_evaluation/llm-judge/codestral/llama-4-maverick/ds/tier3/_tier_summary.json`
7. `results/detection_evaluation/llm-judge/codestral/qwen3-coder-plus/ds/tier3/_tier_summary.json`
8. `results/detection_evaluation/llm-judge/mimo-v2-flash/claude-opus-4-5/ds/tier3/_tier_summary.json`
9. `results/detection_evaluation/llm-judge/mimo-v2-flash/deepseek-v3-2/ds/tier2/_tier_summary.json`
10. `results/detection_evaluation/llm-judge/mimo-v2-flash/deepseek-v3-2/ds/tier3/_tier_summary.json`
11. `results/detection_evaluation/llm-judge/mimo-v2-flash/gpt-5.2/ds/tier3/_tier_summary.json`
12. `results/detection_evaluation/llm-judge/mimo-v2-flash/grok-4-fast/ds/tier3/_tier_summary.json`
13. `results/detection_evaluation/llm-judge/mimo-v2-flash/grok-4-fast/ds/tier4/_tier_summary.json`
14. `results/detection_evaluation/llm-judge/mimo-v2-flash/llama-4-maverick/ds/tier3/_tier_summary.json`
15. `results/detection_evaluation/llm-judge/mimo-v2-flash/qwen3-coder-plus/ds/tier1/_tier_summary.json`
16. `results/detection_evaluation/llm-judge/mimo-v2-flash/qwen3-coder-plus/ds/tier2/_tier_summary.json`
17. `results/detection_evaluation/llm-judge/mimo-v2-flash/qwen3-coder-plus/ds/tier4/_tier_summary.json`

## Representative mismatch signatures (high-signal)

The failures tend to look like one of:

- **Per-vulnerability sample counts don’t align** (e.g., `by_vulnerability_type.<x>.total_samples` differs), causing a cascade in rates.
- **Per-vulnerability confusion counts** differ (e.g., `target_matches`, `false_positives`, etc.), indicating either:
  - the tier summary was computed from a different set of `j_*.json`, or
  - the tier summary code applied filtering (failed evals / invalid JSON / missing fields) that no longer matches current files.

Examples (first few diff keys per file — **all from remaining failures**):

- `codestral/gemini-3-pro/ds/tier1`: weak_randomness classification totals differ by 1 target match.
- `codestral/grok-4-fast/ds/tier2`: `dos.total_samples` expected 3 vs actual 4.
- `mimo-v2-flash/grok-4-fast/ds/tier4`: `inflation_attack.total_findings` expected 1 vs actual 0.
- `codestral/gpt-5.2/ds/tier3`: unchecked_call aggregates disagree (target_matches, false_positives).

For exact keys/values, see `quickvalidation/all_tier_summaries/all_results.json` (each record has `diffs{}`).

## Notes about DS dataset assumptions (important)

We checked DS ground truth and confirmed **all DS samples are vulnerable** (`is_vulnerable=true` across ds tiers).  
So for DS:

- `verdict_correct_count` should effectively correspond to `said_vulnerable == true` counts (no true negatives exist).
- “lucky guess” definitions matter a lot; the validator was aligned to match stored summaries:
  - **Lucky guess** = correct vulnerable verdict **AND** `target_assessment.found == false` **AND** `bonus_valid == 0`
  - **Lucky guess rate** computed over **total samples** in DS tiers.

The above matches the tier1 validation we did earlier and eliminated a large class of false failures.

## How to reproduce locally (Paul)

From repo root (`evaluation/`):

```bash
python3 quickvalidation/validate_all_tier_summaries.py \
  --out_dir quickvalidation/all_tier_summaries \
  --tol 1e-9
```

Then inspect:

- `quickvalidation/all_tier_summaries/report.md`
- `quickvalidation/all_tier_summaries/all_results.json`

## Recommended next steps

1. **Determine whether the remaining 17 failing `_tier_summary.json` files are stale**
   - Re-run the official aggregation pipeline for those exact directories and compare.
   - **Note**: 2 have been fixed (see above), but 17 still require regeneration.

2. **Audit “failed_evaluations” logic**
   - At least one failing case appears to mark `failed_evaluations=1` while the directory currently contains 20 readable `j_*.json` files.
   - If failures are tracked elsewhere (e.g., separate error logs), the tier summary generator should either:
     - regenerate from the current on-disk `j_*.json`, or
     - carry along explicit “excluded sample list” in `_tier_summary.json` for auditability.

3. **Standardize invariants**
   - Ensure that the generator uses a single consistent schema for:
     - per-type totals (`total_samples`)
     - classification counting source (prefer `summary` section in each `j_*.json` to avoid double counting)
     - how “bonus_valid” affects lucky-guess accounting

If you want, I can also generate a "focused" per-file debug bundle for each of the **remaining 17 failing summaries** (list of included samples + recomputed vs expected subtrees) to speed up pinpointing exactly which sample(s) cause the mismatch.

---

## ⚠️ Action Required

**The 17 remaining failures listed above have NOT been fixed and still need to be addressed.** The validation script can be re-run at any time to verify fixes:

```bash
python3 quickvalidation/validate_all_tier_summaries.py \
  --out_dir quickvalidation/all_tier_summaries \
  --tol 1e-9
```



