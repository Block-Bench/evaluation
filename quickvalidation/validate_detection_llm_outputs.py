#!/usr/bin/env python3
"""
Validate detection outputs under results/detection/llm/**.

Goal: ensure we only evaluate on valid outputs, and surface:
- malformed JSON files (should be none if files load)
- parsing failures with non-empty raw_response (salvageable but not parsed)
- parsing failures with empty raw_response (true model failure / timeout / empty)
- missing required fields for successful parses
- suspicious values (unknown verdict, non-numeric line numbers, etc.)
- coverage summaries (counts per model/dataset/variant/tier)

Outputs:
- quickvalidation/detection_outputs/report.md
- quickvalidation/detection_outputs/all_issues.json
"""

from __future__ import annotations

import json
import re
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple


ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "results" / "detection" / "llm"


VERDICT_ALLOWED = {"vulnerable", "safe", "unknown", "none"}


def _read_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def _is_number(x: Any) -> bool:
    return isinstance(x, (int, float)) and not isinstance(x, bool)


def _path_parts(rel: Path) -> Tuple[str, str, str, str]:
    """
    Expected rel patterns:
      <model>/ds/tierN/d_ds_tN_xxx.json
      <model>/tc/<variant>/d_<sample>.json
    Returns (model, dataset, group, sample_id)
      dataset in {"ds","tc",...}
      group is tierN for ds; variant name for tc
    """
    parts = rel.parts
    model = parts[0] if len(parts) >= 1 else "unknown_model"
    dataset = parts[1] if len(parts) >= 2 else "unknown_dataset"
    group = "unknown_group"
    sample_id = rel.stem

    if dataset == "ds" and len(parts) >= 4:
        group = parts[2]  # tier1..tier4
        # file stem like d_ds_t1_001
        m = re.match(r"d_(.+)$", rel.stem)
        if m:
            sample_id = m.group(1)
    elif dataset == "tc" and len(parts) >= 4:
        group = parts[2]  # sanitized, nocomments, minimalsanitized, chameleon_medical, etc.
        m = re.match(r"d_(.+)$", rel.stem)
        if m:
            sample_id = m.group(1)
    else:
        # other datasets/variants we still scan generically
        if len(parts) >= 3:
            group = parts[2]

    return model, dataset, group, sample_id


@dataclass
class Issue:
    path: str
    model: str
    dataset: str
    group: str
    sample_id: str
    severity: str  # "error" | "warn"
    code: str
    message: str


