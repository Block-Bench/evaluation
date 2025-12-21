#!/usr/bin/env python3
"""Check testing coverage for Grok 4."""

from pathlib import Path

BASE_DIR = Path(__file__).parent.parent

def check_coverage():
    """Check what's tested and what's missing for Grok 4."""

    # Check model outputs
    grok4_output = BASE_DIR / 'output' / 'grok_4'

    # Check judge outputs
    grok4_judge = BASE_DIR / 'judge_output' / 'grok_4' / 'judge_outputs'

    # Get all model output files
    direct_outputs = list((grok4_output / 'direct').glob('*.json')) if (grok4_output / 'direct').exists() else []
    adversarial_outputs = list((grok4_output / 'adversarial').glob('*.json')) if (grok4_output / 'adversarial').exists() else []
    naturalistic_outputs = list((grok4_output / 'naturalistic').glob('*.json')) if (grok4_output / 'naturalistic').exists() else []

    # Get judged files
    judged_files = list(grok4_judge.glob('*.json')) if grok4_judge.exists() else []

    print("=" * 60)
    print("GROK 4 TESTING COVERAGE ANALYSIS")
    print("=" * 60)
    print()

    print("MODEL OUTPUTS:")
    print(f"  Direct:       {len(direct_outputs)} files")
    print(f"  Adversarial:  {len(adversarial_outputs)} files")
    print(f"  Naturalistic: {len(naturalistic_outputs)} files")
    print(f"  TOTAL:        {len(direct_outputs) + len(adversarial_outputs) + len(naturalistic_outputs)} files")
    print()

    print("JUDGE OUTPUTS:")
    print(f"  Completed:    {len(judged_files)} files")
    print()

    print("WHAT'S MISSING:")
    print()

    # Unjudged direct samples
    judged_sample_ids = set()
    for jf in judged_files:
        # Extract sample ID from judge filename like j_nc_ds_002_direct.json
        parts = jf.stem.replace('j_', '').replace('_direct', '').replace('_adversarial', '').replace('_naturalistic', '')
        judged_sample_ids.add(parts)

    unjudged_direct = []
    for output_file in direct_outputs:
        # Extract sample ID from output filename like r_ch_medical_nc_ds_002.json
        sample_id = output_file.stem.replace('r_', '')

        # Check if this was judged (need to match against judge file pattern)
        judged = False
        for jf in judged_files:
            if sample_id in jf.stem:
                judged = True
                break

        if not judged:
            unjudged_direct.append(sample_id)

    if unjudged_direct:
        print(f"1. UNJUDGED DIRECT SAMPLES ({len(unjudged_direct)} files):")
        for sample in sorted(unjudged_direct):
            print(f"   - {sample}")
        print()

    # Compare with other models to see what full coverage looks like
    gpt_output = BASE_DIR / 'output' / 'gpt-5.2'

    if gpt_output.exists():
        gpt_direct = list((gpt_output / 'direct').glob('*.json')) if (gpt_output / 'direct').exists() else []
        gpt_adversarial = list((gpt_output / 'adversarial').glob('*.json')) if (gpt_output / 'adversarial').exists() else []
        gpt_naturalistic = list((gpt_output / 'naturalistic').glob('*.json')) if (gpt_output / 'naturalistic').exists() else []

        print("2. MISSING PROMPT TYPES:")
        print(f"   - Adversarial: Need ~{len(gpt_adversarial)} samples (currently: {len(adversarial_outputs)})")
        print(f"   - Naturalistic: Need ~{len(gpt_naturalistic)} samples (currently: {len(naturalistic_outputs)})")
        print()

        print("3. INCOMPLETE DIRECT COVERAGE:")
        print(f"   - GPT-5.2 has {len(gpt_direct)} direct samples")
        print(f"   - Grok 4 has {len(direct_outputs)} direct samples")
        print(f"   - Missing: ~{len(gpt_direct) - len(direct_outputs)} direct samples")
        print()

    print("=" * 60)
    print("RECOMMENDATION")
    print("=" * 60)
    print()
    print("To get comprehensive Grok 4 evaluation, we need to:")
    print()
    print("1. Judge the 10 unjudged direct samples (quick win!)")
    print("2. Run Grok 4 on adversarial prompts (~5 samples)")
    print("3. Run Grok 4 on naturalistic prompts (~5 samples)")
    print("4. Run Grok 4 on remaining direct samples (~45 samples)")
    print()
    print("Current metrics are based on only 5 samples (7.4% of full coverage)")
    print("This is NOT statistically representative for drawing conclusions.")
    print()

if __name__ == '__main__':
    check_coverage()
