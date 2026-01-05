#!/usr/bin/env python3
"""
Quick validation utility for BlockBench tier aggregation summaries.

Validates that a tier's `_tier_summary.json` matches metrics recomputed from:
- per-sample judge outputs: results/detection_evaluation/llm-judge/<judge_model>/<detector_model>/<dataset>/<tier>/*.json
- per-sample ground truth:  samples/<dataset>/<tier>/ground_truth/<sample_id>.json

Outputs:
- recomputed_tier_summary.json
- diff.json (only fields that differ beyond tolerance)
- report.md (human-readable)
"""

from __future__ import annotations

import argparse
import json
import math
import os
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, Iterable, List, Mapping, Optional, Tuple


ROOT = Path(__file__).resolve().parents[1]


def _read_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def _safe_div(n: float, d: float) -> float:
    return float(n) / float(d) if d else 0.0


def _mean(xs: List[float]) -> float:
    return sum(xs) / len(xs) if xs else 0.0


def _pstdev(xs: List[float]) -> Optional[float]:
    if len(xs) <= 1:
        return None
    m = _mean(xs)
    return math.sqrt(sum((x - m) ** 2 for x in xs) / len(xs))


def _stdev(xs: List[float]) -> Optional[float]:
    if len(xs) <= 1:
        return None
    m = _mean(xs)
    return math.sqrt(sum((x - m) ** 2 for x in xs) / (len(xs) - 1))


def _round_floats(obj: Any, ndigits: int = 16) -> Any:
    # Keep deterministic JSON while not clobbering exact ratios too aggressively
    if isinstance(obj, float):
        return round(obj, ndigits)
    if isinstance(obj, list):
        return [_round_floats(x, ndigits) for x in obj]
    if isinstance(obj, dict):
        return {k: _round_floats(v, ndigits) for k, v in obj.items()}
    return obj


def _sum_dicts(dicts: Iterable[Mapping[str, int]], keys: Iterable[str]) -> Dict[str, int]:
    out: Dict[str, int] = {k: 0 for k in keys}
    for d in dicts:
        for k in keys:
            out[k] += int(d.get(k, 0))
    return out


def _type_match_bucket(type_match: Optional[str], found: bool) -> str:
    # Tier summaries use: exact, semantic, partial, wrong, not_mentioned
    if not found or not type_match:
        return "not_mentioned"
    tm = str(type_match).strip().lower()
    if tm in {"exact", "semantic", "partial", "wrong"}:
        return tm
    # Be conservative: unknown bucket -> not_mentioned
    return "not_mentioned"

def _type_match_bucket_tool(type_match: Optional[str]) -> str:
    # Tool summaries use same labels but often omit 0-count keys in output
    if not type_match:
        return "not_mentioned"
    tm = str(type_match).strip().lower()
    if tm in {"exact", "semantic", "partial", "wrong", "not_mentioned"}:
        return tm
    return "not_mentioned"


