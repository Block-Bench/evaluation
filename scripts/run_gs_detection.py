#!/usr/bin/env python3
"""Run LLM vulnerability detection on GS (Gold Standard) samples."""
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
from src.detection.llm.prompts.gs import (
    GSDirectPromptBuilder,
    GSContextProtocolPromptBuilder,
    GSContextProtocolCoTPromptBuilder,
    GSContextProtocolCoTNaturalisticPromptBuilder,
    GSContextProtocolCoTAdversarialPromptBuilder,
)

# Prompt type to builder mapping
PROMPT_BUILDERS = {
    'direct': GSDirectPromptBuilder,
    'context_protocol': GSContextProtocolPromptBuilder,
    'context_protocol_cot': GSContextProtocolCoTPromptBuilder,
    'context_protocol_cot_naturalistic': GSContextProtocolCoTNaturalisticPromptBuilder,
    'context_protocol_cot_adversarial': GSContextProtocolCoTAdversarialPromptBuilder,
}


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


def load_context_files(sample_id: str, contracts_dir: Path) -> list[dict]:
    """Load Solidity context files for a sample if they exist."""
    context_dir = contracts_dir / 'context' / sample_id
    if not context_dir.exists():
        return []

    context_files = []
    for ctx_file in sorted(context_dir.glob('*.sol')):
        context_files.append({
            'name': ctx_file.name,
            'code': ctx_file.read_text()
        })
    return context_files


def load_protocol_doc(sample_id: str, protocol_doc_dir: Path) -> str | None:
    """Load protocol documentation for a sample if it exists."""
    doc_file = protocol_doc_dir / f'{sample_id}_context.txt'
    if doc_file.exists():
        return doc_file.read_text()
    return None


async def run_sample(
    model: str,
    sample_id: str,
    prompt_type: str,
    code: str,
    context_files: list[dict],
    protocol_doc: str | None,
    ground_truth: dict
):
    """Run detection on a single sample."""
    import time

    builder_class = PROMPT_BUILDERS[prompt_type]
    builder = builder_class()

    # Build prompt with appropriate arguments based on prompt type
    if prompt_type == 'direct':
        prompt = builder.build(
            code=code,
            context_files=context_files if context_files else None
        )
    else:  # context_protocol variants (with protocol_doc)
        prompt = builder.build(
            code=code,
            context_files=context_files if context_files else None,
            protocol_doc=protocol_doc
        )

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
        'dataset': 'gs',
        'prompt_type': prompt_type,
        'model': model,
        'timestamp': datetime.now(timezone.utc).isoformat(),
        'ground_truth': ground_truth,
        'prediction': parsed or {},
        'parsing': {
            'success': parsed is not None,
            'errors': errors,
            'raw_response': resp.content
        },
        'context_info': {
            'has_context_files': len(context_files) > 0,
            'context_file_count': len(context_files),
            'has_protocol_doc': protocol_doc is not None
        },
        'api_metrics': {
            'input_tokens': resp.input_tokens,
            'output_tokens': resp.output_tokens,
            'latency_ms': latency
        }
    }


async def main():
    parser = argparse.ArgumentParser(description='Run LLM detection on GS samples')
    parser.add_argument('--model', '-m', required=True, help='Model name')
    parser.add_argument('--prompt-type', '-p', default='direct',
                        choices=['direct', 'context_protocol', 'context_protocol_cot', 'context_protocol_cot_naturalistic', 'context_protocol_cot_adversarial'],
                        help='Prompt type to use')
    parser.add_argument('--sample', '-s', help='Specific sample ID (e.g., gs_001)')
    parser.add_argument('--limit', '-l', type=int, help='Limit number of samples')
    args = parser.parse_args()

    # Setup directories
    samples_dir = PROJECT_ROOT / 'samples/gs'
    contracts_dir = samples_dir / 'contracts'
    ground_truth_dir = samples_dir / 'ground_truth'
    protocol_doc_dir = samples_dir / 'protocol_context_doc'

    # Output organized by prompt type (like TC variants)
    output_dir = PROJECT_ROOT / f'results/detection/llm/{args.model}/gs/{args.prompt_type}'
    output_dir.mkdir(parents=True, exist_ok=True)

    # Get samples
    if args.sample:
        samples = [args.sample]
    else:
        samples = sorted([f.stem for f in contracts_dir.glob('gs_*.sol')])

    if args.limit:
        samples = samples[:args.limit]

    # Filter out already completed
    pending = []
    for sid in samples:
        out_file = output_dir / f'd_{sid}.json'
        if not out_file.exists():
            pending.append(sid)

    print(f'Running {args.model} on gs/{args.prompt_type}: {len(pending)} pending of {len(samples)}')

    for i, sid in enumerate(pending, 1):
        # Load main contract
        code = (contracts_dir / f'{sid}.sol').read_text()

        # Load context files (always included if available)
        context_files = load_context_files(sid, contracts_dir)

        # Load protocol doc (for all context_protocol variants)
        protocol_doc = None
        if args.prompt_type in ['context_protocol', 'context_protocol_cot', 'context_protocol_cot_naturalistic', 'context_protocol_cot_adversarial']:
            protocol_doc = load_protocol_doc(sid, protocol_doc_dir)

        # Load ground truth
        gt_path = ground_truth_dir / f'{sid}.json'
        ground_truth = json.loads(gt_path.read_text()) if gt_path.exists() else {}

        try:
            result = await run_sample(
                args.model, sid, args.prompt_type,
                code, context_files, protocol_doc, ground_truth
            )
            out_file = output_dir / f'd_{sid}.json'
            with open(out_file, 'w') as f:
                json.dump(result, f, indent=2)

            verdict = result['prediction'].get('verdict', 'unknown')
            findings = len(result['prediction'].get('vulnerabilities', []))
            ctx_info = f"[ctx:{result['context_info']['context_file_count']}]" if context_files else ""
            print(f'[{i}/{len(pending)}] {sid}{ctx_info}... {verdict}, {findings} findings')
        except Exception as e:
            print(f'[{i}/{len(pending)}] {sid}... ERROR: {e}')

    print(f'{args.model}/{args.prompt_type}: COMPLETE')


if __name__ == '__main__':
    asyncio.run(main())
