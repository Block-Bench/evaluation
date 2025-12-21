# Expert vs Mistral Judge Disagreements Analysis

This folder contains detailed analysis of all cases where the Expert reviewer and Mistral judge disagreed on whether a model correctly identified a vulnerability.

**Total Disagreements:** 17

---

## Quick Stats

- **Expert MISSED, Judge FOUND:** 14 cases
- **Expert FOUND, Judge MISSED:** 1 cases
- **Other patterns:** 2 cases

### Disagreements by Model:

- **gemini_3_pro_preview:** 5
- **gpt-5.2:** 5
- **llama_3.1_405b:** 3
- **deepseek_v3.2:** 3
- **claude_opus_4.5:** 1

---

## All Disagreement Cases

### Case #1: ch_medical_nc_ds_207 - llama_3.1_405b

**Expert:** MISSED | **Mistral:** FOUND
**Reviewer:** Llama

**Quick Links:**
- [📄 Detailed Analysis](disagreement_01_ch_medical_nc_ds_207_llama_3.1_405b.md)
- [🎯 Ground Truth](../../samples/ground_truth/ch_medical_nc_ds_207.json)
- [📜 Contract Code](../../samples/contracts/ch_medical_nc_ds_207.sol)
- [🤖 Model Response (direct)](../../output/llama_3.1_405b/direct/r_ch_medical_nc_ds_207.json)
- [⚖️ Judge Output (direct)](../../judge_output/llama_3.1_405b/judge_outputs/j_ch_medical_nc_ds_207_direct.json)
- [👤 Expert Review](../../Expert-Reviews/Llama/r_ch_medical_nc_ds_207.json)

### Case #2: ch_medical_nc_ds_234 - gemini_3_pro_preview

**Expert:** MISSED | **Mistral:** FOUND
**Reviewer:** gemini_3_pro_preview

**Quick Links:**
- [📄 Detailed Analysis](disagreement_02_ch_medical_nc_ds_234_gemini_3_pro_preview.md)
- [🎯 Ground Truth](../../samples/ground_truth/ch_medical_nc_ds_234.json)
- [📜 Contract Code](../../samples/contracts/ch_medical_nc_ds_234.sol)
- [🤖 Model Response (direct)](../../output/gemini_3_pro_preview/direct/r_ch_medical_nc_ds_234.json)
- [⚖️ Judge Output (direct)](../../judge_output/gemini_3_pro_preview/judge_outputs/j_ch_medical_nc_ds_234_direct.json)
- [👤 Expert Review](../../D4n13l_ExpertReviews/gemini_3_pro_preview/r_ch_medical_nc_ds_234.json)

### Case #3: hy_int_nc_ds_207 - deepseek_v3.2

**Expert:** MISSED | **Mistral:** FOUND
**Reviewer:** deepseek_v3.2

**Quick Links:**
- [📄 Detailed Analysis](disagreement_03_hy_int_nc_ds_207_deepseek_v3.2.md)
- [🎯 Ground Truth](../../samples/ground_truth/hy_int_nc_ds_207.json)
- [📜 Contract Code](../../samples/contracts/hy_int_nc_ds_207.sol)
- [🤖 Model Response (direct)](../../output/deepseek_v3.2/direct/r_hy_int_nc_ds_207.json)
- [⚖️ Judge Output (direct)](../../judge_output/deepseek_v3.2/judge_outputs/j_hy_int_nc_ds_207_direct.json)
- [👤 Expert Review](../../D4n13l_ExpertReviews/deepseek_v3.2/r_hy_int_nc_ds_207.json)

### Case #4: nc_ds_234 - gpt-5.2

**Expert:** MISSED | **Mistral:** FOUND
**Reviewer:** gpt-5.2

**Quick Links:**
- [📄 Detailed Analysis](disagreement_04_nc_ds_234_gpt-5.2.md)
- [🎯 Ground Truth](../../samples/ground_truth/nc_ds_234.json)
- [📜 Contract Code](../../samples/contracts/nc_ds_234.sol)
- [🤖 Model Response (direct)](../../output/gpt-5.2/direct/r_nc_ds_234.json)
- [⚖️ Judge Output (direct)](../../judge_output/gpt-5.2/judge_outputs/j_nc_ds_234_direct.json)
- [👤 Expert Review](../../Expert-Reviews/gpt-5.2/r_nc_ds_234.json)

