# Metrics Visualization Summary

## Generated Charts

1. **01_model_rankings.png**
   - Three horizontal bar charts showing model rankings
   - Detection Rate, Quality Score, and Finding Precision
   - Sorted by performance with sample counts

2. **02_prompt_type_performance.png**
   - Detection rate and quality by prompt type (Direct, Adversarial, Naturalistic)
   - Grouped bar charts for easy comparison

3. **03_quality_breakdown.png**
   - Breakdown of quality metrics: RCIR, AVA, FSV
   - Shows which models excel at different aspects of vulnerability analysis

4. **04_detection_vs_quality.png**
   - Scatter plot showing trade-off between detection rate and quality
   - Bubble size represents sample count
   - Helps identify balanced vs specialized models

5. **05_hallucination_and_findings.png**
   - Hallucination rates (false findings)
   - Average findings per sample with precision annotations

6. **06_vulnerability_type_performance.png**
   - Detection rates for top 8 vulnerability types
   - Shows which models excel at which vulnerability categories

7. **07_difficulty_tier_performance.png**
   - Performance across different difficulty tiers
   - Shows model degradation on harder samples

8. **08_comprehensive_heatmap.png**
   - Complete performance heatmap across all key metrics
   - Easy to spot strengths and weaknesses at a glance

## How to Use These Charts

- Use charts 1, 4, and 8 for overview presentations
- Use charts 2 and 7 to show robustness across conditions
- Use charts 3 and 5 for detailed capability analysis
- Use chart 6 for domain-specific insights

All charts are saved at 300 DPI for publication quality.