def validate_one(path: Path) -> Tuple[Optional[Dict[str, Any]], List[Issue]]:
    rel = path.relative_to(BASE)
    model, dataset, group, sample_id = _path_parts(rel)
    issues: List[Issue] = []

    try:
        j = _read_json(path)
    except Exception as e:  # noqa: BLE001
        return None, [
            Issue(
                path=str(path),
                model=model,
                dataset=dataset,
                group=group,
                sample_id=sample_id,
                severity="error",
                code="MALFORMED_JSON",
                message=f"JSON parse failed: {e}",
            )
        ]

    # Basic required keys
    for k in ["sample_id", "prediction", "parsing"]:
        if k not in j:
            issues.append(
                Issue(str(path), model, dataset, group, sample_id, "error", "MISSING_KEY", f"Missing top-level key: {k}")
            )

    parsing = j.get("parsing") if isinstance(j.get("parsing"), dict) else {}
    success = bool(parsing.get("success", False))
    raw = parsing.get("raw_response", "")
    errs = parsing.get("errors", [])

    # Validate success vs raw response
    if not success:
        if isinstance(raw, str) and raw.strip():
            issues.append(
                Issue(
                    str(path),
                    model,
                    dataset,
                    group,
                    sample_id,
                    "warn",
                    "PARSE_FAILED_HAS_RAW",
                    "parsing.success=false but parsing.raw_response is non-empty (potentially salvageable).",
                )
            )
        else:
            issues.append(
                Issue(
                    str(path),
                    model,
                    dataset,
                    group,
                    sample_id,
                    "error",
                    "PARSE_FAILED_EMPTY_RAW",
                    "parsing.success=false and raw_response is empty (no usable model output).",
                )
            )

    # Validate prediction object if success
    pred = j.get("prediction") if isinstance(j.get("prediction"), dict) else {}
    if success:
        verdict = pred.get("verdict")
        if verdict not in VERDICT_ALLOWED:
            issues.append(
                Issue(
                    str(path),
                    model,
                    dataset,
                    group,
                    sample_id,
                    "error",
                    "BAD_VERDICT",
                    f"prediction.verdict must be one of {sorted(VERDICT_ALLOWED)}, got {verdict!r}",
                )
            )
        conf = pred.get("confidence")
        if conf is None or not _is_number(conf) or not (0.0 <= float(conf) <= 1.0):
            issues.append(
                Issue(
                    str(path),
                    model,
                    dataset,
                    group,
                    sample_id,
                    "warn",
                    "BAD_CONFIDENCE",
                    f"prediction.confidence should be numeric in [0,1], got {conf!r}",
                )
            )

        vulns = pred.get("vulnerabilities", [])
        if not isinstance(vulns, list):
            issues.append(
                Issue(
                    str(path),
                    model,
                    dataset,
                    group,
                    sample_id,
                    "error",
                    "BAD_VULNERABILITIES",
                    f"prediction.vulnerabilities should be a list, got {type(vulns).__name__}",
                )
            )
        else:
            for idx, v in enumerate(vulns):
                if not isinstance(v, dict):
                    issues.append(
                        Issue(
                            str(path),
                            model,
                            dataset,
                            group,
                            sample_id,
                            "error",
                            "BAD_VULN_ITEM",
                            f"prediction.vulnerabilities[{idx}] is not an object",
                        )
                    )
                    continue
                lines = v.get("vulnerable_lines", [])
                if lines is None:
                    continue
                if not isinstance(lines, list):
                    issues.append(
                        Issue(
                            str(path),
                            model,
                            dataset,
                            group,
                            sample_id,
                            "warn",
                            "BAD_VULN_LINES",
                            f"vulnerable_lines should be list, got {type(lines).__name__}",
                        )
                    )
                    continue
                for li in lines:
                    if not isinstance(li, int):
                        issues.append(
                            Issue(
                                str(path),
                                model,
                                dataset,
                                group,
                                sample_id,
                                "warn",
                                "NON_INT_LINE",
                                f"Non-integer vulnerable_lines entry: {li!r}",
                            )
                        )
                        break

    # Dataset-specific sanity
    if dataset == "ds":
        # should have numeric tier
        if "tier" not in j:
            issues.append(Issue(str(path), model, dataset, group, sample_id, "warn", "MISSING_TIER", "Missing tier field"))
        elif not isinstance(j.get("tier"), int):
            issues.append(
                Issue(str(path), model, dataset, group, sample_id, "warn", "BAD_TIER", f"tier should be int, got {j.get('tier')!r}")
            )

    # If parsing failed but there is a verdict in raw response, help flag this as salvageable
    if not success and isinstance(raw, str) and raw:
        has_verdict_word = ("\"verdict\"" in raw) or ("verdict" in raw.lower())
        if has_verdict_word:
            issues.append(
                Issue(
                    str(path),
                    model,
                    dataset,
                    group,
                    sample_id,
                    "warn",
                    "RAW_CONTAINS_VERDICT",
                    "Raw response appears to contain a verdict but parsing failed.",
                )
            )

    return j, issues


