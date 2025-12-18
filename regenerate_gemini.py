#!/usr/bin/env python3
"""Regenerate 4 failed Gemini samples"""
import asyncio
import sys
from pathlib import Path

# Add current directory to path
sys.path.insert(0, str(Path.cwd()))

from src.data.sample_loader import SampleLoader
from src.models.registry import get_model_client
from src.pipeline.runner import EvaluationPipeline
from src.prompts.templates import DIRECT_SYSTEM_PROMPT, DIRECT_USER_PROMPT

async def main():
    # Load samples
    samples_dir = Path("samples")
    loader = SampleLoader(str(samples_dir))
    all_samples = loader.load_samples(load_code=True, load_ground_truth=True)
    
    # Filter to only the 4 failed ones
    failed_ids = ["sn_tc_002", "ch_medical_nc_tc_005", "sn_gs_005", "ss_l3_medium_nc_ds_234"]
    samples = [s for s in all_samples if s.transformed_id in failed_ids]
    
    print(f"Found {len(samples)} samples to regenerate:")
    for s in samples:
        print(f"  - {s.transformed_id}")
    
    # Initialize Gemini client
    client = get_model_client(
        provider="vertex_google",
        model_id="gemini-3-pro-preview",
        project_id=None,  # Will use from env
        location="us-central1"
    )
    
    # Create pipeline
    pipeline = EvaluationPipeline(
        model_client=client,
        output_dir=Path("output/gemini_3_pro_preview"),
        prompt_templates={"direct": (DIRECT_SYSTEM_PROMPT, DIRECT_USER_PROMPT)},
        resume=False  # Force regeneration
    )
    
    # Run evaluation
    print("\nStarting evaluation...")
    await pipeline.run(samples, prompt_types=["direct"])
    
    print("\nRegeneration complete!")

if __name__ == "__main__":
    asyncio.run(main())
