# TC Majority Vote Results

**Judges:** glm-4.7, mimo-v2-flash, mistral-large
**Method:** Majority vote (2-of-3 judges must agree target was found)

## TDR by Detector and Variant

| Detector | MinSan | San | NoCom | Cham | Shape | Troj | FalseP | Avg |
|----------|------:|------:|------:|------:|------:|------:|------:|------:|
| Claude | 71.7 | 54.3 | 50.0 | 43.5 | 50.0 | 32.6 | 54.3 | 50.9 |
| DeepSeek | 58.7 | 37.0 | 41.3 | 21.7 | 26.1 | 43.5 | 30.4 | 37.0 |
| Gemini | 65.2 | 28.3 | 32.6 | 37.0 | 34.8 | 34.8 | 37.0 | 38.5 |
| GPT-5.2 | 54.3 | 34.8 | 37.0 | 28.3 | 30.4 | 30.4 | 37.0 | 36.0 |
| Grok | 32.6 | 23.9 | 19.6 | 15.2 | 15.2 | 21.7 | 21.7 | 21.4 |
| Llama | 52.2 | 39.1 | 30.4 | 21.7 | 13.0 | 43.5 | 21.7 | 31.7 |
| Qwen | 56.5 | 43.5 | 30.4 | 15.2 | 17.4 | 28.3 | 41.3 | 33.2 |

## Inter-Judge Agreement (Fleiss' κ)

| Detector | MinSan | San | NoCom | Cham | Shape | Troj | FalseP |
|----------|------:|------:|------:|------:|------:|------:|------:|
| Claude | 0.59 | 0.07 | 0.06 | 0.13 | 0.08 | 0.05 | 0.14 |
| DeepSeek | 0.68 | 0.10 | 0.07 | 0.17 | 0.16 | 0.11 | 0.09 |
| Gemini | 0.57 | 0.23 | 0.23 | 0.21 | 0.23 | 0.20 | 0.17 |
| GPT-5.2 | 0.77 | 0.20 | 0.12 | 0.23 | 0.24 | 0.22 | 0.21 |
| Grok | 0.59 | 0.29 | 0.36 | 0.27 | 0.27 | 0.32 | 0.32 |
| Llama | 0.68 | 0.04 | 0.11 | 0.27 | 0.16 | 0.04 | 0.13 |
| Qwen | 0.54 | 0.11 | 0.20 | 0.36 | 0.17 | 0.07 | 0.05 |

## Legend
- **TDR**: Target Detection Rate (% of samples where majority of judges found target)
- **κ**: Fleiss' kappa (inter-rater agreement, -1 to 1, >0.6 is substantial)

## Variant Descriptions
- **MinSan**: Minimal sanitization (comments removed, formatting standardized)
- **San**: Full sanitization (identifiers renamed, structure preserved)
- **NoCom**: Comments removed only
- **Cham**: Chameleon Medical (domain recontextualization to medical)
- **Shape**: ShapeShifter L3 (code restructuring/obfuscation)
- **Troj**: Trojan (hidden vulnerability variants)
- **FalseP**: False Prophet (misleading comments added)