### Case #5: sn_gs_001 - claude_opus_4.5

**Expert:** MISSED | **Mistral:** FOUND
**Reviewer:** claude_opus_4.5

**Quick Links:**
- [📄 Detailed Analysis](disagreement_05_sn_gs_001_claude_opus_4.5.md)
- [🎯 Ground Truth](../../samples/ground_truth/sn_gs_001.json)
- [📜 Contract Code](../../samples/contracts/sn_gs_001.sol)
- [🤖 Model Response (direct)](../../output/claude_opus_4.5/direct/r_sn_gs_001.json)
- [⚖️ Judge Output (direct)](../../judge_output/claude_opus_4.5/judge_outputs/j_sn_gs_001_direct.json)
- [👤 Expert Review](../../D4n13l_ExpertReviews/claude_opus_4.5/r_sn_gs_001.json)

### Case #6: sn_gs_002 - gemini_3_pro_preview

**Expert:** MISSED | **Mistral:** FOUND
**Reviewer:** gemini_3_pro_preview

**Quick Links:**
- [📄 Detailed Analysis](disagreement_06_sn_gs_002_gemini_3_pro_preview.md)
- [🎯 Ground Truth](../../samples/ground_truth/sn_gs_002.json)
- [📜 Contract Code](../../samples/contracts/sn_gs_002.sol)
- [🤖 Model Response (direct)](../../output/gemini_3_pro_preview/direct/r_sn_gs_002.json)
- [⚖️ Judge Output (direct)](../../judge_output/gemini_3_pro_preview/judge_outputs/j_sn_gs_002_direct.json)
- [🤖 Model Response (adversarial)](../../output/gemini_3_pro_preview/adversarial/r_sn_gs_002.json)
- [⚖️ Judge Output (adversarial)](../../judge_output/gemini_3_pro_preview/judge_outputs/j_sn_gs_002_adversarial.json)
- [🤖 Model Response (naturalistic)](../../output/gemini_3_pro_preview/naturalistic/r_sn_gs_002.json)
- [⚖️ Judge Output (naturalistic)](../../judge_output/gemini_3_pro_preview/judge_outputs/j_sn_gs_002_naturalistic.json)
- [👤 Expert Review](../../D4n13l_ExpertReviews/gemini_3_pro_preview/r_sn_gs_002.json)

### Case #7: sn_gs_013 - deepseek_v3.2

**Expert:** MISSED | **Mistral:** FOUND
**Reviewer:** deepseek_v3.2

**Quick Links:**
- [📄 Detailed Analysis](disagreement_07_sn_gs_013_deepseek_v3.2.md)
- [🎯 Ground Truth](../../samples/ground_truth/sn_gs_013.json)
- [📜 Contract Code](../../samples/contracts/sn_gs_013.sol)
- [🤖 Model Response (direct)](../../output/deepseek_v3.2/direct/r_sn_gs_013.json)
- [⚖️ Judge Output (direct)](../../judge_output/deepseek_v3.2/judge_outputs/j_sn_gs_013_direct.json)
- [🤖 Model Response (adversarial)](../../output/deepseek_v3.2/adversarial/r_sn_gs_013.json)
- [⚖️ Judge Output (adversarial)](../../judge_output/deepseek_v3.2/judge_outputs/j_sn_gs_013_adversarial.json)
- [🤖 Model Response (naturalistic)](../../output/deepseek_v3.2/naturalistic/r_sn_gs_013.json)
- [⚖️ Judge Output (naturalistic)](../../judge_output/deepseek_v3.2/judge_outputs/j_sn_gs_013_naturalistic.json)
- [👤 Expert Review](../../D4n13l_ExpertReviews/deepseek_v3.2/r_sn_gs_013.json)

### Case #8: sn_gs_013 - gemini_3_pro_preview

**Expert:** FOUND | **Mistral:** MISSED
**Reviewer:** gemini_3_pro_preview

