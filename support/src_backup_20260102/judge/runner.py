"""
Main Judge Runner - orchestrates the evaluation pipeline.
"""

import asyncio
import json
from pathlib import Path
from datetime import datetime
from typing import Optional

from .config import JudgeModelConfig, JudgeConfig
from .client import BaseJudgeClient
from .mistral_judge import MistralJudgeClient
from .schemas import (
    JudgeInput,
    JudgeOutput,
    SampleMetrics,
    AggregatedMetrics,
    GroundTruthForJudge,
    PromptType,
    FullEvaluationReport,
)
from .metrics import compute_sample_metrics
from .aggregator import compute_aggregated_metrics


class JudgeRunner:
    """Main orchestrator for judge evaluations"""

    def __init__(
        self,
        judge_model_config: JudgeModelConfig,
        output_dir: Path,
        max_concurrency: int = 5,
        checkpoint_every: int = 10
    ):
        self.judge_config = judge_model_config
        self.output_dir = Path(output_dir)
        self.max_concurrency = max_concurrency
        self.checkpoint_every = checkpoint_every

        # Initialize judge client
        self.judge = self._create_judge_client(judge_model_config)

        # Create output directories
        self.output_dir.mkdir(parents=True, exist_ok=True)
        (self.output_dir / "judge_outputs").mkdir(exist_ok=True)
        (self.output_dir / "sample_metrics").mkdir(exist_ok=True)
        (self.output_dir / "metrics_history").mkdir(exist_ok=True)

    def _create_judge_client(self, config: JudgeModelConfig) -> BaseJudgeClient:
        """Factory method to create appropriate judge client"""
        if config.provider in ["mistral", "vertex_mistral"]:
            return MistralJudgeClient(config)
        else:
            raise ValueError(f"Unsupported judge provider: {config.provider}")

    async def run(
        self,
        inputs: list[JudgeInput],
        ground_truths: dict[str, GroundTruthForJudge],  # keyed by sample_id
        resume: bool = True
    ) -> tuple[list[JudgeOutput], list[SampleMetrics], AggregatedMetrics]:
        """
        Run judge evaluation on all inputs.

        Args:
            inputs: List of JudgeInput objects
            ground_truths: Dict mapping sample_id to GroundTruth
            resume: Whether to resume from checkpoint

        Returns:
            - List of JudgeOutput (raw judge results)
            - List of SampleMetrics (computed per-sample metrics)
            - AggregatedMetrics (final aggregated metrics)
        """
        print(f"Starting judge evaluation on {len(inputs)} samples")
        print(f"Judge model: {self.judge_config.name}")
        print(f"Max concurrency: {self.max_concurrency}")
        print(f"Output directory: {self.output_dir}")

        # Load checkpoint if resuming
        completed_ids = set()
        if resume:
            completed_ids = self._load_checkpoint()
            print(f"Found {len(completed_ids)} already completed samples")

        remaining_inputs = [i for i in inputs if self._get_input_key(i) not in completed_ids]
        print(f"Remaining samples to evaluate: {len(remaining_inputs)}")

        # Load existing outputs
        judge_outputs = self._load_existing_outputs() if resume else []

        # Process in batches
        total_cost = sum(o.judge_cost_usd for o in judge_outputs)
        errors = []

        for i in range(0, len(remaining_inputs), self.checkpoint_every):
            batch = remaining_inputs[i:i + self.checkpoint_every]

            print(f"\nProcessing batch {i // self.checkpoint_every + 1} ({len(batch)} samples)...")

            # Evaluate batch with concurrency
            batch_outputs = await self._evaluate_batch(batch, errors)

            # Save outputs
            for output in batch_outputs:
                self._save_judge_output(output)
                judge_outputs.append(output)
                total_cost += output.judge_cost_usd

            # Update checkpoint
            self._save_checkpoint([self._get_output_key(o) for o in judge_outputs])

            print(f"Progress: {len(judge_outputs)}/{len(inputs)} | Cost: ${total_cost:.4f}")

        # Compute per-sample metrics
        print("\nComputing per-sample metrics...")
        sample_metrics = []
        gt_list = []

        for output in judge_outputs:
            gt = ground_truths.get(output.sample_id)
            if gt:
                metrics = compute_sample_metrics(output, gt)
                sample_metrics.append(metrics)
                gt_list.append(gt)
                self._save_sample_metrics(metrics)

        # Compute aggregated metrics
        print("Computing aggregated metrics...")
        aggregated = compute_aggregated_metrics(sample_metrics, gt_list)

        # Save final reports
        self._save_aggregated_metrics(aggregated)
        self._save_summary_report(aggregated, judge_outputs, total_cost)

        print(f"\n{'='*60}")
        print(f"Evaluation Complete!")
        print(f"  Samples: {len(judge_outputs)}")
        print(f"  Errors: {len(errors)}")
        print(f"  Total Cost: ${total_cost:.4f}")
        print(f"  Results: {self.output_dir}")
        print(f"{'='*60}")

        if errors:
            print(f"\nErrors encountered:")
            for sample_id, error in errors[:5]:
                print(f"  {sample_id}: {error}")
            if len(errors) > 5:
                print(f"  ... and {len(errors) - 5} more")

        return judge_outputs, sample_metrics, aggregated

    async def _evaluate_batch(
        self,
        batch: list[JudgeInput],
        errors: list
    ) -> list[JudgeOutput]:
        """Evaluate a batch with concurrency control"""
        semaphore = asyncio.Semaphore(self.max_concurrency)
        results = []

        async def evaluate_one(input: JudgeInput) -> Optional[JudgeOutput]:
            async with semaphore:
                try:
                    key = f"{input.transformed_id}×{input.prompt_type.value}"
                    print(f"  Evaluating {key}...", end=" ", flush=True)
                    output = await self.judge.evaluate_with_retry(input)
                    status = "TARGET" if output.target_assessment.found else "no-target"
                    print(f"OK ({status})")
                    return output
                except Exception as e:
                    print(f"ERROR: {e}")
                    errors.append((input.sample_id, str(e)))
                    return None

        outputs = await asyncio.gather(*[evaluate_one(i) for i in batch])
        return [o for o in outputs if o is not None]

    def _get_input_key(self, input: JudgeInput) -> str:
        """Get unique key for a judge input"""
        return f"{input.transformed_id}_{input.prompt_type.value}"

    def _get_output_key(self, output: JudgeOutput) -> str:
        """Get unique key for a judge output"""
        return f"{output.transformed_id}_{output.prompt_type.value}"

    def _load_checkpoint(self) -> set[str]:
        """Load completed sample IDs from checkpoint"""
        checkpoint_file = self.output_dir / "checkpoint.json"
        if checkpoint_file.exists():
            with open(checkpoint_file) as f:
                data = json.load(f)
                return set(data.get("completed", []))
        return set()

    def _save_checkpoint(self, completed_ids: list[str]):
        """Save checkpoint"""
        checkpoint_file = self.output_dir / "checkpoint.json"
        with open(checkpoint_file, "w") as f:
            json.dump({
                "completed": completed_ids,
                "timestamp": datetime.now().isoformat()
            }, f, indent=2)

    def _load_existing_outputs(self) -> list[JudgeOutput]:
        """Load any existing judge outputs"""
        outputs = []
        output_dir = self.output_dir / "judge_outputs"
        for file in output_dir.glob("j_*.json"):
            try:
                with open(file) as f:
                    data = json.load(f)
                    # Convert string enum values back
                    data["prompt_type"] = PromptType(data["prompt_type"])
                    outputs.append(JudgeOutput(**data))
            except Exception as e:
                print(f"Warning: Failed to load {file}: {e}")
        return outputs

    def _save_judge_output(self, output: JudgeOutput):
        """Save a single judge output"""
        filename = f"j_{output.transformed_id}_{output.prompt_type.value}.json"
        file_path = self.output_dir / "judge_outputs" / filename
        with open(file_path, "w") as f:
            json.dump(output.model_dump(mode="json"), f, indent=2)

    def _save_sample_metrics(self, metrics: SampleMetrics):
        """Save per-sample metrics"""
        filename = f"m_{metrics.transformed_id}_{metrics.prompt_type.value}.json"
        file_path = self.output_dir / "sample_metrics" / filename
        with open(file_path, "w") as f:
            json.dump(metrics.model_dump(mode="json"), f, indent=2)

    def _save_aggregated_metrics(self, metrics: AggregatedMetrics):
        """Save aggregated metrics (current + historical snapshot)"""
        # Save current/latest
        file_path = self.output_dir / "aggregated_metrics.json"
        with open(file_path, "w") as f:
            json.dump(metrics.model_dump(mode="json"), f, indent=2)

        # Save historical snapshot
        self._save_metrics_history(metrics)

    def _save_metrics_history(self, metrics: AggregatedMetrics):
        """Save timestamped snapshot of metrics for historical tracking"""
        timestamp = datetime.now().strftime("%Y-%m-%dT%H-%M-%S")
        n_samples = metrics.total_samples

        # Create snapshot with metadata
        snapshot = {
            "snapshot_timestamp": datetime.now().isoformat(),
            "sample_count": n_samples,
            "metrics": metrics.model_dump(mode="json")
        }

        # Save with descriptive filename
        filename = f"{timestamp}_n{n_samples}.json"
        file_path = self.output_dir / "metrics_history" / filename
        with open(file_path, "w") as f:
            json.dump(snapshot, f, indent=2)

        print(f"  Saved metrics snapshot: {filename}")

    def _save_summary_report(
        self,
        metrics: AggregatedMetrics,
        outputs: list[JudgeOutput],
        total_cost: float
    ):
        """Generate and save human-readable summary report"""
        d = metrics.detection
        tf = metrics.target_finding
        fq = metrics.finding_quality
        rq = metrics.reasoning_quality
        ta = metrics.type_accuracy
        cal = metrics.calibration
        comp = metrics.composite

        report = f"""# Judge Evaluation Report

Generated: {datetime.now().isoformat()}
Judge Model: {self.judge_config.name}
Total Cost: ${total_cost:.4f}

## Summary

- Total Samples Evaluated: {metrics.total_samples}
- Vulnerable Samples: {metrics.vulnerable_samples}
- Safe Samples: {metrics.safe_samples}

## Tier 1: Detection Performance

| Metric | Value |
|--------|-------|
| Accuracy | {d['accuracy']:.3f} |
| Precision | {d['precision']:.3f} |
| Recall | {d['recall']:.3f} |
| F1 Score | {d['f1']:.3f} |
| F2 Score | {d['f2']:.3f} |
| False Positive Rate | {d['fpr']:.3f} |
| False Negative Rate | {d['fnr']:.3f} |

Confusion Matrix: TP={d['tp']}, TN={d['tn']}, FP={d['fp']}, FN={d['fn']}

## Tier 2: Target Finding

| Metric | Value |
|--------|-------|
| Target Detection Rate | {tf['target_detection_rate']:.3f} |
| Lucky Guess Rate | {tf['lucky_guess_rate']:.3f} |
| Bonus Discovery Rate | {tf['bonus_discovery_rate']:.3f} |

Target Found: {tf['target_found_count']}, Lucky Guesses: {tf['lucky_guess_count']}

## Tier 3: Finding Quality

| Metric | Value |
|--------|-------|
| Finding Precision | {fq['finding_precision']:.3f} |
| Hallucination Rate | {fq['hallucination_rate']:.3f} |
| Over-Flagging Score | {fq['over_flagging_score']:.2f} |
| Avg Findings per Sample | {fq['avg_findings_per_sample']:.2f} |

Total: {fq['total_findings']}, Valid: {fq['valid_findings']}, Hallucinated: {fq['hallucinated_findings']}

## Tier 4: Reasoning Quality

(Computed only for samples where target vulnerability was found)

| Metric | Mean | Std |
|--------|------|-----|
| Root Cause (RCIR) | {f"{rq['mean_rcir']:.3f}" if rq['mean_rcir'] is not None else 'N/A'} | {f"{rq['std_rcir']:.3f}" if rq['std_rcir'] is not None else 'N/A'} |
| Attack Vector (AVA) | {f"{rq['mean_ava']:.3f}" if rq['mean_ava'] is not None else 'N/A'} | {f"{rq['std_ava']:.3f}" if rq['std_ava'] is not None else 'N/A'} |
| Fix Validity (FSV) | {f"{rq['mean_fsv']:.3f}" if rq['mean_fsv'] is not None else 'N/A'} | {f"{rq['std_fsv']:.3f}" if rq['std_fsv'] is not None else 'N/A'} |

Samples with reasoning scores: {rq['n_samples_with_reasoning']}

## Tier 5: Type Accuracy

| Metric | Value |
|--------|-------|
| Exact Match Rate | {ta['exact_match_rate']:.3f} |
| Semantic Match Rate | {ta['semantic_match_rate']:.3f} |
| Partial Match Rate | {ta['partial_match_rate']:.3f} |

## Tier 6: Calibration

| Metric | Value |
|--------|-------|
| ECE | {f"{cal['ece']:.3f}" if cal['ece'] is not None else 'N/A'} |
| MCE | {f"{cal['mce']:.3f}" if cal['mce'] is not None else 'N/A'} |
| Overconfidence Rate | {f"{cal['overconfidence_rate']:.3f}" if cal['overconfidence_rate'] is not None else 'N/A'} |
| Brier Score | {f"{cal['brier_score']:.3f}" if cal['brier_score'] is not None else 'N/A'} |

## Tier 7: Composite Scores

| Metric | Value |
|--------|-------|
| **Security Understanding Index (SUI)** | **{comp['sui']:.3f}** |
| True Understanding Score | {comp['true_understanding_score']:.3f} |
| Lucky Guess Indicator | {comp['lucky_guess_indicator']:.3f} |

### SUI Components

"""
        for component, value in comp.get('sui_components', {}).items():
            if value is not None:
                report += f"- {component}: {value:.3f}\n"

        # Add per-prompt-type breakdown if available
        if metrics.by_prompt_type:
            report += "\n## Per-Prompt-Type Breakdown\n\n"
            for pt, pt_metrics in metrics.by_prompt_type.items():
                report += f"### {pt.upper()}\n\n"
                report += f"- Accuracy: {pt_metrics['detection']['accuracy']:.3f}\n"
                report += f"- Target Detection: {pt_metrics['target_finding']['target_detection_rate']:.3f}\n"
                report += f"- Finding Precision: {pt_metrics['finding_quality']['finding_precision']:.3f}\n"
                report += f"- SUI: {pt_metrics['composite']['sui']:.3f}\n\n"

        # Save report
        report_path = self.output_dir / "summary_report.md"
        with open(report_path, "w") as f:
            f.write(report)

    def generate_trend_report(self) -> Optional[str]:
        """Generate a trend report from metrics history"""
        history_dir = self.output_dir / "metrics_history"
        if not history_dir.exists():
            return None

        # Load all historical snapshots
        snapshots = []
        for file in sorted(history_dir.glob("*.json")):
            try:
                with open(file) as f:
                    snapshots.append(json.load(f))
            except Exception as e:
                print(f"Warning: Failed to load {file}: {e}")

        if len(snapshots) < 2:
            return None  # Need at least 2 points for trend

        # Extract key metrics over time
        report = f"""# Metrics Trend Report

Generated: {datetime.now().isoformat()}
Total Snapshots: {len(snapshots)}

## Sample Count Progression

| Timestamp | Samples | SUI | Target Det. | Finding Prec. | Halluc. Rate |
|-----------|---------|-----|-------------|---------------|--------------|
"""
        for snap in snapshots:
            ts = snap["snapshot_timestamp"][:19]  # Truncate to readable
            n = snap["sample_count"]
            m = snap["metrics"]
            sui = m["composite"]["sui"]
            tdr = m["target_finding"]["target_detection_rate"]
            fp = m["finding_quality"]["finding_precision"]
            hr = m["finding_quality"]["hallucination_rate"]
            report += f"| {ts} | {n} | {sui:.3f} | {tdr:.3f} | {fp:.3f} | {hr:.3f} |\n"

        # Compare first vs last
        first = snapshots[0]["metrics"]
        last = snapshots[-1]["metrics"]

        report += f"""
## Change Analysis (First → Latest)

| Metric | First (n={snapshots[0]['sample_count']}) | Latest (n={snapshots[-1]['sample_count']}) | Delta |
|--------|-------|--------|-------|
| SUI | {first['composite']['sui']:.3f} | {last['composite']['sui']:.3f} | {last['composite']['sui'] - first['composite']['sui']:+.3f} |
| Target Detection | {first['target_finding']['target_detection_rate']:.3f} | {last['target_finding']['target_detection_rate']:.3f} | {last['target_finding']['target_detection_rate'] - first['target_finding']['target_detection_rate']:+.3f} |
| Lucky Guess Rate | {first['target_finding']['lucky_guess_rate']:.3f} | {last['target_finding']['lucky_guess_rate']:.3f} | {last['target_finding']['lucky_guess_rate'] - first['target_finding']['lucky_guess_rate']:+.3f} |
| Finding Precision | {first['finding_quality']['finding_precision']:.3f} | {last['finding_quality']['finding_precision']:.3f} | {last['finding_quality']['finding_precision'] - first['finding_quality']['finding_precision']:+.3f} |
| Hallucination Rate | {first['finding_quality']['hallucination_rate']:.3f} | {last['finding_quality']['hallucination_rate']:.3f} | {last['finding_quality']['hallucination_rate'] - first['finding_quality']['hallucination_rate']:+.3f} |
| Accuracy | {first['detection']['accuracy']:.3f} | {last['detection']['accuracy']:.3f} | {last['detection']['accuracy'] - first['detection']['accuracy']:+.3f} |

## Interpretation

"""
        # Add interpretation
        sui_delta = last['composite']['sui'] - first['composite']['sui']
        if abs(sui_delta) < 0.02:
            report += "- **SUI Stable**: Metrics are consistent as sample size grows (good sign)\n"
        elif sui_delta > 0:
            report += f"- **SUI Improving**: +{sui_delta:.3f} improvement as more samples added\n"
        else:
            report += f"- **SUI Declining**: {sui_delta:.3f} drop - earlier samples may have been easier\n"

        tdr_delta = last['target_finding']['target_detection_rate'] - first['target_finding']['target_detection_rate']
        if abs(tdr_delta) < 0.05:
            report += "- **Target Detection Stable**: Consistent vulnerability identification\n"
        elif tdr_delta < 0:
            report += f"- **Target Detection Declining**: Model struggles with newer/harder samples\n"

        hr_delta = last['finding_quality']['hallucination_rate'] - first['finding_quality']['hallucination_rate']
        if hr_delta > 0.05:
            report += f"- **Hallucination Increasing**: More false findings as samples grow (concerning)\n"
        elif hr_delta < -0.05:
            report += f"- **Hallucination Decreasing**: False findings becoming rarer\n"

        # Save trend report
        report_path = self.output_dir / "trend_report.md"
        with open(report_path, "w") as f:
            f.write(report)

        print(f"Trend report saved to: {report_path}")
        return report


