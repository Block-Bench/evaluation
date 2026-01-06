# GS Majority Vote Results

**Judges:** glm-4.7, mimo-v2-flash, mistral-large
**Method:** Majority vote (2-of-3 judges must agree target was found)

## TDR by Detector and Prompt Type

| Model | Direct | Context | CoT | CoT-Nat | CoT-Adv | Avg |
|-------|-------:|--------:|----:|--------:|--------:|----:|
| Claude | 11.8 | 26.5 | 26.5 | 20.6 | **41.2** | **25.3** |
| Gemini | **17.6** | 20.6 | 17.6 | 26.5 | 32.4 | 22.9 |
| GPT-5.2 | 5.9 | 11.8 | 14.7 | **29.4** | 29.4 | 18.2 |
| Qwen | 0.0 | 5.9 | 14.7 | **32.4** | 17.6 | 14.1 |
| DeepSeek | 0.0 | **20.6** | 8.8 | 17.6 | 17.6 | 12.9 |
| Grok | 2.9 | 8.8 | 8.8 | 14.7 | 8.8 | 8.8 |
| Llama | 2.9 | 0.0 | 8.8 | 2.9 | 0.0 | 2.9 |

## Inter-Judge Agreement (Fleiss' κ)

| Model | Direct | Context | CoT | CoT-Nat | CoT-Adv |
|-------|-------:|--------:|----:|--------:|--------:|
| Claude | 0.74 | 0.70 | 0.81 | 0.89 | 0.66 |
| Gemini | 0.82 | 0.58 | 0.65 | 0.72 | 0.75 |
| GPT-5.2 | 0.65 | 0.62 | 0.78 | 0.70 | 0.77 |
| Grok | 1.00 | 1.00 | 0.76 | 0.82 | 0.89 |
| Qwen | 1.00 | 0.37 | 0.47 | 0.53 | 0.45 |
| DeepSeek | -0.02 | 0.44 | 0.32 | 0.35 | 0.55 |
| Llama | 0.31 | -0.04 | 0.34 | 0.31 | -0.01 |

## Legend

- **TDR**: Target Detection Rate (% of samples where majority of judges found target)
- **κ**: Fleiss' kappa (inter-rater agreement, -1 to 1, >0.6 is substantial)

## Prompt Type Descriptions

- **Direct**: Basic detection prompt with no additional context
- **Context**: Adds protocol documentation context
- **CoT**: Context + Chain-of-Thought reasoning
- **CoT-Nat**: CoT + Naturalistic framing (colleague review style)
- **CoT-Adv**: CoT + Adversarial framing (pentester perspective)

## Key Observations

1. **CoT-Adversarial helps Claude most**: 11.8% → 41.2% (+29.4pp)
2. **CoT-Naturalistic helps Qwen most**: 0.0% → 32.4% (+32.4pp)
3. **Llama struggles across all prompts**: Max 8.8% TDR
4. **Agreement generally high**: Most κ > 0.6 except DeepSeek and Llama
5. **Grok has perfect agreement on simple prompts** (κ=1.0) but low TDR