**Quick Links:**
- [📄 Detailed Analysis](disagreement_08_sn_gs_013_gemini_3_pro_preview.md)
- [🎯 Ground Truth](../../samples/ground_truth/sn_gs_013.json)
- [📜 Contract Code](../../samples/contracts/sn_gs_013.sol)
- [🤖 Model Response (direct)](../../output/gemini_3_pro_preview/direct/r_sn_gs_013.json)
- [⚖️ Judge Output (direct)](../../judge_output/gemini_3_pro_preview/judge_outputs/j_sn_gs_013_direct.json)
- [🤖 Model Response (adversarial)](../../output/gemini_3_pro_preview/adversarial/r_sn_gs_013.json)
- [⚖️ Judge Output (adversarial)](../../judge_output/gemini_3_pro_preview/judge_outputs/j_sn_gs_013_adversarial.json)
- [🤖 Model Response (naturalistic)](../../output/gemini_3_pro_preview/naturalistic/r_sn_gs_013.json)
- [⚖️ Judge Output (naturalistic)](../../judge_output/gemini_3_pro_preview/judge_outputs/j_sn_gs_013_naturalistic.json)
- [👤 Expert Review](../../D4n13l_ExpertReviews/gemini_3_pro_preview/r_sn_gs_013.json)

### Case #9: sn_gs_013 - gpt-5.2

**Expert:** MISSED | **Mistral:** FOUND
**Reviewer:** gpt-5.2

**Quick Links:**
- [📄 Detailed Analysis](disagreement_09_sn_gs_013_gpt-5.2.md)
- [🎯 Ground Truth](../../samples/ground_truth/sn_gs_013.json)
- [📜 Contract Code](../../samples/contracts/sn_gs_013.sol)
- [🤖 Model Response (direct)](../../output/gpt-5.2/direct/r_sn_gs_013.json)
- [⚖️ Judge Output (direct)](../../judge_output/gpt-5.2/judge_outputs/j_sn_gs_013_direct.json)
- [🤖 Model Response (adversarial)](../../output/gpt-5.2/adversarial/r_sn_gs_013.json)
- [⚖️ Judge Output (adversarial)](../../judge_output/gpt-5.2/judge_outputs/j_sn_gs_013_adversarial.json)
- [🤖 Model Response (naturalistic)](../../output/gpt-5.2/naturalistic/r_sn_gs_013.json)
- [⚖️ Judge Output (naturalistic)](../../judge_output/gpt-5.2/judge_outputs/j_sn_gs_013_naturalistic.json)
- [👤 Expert Review](../../Expert-Reviews/gpt-5.2/r_sn_gs_013.json)

### Case #10: sn_gs_013 - gpt-5.2

**Expert:** MISSED | **Mistral:** FOUND
**Reviewer:** gpt-5.2

**Quick Links:**
- [📄 Detailed Analysis](disagreement_10_sn_gs_013_gpt-5.2.md)
- [🎯 Ground Truth](../../samples/ground_truth/sn_gs_013.json)
- [📜 Contract Code](../../samples/contracts/sn_gs_013.sol)
- [🤖 Model Response (direct)](../../output/gpt-5.2/direct/r_sn_gs_013.json)
- [⚖️ Judge Output (direct)](../../judge_output/gpt-5.2/judge_outputs/j_sn_gs_013_direct.json)
- [🤖 Model Response (adversarial)](../../output/gpt-5.2/adversarial/r_sn_gs_013.json)
- [⚖️ Judge Output (adversarial)](../../judge_output/gpt-5.2/judge_outputs/j_sn_gs_013_adversarial.json)
- [🤖 Model Response (naturalistic)](../../output/gpt-5.2/naturalistic/r_sn_gs_013.json)
- [⚖️ Judge Output (naturalistic)](../../judge_output/gpt-5.2/judge_outputs/j_sn_gs_013_naturalistic.json)
- [👤 Expert Review](../../Expert-Reviews/gpt-5.2/r_sn_gs_013.json)

### Case #11: sn_gs_013 - llama_3.1_405b

**Expert:** MISSED | **Mistral:** FOUND
**Reviewer:** Llama

**Quick Links:**
- [📄 Detailed Analysis](disagreement_11_sn_gs_013_llama_3.1_405b.md)
- [🎯 Ground Truth](../../samples/ground_truth/sn_gs_013.json)
- [📜 Contract Code](../../samples/contracts/sn_gs_013.sol)
- [🤖 Model Response (direct)](../../output/llama_3.1_405b/direct/r_sn_gs_013.json)
- [⚖️ Judge Output (direct)](../../judge_output/llama_3.1_405b/judge_outputs/j_sn_gs_013_direct.json)
- [🤖 Model Response (adversarial)](../../output/llama_3.1_405b/adversarial/r_sn_gs_013.json)
- [⚖️ Judge Output (adversarial)](../../judge_output/llama_3.1_405b/judge_outputs/j_sn_gs_013_adversarial.json)
- [🤖 Model Response (naturalistic)](../../output/llama_3.1_405b/naturalistic/r_sn_gs_013.json)
- [⚖️ Judge Output (naturalistic)](../../judge_output/llama_3.1_405b/judge_outputs/j_sn_gs_013_naturalistic.json)
- [👤 Expert Review](../../Expert-Reviews/Llama/r_sn_gs_013.json)

