# Three-Layer Claim Assurance Model

## Purpose

Defines the three-layer scoring model that gives cogni-research its identity as a **research engine with research-grade claim checking**. Every claim extracted from findings passes through three independent assessment layers before receiving a final confidence score.

---

## Architecture Overview

```
Finding (04-findings) 
  --> claim-extractor (Layer 1 + Layer 2) 
    --> cogni-claims (Layer 3) 
      --> Claim (06-claims) with final_confidence
```

| Layer | What it measures | Who computes it | Score range |
|-------|-----------------|-----------------|-------------|
| **Layer 1: Evidence Confidence** | How strong is the underlying evidence? | claim-extractor | 0.0 - 1.0 |
| **Layer 2: Claim Quality** | How well-formed is the claim itself? | claim-extractor | 0.0 - 1.0 |
| **Layer 3: Source Verification** | Does the source URL actually support the claim? | cogni-claims | verified / deviated / unavailable |

---

## Layer 1: Evidence Confidence

Measures the strength of the evidence base from which the claim was extracted.

### Scoring Factors

| Factor | Weight | What it measures | Score anchors |
|--------|--------|-----------------|---------------|
| **Source Quality** | 25% | Reliability tier of the source (academic, industry, news, blog) | Tier 1 = 1.0, Tier 2 = 0.8, Tier 3 = 0.6, Tier 4 = 0.4 |
| **Cross-Validation** | 25% | Number of independent sources supporting the same claim | 3+ sources = 1.0, 2 = 0.7, 1 = 0.4 |
| **Recency** | 20% | How recent the source material is | < 6 months = 1.0, 6-12 months = 0.8, 1-2 years = 0.6, 2-5 years = 0.4, 5+ years = 0.2 |
| **Expertise** | 15% | Domain authority of the source author/publisher | Recognized expert = 1.0, Practitioner = 0.7, Generalist = 0.4 |
| **Methodological Rigor** | 15% | Research methodology quality (if disclosed) | Peer-reviewed = 1.0, Industry study = 0.7, Editorial = 0.4, No methodology = 0.2 |

### Calculation

```
evidence_confidence = (source_quality × 0.25) + (cross_validation × 0.25) 
                    + (recency × 0.20) + (expertise × 0.15) 
                    + (methodological_rigor × 0.15)
```

### YAML Output

```yaml
evidence_confidence: 0.82
evidence_factors:
  source_quality: 0.80
  cross_validation: 1.00
  recency: 0.80
  expertise: 0.70
  methodological_rigor: 0.70
```

---

## Layer 2: Claim Quality

Measures the linguistic and logical quality of the extracted claim text.

### Scoring Dimensions

| Dimension | Weight | What it measures | Score anchors |
|-----------|--------|-----------------|---------------|
| **Atomicity** | 30% | Claim contains exactly one testable assertion | Single assertion = 1.0, Compound = 0.5, Vague = 0.2 |
| **Fluency** | 20% | Claim reads as a standalone sentence | Clear standalone = 1.0, Requires context = 0.5, Fragment = 0.2 |
| **Decontextualization** | 25% | Claim is understandable without the source | Fully independent = 1.0, Needs some context = 0.6, Source-dependent = 0.2 |
| **Faithfulness** | 25% | Claim accurately represents the source (no strengthened language) | Exact preservation = 1.0, Minor drift = 0.7, Strengthened = 0.3, Fabricated = 0.0 |

### Calculation

```
claim_quality = (atomicity × 0.30) + (fluency × 0.20) 
              + (decontextualization × 0.25) + (faithfulness × 0.25)
```

### Anti-Hallucination: Faithfulness Dimension

The faithfulness dimension specifically detects language strengthening:

| Source text | Claim text | Faithfulness score |
|-------------|-----------|-------------------|
| "may improve outcomes" | "may improve outcomes" | 1.0 (preserved) |
| "may improve outcomes" | "improves outcomes" | 0.3 (strengthened) |
| "suggests a correlation" | "proves causation" | 0.0 (fabricated) |

**Hedge words to preserve:** may, might, could, suggests, likely, appears, tends, indicates, preliminary, estimated

### YAML Output

```yaml
claim_quality: 0.75
quality_dimensions:
  atomicity: 0.90
  fluency: 0.80
  decontextualization: 0.70
  faithfulness: 0.60
```

---

## Layer 3: Source Verification (via cogni-claims)

Independently verifies whether the source URL actually supports the claim by fetching and comparing.

### Verification Statuses

| Status | Meaning | When assigned |
|--------|---------|---------------|
| **verified** | Source URL content supports the claim | cogni-claims confirms alignment |
| **deviated** | Source URL content differs from the claim | cogni-claims detects deviation |
| **unavailable** | Source URL could not be fetched | 404, paywall, timeout, etc. |

### Deviation Taxonomy (from cogni-claims)