@dataclass(frozen=True)
class SampleRecord:
    sample_id: str
    judge_path: Path
    judge: Dict[str, Any]
    gt: Dict[str, Any]

    @property
    def is_vulnerable_gt(self) -> bool:
        return bool(self.gt.get("is_vulnerable", False))

    @property
    def said_vulnerable(self) -> bool:
        return bool(self.judge.get("overall_verdict", {}).get("said_vulnerable", False))

    @property
    def target_found(self) -> bool:
        return bool(self.judge.get("target_assessment", {}).get("found", False))

    @property
    def vuln_type(self) -> str:
        # Ground truth uses snake_case vulnerability_type
        return str(self.gt.get("vulnerability_type", "unknown"))

    @property
    def type_match(self) -> Optional[str]:
        return self.judge.get("target_assessment", {}).get("type_match")

    @property
    def rcir(self) -> Optional[float]:
        return self.judge.get("target_assessment", {}).get("root_cause_identification", {}).get("score")

    @property
    def ava(self) -> Optional[float]:
        return self.judge.get("target_assessment", {}).get("attack_vector_validity", {}).get("score")

    @property
    def fsv(self) -> Optional[float]:
        return self.judge.get("target_assessment", {}).get("fix_suggestion_validity", {}).get("score")

    @property
    def latency_ms(self) -> Optional[float]:
        return self.judge.get("judge_latency_ms")

    @property
    def summary(self) -> Dict[str, int]:
        return dict(self.judge.get("summary", {}))

    @property
    def verdict_correct_flag(self) -> Optional[bool]:
        # Tool outputs use overall_verdict.verdict_correct (precomputed)
        ov = self.judge.get("overall_verdict", {})
        if isinstance(ov, dict) and "verdict_correct" in ov:
            return bool(ov.get("verdict_correct"))
        return None

    @property
    def target_detected_flag(self) -> Optional[bool]:
        # Tool outputs use overall_verdict.target_detected
        ov = self.judge.get("overall_verdict", {})
        if isinstance(ov, dict) and "target_detected" in ov:
            return bool(ov.get("target_detected"))
        return None

    @property
    def latency_ms_any(self) -> Optional[float]:
        # LLM outputs: judge_latency_ms; tool outputs: latency_ms
        if self.latency_ms is not None:
            return self.latency_ms
        if "latency_ms" in self.judge:
            return self.judge.get("latency_ms")
        return None


def load_samples(
    tier_dir: Path,
    dataset: str,
    tier: str,
) -> Tuple[List[SampleRecord], List[Tuple[Path, str]]]:
    """
    Returns: (records, failures)
    failures: list of (path, reason)
    """
    failures: List[Tuple[Path, str]] = []
    records: List[SampleRecord] = []

    gt_dir = ROOT / "samples" / dataset / tier / "ground_truth"

    for p in sorted(tier_dir.glob("j_*.json")):
        try:
            judge = _read_json(p)
            sample_id = str(judge.get("sample_id") or "").strip()
            if not sample_id:
                failures.append((p, "missing sample_id"))
                continue
            gt_path = gt_dir / f"{sample_id}.json"
            if not gt_path.exists():
                failures.append((p, f"missing ground truth: {gt_path}"))
                continue
            gt = _read_json(gt_path)
            records.append(SampleRecord(sample_id=sample_id, judge_path=p, judge=judge, gt=gt))
        except Exception as e:  # noqa: BLE001 - validation script
            failures.append((p, f"exception: {e}"))

    return records, failures


