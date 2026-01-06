# DS Strict Majority Vote Results

**Judges:** glm-4.7, mimo-v2-flash, mistral-large
**Method:** Majority vote with strict location validation

## Strict Rule
If a judge marks `target_found=true` but `location_match=false`, we verify if
`location_claimed` actually matches any function in ground truth's `vulnerable_functions`.
If not, we override to `target_found=false`.

## TDR by Detector and Tier (STRICT)

| Detector | T1 | T2 | T3 | T4 | Avg |
|----------|------:|------:|------:|------:|------:|
| Claude | 100.0 | 83.8 | 66.7 | 92.3 | 85.7 |
| DeepSeek | 60.0 | 64.9 | 43.3 | 61.5 | 57.4 |
| Gemini | 75.0 | 78.4 | 50.0 | 92.3 | 73.9 |
| GPT-5.2 | 60.0 | 70.3 | 36.7 | 84.6 | 62.9 |
| Grok | 40.0 | 37.8 | 33.3 | 30.8 | 35.5 |
| Llama | 65.0 | 45.9 | 40.0 | 69.2 | 55.0 |
| Qwen | 55.0 | 56.8 | 43.3 | 53.8 | 52.2 |

## Inter-Judge Agreement (STRICT)

| Detector | T1 | T2 | T3 | T4 |
|----------|------:|------:|------:|------:|
| Claude | κ=-0.09 (75%) | κ=0.56 (76%) | κ=0.60 (73%) | κ=0.54 (85%) |
| DeepSeek | κ=0.79 (85%) | κ=0.70 (78%) | κ=0.69 (77%) | κ=0.48 (62%) |
| Gemini | κ=0.62 (75%) | κ=0.64 (78%) | κ=0.51 (63%) | κ=0.54 (85%) |
| GPT-5.2 | κ=0.80 (85%) | κ=0.79 (86%) | κ=0.81 (87%) | κ=0.83 (92%) |
| Grok | κ=0.93 (95%) | κ=0.84 (89%) | κ=0.73 (83%) | κ=0.87 (92%) |
| Llama | κ=0.41 (60%) | κ=0.64 (73%) | κ=0.77 (83%) | κ=0.55 (69%) |
| Qwen | κ=0.73 (80%) | κ=0.71 (78%) | κ=0.72 (80%) | κ=0.48 (62%) |

## Override Statistics

Total overrides: 9
Total samples checked: 700