# Detection LLM Output Validation Report

- base: `/Users/poamen/projects/grace/blockbench/evaluation/results/detection/llm`
- json files scanned: 1918

## Parsing status

- parsing.success=true: 1887
- parsing.success=false: 31
  - with non-empty raw_response: 0
  - with empty raw_response: 31

## Issues (counts)

- errors: 48
- warnings: 1

### Top issue codes

- error `PARSE_FAILED_EMPTY_RAW`: 31
- error `BAD_VERDICT`: 17
- warn `BAD_CONFIDENCE`: 1

## By dataset

### ds

- files: 700
- parsing success: 700
- parsing failed: 0
  - failed w/ raw: 0
  - failed empty raw: 0

### tc

- files: 1201
- parsing success: 1174
- parsing failed: 27
  - failed w/ raw: 0
  - failed empty raw: 27

## Coverage (expected vs present)

Expected sample sets are derived from `samples/**/ground_truth/*.json`.

### claude-opus-4-5

- **ds/tier1**: present=20, parsing_ok=20, invalid_or_failed=0, expected=20, missing=0, extra=0
- **ds/tier2**: present=37, parsing_ok=37, invalid_or_failed=0, expected=37, missing=0, extra=0
- **ds/tier3**: present=30, parsing_ok=30, invalid_or_failed=0, expected=30, missing=0, extra=0
- **ds/tier4**: present=13, parsing_ok=13, invalid_or_failed=0, expected=13, missing=0, extra=0
- **tc/chameleon_medical**: present=46, parsing_ok=46, invalid_or_failed=0, expected=46, missing=0, extra=0
- **tc/minimalsanitized**: present=46, parsing_ok=46, invalid_or_failed=0, expected=46, missing=0, extra=0
- **tc/nocomments**: present=46, parsing_ok=46, invalid_or_failed=0, expected=46, missing=0, extra=0
- **tc/sanitized**: present=46, parsing_ok=46, invalid_or_failed=0, expected=46, missing=0, extra=0

### deepseek-v3-2

- **ds/tier1**: present=20, parsing_ok=20, invalid_or_failed=0, expected=20, missing=0, extra=0
- **ds/tier2**: present=37, parsing_ok=37, invalid_or_failed=0, expected=37, missing=0, extra=0
- **ds/tier3**: present=30, parsing_ok=30, invalid_or_failed=0, expected=30, missing=0, extra=0
- **ds/tier4**: present=13, parsing_ok=13, invalid_or_failed=0, expected=13, missing=0, extra=0
- **tc/chameleon_medical**: present=30, parsing_ok=30, invalid_or_failed=0, expected=46, missing=16, extra=0
  - missing sample_ids (first 10): ch_medical_tc_031, ch_medical_tc_032, ch_medical_tc_033, ch_medical_tc_034, ch_medical_tc_035, ch_medical_tc_036, ch_medical_tc_037, ch_medical_tc_038, ch_medical_tc_039, ch_medical_tc_040 ...
- **tc/minimalsanitized**: present=46, parsing_ok=46, invalid_or_failed=0, expected=46, missing=0, extra=0
- **tc/nocomments**: present=46, parsing_ok=46, invalid_or_failed=0, expected=46, missing=0, extra=0
- **tc/sanitized**: present=46, parsing_ok=46, invalid_or_failed=0, expected=46, missing=0, extra=0

### gemini-3-pro

- **ds/tier1**: present=20, parsing_ok=20, invalid_or_failed=0, expected=20, missing=0, extra=0
- **ds/tier2**: present=37, parsing_ok=37, invalid_or_failed=0, expected=37, missing=0, extra=0
- **ds/tier3**: present=30, parsing_ok=30, invalid_or_failed=0, expected=30, missing=0, extra=0
- **ds/tier4**: present=13, parsing_ok=13, invalid_or_failed=0, expected=13, missing=0, extra=0
- **tc/minimalsanitized**: present=46, parsing_ok=46, invalid_or_failed=0, expected=46, missing=0, extra=0
- **tc/nocomments**: present=46, parsing_ok=36, invalid_or_failed=10, expected=46, missing=0, extra=0
- **tc/sanitized**: present=46, parsing_ok=29, invalid_or_failed=17, expected=46, missing=0, extra=0

### gemini-3-pro-hyper-extended

- **tc/nocomments**: present=7, parsing_ok=7, invalid_or_failed=0, expected=46, missing=39, extra=0
  - missing sample_ids (first 10): nc_tc_001, nc_tc_002, nc_tc_003, nc_tc_004, nc_tc_005, nc_tc_006, nc_tc_007, nc_tc_008, nc_tc_010, nc_tc_011 ...
- **tc/sanitized**: present=7, parsing_ok=7, invalid_or_failed=0, expected=46, missing=39, extra=0
  - missing sample_ids (first 10): sn_tc_001, sn_tc_002, sn_tc_003, sn_tc_007, sn_tc_008, sn_tc_009, sn_tc_011, sn_tc_012, sn_tc_014, sn_tc_015 ...

### gemini-variants

- **gemini-3-pro-extended/ds**: present=11, parsing_ok=11, invalid_or_failed=0 (no expected set found)
- **gemini-3-pro-hyper-extended/ds**: present=1, parsing_ok=1, invalid_or_failed=0 (no expected set found)
- **gemini-3-pro-low/ds**: present=1, parsing_ok=0, invalid_or_failed=1 (no expected set found)
- **gemini-3-pro-medium/ds**: present=4, parsing_ok=1, invalid_or_failed=3 (no expected set found)