def main() -> int:
    out_dir = ROOT / "quickvalidation" / "detection_outputs"
    out_dir.mkdir(parents=True, exist_ok=True)

    files = sorted(BASE.glob("**/*.json"))
    counts = defaultdict(int)
    issue_list: List[Dict[str, Any]] = []

    # Expected coverage, derived from samples manifests (ground_truth files)
    expected: Dict[Tuple[str, str], set[str]] = {}  # (dataset, group) -> {sample_id}
    # DS tiers
    for tier_dir in sorted((ROOT / "samples" / "ds").glob("tier*/ground_truth")):
        tier = tier_dir.parent.name  # tier1..tier4
        ids = {p.stem for p in tier_dir.glob("*.json")}
        expected[("ds", tier)] = ids
    # TC variants (sanitized, nocomments, minimalsanitized, chameleon_medical, etc.)
    tc_root = ROOT / "samples" / "tc"
    if tc_root.exists():
        for gt_dir in sorted(tc_root.glob("*/ground_truth")):
            variant = gt_dir.parent.name
            ids = {p.stem for p in gt_dir.glob("*.json")}
            expected[("tc", variant)] = ids

    # Observed coverage in results
    observed_files: Dict[Tuple[str, str, str], set[str]] = defaultdict(set)  # (model,dataset,group)->sample_ids
    observed_parse_success: Dict[Tuple[str, str, str], int] = defaultdict(int)
    observed_parse_failed: Dict[Tuple[str, str, str], int] = defaultdict(int)
    observed_invalid_schema: Dict[Tuple[str, str, str], int] = defaultdict(int)

    # Coverage + quality
    for fp in files:
        rel = fp.relative_to(BASE)
        model, dataset, group, sample_id = _path_parts(rel)
        counts["files_total"] += 1
        counts[f"files_total::{dataset}"] += 1
        counts[f"files_total::{model}"] += 1
        counts[f"files_total::{model}::{dataset}::{group}"] += 1
        observed_files[(model, dataset, group)].add(sample_id)

        j, issues = validate_one(fp)
        if j is not None:
            parsing = j.get("parsing", {}) if isinstance(j.get("parsing"), dict) else {}
            if parsing.get("success") is True:
                counts["parsing_success"] += 1
                counts[f"parsing_success::{dataset}"] += 1
                observed_parse_success[(model, dataset, group)] += 1
            else:
                counts["parsing_failed"] += 1
                counts[f"parsing_failed::{dataset}"] += 1
                observed_parse_failed[(model, dataset, group)] += 1
                raw = parsing.get("raw_response", "")
                if isinstance(raw, str) and raw.strip():
                    counts["parsing_failed_has_raw"] += 1
                    counts[f"parsing_failed_has_raw::{dataset}"] += 1
                else:
                    counts["parsing_failed_empty_raw"] += 1
                    counts[f"parsing_failed_empty_raw::{dataset}"] += 1

        for iss in issues:
            counts[f"issues::{iss.severity}"] += 1
            counts[f"issues::{iss.severity}::{iss.code}"] += 1
            issue_list.append(iss.__dict__)
            if iss.severity == "error" and iss.code in {"BAD_VERDICT", "MISSING_KEY", "BAD_VULNERABILITIES", "BAD_VULN_ITEM"}:
                observed_invalid_schema[(model, dataset, group)] += 1

    (out_dir / "all_issues.json").write_text(json.dumps(issue_list, indent=2, sort_keys=False) + "\n", encoding="utf-8")

    # Markdown report
    lines: List[str] = []
    lines.append("# Detection LLM Output Validation Report\n\n")
    lines.append(f"- base: `{BASE}`\n")
    lines.append(f"- json files scanned: {counts['files_total']}\n\n")

    lines.append("## Parsing status\n\n")
    lines.append(f"- parsing.success=true: {counts.get('parsing_success', 0)}\n")
    lines.append(f"- parsing.success=false: {counts.get('parsing_failed', 0)}\n")
    lines.append(f"  - with non-empty raw_response: {counts.get('parsing_failed_has_raw', 0)}\n")
    lines.append(f"  - with empty raw_response: {counts.get('parsing_failed_empty_raw', 0)}\n\n")

    lines.append("## Issues (counts)\n\n")
    lines.append(f"- errors: {counts.get('issues::error', 0)}\n")
    lines.append(f"- warnings: {counts.get('issues::warn', 0)}\n\n")

    # Top issue codes
    lines.append("### Top issue codes\n\n")
    issue_code_counts = {k.split("issues::", 1)[1]: v for k, v in counts.items() if k.startswith("issues::") and k.count("::") == 2}
    for key, v in sorted(issue_code_counts.items(), key=lambda kv: kv[1], reverse=True)[:20]:
        severity, code = key.split("::", 1)
        lines.append(f"- {severity} `{code}`: {v}\n")

    # Dataset-level summary
    lines.append("\n## By dataset\n\n")
    for ds in ["ds", "tc"]:
        if counts.get(f"files_total::{ds}", 0) == 0:
            continue
        lines.append(f"### {ds}\n\n")
        lines.append(f"- files: {counts.get(f'files_total::{ds}', 0)}\n")
        lines.append(f"- parsing success: {counts.get(f'parsing_success::{ds}', 0)}\n")
        lines.append(f"- parsing failed: {counts.get(f'parsing_failed::{ds}', 0)}\n")
        lines.append(f"  - failed w/ raw: {counts.get(f'parsing_failed_has_raw::{ds}', 0)}\n")
        lines.append(f"  - failed empty raw: {counts.get(f'parsing_failed_empty_raw::{ds}', 0)}\n\n")

    lines.append("## Coverage (expected vs present)\n\n")
    lines.append("Expected sample sets are derived from `samples/**/ground_truth/*.json`.\n\n")
    # Summarize only where we have expectations and observed files.
    models = sorted({m for (m, _, _) in observed_files.keys()})
    for model in models:
        lines.append(f"### {model}\n\n")
        groups = sorted([(d, g) for (m, d, g) in observed_files.keys() if m == model])
        if not groups:
            lines.append("- no files found\n\n")
            continue
        for dataset, group in groups:
            present = observed_files[(model, dataset, group)]
            exp = expected.get((dataset, group))
            ok = observed_parse_success.get((model, dataset, group), 0)
            bad = observed_parse_failed.get((model, dataset, group), 0) + observed_invalid_schema.get((model, dataset, group), 0)
            lines.append(f"- **{dataset}/{group}**: present={len(present)}, parsing_ok={ok}, invalid_or_failed={bad}")
            if exp is None:
                lines.append(" (no expected set found)\n")
                continue
            missing = sorted(exp - present)
            extra = sorted(present - exp)
            lines.append(f", expected={len(exp)}, missing={len(missing)}, extra={len(extra)}\n")
            if missing:
                preview = ", ".join(missing[:10])
                suffix = " ..." if len(missing) > 10 else ""
                lines.append(f"  - missing sample_ids (first 10): {preview}{suffix}\n")
            if extra:
                preview = ", ".join(extra[:10])
                suffix = " ..." if len(extra) > 10 else ""
                lines.append(f"  - extra sample_ids (first 10): {preview}{suffix}\n")
        lines.append("\n")

    lines.append("## Next steps\n\n")
    lines.append("- If `PARSE_FAILED_HAS_RAW` > 0, consider running a salvage script to extract JSON from `raw_response`.\n")
    lines.append("- If `PARSE_FAILED_EMPTY_RAW` > 0, those samples need re-runs (no usable output).\n")
    lines.append("- If you see `BAD_VERDICT` with `prediction.verdict` missing, check for schema typos (e.g., `verifest` vs `verdict`) and fix/normalize before evaluation.\n")
    lines.append(f"- Full issue list: `{out_dir / 'all_issues.json'}`\n")

    (out_dir / "report.md").write_text("".join(lines), encoding="utf-8")

    # Exit non-zero if any errors
    return 0 if counts.get("issues::error", 0) == 0 else 2


if __name__ == "__main__":
    raise SystemExit(main())


