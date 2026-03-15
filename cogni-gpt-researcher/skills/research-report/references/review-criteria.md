# Review Criteria Reference

## Structural Review Dimensions

| Dimension | Weight | Score 0.9+ | Score 0.7-0.89 | Score < 0.7 |
|-----------|--------|-----------|----------------|-------------|
| **Completeness** | 0.25 | All sub-questions addressed | Minor gaps | Major gaps |
| **Coherence** | 0.20 | Smooth flow, clear transitions | Some rough transitions | Disjointed |
| **Source diversity** | 0.20 | 3+ sources per section | 2 sources per section | Single-source sections |
| **Depth** | 0.20 | Specific data, expert analysis | Some specifics | Surface-level only |
| **Clarity** | 0.15 | Professional, well-organized | Readable but rough | Unclear, poorly organized |

## Claims-Based Review

When cogni-claims verification data is available:

### Verification Rate Thresholds
- **>= 0.85**: Excellent — most claims verified against sources
- **0.70 - 0.84**: Good — some issues to address
- **0.50 - 0.69**: Concerning — significant accuracy issues
- **< 0.50**: Poor — major revision needed

### Deviation Severity Handling
- **Critical**: MUST fix. Source directly contradicts claim. Block acceptance.
- **High**: MUST fix. Significant misrepresentation. Block acceptance.
- **Medium**: SHOULD fix. Noticeable inaccuracy. Don't block but flag.
- **Low**: MAY fix. Minor imprecision. Informational only.

## Verdict Decision Matrix

| Structural Score | Claims Rate | Critical/High Deviations | Verdict |
|-----------------|-------------|-------------------------|---------|
| >= 0.80 | >= 0.85 | None | **Accept** |
| >= 0.80 | >= 0.70 | None | **Accept** |
| >= 0.75 | any | None, iteration 3 | **Accept** (max iterations) |
| any | any | >= 1 critical | **Revise** |
| any | any | >= 2 high | **Revise** |
| < 0.70 | any | any | **Revise** |

## Without cogni-claims

If claims verification is unavailable (plugin not installed):
- Use structural review only
- Accept threshold: structural score >= 0.75
- Maximum 2 review iterations (instead of 3)