### gpt-5.2

- **ds/tier1**: present=20, parsing_ok=20, invalid_or_failed=0, expected=20, missing=0, extra=0
- **ds/tier2**: present=37, parsing_ok=37, invalid_or_failed=0, expected=37, missing=0, extra=0
- **ds/tier3**: present=30, parsing_ok=30, invalid_or_failed=0, expected=30, missing=0, extra=0
- **ds/tier4**: present=13, parsing_ok=13, invalid_or_failed=0, expected=13, missing=0, extra=0
- **tc/chameleon_medical**: present=21, parsing_ok=21, invalid_or_failed=0, expected=46, missing=25, extra=0
  - missing sample_ids (first 10): ch_medical_tc_022, ch_medical_tc_023, ch_medical_tc_024, ch_medical_tc_025, ch_medical_tc_026, ch_medical_tc_027, ch_medical_tc_028, ch_medical_tc_029, ch_medical_tc_030, ch_medical_tc_031 ...
- **tc/minimalsanitized**: present=46, parsing_ok=46, invalid_or_failed=0, expected=46, missing=0, extra=0
- **tc/nocomments**: present=46, parsing_ok=46, invalid_or_failed=0, expected=46, missing=0, extra=0
- **tc/sanitized**: present=46, parsing_ok=46, invalid_or_failed=0, expected=46, missing=0, extra=0

### grok-4-fast

- **ds/tier1**: present=20, parsing_ok=20, invalid_or_failed=0, expected=20, missing=0, extra=0
- **ds/tier2**: present=37, parsing_ok=37, invalid_or_failed=0, expected=37, missing=0, extra=0
- **ds/tier3**: present=30, parsing_ok=30, invalid_or_failed=0, expected=30, missing=0, extra=0
- **ds/tier4**: present=13, parsing_ok=13, invalid_or_failed=0, expected=13, missing=0, extra=0
- **tc/chameleon_medical**: present=32, parsing_ok=32, invalid_or_failed=0, expected=46, missing=14, extra=0
  - missing sample_ids (first 10): ch_medical_tc_033, ch_medical_tc_034, ch_medical_tc_035, ch_medical_tc_036, ch_medical_tc_037, ch_medical_tc_038, ch_medical_tc_039, ch_medical_tc_040, ch_medical_tc_041, ch_medical_tc_042 ...
- **tc/minimalsanitized**: present=46, parsing_ok=46, invalid_or_failed=0, expected=46, missing=0, extra=0
- **tc/nocomments**: present=46, parsing_ok=46, invalid_or_failed=0, expected=46, missing=0, extra=0
- **tc/sanitized**: present=46, parsing_ok=46, invalid_or_failed=0, expected=46, missing=0, extra=0

### llama-4-maverick

- **ds/tier1**: present=20, parsing_ok=20, invalid_or_failed=0, expected=20, missing=0, extra=0
- **ds/tier2**: present=37, parsing_ok=37, invalid_or_failed=0, expected=37, missing=0, extra=0
- **ds/tier3**: present=30, parsing_ok=30, invalid_or_failed=0, expected=30, missing=0, extra=0
- **ds/tier4**: present=13, parsing_ok=13, invalid_or_failed=0, expected=13, missing=0, extra=0
- **tc/chameleon_medical**: present=46, parsing_ok=46, invalid_or_failed=0, expected=46, missing=0, extra=0
- **tc/minimalsanitized**: present=46, parsing_ok=46, invalid_or_failed=0, expected=46, missing=0, extra=0
- **tc/nocomments**: present=46, parsing_ok=46, invalid_or_failed=0, expected=46, missing=0, extra=0
- **tc/sanitized**: present=46, parsing_ok=46, invalid_or_failed=0, expected=46, missing=0, extra=0

### qwen3-coder-plus

- **ds/tier1**: present=20, parsing_ok=20, invalid_or_failed=3, expected=20, missing=0, extra=0
- **ds/tier2**: present=37, parsing_ok=37, invalid_or_failed=3, expected=37, missing=0, extra=0
- **ds/tier3**: present=30, parsing_ok=30, invalid_or_failed=6, expected=30, missing=0, extra=0
- **ds/tier4**: present=13, parsing_ok=13, invalid_or_failed=1, expected=13, missing=0, extra=0
- **tc/chameleon_medical**: present=46, parsing_ok=46, invalid_or_failed=1, expected=46, missing=0, extra=0
- **tc/minimalsanitized**: present=46, parsing_ok=46, invalid_or_failed=0, expected=46, missing=0, extra=0
- **tc/nocomments**: present=46, parsing_ok=46, invalid_or_failed=2, expected=46, missing=0, extra=0
- **tc/sanitized**: present=46, parsing_ok=46, invalid_or_failed=1, expected=46, missing=0, extra=0

## Next steps

- If `PARSE_FAILED_HAS_RAW` > 0, consider running a salvage script to extract JSON from `raw_response`.
- If `PARSE_FAILED_EMPTY_RAW` > 0, those samples need re-runs (no usable output).
- If you see `BAD_VERDICT` with `prediction.verdict` missing, check for schema typos (e.g., `verifest` vs `verdict`) and fix/normalize before evaluation.
- Full issue list: `/Users/poamen/projects/grace/blockbench/evaluation/quickvalidation/detection_outputs/all_issues.json`