def compute_group_summary_llm(
    records: List[SampleRecord],
    detector_model: str,
    judge_model: str,
    tier: str,
    timestamp: Optional[str] = None,
    include_by_type: bool = True,
) -> Dict[str, Any]:
    total = len(records)
    target_found_count = sum(1 for r in records if r.target_found)
    verdict_correct_count = sum(1 for r in records if r.said_vulnerable == r.is_vulnerable_gt)
    lucky_guess_count = sum(1 for r in records if (r.said_vulnerable == r.is_vulnerable_gt) and (not r.target_found))

    # Findings classifications: use per-sample summary buckets (most stable) and align with tier summary schema.
    summary_keys = [
        "total_findings",
        "target_matches",
        "partial_matches",
        "bonus_valid",
        "hallucinated",
        "mischaracterized",
        "design_choice",
        "out_of_scope",
        "security_theater",
        "informational",
    ]
    per_sample_summaries = [r.summary for r in records]
    summed = _sum_dicts(per_sample_summaries, summary_keys)

    # Tier summary uses "invalid" instead of "hallucinated" (and omits hallucinated).
    # In our pipeline, hallucinated findings are the "invalid" bucket.
    invalid = int(summed.get("hallucinated", 0))

    total_findings = int(summed.get("total_findings", 0))
    tp_findings = int(summed.get("target_matches", 0)) + int(summed.get("partial_matches", 0)) + int(summed.get("bonus_valid", 0))
    fp_findings = total_findings - tp_findings

    precision = _safe_div(tp_findings, total_findings)
    tdr = _safe_div(target_found_count, total)
    f1 = (2 * precision * tdr / (precision + tdr)) if (precision + tdr) else 0.0

    samples_with_bonus = sum(1 for r in records if int(r.summary.get("bonus_valid", 0)) > 0)

    # Type match distribution: bucket per found sample; if not found -> not_mentioned.
    type_dist = {k: 0 for k in ["exact", "semantic", "partial", "wrong", "not_mentioned"]}
    for r in records:
        b = _type_match_bucket(r.type_match, r.target_found)
        type_dist[b] += 1

    # Reasoning quality: only for target_found samples (per metrics.md).
    found_records = [r for r in records if r.target_found]
    rcir_scores = [float(r.rcir) for r in found_records if r.rcir is not None]
    ava_scores = [float(r.ava) for r in found_records if r.ava is not None]
    fsv_scores = [float(r.fsv) for r in found_records if r.fsv is not None]

    # Performance
    latencies = [float(r.latency_ms_any) for r in records if r.latency_ms_any is not None]

    out: Dict[str, Any] = {
        "detector": detector_model,
        "tier": tier,
        "judge_model": judge_model,
        "timestamp": timestamp,
        "sample_counts": {
            "total": total,
            "successful_evaluations": total,
            "failed_evaluations": 0,
        },
        "detection_metrics": {
            "target_found_count": target_found_count,
            "target_detection_rate": tdr,
            "miss_rate": 1.0 - tdr,
            "lucky_guess_count": lucky_guess_count,
            "lucky_guess_rate": _safe_div(lucky_guess_count, verdict_correct_count),
            "samples_with_bonus": samples_with_bonus,
            "ancillary_discovery_rate": _safe_div(samples_with_bonus, total),
            "verdict_correct_count": verdict_correct_count,
            "verdict_accuracy": _safe_div(verdict_correct_count, total),
            "total_findings": total_findings,
            "avg_findings_per_sample": _safe_div(total_findings, total),
            "true_positives": tp_findings,
            "false_positives": fp_findings,
            "precision": precision,
            "invalid_finding_rate": _safe_div(fp_findings, total_findings),
            "false_alarm_density": _safe_div(fp_findings, total),
            "f1_score": f1,
        },
        "quality_scores": {
            "avg_rcir": _mean(rcir_scores),
            "avg_ava": _mean(ava_scores),
            "avg_fsv": _mean(fsv_scores),
            # The existing tier summaries use *sample* standard deviation (n-1).
            "std_rcir": _stdev(rcir_scores),
            "std_ava": _stdev(ava_scores),
            "std_fsv": _stdev(fsv_scores),
            "count": len(found_records),
        },
        "classification_totals": {
            "target_matches": int(summed.get("target_matches", 0)),
            "partial_matches": int(summed.get("partial_matches", 0)),
            "bonus_valid": int(summed.get("bonus_valid", 0)),
            "invalid": invalid,
            "mischaracterized": int(summed.get("mischaracterized", 0)),
            "design_choice": int(summed.get("design_choice", 0)),
            "out_of_scope": int(summed.get("out_of_scope", 0)),
            "security_theater": int(summed.get("security_theater", 0)),
            "informational": int(summed.get("informational", 0)),
        },
        "type_match_distribution": type_dist,
        "performance": {
            "avg_latency_ms": _mean(latencies),
        },
    }

    if include_by_type:
        by_type: Dict[str, Any] = {}
        for vt in sorted({r.vuln_type for r in records}):
            subset = [r for r in records if r.vuln_type == vt]
            sub = compute_group_summary(
                subset,
                detector_model=detector_model,
                judge_model=judge_model,
                tier=tier,
                timestamp=timestamp,
                include_by_type=False,
            )
            # Keep only the per-type rollup fields used in the existing tier summaries
            by_type[vt] = {
                "total_samples": sub["sample_counts"]["total"],
                **sub["detection_metrics"],
                "classifications": sub["classification_totals"],
                "type_match_distribution": sub["type_match_distribution"],
                "quality_scores": sub["quality_scores"],
            }
        out["by_vulnerability_type"] = by_type

    return out


