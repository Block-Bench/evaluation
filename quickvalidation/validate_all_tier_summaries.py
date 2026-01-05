#!/usr/bin/env python3
"""
Batch-validate all `_tier_summary.json` files under results/detection_evaluation/llm-judge/.

For each summary:
- infer (judge_model, detector_model/tool, dataset, tier) from its path
- recompute aggregates from per-sample j_*.json + samples/**/ground_truth
- diff against expected summary

Outputs a consolidated report under quickvalidation/all_tier_summaries/.
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any, Dict, List, Tuple

from validate_tier_summary import _diff, _read_json, _round_floats, compute_group_summary_llm, compute_group_summary_tool, load_samples


ROOT = Path(__file__).resolve().parents[1]


SUMMARY_RE = re.compile(
    r"results/detection_evaluation/llm-judge/(?P<judge>[^/]+)/(?P<detector>[^/]+)/(?P<dataset>[^/]+)/(?P<tier>tier\d+)/_tier_summary\.json$"
)


def validate_one(summary_path: Path, tol: float) -> Dict[str, Any]:
    rel = summary_path.as_posix()
    m = SUMMARY_RE.search(rel)
    if not m:
        return {
            "path": str(summary_path),
            "status": "skipped",
            "reason": "unrecognized_path_pattern",
        }

    judge_model = m.group("judge")
    detector_model = m.group("detector")
    dataset = m.group("dataset")
    tier = m.group("tier")

    tier_dir = summary_path.parent
    expected = _read_json(summary_path)

    records, failures = load_samples(tier_dir, dataset=dataset, tier=tier)

    if isinstance(expected, dict) and "tool" in expected:
        recomputed = compute_group_summary_tool(
            records,
            tool=str(expected.get("tool")),
            judge_model=str(expected.get("judge_model", judge_model)),
            judge_family=expected.get("judge_family"),
            tier=tier,
            timestamp=expected.get("timestamp"),
            include_by_type=True,
        )
    else:
        recomputed = compute_group_summary_llm(
            records,
            detector_model=detector_model,
            judge_model=judge_model,
            tier=tier,
            timestamp=expected.get("timestamp"),
            include_by_type=True,
        )

    recomputed["sample_counts"]["failed_evaluations"] = len(failures)
    recomputed["sample_counts"]["successful_evaluations"] = len(records)
    recomputed["sample_counts"]["total"] = len(records) + len(failures)

    expected_norm = _round_floats(expected)
    recomputed_norm = _round_floats(recomputed)
    diffs = _diff(expected_norm, recomputed_norm, tol=tol)

    return {
        "path": str(summary_path),
        "judge_model": judge_model,
        "detector_model": detector_model,
        "dataset": dataset,
        "tier": tier,
        "records": len(records),
        "failures": [{"path": str(p), "reason": r} for p, r in failures],
        "status": "pass" if not diffs else "fail",
        "diff_count": len(diffs),
        "diffs": diffs,
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--tol", type=float, default=1e-9)
    ap.add_argument("--out_dir", default=str(ROOT / "quickvalidation" / "all_tier_summaries"))
    args = ap.parse_args()

    base = ROOT / "results" / "detection_evaluation" / "llm-judge"
    summaries = sorted(base.glob("**/_tier_summary.json"))

    results: List[Dict[str, Any]] = []
    for s in summaries:
        results.append(validate_one(s, tol=args.tol))

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    # Write full JSON
    (out_dir / "all_results.json").write_text(json.dumps(results, indent=2, sort_keys=False) + "\n", encoding="utf-8")

    # Write a concise markdown report
    passed = sum(1 for r in results if r.get("status") == "pass")
    failed = sum(1 for r in results if r.get("status") == "fail")
    skipped = sum(1 for r in results if r.get("status") == "skipped")

    lines: List[str] = []
    lines.append("# All Tier Summary Validation Report\n\n")
    lines.append(f"- total summaries: {len(results)}\n")
    lines.append(f"- pass: {passed}\n")
    lines.append(f"- fail: {failed}\n")
    lines.append(f"- skipped: {skipped}\n")
    lines.append(f"- tolerance: {args.tol}\n\n")

    if failed:
        lines.append("## Failures\n\n")
        for r in results:
            if r.get("status") != "fail":
                continue
            lines.append(f"- `{r['path']}` (diffs={r['diff_count']}, records={r.get('records')}, failures={len(r.get('failures', []))})\n")
            # show up to 10 diff keys
            diff_keys = sorted(list((r.get("diffs") or {}).keys()))[:10]
            for k in diff_keys:
                v = r["diffs"][k]
                lines.append(f"  - `{k}` expected={v.get('expected')} actual={v.get('actual')} delta={v.get('delta')}\n")
    else:
        lines.append("## Failures\n\n- None 🎉\n")

    if skipped:
        lines.append("\n## Skipped\n\n")
        for r in results:
            if r.get("status") == "skipped":
                lines.append(f"- `{r['path']}`: {r.get('reason')}\n")

    (out_dir / "report.md").write_text("".join(lines), encoding="utf-8")

    return 0 if failed == 0 else 2


if __name__ == "__main__":
    raise SystemExit(main())