def generate_trend_report_for_model(output_dir: Path) -> Optional[str]:
    """
    Standalone function to generate trend report for a model's output directory.

    Usage:
        from src.judge.runner import generate_trend_report_for_model
        report = generate_trend_report_for_model(Path("judge_output/grok_4"))
    """
    history_dir = output_dir / "metrics_history"
    if not history_dir.exists():
        print(f"No metrics history found in {output_dir}")
        return None

    # Load all historical snapshots
    snapshots = []
    for file in sorted(history_dir.glob("*.json")):
        try:
            with open(file) as f:
                snapshots.append(json.load(f))
        except Exception as e:
            print(f"Warning: Failed to load {file}: {e}")

    if len(snapshots) < 2:
        print(f"Need at least 2 snapshots for trend analysis, found {len(snapshots)}")
        return None

    # Generate report (same logic as class method)
    report = f"""# Metrics Trend Report

Generated: {datetime.now().isoformat()}
Model Output: {output_dir}
Total Snapshots: {len(snapshots)}

## Sample Count Progression

| Timestamp | Samples | SUI | Target Det. | Finding Prec. | Halluc. Rate |
|-----------|---------|-----|-------------|---------------|--------------|
"""
    for snap in snapshots:
        ts = snap["snapshot_timestamp"][:19]
        n = snap["sample_count"]
        m = snap["metrics"]
        sui = m["composite"]["sui"]
        tdr = m["target_finding"]["target_detection_rate"]
        fp = m["finding_quality"]["finding_precision"]
        hr = m["finding_quality"]["hallucination_rate"]
        report += f"| {ts} | {n} | {sui:.3f} | {tdr:.3f} | {fp:.3f} | {hr:.3f} |\n"

    first = snapshots[0]["metrics"]
    last = snapshots[-1]["metrics"]

    report += f"""
## Change Analysis (First → Latest)

| Metric | First (n={snapshots[0]['sample_count']}) | Latest (n={snapshots[-1]['sample_count']}) | Delta |
|--------|-------|--------|-------|
| SUI | {first['composite']['sui']:.3f} | {last['composite']['sui']:.3f} | {last['composite']['sui'] - first['composite']['sui']:+.3f} |
| Target Detection | {first['target_finding']['target_detection_rate']:.3f} | {last['target_finding']['target_detection_rate']:.3f} | {last['target_finding']['target_detection_rate'] - first['target_finding']['target_detection_rate']:+.3f} |
| Finding Precision | {first['finding_quality']['finding_precision']:.3f} | {last['finding_quality']['finding_precision']:.3f} | {last['finding_quality']['finding_precision'] - first['finding_quality']['finding_precision']:+.3f} |
| Hallucination Rate | {first['finding_quality']['hallucination_rate']:.3f} | {last['finding_quality']['hallucination_rate']:.3f} | {last['finding_quality']['hallucination_rate'] - first['finding_quality']['hallucination_rate']:+.3f} |
"""

    # Save
    report_path = output_dir / "trend_report.md"
    with open(report_path, "w") as f:
        f.write(report)

    print(f"Trend report saved to: {report_path}")
    return report