def compute_group_summary_tool(
    records: List[SampleRecord],
    tool: str,
    judge_model: str,
    judge_family: Optional[str],
    tier: str,
    timestamp: Optional[str] = None,
    include_by_type: bool = True,
    omit_zero_type_match_keys: bool = True,
) -> Dict[str, Any]:
    total = len(records)

    # Prefer explicit flags in tool outputs; fallback to generic fields if missing
    target_found_count = sum(
        1
        for r in records
        if (r.target_detected_flag if r.target_detected_flag is not None else r.target_found)
    )
    verdict_correct_count = sum(
        1
        for r in records
        if (r.verdict_correct_flag if r.verdict_correct_flag is not None else (r.said_vulnerable == r.is_vulnerable_gt))
    )

    target_found_rate = _safe_div(target_found_count, total)
    recall = target_found_rate

    summary_keys = [
        "total_findings",
        "target_matches",
        "partial_matches",
        "bonus_valid",
        "invalid",
        "mischaracterized",
        "design_choice",
        "out_of_scope",
        "security_theater",
        "informational",
    ]
    per_sample_summaries = [r.summary for r in records]
    summed = _sum_dicts(per_sample_summaries, summary_keys)

    total_findings = int(summed.get("total_findings", 0))
    tp_findings = int(summed.get("target_matches", 0)) + int(summed.get("partial_matches", 0)) + int(summed.get("bonus_valid", 0))
    fp_findings = int(summed.get("invalid", 0)) + int(summed.get("mischaracterized", 0)) + int(summed.get("security_theater", 0)) + int(summed.get("design_choice", 0))

    precision = _safe_div(tp_findings, (tp_findings + fp_findings))
    fp_rate = _safe_div(fp_findings, total_findings)

    # Tool summaries appear to use null when recall==0 or precision==0 (avoid misleading 0.0)
    f1: Optional[float]
    if precision == 0.0 or recall == 0.0:
        f1 = None
    else:
        f1 = 2 * precision * recall / (precision + recall)

    # Type match distribution: tool summaries usually omit zero keys
    type_dist_full = {k: 0 for k in ["not_mentioned", "exact", "semantic", "partial", "wrong"]}
    for r in records:
        tm = r.judge.get("target_assessment", {}).get("type_match")
        b = _type_match_bucket_tool(tm)
        type_dist_full[b] += 1
    type_dist = {k: v for k, v in type_dist_full.items() if (v != 0 or not omit_zero_type_match_keys)}
    # Preserve a stable key order similar to existing summaries
    preferred_order = ["not_mentioned", "semantic", "partial", "wrong", "exact"]
    type_dist = {k: type_dist[k] for k in preferred_order if k in type_dist}

    out: Dict[str, Any] = {
        "tool": tool,
        "tier": tier,
        "judge_model": judge_model,
        "judge_family": judge_family,
        "timestamp": timestamp,
        "sample_counts": {
            "total": total,
            "successful_evaluations": total,
            "failed_evaluations": 0,
        },
        "detection_metrics": {
            "target_found_count": target_found_count,
            "target_found_rate": target_found_rate,
            "recall": recall,
            "miss_rate": 1.0 - target_found_rate,
            "verdict_correct_count": verdict_correct_count,
            "verdict_accuracy": _safe_div(verdict_correct_count, total),
            "total_findings": total_findings,
            "avg_findings_per_sample": _safe_div(total_findings, total),
            "true_positives": tp_findings,
            "false_positives": fp_findings,
            "precision": precision,
            "fp_rate": fp_rate,
            "f1_score": f1,
        },
        "classification_totals": {
            "target_matches": int(summed.get("target_matches", 0)),
            "partial_matches": int(summed.get("partial_matches", 0)),
            "bonus_valid": int(summed.get("bonus_valid", 0)),
            "invalid": int(summed.get("invalid", 0)),
            "mischaracterized": int(summed.get("mischaracterized", 0)),
            "design_choice": int(summed.get("design_choice", 0)),
            "out_of_scope": int(summed.get("out_of_scope", 0)),
            "security_theater": int(summed.get("security_theater", 0)),
            "informational": int(summed.get("informational", 0)),
        },
        "type_match_distribution": type_dist,
    }

    if include_by_type:
        by_type: Dict[str, Any] = {}
        for vt in sorted({r.vuln_type for r in records}):
            subset = [r for r in records if r.vuln_type == vt]
            sub = compute_group_summary_tool(
                subset,
                tool=tool,
                judge_model=judge_model,
                judge_family=judge_family,
                tier=tier,
                timestamp=timestamp,
                include_by_type=False,
                omit_zero_type_match_keys=omit_zero_type_match_keys,
            )
            by_type[vt] = {
                "total_samples": sub["sample_counts"]["total"],
                **sub["detection_metrics"],
                "classifications": sub["classification_totals"],
            }
        out["by_vulnerability_type"] = by_type

    return out