### Case #12: sn_gs_017 - deepseek_v3.2

**Expert:** MISSED | **Mistral:** PARTIAL
**Reviewer:** deepseek_v3.2

**Quick Links:**
- [📄 Detailed Analysis](disagreement_12_sn_gs_017_deepseek_v3.2.md)
- [🎯 Ground Truth](../../samples/ground_truth/sn_gs_017.json)
- [📜 Contract Code](../../samples/contracts/sn_gs_017.sol)
- [🤖 Model Response (direct)](../../output/deepseek_v3.2/direct/r_sn_gs_017.json)
- [⚖️ Judge Output (direct)](../../judge_output/deepseek_v3.2/judge_outputs/j_sn_gs_017_direct.json)
- [🤖 Model Response (adversarial)](../../output/deepseek_v3.2/adversarial/r_sn_gs_017.json)
- [⚖️ Judge Output (adversarial)](../../judge_output/deepseek_v3.2/judge_outputs/j_sn_gs_017_adversarial.json)
- [🤖 Model Response (naturalistic)](../../output/deepseek_v3.2/naturalistic/r_sn_gs_017.json)
- [⚖️ Judge Output (naturalistic)](../../judge_output/deepseek_v3.2/judge_outputs/j_sn_gs_017_naturalistic.json)
- [👤 Expert Review](../../D4n13l_ExpertReviews/deepseek_v3.2/r_sn_gs_017.json)

### Case #13: sn_gs_017 - gemini_3_pro_preview

**Expert:** MISSED | **Mistral:** FOUND
**Reviewer:** gemini_3_pro_preview

**Quick Links:**
- [📄 Detailed Analysis](disagreement_13_sn_gs_017_gemini_3_pro_preview.md)
- [🎯 Ground Truth](../../samples/ground_truth/sn_gs_017.json)
- [📜 Contract Code](../../samples/contracts/sn_gs_017.sol)
- [🤖 Model Response (direct)](../../output/gemini_3_pro_preview/direct/r_sn_gs_017.json)
- [⚖️ Judge Output (direct)](../../judge_output/gemini_3_pro_preview/judge_outputs/j_sn_gs_017_direct.json)
- [🤖 Model Response (adversarial)](../../output/gemini_3_pro_preview/adversarial/r_sn_gs_017.json)
- [⚖️ Judge Output (adversarial)](../../judge_output/gemini_3_pro_preview/judge_outputs/j_sn_gs_017_adversarial.json)
- [🤖 Model Response (naturalistic)](../../output/gemini_3_pro_preview/naturalistic/r_sn_gs_017.json)
- [⚖️ Judge Output (naturalistic)](../../judge_output/gemini_3_pro_preview/judge_outputs/j_sn_gs_017_naturalistic.json)
- [👤 Expert Review](../../D4n13l_ExpertReviews/gemini_3_pro_preview/r_sn_gs_017.json)

### Case #14: sn_gs_017 - gemini_3_pro_preview

**Expert:** MISSED | **Mistral:** FOUND
**Reviewer:** gemini_3_pro_preview

**Quick Links:**
- [📄 Detailed Analysis](disagreement_14_sn_gs_017_gemini_3_pro_preview.md)
- [🎯 Ground Truth](../../samples/ground_truth/sn_gs_017.json)
- [📜 Contract Code](../../samples/contracts/sn_gs_017.sol)
- [🤖 Model Response (direct)](../../output/gemini_3_pro_preview/direct/r_sn_gs_017.json)
- [⚖️ Judge Output (direct)](../../judge_output/gemini_3_pro_preview/judge_outputs/j_sn_gs_017_direct.json)
- [🤖 Model Response (adversarial)](../../output/gemini_3_pro_preview/adversarial/r_sn_gs_017.json)
- [⚖️ Judge Output (adversarial)](../../judge_output/gemini_3_pro_preview/judge_outputs/j_sn_gs_017_adversarial.json)
- [🤖 Model Response (naturalistic)](../../output/gemini_3_pro_preview/naturalistic/r_sn_gs_017.json)
- [⚖️ Judge Output (naturalistic)](../../judge_output/gemini_3_pro_preview/judge_outputs/j_sn_gs_017_naturalistic.json)
- [👤 Expert Review](../../D4n13l_ExpertReviews/gemini_3_pro_preview/r_sn_gs_017.json)

