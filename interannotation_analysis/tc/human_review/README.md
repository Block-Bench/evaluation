# TC Human Review Sample Selection

## Overview
15 base contracts selected for human review to validate LLM judge accuracy across TC variants.

## Selection Methodology
- **Budget**: 15 contracts (25% of 46 base contracts, ~105 total reviews across 7 variants)
- **Criteria**: Ranked by total inter-annotator disagreement across all 7 variants
- **Judges compared**: codestral, gemini-3-flash, mimo-v2-flash
- **Disagreement metric**: `target_assessment.found` field (true/false)

## Variants Covered (7 total)
1. sanitized (sn_tc_*)
2. nocomments (nc_tc_*)
3. chameleon_medical (cm_tc_*)
4. shapeshifter_l3 (ss_tc_*)
5. trojan (tr_tc_*)
6. falseProphet (fp_tc_*)
7. minimalsanitized (ms_tc_*)

## Selected Contracts
| Rank | Base Contract | Total Disagreements | Category |
|------|---------------|---------------------|----------|
| 1 | tc_045 | 25 | highest |
| 2 | tc_030 | 23 | high |
| 3 | tc_003 | 16 | high |
| 4 | tc_035 | 16 | high |
| 5 | tc_002 | 14 | high |
| 6 | tc_034 | 14 | high |
| 7 | tc_016 | 13 | moderate |
| 8 | tc_031 | 13 | moderate |
| 9 | tc_042 | 13 | moderate |
| 10 | tc_001 | 11 | moderate |
| 11 | tc_005 | 11 | moderate |
| 12 | tc_010 | 11 | moderate |
| 13 | tc_039 | 11 | moderate |
| 14 | tc_012 | 10 | moderate |
| 15 | tc_017 | 10 | moderate |

## Statistics
- Total samples reviewed: 15 base contracts x 7 variants = 105 judge evaluations
- Coverage of all disagreement cases: 197 of 350 total disagreements (56.3%)
- Excludes: differential variant (separate evaluation paradigm)

## Review Task
For each sample, human reviewer should:
1. Read the contract and ground truth
2. Evaluate if the detector correctly identified the target vulnerability
3. Determine which judge(s) made the correct assessment
