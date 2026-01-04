#!/usr/bin/env python3
"""
Test Codestral LLM Judge on a single sample.

Codestral uses Vertex AI rawPredict endpoint with Mistral message format.
"""

import json
import os
import re
import sys
from datetime import datetime
from pathlib import Path

# Add project root to path
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT / "src"))

from evaluation.llm_judge.prompts import (
    get_traditional_tool_system_prompt,
    get_traditional_tool_user_prompt
)


def load_sample_data(sample_id: str = "ds_t1_001", use_processed: bool = True):
    """Load detection result, ground truth, and contract code for a sample."""
    base = PROJECT_ROOT

    # Detection result - use processed by default
    if use_processed:
        detection_file = base / f"results/detection/traditional/slither/ds/tier1/processed/p_{sample_id}.json"
    else:
        detection_file = base / f"results/detection/traditional/slither/ds/tier1/raw/d_{sample_id}.json"
    with open(detection_file) as f:
        detection = json.load(f)

    # Ground truth
    gt_file = base / f"samples/ds/tier1/ground_truth/{sample_id}.json"
    with open(gt_file) as f:
        ground_truth = json.load(f)

    # Contract code
    contract_file = base / f"samples/ds/tier1/contracts/{sample_id}.sol"
    with open(contract_file) as f:
        code = f.read()

    return detection, ground_truth, code


def call_codestral(system_prompt: str, user_prompt: str) -> str:
    """
    Call Codestral via Vertex AI rawPredict endpoint.

    Uses Mistral message format.
    """
    from google.auth import default
    from google.auth.transport.requests import Request
    import requests

    # Get credentials
    credentials, project = default()
    credentials.refresh(Request())

    project_id = os.getenv("VERTEX_PROJECT_ID", project)
    location = "europe-west4"  # Codestral is in europe-west4
    model = "codestral-2"

    endpoint = f"https://{location}-aiplatform.googleapis.com/v1/projects/{project_id}/locations/{location}/publishers/mistralai/models/{model}:rawPredict"

    headers = {
        "Authorization": f"Bearer {credentials.token}",
        "Content-Type": "application/json"
    }

    # Mistral message format
    payload = {
        "model": model,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt}
        ],
        "temperature": 0.0,
        "max_tokens": 4096
    }

    print(f"Calling Codestral at {location}...")
    response = requests.post(endpoint, headers=headers, json=payload, timeout=120)

    if response.status_code != 200:
        print(f"Error {response.status_code}: {response.text}")
        raise Exception(f"API call failed: {response.status_code}")

    data = response.json()
    return data["choices"][0]["message"]["content"]


def main():
    """Test Codestral on a single sample."""
    import argparse

    parser = argparse.ArgumentParser(description="Test Codestral LLM Judge")
    parser.add_argument("--sample", default="ds_t1_001", help="Sample ID to test")
    parser.add_argument("--dry-run", action="store_true", help="Print prompts without calling API")
    args = parser.parse_args()

    print(f"Loading sample: {args.sample}")
    detection, ground_truth, code = load_sample_data(args.sample)

    # Build prompts
    system_prompt = get_traditional_tool_system_prompt()
    user_prompt = get_traditional_tool_user_prompt(
        detection_output=detection,
        ground_truth=ground_truth,
        code_snippet=code
    )

    print(f"\n{'='*60}")
    print("SYSTEM PROMPT:")
    print(f"{'='*60}")
    print(system_prompt[:500] + "...")

    print(f"\n{'='*60}")
    print("USER PROMPT (first 2000 chars):")
    print(f"{'='*60}")
    print(user_prompt[:2000] + "...")

    print(f"\n{'='*60}")
    print(f"Total prompt length: {len(system_prompt) + len(user_prompt)} chars")
    print(f"{'='*60}")

    if args.dry_run:
        print("\n[DRY RUN - Not calling API]")
        return

    # Call Codestral
    print("\nCalling Codestral...")
    try:
        response = call_codestral(system_prompt, user_prompt)

        print(f"\n{'='*60}")
        print("CODESTRAL RESPONSE:")
        print(f"{'='*60}")
        print(response)

        # Parse JSON from response
        json_match = re.search(r'```json\s*(.*?)\s*```', response, re.DOTALL)
        if json_match:
            parsed = json.loads(json_match.group(1))
        else:
            parsed = json.loads(response)

        # Folder structure: llm-judge/{judge}/ds/{tier}/
        tier = "tier1"  # Extract from sample_id
        output_dir = PROJECT_ROOT / f"results/detection_evaluation/llm-judge/codestral/ds/{tier}"
        output_dir.mkdir(parents=True, exist_ok=True)

        # Save formatted output (parsed JSON)
        formatted_output = {
            "sample_id": args.sample,
            "tool": "slither",
            "judge_model": "codestral",
            "judge_family": "mistral",
            "timestamp": datetime.now().isoformat(),
            **parsed
        }

        formatted_file = output_dir / f"j_{args.sample}.json"
        with open(formatted_file, 'w') as f:
            json.dump(formatted_output, f, indent=2)
        print(f"\nFormatted output saved to: {formatted_file}")

        # Save raw response separately
        raw_dir = output_dir / "raw"
        raw_dir.mkdir(parents=True, exist_ok=True)
        raw_file = raw_dir / f"raw_{args.sample}.txt"
        with open(raw_file, 'w') as f:
            f.write(response)
        print(f"Raw response saved to: {raw_file}")

    except Exception as e:
        print(f"Error: {e}")
        raise


if __name__ == "__main__":
    main()
