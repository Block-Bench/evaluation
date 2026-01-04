#!/usr/bin/env python3
"""Test single Grok 4 evaluation."""

import asyncio
import sys
from pathlib import Path

from dotenv import load_dotenv
load_dotenv()

sys.path.insert(0, str(Path(__file__).parent.parent))

from scripts.run_grok4_missing import Grok4Runner

async def test_single():
    """Test a single evaluation."""
    print("Creating runner...", flush=True)
    runner = Grok4Runner()

    print("Testing single sample: sn_gs_026", flush=True)
    result = await runner.evaluate_sample("sn_gs_026", "naturalistic")

    print(f"Result: {result.get('error') or 'SUCCESS'}", flush=True)
    print(f"Cost: ${result.get('cost_usd', 0):.4f}", flush=True)

    return result

if __name__ == '__main__':
    asyncio.run(test_single())