def _diff(a: Any, b: Any, tol: float, path: str = "") -> Dict[str, Any]:
    """
    Returns a nested dict of differences: {path: {"expected": a, "actual": b}}.
    We treat 'a' as expected (existing) and 'b' as actual (recomputed).
    """
    diffs: Dict[str, Any] = {}

    if isinstance(a, dict) and isinstance(b, dict):
        keys = set(a.keys()) | set(b.keys())
        for k in sorted(keys):
            p = f"{path}.{k}" if path else k
            if k not in a:
                diffs[p] = {"expected": None, "actual": b[k], "note": "missing_in_expected"}
            elif k not in b:
                diffs[p] = {"expected": a[k], "actual": None, "note": "missing_in_recomputed"}
            else:
                diffs.update(_diff(a[k], b[k], tol, p))
        return diffs

    if isinstance(a, list) and isinstance(b, list):
        if len(a) != len(b):
            diffs[path] = {"expected": a, "actual": b, "note": "list_length_mismatch"}
            return diffs
        for i, (ai, bi) in enumerate(zip(a, b)):
            diffs.update(_diff(ai, bi, tol, f"{path}[{i}]"))
        return diffs

    # Numeric tolerances
    if isinstance(a, (int, float)) and isinstance(b, (int, float)):
        af = float(a)
        bf = float(b)
        if math.isfinite(af) and math.isfinite(bf):
            if abs(af - bf) > tol:
                diffs[path] = {"expected": a, "actual": b, "delta": bf - af}
            return diffs

    # Null handling for stdev with count<=1
    if a is None and b is None:
        return diffs

    if a != b:
        diffs[path] = {"expected": a, "actual": b}
    return diffs


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--judge_model", default="mimo-v2-flash")
    ap.add_argument("--detector_model", default="claude-opus-4-5")
    ap.add_argument("--dataset", default="ds")
    ap.add_argument("--tier", default="tier1")
    ap.add_argument("--tol", type=float, default=1e-9, help="absolute tolerance for float comparisons")
    ap.add_argument("--out_dir", default=str(ROOT / "quickvalidation" / "tier1"))
    args = ap.parse_args()

    tier_dir = ROOT / "results" / "detection_evaluation" / "llm-judge" / args.judge_model / args.detector_model / args.dataset / args.tier
    expected_path = tier_dir / "_tier_summary.json"
    if not expected_path.exists():
        raise SystemExit(f"Missing expected summary: {expected_path}")

    expected = _read_json(expected_path)
    records, failures = load_samples(tier_dir, dataset=args.dataset, tier=args.tier)

    # Reuse the expected timestamp for stable comparison
    if isinstance(expected, dict) and "tool" in expected:
        recomputed = compute_group_summary_tool(
            records,
            tool=str(expected.get("tool")),
            judge_model=str(expected.get("judge_model", args.judge_model)),
            judge_family=expected.get("judge_family"),
            tier=args.tier,
            timestamp=expected.get("timestamp"),
            include_by_type=True,
        )
    else:
        recomputed = compute_group_summary_llm(
            records,
            detector_model=args.detector_model,
            judge_model=args.judge_model,
            tier=args.tier,
            timestamp=expected.get("timestamp"),
            include_by_type=True,
        )

    # Populate failed_evaluations if any
    recomputed["sample_counts"]["failed_evaluations"] = len(failures)
    recomputed["sample_counts"]["successful_evaluations"] = len(records)
    recomputed["sample_counts"]["total"] = len(records) + len(failures)
    # Keep "total" in the rest of the metrics consistent with successful evaluations (like the pipeline does)
    # If you want a stricter interpretation, rerun after fixing failures.

    # Compare
    expected_norm = _round_floats(expected)
    recomputed_norm = _round_floats(recomputed)
    diffs = _diff(expected_norm, recomputed_norm, tol=args.tol)

    # Also compute sample stddevs for debugging if std fields are the only mismatches
    found_records = [r for r in records if r.target_found]
    rcir_scores = [float(r.rcir) for r in found_records if r.rcir is not None]
    ava_scores = [float(r.ava) for r in found_records if r.ava is not None]
    fsv_scores = [float(r.fsv) for r in found_records if r.fsv is not None]
    debug_std = {
        "std_sample_rcir": _stdev(rcir_scores),
        "std_sample_ava": _stdev(ava_scores),
        "std_sample_fsv": _stdev(fsv_scores),
        "std_population_rcir": _pstdev(rcir_scores),
        "std_population_ava": _pstdev(ava_scores),
        "std_population_fsv": _pstdev(fsv_scores),
    }

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    (out_dir / "recomputed_tier_summary.json").write_text(
        json.dumps(recomputed_norm, indent=2, sort_keys=False) + "\n", encoding="utf-8"
    )
    (out_dir / "diff.json").write_text(json.dumps(diffs, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    # Human report
    lines: List[str] = []
    lines.append("# Tier Summary Validation Report\n")
    lines.append(f"- expected: `{expected_path}`\n")
    lines.append(f"- recomputed: `{out_dir / 'recomputed_tier_summary.json'}`\n")
    lines.append(f"- files loaded: {len(records)}\n")
    lines.append(f"- failures: {len(failures)}\n")
    if failures:
        lines.append("\n## Failures\n")
        for p, reason in failures:
            lines.append(f"- `{p}`: {reason}\n")
    lines.append("\n## Diff Summary\n")
    if not diffs:
        lines.append("- PASS: recomputed summary matches expected within tolerance.\n")
    else:
        lines.append(f"- FAIL: {len(diffs)} differing fields (tol={args.tol}).\n")
        # Show up to first 50 diffs
        lines.append("\n### First differences\n")
        for i, (k, v) in enumerate(sorted(diffs.items())[:50]):
            lines.append(f"- `{k}`: expected={v.get('expected')} actual={v.get('actual')} delta={v.get('delta')}\n")
        if rcir_scores or ava_scores or fsv_scores:
            lines.append("\n### Stddev debug (if mismatches are std_* only)\n")
            lines.append(f"- sample vs population stddevs: {debug_std}\n")
    (out_dir / "report.md").write_text("".join(lines), encoding="utf-8")

    # Exit code suitable for CI
    return 0 if not diffs else 2


if __name__ == "__main__":
    raise SystemExit(main())