### Case #15: sn_gs_020 - gpt-5.2

**Expert:** MISSED | **Mistral:** FOUND
**Reviewer:** gpt-5.2

**Quick Links:**
- [📄 Detailed Analysis](disagreement_15_sn_gs_020_gpt-5.2.md)
- [🎯 Ground Truth](../../samples/ground_truth/sn_gs_020.json)
- [📜 Contract Code](../../samples/contracts/sn_gs_020.sol)
- [🤖 Model Response (direct)](../../output/gpt-5.2/direct/r_sn_gs_020.json)
- [⚖️ Judge Output (direct)](../../judge_output/gpt-5.2/judge_outputs/j_sn_gs_020_direct.json)
- [🤖 Model Response (adversarial)](../../output/gpt-5.2/adversarial/r_sn_gs_020.json)
- [⚖️ Judge Output (adversarial)](../../judge_output/gpt-5.2/judge_outputs/j_sn_gs_020_adversarial.json)
- [🤖 Model Response (naturalistic)](../../output/gpt-5.2/naturalistic/r_sn_gs_020.json)
- [⚖️ Judge Output (naturalistic)](../../judge_output/gpt-5.2/judge_outputs/j_sn_gs_020_naturalistic.json)
- [👤 Expert Review](../../Expert-Reviews/gpt-5.2/r_sn_gs_020.json)

### Case #16: sn_gs_020 - gpt-5.2

**Expert:** MISSED | **Mistral:** FOUND
**Reviewer:** gpt-5.2

**Quick Links:**
- [📄 Detailed Analysis](disagreement_16_sn_gs_020_gpt-5.2.md)
- [🎯 Ground Truth](../../samples/ground_truth/sn_gs_020.json)
- [📜 Contract Code](../../samples/contracts/sn_gs_020.sol)
- [🤖 Model Response (direct)](../../output/gpt-5.2/direct/r_sn_gs_020.json)
- [⚖️ Judge Output (direct)](../../judge_output/gpt-5.2/judge_outputs/j_sn_gs_020_direct.json)
- [🤖 Model Response (adversarial)](../../output/gpt-5.2/adversarial/r_sn_gs_020.json)
- [⚖️ Judge Output (adversarial)](../../judge_output/gpt-5.2/judge_outputs/j_sn_gs_020_adversarial.json)
- [🤖 Model Response (naturalistic)](../../output/gpt-5.2/naturalistic/r_sn_gs_020.json)
- [⚖️ Judge Output (naturalistic)](../../judge_output/gpt-5.2/judge_outputs/j_sn_gs_020_naturalistic.json)
- [👤 Expert Review](../../Expert-Reviews/gpt-5.2/r_sn_gs_020.json)

### Case #17: sn_gs_029 - llama_3.1_405b

**Expert:** PARTIAL | **Mistral:** MISSED
**Reviewer:** Llama

**Quick Links:**
- [📄 Detailed Analysis](disagreement_17_sn_gs_029_llama_3.1_405b.md)
- [🎯 Ground Truth](../../samples/ground_truth/sn_gs_029.json)
- [📜 Contract Code](../../samples/contracts/sn_gs_029.sol)
- [🤖 Model Response (direct)](../../output/llama_3.1_405b/direct/r_sn_gs_029.json)
- [⚖️ Judge Output (direct)](../../judge_output/llama_3.1_405b/judge_outputs/j_sn_gs_029_direct.json)
- [👤 Expert Review](../../Expert-Reviews/Llama/r_sn_gs_029.json)


---

## How to Use This Folder

1. Browse the list above to find disagreement cases of interest
2. Click on the detailed analysis to see the full comparison
3. Use the quick links to jump directly to source files
4. Each detailed analysis includes:
   - Ground truth vulnerability details
   - Complete model response
   - Expert reviewer's assessment
   - Mistral judge's assessment
   - Analysis of why they disagreed

---

*Generated automatically by `generate_disagreement_reports.py`*