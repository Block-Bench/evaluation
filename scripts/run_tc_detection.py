#!/usr/bin/env python3
"""Run LLM vulnerability detection on TC (Temporal Contamination) samples."""
import argparse
import asyncio
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from dotenv import load_dotenv
load_dotenv(PROJECT_ROOT / '.env')

from src.detection.llm.model_config import get_client, load_model_config
from src.detection.llm.prompts.tc.direct import TCDirectPromptBuilder


def parse_json_response(raw: str):
    """Parse JSON from model response."""
    s = raw.strip()
    js = s if s.startswith('{') else None
    if js is None and s.startswith('```'):
        m = re.match(r'```(?:json)?\s*\n?', s)
        if m:
            lf = s.rfind('```')
            if lf > m.end():
                js = s[m.end():lf].strip()
    if js is None:
        m = re.search(r'```(?:json)?\s*\n?(.*?)\n?```', raw, re.DOTALL)
        js = m.group(1).strip() if m else s
    try:
        return json.loads(js), []
    except:
        try:
            return json.loads(re.sub(r',\s*([}\]])', r'\1', js)), []
        except Exception as e:
            return None, [str(e)]


async def run_sample(model: str, sample_id: str, variant: str, code: str, metadata: dict):
    """Run detection on a single sample."""
    import time

    builder = TCDirectPromptBuilder()
    prompt = builder.build(code)
    config = load_model_config(PROJECT_ROOT / f'config/models/{model}.yaml')
    client = get_client(model)

    start = time.time()
    resp = await client.generate(
        system_prompt=prompt.system_prompt,
        user_prompt=prompt.user_prompt,
        max_tokens=config.max_tokens,
        temperature=config.temperature
    )
    latency = (time.time() - start) * 1000

    parsed, errors = parse_json_response(resp.content)

    return {
        'sample_id': sample_id,
        'variant': variant,
        'model': model,
        'prompt_type': 'direct',
        'timestamp': datetime.now(timezone.utc).isoformat(),
        'ground_truth': {
            'is_vulnerable': metadata.get('is_vulnerable', True),
            'vulnerability_type': metadata.get('vulnerability_type'),
            'vulnerable_function': metadata.get('vulnerable_function'),
            'vulnerable_lines': metadata.get('vulnerable_lines', []),
            'severity': metadata.get('severity')
        },
        'prediction': parsed or {},
        'parsing': {
            'success': parsed is not None,
            'errors': errors,
            'raw_response': resp.content
        },
        'api_metrics': {
            'input_tokens': resp.input_tokens,
            'output_tokens': resp.output_tokens,
            'latency_ms': latency
        }
    }


async def main():
    parser = argparse.ArgumentParser(description='Run LLM detection on TC samples')
    parser.add_argument('--model', '-m', required=True, help='Model name')
    parser.add_argument('--variant', '-v', default='minimalsanitized', help='TC variant')
    parser.add_argument('--sample', '-s', help='Specific sample ID')
    parser.add_argument('--limit', '-l', type=int, help='Limit number of samples')
    args = parser.parse_args()

    variant = args.variant
    contracts_dir = PROJECT_ROOT / f'samples/tc/{variant}/contracts'
    metadata_dir = PROJECT_ROOT / f'samples/tc/{variant}/metadata'
    output_dir = PROJECT_ROOT / f'results/detection/llm/{args.model}/tc/{variant}'
    output_dir.mkdir(parents=True, exist_ok=True)

    # Get samples
    if args.sample:
        samples = [args.sample]
    else:
        samples = sorted([f.stem for f in contracts_dir.glob('*.sol')])

    if args.limit:
        samples = samples[:args.limit]

    # Filter out already completed
    pending = []
    for sid in samples:
        out_file = output_dir / f'd_{sid}.json'
        if not out_file.exists():
            pending.append(sid)

    print(f'Running {args.model} on {variant}: {len(pending)} pending of {len(samples)}')

    for i, sid in enumerate(pending, 1):
        code = (contracts_dir / f'{sid}.sol').read_text()
        meta_path = metadata_dir / f'{sid}.json'
        metadata = json.loads(meta_path.read_text()) if meta_path.exists() else {}

        try:
            result = await run_sample(args.model, sid, variant, code, metadata)
            out_file = output_dir / f'd_{sid}.json'
            with open(out_file, 'w') as f:
                json.dump(result, f, indent=2)

            verdict = result['prediction'].get('verdict', 'unknown')
            findings = len(result['prediction'].get('vulnerabilities', []))
            print(f'[{i}/{len(pending)}] {sid}... {verdict}, {findings} findings')
        except Exception as e:
            print(f'[{i}/{len(pending)}] {sid}... ERROR: {e}')

    print(f'{args.model}: COMPLETE')


if __name__ == '__main__':
    asyncio.run(main())
