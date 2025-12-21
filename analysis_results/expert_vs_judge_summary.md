# Expert vs Mistral Judge Comparison Report

**Total Comparisons:** 158

## 1. Primary Verdict Agreement

- **Exact Match:** 141 (89.2%)
- **Lenient Match (FOUND/PARTIAL):** 0 (0.0%)
- **Disagree:** 17 (10.8%)

**Combined Agreement Rate:** 89.2%

## 2. Agreement by Evaluated Model

| Model | Total | Exact | Lenient | Disagree | Agreement % |
|-------|-------|-------|---------|----------|-------------|
| claude_opus_4.5 | 34 | 33 | 0 | 1 | 97.1% |
| deepseek_v3.2 | 35 | 32 | 0 | 3 | 91.4% |
| gemini_3_pro_preview | 31 | 26 | 0 | 5 | 83.9% |
| gpt-5.2 | 29 | 24 | 0 | 5 | 82.8% |
| grok_4 | 3 | 3 | 0 | 0 | 100.0% |
| llama_3.1_405b | 26 | 23 | 0 | 3 | 88.5% |

## 3. Vulnerability Type Correctness

- **Agree:** 139 (88.5%)
- **Disagree:** 18 (11.5%)

## 4. Reasoning Quality Agreement

- **Close (≤0.3 difference):** 41 (82.0%)
- **Different (>0.3 difference):** 9 (18.0%)

## 5. Bonus Findings Count Agreement

- **Exact Match:** 104 (65.8%)
- **Close (±1):** 35 (22.2%)
- **Different (>1):** 19 (12.0%)

## 6. Data Quality Issues in Expert Reviews

**Total Reviews with Issues:** 9

| Issue Type | Count |
|------------|-------|
| inconsistent_found_status | 8 |
| empty_reasoning_quality | 1 |

## 7. Notable Disagreements

Found 17 cases where Expert and Mistral completely disagreed.

### 1. ch_medical_nc_ds_207 (llama_3.1_405b)
- **Expert:** MISSED
- **Mistral:** FOUND

### 2. ch_medical_nc_ds_234 (gemini_3_pro_preview)
- **Expert:** MISSED
- **Mistral:** FOUND

### 3. hy_int_nc_ds_207 (deepseek_v3.2)
- **Expert:** MISSED
- **Mistral:** FOUND

### 4. nc_ds_234 (gpt-5.2)
- **Expert:** MISSED
- **Mistral:** FOUND
- **Data Issues:** inconsistent_found_status

### 5. sn_gs_001 (claude_opus_4.5)
- **Expert:** MISSED
- **Mistral:** FOUND

### 6. sn_gs_002 (gemini_3_pro_preview)
- **Expert:** MISSED
- **Mistral:** FOUND

### 7. sn_gs_013 (deepseek_v3.2)
- **Expert:** MISSED
- **Mistral:** FOUND

### 8. sn_gs_013 (gemini_3_pro_preview)
- **Expert:** FOUND
- **Mistral:** MISSED

### 9. sn_gs_013 (gpt-5.2)
- **Expert:** MISSED
- **Mistral:** FOUND

### 10. sn_gs_013 (gpt-5.2)
- **Expert:** MISSED
- **Mistral:** FOUND

*...and 7 more disagreements*

