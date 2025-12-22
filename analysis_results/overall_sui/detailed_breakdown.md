# Overall SUI Calculation - Detailed Breakdown

**Formula:** SUI = 0.4·TDR + 0.3·Reasoning + 0.3·Precision

## 1. GPT-5.2

- **Total Samples:** 68
- **Vulnerable Samples:** 68
- **Targets Found:** 38
- **TDR:** 55.9%
- **Mean Reasoning:** 0.974
  - RCIR: 0.974
  - AVA: 0.980
  - FSV: 0.967
- **Finding Precision:** 76.6%
- **Accuracy:** 75.0%
- **Avg Findings per Sample:** 2.4

**SUI Calculation:**
```
SUI = 0.4×0.559 + 0.3×0.974 + 0.3×0.766
    = 0.224 + 0.292 + 0.230
    = 0.746
```

## 2. Gemini 3 Pro

- **Total Samples:** 66
- **Vulnerable Samples:** 66
- **Targets Found:** 38
- **TDR:** 57.6%
- **Mean Reasoning:** 0.963
  - RCIR: 0.967
  - AVA: 0.974
  - FSV: 0.947
- **Finding Precision:** 71.5%
- **Accuracy:** 93.9%
- **Avg Findings per Sample:** 2.6

**SUI Calculation:**
```
SUI = 0.4×0.576 + 0.3×0.963 + 0.3×0.715
    = 0.230 + 0.289 + 0.214
    = 0.734
```

## 3. Claude Opus 4.5

- **Total Samples:** 68
- **Vulnerable Samples:** 68
- **Targets Found:** 36
- **TDR:** 52.9%
- **Mean Reasoning:** 0.979
  - RCIR: 0.979
  - AVA: 0.993
  - FSV: 0.965
- **Finding Precision:** 65.9%
- **Accuracy:** 83.8%
- **Avg Findings per Sample:** 3.5

**SUI Calculation:**
```
SUI = 0.4×0.529 + 0.3×0.979 + 0.3×0.659
    = 0.212 + 0.294 + 0.198
    = 0.703
```

## 4. Grok 4

- **Total Samples:** 68
- **Vulnerable Samples:** 68
- **Targets Found:** 30
- **TDR:** 44.1%
- **Mean Reasoning:** 0.983
  - RCIR: 0.983
  - AVA: 1.000
  - FSV: 0.967
- **Finding Precision:** 68.4%
- **Accuracy:** 69.1%
- **Avg Findings per Sample:** 2.1

**SUI Calculation:**
```
SUI = 0.4×0.441 + 0.3×0.983 + 0.3×0.684
    = 0.176 + 0.295 + 0.205
    = 0.677
```

## 5. DeepSeek v3.2

- **Total Samples:** 68
- **Vulnerable Samples:** 68
- **Targets Found:** 26
- **TDR:** 38.2%
- **Mean Reasoning:** 0.896
  - RCIR: 0.910
  - AVA: 0.915
  - FSV: 0.863
- **Finding Precision:** 58.9%
- **Accuracy:** 82.4%
- **Avg Findings per Sample:** 3.0

**SUI Calculation:**
```
SUI = 0.4×0.382 + 0.3×0.896 + 0.3×0.589
    = 0.153 + 0.269 + 0.177
    = 0.599
```

## 6. Llama 3.1 405B

- **Total Samples:** 67
- **Vulnerable Samples:** 67
- **Targets Found:** 12
- **TDR:** 17.9%
- **Mean Reasoning:** 0.868
  - RCIR: 0.875
  - AVA: 0.896
  - FSV: 0.833
- **Finding Precision:** 20.4%
- **Accuracy:** 88.1%
- **Avg Findings per Sample:** 2.0

**SUI Calculation:**
```
SUI = 0.4×0.179 + 0.3×0.868 + 0.3×0.204
    = 0.072 + 0.260 + 0.061
    = 0.393
```