When status is `deviated`, a severity and type are assigned:

| Severity | Modifier | Meaning |
|----------|----------|---------|
| `low` | 0.9 | Minor wording difference, same meaning |
| `medium` | 0.7 | Selective omission or context loss |
| `high` | 0.4 | Unsupported conclusion or data staleness |
| `critical` | 0.1 | Misquotation or source contradiction |

| Deviation Type | Description |
|----------------|-------------|
| `misquotation` | Claim misquotes or significantly paraphrases the source |
| `unsupported_conclusion` | Claim draws a conclusion the source does not support |
| `selective_omission` | Claim omits key qualifications or caveats |
| `data_staleness` | Source data has been updated/corrected since claim extraction |
| `source_contradiction` | Source actively contradicts the claim |

### YAML Output

```yaml
source_verification: verified
deviation_count: 0
deviation_max_severity: null
verification_ref: "cogni-claims/claims.json#claim-abc123"
```

Or for a deviated claim:

```yaml
source_verification: deviated
deviation_count: 1
deviation_max_severity: medium
deviation_types: [selective_omission]
verification_ref: "cogni-claims/claims.json#claim-def456"
```

---

## Composite Score Calculation

### Step 1: Confidence Score (Layers 1 + 2)

```
confidence_score = (evidence_confidence × 0.6) + (claim_quality × 0.4)
```

Evidence confidence is weighted higher (60%) because strong evidence with imperfect claim wording is more valuable than perfect wording with weak evidence.

### Step 2: Verification Modifier (Layer 3)

| Verification Status | Modifier |
|--------------------|----------|
| `verified` | 1.0 |
| `deviated` (low severity) | 0.9 |
| `deviated` (medium severity) | 0.7 |
| `deviated` (high severity) | 0.4 |
| `deviated` (critical severity) | 0.1 |
| `unavailable` | 0.8 |

### Step 3: Final Confidence

```
final_confidence = confidence_score × verification_modifier
```

### Example Calculations

**High-confidence verified claim:**
```
evidence_confidence = 0.85
claim_quality = 0.80
confidence_score = (0.85 × 0.6) + (0.80 × 0.4) = 0.51 + 0.32 = 0.83
verification = verified (modifier = 1.0)
final_confidence = 0.83 × 1.0 = 0.83
```

**Medium-confidence with deviation:**
```
evidence_confidence = 0.70
claim_quality = 0.75
confidence_score = (0.70 × 0.6) + (0.75 × 0.4) = 0.42 + 0.30 = 0.72
verification = deviated/medium (modifier = 0.7)
final_confidence = 0.72 × 0.7 = 0.50
```

**Weak claim with critical deviation:**
```
evidence_confidence = 0.50
claim_quality = 0.60
confidence_score = (0.50 × 0.6) + (0.60 × 0.4) = 0.30 + 0.24 = 0.54
verification = deviated/critical (modifier = 0.1)
final_confidence = 0.54 × 0.1 = 0.05
```

---

## Complete Claim Entity Frontmatter

```yaml
# Layer 1 (claim-extractor)
evidence_confidence: 0.82
evidence_factors:
  source_quality: 0.80
  cross_validation: 1.00
  recency: 0.80
  expertise: 0.70
  methodological_rigor: 0.70

# Layer 2 (claim-extractor)
claim_quality: 0.75
quality_dimensions:
  atomicity: 0.90
  fluency: 0.80
  decontextualization: 0.70
  faithfulness: 0.60

# Composite (claim-extractor)
confidence_score: 0.79

# Layer 3 (cogni-claims, Phase 7.5)
source_verification: verified
deviation_count: 0
deviation_max_severity: null
verification_ref: "cogni-claims/claims.json#claim-abc123"

# Final (after Phase 7.5)
final_confidence: 0.79
```

---

## Confidence Thresholds

| Threshold | Final Confidence | Usage |
|-----------|-----------------|-------|
| **High Confidence** | >= 0.75 | Suitable for executive reports, strategic recommendations |
| **Medium Confidence** | 0.50 - 0.74 | Suitable for supporting evidence, contextual information |
| **Low Confidence** | 0.25 - 0.49 | Flag for review, include with caveat |
| **Very Low Confidence** | < 0.25 | Exclude from reports unless explicitly requested |

---

## Export Integration

### HTML Report Badges

Claims in export-html-report display three badges:
- **Evidence** badge (Layer 1): green/yellow/red based on evidence_confidence
- **Quality** badge (Layer 2): green/yellow/red based on claim_quality
- **Verified** badge (Layer 3): green (verified) / yellow (unavailable) / red (deviated)

### PDF Report

Claims in export-pdf-report include a confidence indicator with the final_confidence score and verification status.

---

## Version History

- **v1.0.0:** Initial three-layer claim assurance model for cogni-research v1.0.0
