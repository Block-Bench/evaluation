# Table 3: Quality Metrics with 95% Confidence Intervals

| Model | SUI | Precision | RCIR | AVA | FSV | LGR | Halluc. |
|-------|----:|----------:|-----:|----:|----:|----:|--------:|
| Claude | 0.757 | 73.0% | 0.97 | 0.90 | 0.96 | 33.7% | 0.4% |
| GPT-5.2 | 0.744 | 89.6% | 0.99 | 0.95 | 0.97 | 48.5% | 1.1% |
| Gemini | 0.737 | 81.5% | 0.99 | 0.93 | 0.96 | 42.8% | 1.4% |
| Grok | 0.616 | 74.5% | 0.99 | 0.94 | 0.94 | 57.3% | 1.3% |
| DeepSeek | 0.580 | 41.0% | 0.96 | 0.87 | 0.93 | 52.8% | 2.1% |
| Qwen | 0.547 | 41.0% | 0.92 | 0.80 | 0.89 | 56.6% | 0.6% |
| Llama | 0.481 | 23.7% | 0.89 | 0.73 | 0.87 | 59.2% | 0.9% |

## SUI Sensitivity Analysis

| Config | Weights (TDR/R̄/Prec) | Ranking | Spearman's ρ vs Default |
|--------|----------------------|---------|------------------------|
| balanced | 0.33/0.33/0.34 | Gemini > Claude > GPT-5.2 ... | 0.964 |
| detection_default | 0.40/0.30/0.30 | Claude > Gemini > GPT-5.2 ... | 1.000 (baseline) |
| quality_first | 0.30/0.40/0.30 | Gemini > Claude > GPT-5.2 ... | 0.964 |
| precision_first | 0.30/0.30/0.40 | Gemini > Claude > GPT-5.2 ... | 0.964 |
| detection_heavy | 0.50/0.25/0.25 | Claude > Gemini > GPT-5.2 ... | 0.964 |