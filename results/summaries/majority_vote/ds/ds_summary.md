# DS Majority Vote Results

**Judges:** glm-4.7, mimo-v2-flash, mistral-large
**Method:** Majority vote (2-of-3 judges must agree target was found)

## TDR by Detector and Tier

| Detector | T1 | T2 | T3 | T4 | Avg |
|----------|------:|------:|------:|------:|------:|
| Claude | 100.0 | 83.8 | 70.0 | 92.3 | 86.5 |
| DeepSeek | 65.0 | 64.9 | 46.7 | 61.5 | 59.5 |
| Gemini | 75.0 | 78.4 | 50.0 | 92.3 | 73.9 |
| GPT-5.2 | 60.0 | 70.3 | 36.7 | 84.6 | 62.9 |
| Grok | 40.0 | 37.8 | 33.3 | 30.8 | 35.5 |
| Llama | 65.0 | 45.9 | 40.0 | 69.2 | 55.0 |
| Qwen | 60.0 | 56.8 | 43.3 | 53.8 | 53.5 |

## Inter-Judge Agreement

| Detector | T1 | T2 | T3 | T4 |
|----------|------:|------:|------:|------:|
| Claude | κ=-0.09 (75% unan) | κ=0.56 (76% unan) | κ=0.53 (70% unan) | κ=0.54 (85% unan) |
| DeepSeek | κ=0.79 (85% unan) | κ=0.70 (78% unan) | κ=0.64 (73% unan) | κ=0.48 (62% unan) |
| Gemini | κ=0.62 (75% unan) | κ=0.64 (78% unan) | κ=0.47 (60% unan) | κ=0.54 (85% unan) |
| GPT-5.2 | κ=0.80 (85% unan) | κ=0.79 (86% unan) | κ=0.81 (87% unan) | κ=0.83 (92% unan) |
| Grok | κ=0.93 (95% unan) | κ=0.84 (89% unan) | κ=0.69 (80% unan) | κ=0.87 (92% unan) |
| Llama | κ=0.41 (60% unan) | κ=0.64 (73% unan) | κ=0.72 (80% unan) | κ=0.55 (69% unan) |
| Qwen | κ=0.72 (80% unan) | κ=0.71 (78% unan) | κ=0.72 (80% unan) | κ=0.48 (62% unan) |

## Legend
- **TDR**: Target Detection Rate (% of samples where majority of judges found target)
- **κ**: Fleiss' kappa (inter-rater agreement, -1 to 1, >0.6 is substantial)
- **unan**: Percentage of samples where all 3 judges agreed