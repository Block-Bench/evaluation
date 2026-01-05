# Response to TR Annotation Issues

## Issues Fixed

### 1. README Total Files Count
**Issue**: README claimed 50 files, actual count is 46.
**Fix**: Updated README to show correct count of 46 files.

### 2. base_sample_id Broken References (43 files)
**Issue**: After renumbering, base_sample_id fields pointed to old sample numbers (e.g., tr_tc_004 pointed to ms_tc_005 instead of ms_tc_004).
**Fix**: Updated all 43 affected files to have matching sample IDs:
- tr_tc_004.yaml → base_sample_id: "ms_tc_004"
- tr_tc_005.yaml → base_sample_id: "ms_tc_005"
- ... (all 43 files corrected)

Also updated corresponding `reference` paths in base_vulnerability sections.

### 3. location.file Wrong Contract References (34 files)
**Issue**: Injection location.file fields pointed to wrong contract files after renumbering.
**Fix**: Updated all 34 affected files to reference correct contract:
- tr_tc_004.yaml injections → file: "tr_tc_004.sol"
- tr_tc_005.yaml injections → file: "tr_tc_005.sol"
- ... (all 34 files corrected)

### 4. README staticcall Claim
**Issue**: README claimed "No external calls in distractor code" but some samples use staticcall for read-only operations.
**Fix**: Updated README to clarify: "No state-changing external calls in distractor code (read-only staticcall may be present)"

### 5. base_vulnerability.reference Path Incorrect (37 files)
**Issue**: Reference paths used `../minimalsanitized/` which resolves incorrectly from `trojan/code_acts_annotation/`.
**Fix**: Changed to `../../minimalsanitized/` in all 37 affected files.

Before: `../minimalsanitized/code_acts_annotation/ms_tc_001.yaml`
After: `../../minimalsanitized/code_acts_annotation/ms_tc_001.yaml`

Affected: tr_tc_001–008, tr_tc_018–046

### 6. Removed `code` Field from All Annotations (46 files)
**Issue**: Non-verbatim code snippets and descriptive text in `code` fields.
**Fix**: Removed `code` field entirely from all TR annotation files (605 total removals).

**Rationale**:
- The `code` field is not required by the CodeAct taxonomy
- The `lines` field provides authoritative code location
- The `type` field identifies the Code Act type
- Evaluators reference actual contract code at specified lines
- Removes need to maintain duplicate/descriptive text

**New injection structure**:
```yaml
- id: "INJ1"
  type: "DECLARATION"
  security_function: "DECOY"
  location:
    file: "tr_tc_001.sol"
    function: "global"
    lines: [22, 23, 24]
  suspicious_because:
    - "Names suggest security issues"
  safe_because:
    - "Just counters with no impact"
  pattern_triggered: "suspicious_variable_name"
  distraction_risk: "high"
```

**New code_acts structure**:
```yaml
- id: "CA_ROOT1"
  type: "STATE_MOD"
  lines: [74, 75, 76, 77, 78, 79]
  security_function: "ROOT_CAUSE"
  rationale: "Admin can redirect user funds"
```

## Design Decisions (No Change Required)

### 7. Non-Injected Code Annotated as BENIGN/PREREQ (38 files)
**Issue**: Files 009-046 include code_acts sections annotating non-injected base contract code.
**Rationale for keeping**:
- Provides complete line-to-code_act mapping for evaluation purposes
- Documents relationship between injected decoys and actual vulnerability locations
- Maintains consistency with full annotation schema
- Enables evaluation metrics that need to distinguish ROOT_CAUSE/PREREQ from DECOY

## Summary

| Category | Count | Status |
|----------|-------|--------|
| README total files | 1 | Fixed |
| base_sample_id | 43 | Fixed |
| location.file | 34 | Fixed |
| staticcall claim | 1 | Fixed |
| reference path | 37 | Fixed |
| `code` field removal | 46 (605 fields) | Fixed |
| code_acts in 009-046 | 38 | By design |

**Total files modified**: 46 YAML files + 1 README
