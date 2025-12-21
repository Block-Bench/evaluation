#!/usr/bin/env python3
"""
Find all samples that need to be evaluated by Grok 4.
Compare against a reference model (GPT-5.2) to find missing samples.
"""

from pathlib import Path
import json

BASE_DIR = Path(__file__).parent.parent

def get_sample_id_from_filename(filename: str) -> str:
    """Extract sample ID from response filename."""
    # Remove r_ prefix and .json suffix
    return filename.replace('r_', '').replace('.json', '')

def find_missing_samples():
    """Find all samples that Grok 4 hasn't been tested on yet."""

    # Reference model with full coverage
    reference_model = 'gpt-5.2'
    reference_dir = BASE_DIR / 'output' / reference_model

    # Grok 4 directory
    grok4_dir = BASE_DIR / 'output' / 'grok_4'

    # Get all samples from reference model by prompt type
    prompt_types = ['direct', 'adversarial', 'naturalistic']

    missing_by_prompt = {}

    for prompt_type in prompt_types:
        ref_prompt_dir = reference_dir / prompt_type
        grok4_prompt_dir = grok4_dir / prompt_type

        if not ref_prompt_dir.exists():
            print(f"Warning: Reference directory {ref_prompt_dir} doesn't exist")
            continue

        # Get all sample IDs from reference
        ref_samples = set()
        for f in ref_prompt_dir.glob('r_*.json'):
            sample_id = get_sample_id_from_filename(f.name)
            ref_samples.add(sample_id)

        # Get all sample IDs from Grok 4
        grok4_samples = set()
        if grok4_prompt_dir.exists():
            for f in grok4_prompt_dir.glob('r_*.json'):
                sample_id = get_sample_id_from_filename(f.name)
                grok4_samples.add(sample_id)

        # Find missing
        missing = sorted(ref_samples - grok4_samples)
        missing_by_prompt[prompt_type] = missing

    return missing_by_prompt

def main():
    print("=" * 70)
    print("FINDING MISSING GROK 4 SAMPLES")
    print("=" * 70)
    print()

    missing = find_missing_samples()

    total_missing = 0

    for prompt_type, samples in missing.items():
        count = len(samples)
        total_missing += count

        print(f"{prompt_type.upper()} PROMPTS: {count} missing samples")
        print("-" * 70)

        if samples:
            for i, sample in enumerate(samples, 1):
                print(f"  {i:2d}. {sample}")
        else:
            print("  (none - all samples tested)")

        print()

    print("=" * 70)
    print(f"TOTAL MISSING: {total_missing} samples")
    print("=" * 70)
    print()

    # Save to JSON for easy processing
    output_file = BASE_DIR / 'analysis_results' / 'grok4_missing_samples.json'

    with open(output_file, 'w') as f:
        json.dump(missing, f, indent=2)

    print(f"✓ Saved missing samples list to: {output_file}")
    print()

    # Show summary
    print("SUMMARY:")
    print(f"  Direct:       {len(missing.get('direct', []))} samples to run")
    print(f"  Adversarial:  {len(missing.get('adversarial', []))} samples to run")
    print(f"  Naturalistic: {len(missing.get('naturalistic', []))} samples to run")
    print(f"  TOTAL:        {total_missing} samples to run")

if __name__ == '__main__':
    main()
