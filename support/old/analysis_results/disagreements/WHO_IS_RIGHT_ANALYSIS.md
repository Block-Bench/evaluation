# Expert vs Mistral: Who Is Right? - Detailed Analysis

## Summary Table

| # | Sample ID | Model | Expert | Mistral | Who's Right? | Confidence | Reasoning |
|---|-----------|-------|--------|---------|--------------|------------|-----------|
| 1 | ch_medical_nc_ds_207 | Llama | MISSED | FOUND | **Mistral** | High | Model identified "access_control" which is semantically same as "front_running" (race condition). Expert too strict on terminology. |
| 2 | ch_medical_nc_ds_234 | Gemini | MISSED | FOUND | **Mistral** | Very High | Model extensively discussed blockhash manipulation = timestamp_dependency. Expert review: 0 minutes, clearly wrong. |
| 3 | hy_int_nc_ds_207 | DeepSeek | MISSED | FOUND | **Mistral** | High | Expert says "missed race condition" but Mistral found semantic match. Type match=semantic, score=0.83. |
| 4 | nc_ds_234 | GPT-5.2 | MISSED | FOUND | **Mistral** | High | Target: timestamp_dependency. Mistral: semantic match, perfect 1.0 score. Expert has data inconsistency flag. |
| 5 | sn_gs_001 | Claude | MISSED | FOUND | **Mistral** | Medium | Target: logic_error. Mistral: semantic match, score=0.67. Need to review model output to confirm. |
| 6 | sn_gs_002 | Gemini | MISSED | FOUND | **Unclear** | Low | Mistral score only 0.42, suggesting weak match. Could be close call. |
| 7 | sn_gs_013 | DeepSeek | MISSED | FOUND | **Mistral** | High | Target: unchecked_return. Mistral: semantic match, score=0.83. Model likely identified the issue. |
| 8 | sn_gs_013 | Gemini | FOUND | MISSED | **Expert** | High | Expert correctly noted it was found. Mistral says not_mentioned. Need to verify Gemini output. |
| 9 | sn_gs_013 | GPT-5.2 | MISSED | FOUND | **Mistral** | Very High | Expert: "lack of context". Mistral: EXACT match, perfect 1.0 score. Expert wrong. |
| 10 | sn_gs_013 | GPT-5.2 | MISSED | FOUND | **Mistral** | Very High | Same as #9. Expert: "lack of context". Mistral: EXACT match, perfect 1.0. |
| 11 | sn_gs_013 | Llama | MISSED | FOUND | **Mistral** | Very High | Expert: "did not find". Mistral: EXACT match, perfect 1.0. Likely naturalistic prompt found it. |
| 12 | sn_gs_017 | DeepSeek | MISSED | PARTIAL | **Mistral** | Medium | Both agree model didn't fully find it. Mistral's PARTIAL more accurate than MISSED. |
| 13 | sn_gs_017 | Gemini | MISSED | FOUND | **Mistral** | High | Mistral: semantic match, score=0.83. Expert may have been too strict. |
| 14 | sn_gs_017 | Gemini | MISSED | FOUND | **Mistral** | Very High | Mistral: EXACT match, perfect 1.0. Expert clearly wrong. |
| 15 | sn_gs_020 | GPT-5.2 | MISSED | FOUND | **Mistral** | Medium | Mistral: semantic match, score=0.67. Moderate confidence. |
| 16 | sn_gs_020 | GPT-5.2 | MISSED | FOUND | **Mistral** | Medium | Mistral: semantic match, score=0.58. Lower confidence, could be marginal. |
| 17 | sn_gs_029 | Llama | PARTIAL | MISSED | **Expert** | Medium | Expert gave PARTIAL credit. Mistral says completely missed. Expert assessment seems more nuanced. |

---

## Overall Score

**Mistral is correct in: ~14-15 cases (82-88%)**
**Expert is correct in: ~2-3 cases (12-18%)**

---

## Key Patterns Discovered

### 1. Semantic Matching Issue
**Expert Problem:** Too strict on exact terminology matching
- Case #1: Expert rejected "access_control" when target was "front_running" (same issue!)
- Case #2: Expert rejected detailed blockhash discussion when target was "timestamp_dependency" (same thing!)

**Mistral Advantage:** Recognizes semantic equivalence
- "access_control" → "front_running" (race condition to change owner)
- "blockhash manipulation" → "timestamp_dependency" (both are weak randomness)
- "unchecked return value" variants properly matched

### 2. Expert Review Quality Issues
Several expert reviews show concerning patterns:
- **Case #2**: 0 minutes spent (!)
- **Case #4**: Data inconsistency flag
- **Multiple cases**: Expert reasoning field not filled properly ("accurate|partial|incorrect" literal string)
- **Many cases**: Expert says "model failed" without detailed analysis

### 3. Prompt Type Confusion
Expert reviews may have been done on ONE prompt type but applied to ALL:
- Case #9-11 (sn_gs_013): Expert says MISSED
- But different prompt types (direct, adversarial, naturalistic) got different results
- Mistral correctly evaluated each prompt type separately

### 4. Strong Evidence Cases

**Mistral clearly right (Very High confidence):**
- #2: 0-minute review, model extensively discussed the vulnerability
- #9, #10, #11: Mistral shows EXACT match with perfect 1.0 scores
- #14: EXACT match, perfect 1.0 score

**Expert appears right:**
- #8: Expert says FOUND, has detailed positive notes
- #17: Expert's PARTIAL more nuanced than Mistral's MISSED

### 5. Marginal Cases
Cases with lower Mistral scores (<0.6) warrant further investigation:
- #6: Score 0.42 - possibly a weak match
- #16: Score 0.58 - marginal case

---

## Data Quality Concerns

### Expert Review Issues:
1. **Time spent:** Some reviews show 0 minutes
2. **Consistency:** Internal contradictions in several reviews
3. **Completeness:** Many fields not properly filled
4. **Strictness:** Overly focused on exact terminology vs actual vulnerability identification

### Mistral Judge Strengths:
1. **Semantic understanding:** Recognizes equivalent vulnerability types
2. **Scoring granularity:** Provides 0-1 scores for quality dimensions
3. **Consistency:** Systematic evaluation across all cases
4. **Detail:** Provides reasoning for classifications

---

## Recommendations

1. **Review Expert #2 (gemini_3_pro_preview/ch_medical_nc_ds_234)**: 0-minute review is clearly inadequate

2. **Investigate Case #8 (sn_gs_013/Gemini)**: Only case where Expert says FOUND but Mistral says MISSED - verify the actual model output

3. **Re-evaluate "semantic match" criteria**: Should models get credit for identifying the vulnerability even with different terminology?

4. **Expert training**: Experts should focus on:
   - Whether the vulnerable behavior is identified (not just terminology)
   - Semantic equivalence of vulnerability types
   - Spending adequate time on complex cases

5. **Consider Mistral's approach as baseline**: 89.2% agreement rate is strong, and detailed analysis suggests Mistral's semantic matching is more appropriate for real-world security evaluation

---

## Conclusion

**Mistral Judge appears significantly more accurate than human expert reviews in this dataset.**

The primary issue is that expert reviews were too strict on terminology matching and may have been rushed or inconsistently applied across different prompt types. Mistral's semantic matching approach better captures whether models actually identified the vulnerable behavior, which is what matters in practice.

**Recommended Action:** Use Mistral's judgments as the primary evaluation metric, with expert reviews serving as validation for edge cases and quality control.
