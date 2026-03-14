# Flagging Rules Framework

Comprehensive flagging logic for claim quality control using dual-layer thresholds (evidence reliability + claim quality).

## Purpose

Automatically flag claims requiring human review based on:
1. **Evidence-based flags** - Reliability concerns from source quality, conflicts, or missing metadata
2. **Quality-based flags** - Extraction issues from poor atomicity, decontextualization, or faithfulness

## Dual-Layer Flagging Architecture

**Layer 1: Evidence Reliability** → Evidence-based flags (is the evidence trustworthy?)

**Layer 2: Claim Quality** → Quality-based flags (is the claim well-extracted?)

**Combined Logic:** Claims flagged by EITHER layer trigger `flagged_for_review: true`

## Evidence-Based Flagging Rules

### Rule 1: Critical Low Confidence

**Trigger:** `confidence_score < 0.60` AND `is_critical: true`

**Rationale:** Critical claims with low confidence pose high risk if incorrect. Human review required before accepting.

**Critical Claim Indicators:**

Set `is_critical: true` when claim contains:
- **Quantitative data**: Statistics, percentages, numerical benchmarks
- **Security/safety assertions**: Vulnerability claims, safety ratings, risk assessments
- **Performance benchmarks**: Speed metrics, efficiency claims, capacity limits
- **Regulatory/compliance statements**: Legal requirements, standards compliance, certification claims
- **Cost/pricing information**: Budget figures, cost estimates, pricing comparisons

**Examples:**

✅ **Critical + Low Confidence → Flag:**
- Claim: "Product X reduces security breaches by 75%"
- Evidence confidence: 0.55 (Tier 4 blog source, no corroboration)
- Is critical: Yes (security + quantitative)
- **Action:** `flagged_for_review: true`, `critical_low_confidence: true`

✅ **Critical + High Confidence → Accept:**
- Claim: "Green bonds issued $500B in 2023"
- Evidence confidence: 0.82 (Tier 1 authoritative source)
- Is critical: Yes (quantitative data)
- **Action:** `flagged_for_review: false` (high confidence overrides)

### Dimension-Specific Flagging Patterns

**Understanding Variation Across Research Dimensions**

Flagging rates vary naturally across research dimensions based on source quality and claim type distributions. This variation is **expected behavior**, not a bug.

**Pattern Analysis (Reference: Sprint 274 Investigation)**

| Dimension Type | Critical Claims | Typical Flagging | Primary Trigger | Source Quality |
|---------------|-----------------|------------------|-----------------|----------------|
| **High Quantitative** | 30-50% | 15-40% | Rule 1 (critical low confidence) | Tier 2/3 (professional/industry) |
| **Balanced** | 20-35% | 0-10% | Mixed | Tier 1/2 (academic/industry) |
| **Qualitative** | 10-20% | 0-5% | Quality-based (atomicity, decontextualization) | Mixed |

**Example: Production-Technologies vs Business-Model-Innovation**

**Production-Technologies (36% flagging):**
- Critical claims: 33% (11/33 claims with quantitative metrics)
- Average evidence confidence: 0.70
- Source quality: Primarily Tier 2/3 (professional/industry sources)
- Cross-validation: 0.5 (single sources, no independent verification)
- **Result:** Many claims in 0.58-0.62 evidence range → triggers Rule 1 for critical claims

**Business-Model-Innovation (0% flagging):**
- Critical claims: 33% (9/27 claims)
- Average evidence confidence: 0.79
- Source quality: 10 Tier 1 academic sources + 17 Tier 2 industry sources
- Cross-validation: Better source mix
- **Result:** Higher evidence confidence → above 0.60 threshold

**Key Trend:** Same critical claim ratio (33%), but source quality difference (0.70 vs 0.79 evidence) creates 36 percentage point flagging gap. This correctly signals that production-technologies sources need improvement.

**Not a Bug:** High flagging rates in quantitative dimensions indicate:
1. Lower source quality (professional/industry vs academic)
2. Lack of cross-validation (single sources)
3. Single evidence points per claim (no corroboration)

**Recommended Actions:**
- **Immediate:** Accept flagging as quality signal, review flagged claims during synthesis
- **Long-term:** Improve source quality (add academic sources, cross-validate critical claims)
- **Enhancement:** See GitHub issue for automated cross-validation expansion feature

### Rule 1 Threshold Rationale

**Current Threshold: 0.60 for Critical Claims**

**Rationale:** Conservative threshold prioritizing epistemic rigor over efficiency.

**Risk Tradeoff Analysis:**

| Threshold | Accepts | Rejects | Risk Level | Use Case |
|-----------|---------|---------|------------|----------|
| **0.70** | Academic only (Tier 1) | Professional + Industry | Very Low | Mission-critical research |
| **0.60** | Academic + Industry (Tier 1/2) | Professional (Tier 3) | Low | **Current (recommended)** |
| **0.55** | Academic + Industry + Professional | Community (Tier 4) | Moderate | Efficiency priority |
| **0.50** | All tiers with single finding | None unless major issues | High | Not recommended |

**Evidence Score Examples at 0.60 Threshold:**

**Accepted (≥0.60):**
- Tier 1 academic (1.0) + single finding (0.5) + no cross-validation (0.5) = **0.675** ✓
- Tier 2 industry (0.8) + 2 findings (0.7) + no cross-validation (0.5) = **0.695** ✓

**Flagged (<0.60):**
- Tier 3 professional (0.6) + single finding (0.5) + no cross-validation (0.5) = **0.585** ✗
- Tier 2 industry (0.8) + single finding (0.5) + no cross-validation (0.5) = **0.585** ✗

**Design Decision:** Tier 1/2 sources with minimal corroboration are acceptable for critical claims. Tier 3 sources require additional evidence (cross-validation or multiple findings) to exceed threshold.

**When to Adjust Threshold:**

**Lower to 0.55 if:**
- Efficiency is priority over maximum quality control
- Professional sources (Tier 3) are acceptable for critical claims
- Manual review capacity is limited
- Willing to accept borderline critical claims

**Raise to 0.65-0.70 if:**
- Mission-critical research requiring highest standards
- Only academic sources acceptable for critical claims
- Ample resources for source improvement
- Zero tolerance for borderline evidence

**Current Recommendation:** Maintain 0.60 threshold. Address high flagging rates by improving source quality (add academic sources, cross-validate claims) rather than lowering standards.

### Rule 2: Cross-Validation Conflicts

**Trigger:** `cross_validation_score < 0.5` (conflicting sources detected)

**Rationale:** When independent sources disagree materially, human judgment needed to resolve conflict.

**Detection:**
- Multiple sources provide contradictory data points
- Different methodologies yield conflicting results
- Temporal differences create apparent conflicts

**Example:**

✅ **Conflicting Sources → Flag:**
- Claim: "AI code review reduces bugs by 40%"
- Source A (vendor): Claims 60% reduction
- Source B (academic): Shows 15% reduction
- Cross-validation score: 0.3
- **Action:** `flagged_for_review: true`, document conflict in notes

### Rule 3: Missing Source Metadata

**Trigger:** Required source attribution fields are empty or unavailable

**Missing Fields:**
- Source ID (`source_ids: []`)
- Publication date (affects recency scoring)
- Author/publisher information (affects expertise scoring)
- Finding provenance (cannot trace claim to evidence)

**Rationale:** Claims without complete provenance chain cannot be verified. Requires manual source research.

**Example:**

✅ **Missing Source → Flag:**
- Claim extracted but `source_ids: []` in finding frontmatter
- Cannot determine source quality tier
- **Action:** `flagged_for_review: true`, assign default moderate scores

## Quality-Based Flagging Rules

### Rule 4: Poor Overall Extraction Quality

**Trigger:** `claim_quality < 0.5`

**Rationale:** Low composite quality score indicates multiple extraction issues. Claims likely need rewriting.

**Calculation:**
```
claim_quality = (atomicity + fluency + decontextualization + faithfulness) / 4.0
```

If average < 0.5, at least two dimensions have serious issues.

**Example:**

✅ **Low Quality → Flag:**
- Atomicity: 0.0 (multiple relations)
- Fluency: 1.0 (grammatically correct)
- Decontextualization: 0.0 (pronouns present)
- Faithfulness: 0.4 (source misrepresented)
- **Claim Quality:** (0.0 + 1.0 + 0.0 + 0.4) / 4 = 0.35
- **Action:** `flagged_for_review: true`

### Rule 5: Atomicity Failure

**Trigger:** `atomicity = 0.0` (claim contains multiple relations)

**Rationale:** Non-atomic claims conflate multiple facts, reducing verifiability and precision. Must be split.

**Detection:**
- Claim contains "and" connecting two assertions
- Multiple verbs describing different relations
- Compound predicate structures

**Example:**

✅ **Multiple Relations → Flag:**
- Claim: "PICO framework is important and widely used"
- Relations: 2 ("is important" + "is widely used")
- Atomicity: 0.0
- **Action:** `flagged_for_review: true`
- **quality_flags:** `["atomicity: Contains multiple relations - needs splitting (score 0.0)"]`

**Refinement Required:** Split into:
1. "PICO framework may be important in systematic reviews"
2. "PICO framework may be widely used in systematic reviews"

### Rule 6: Decontextualization Failure

**Trigger:** `decontextualization = 0.0` (claim requires context to understand)

**Rationale:** Claims with pronouns or vague references cannot stand alone in knowledge bases. Requires full entity names.

**Detection:**
- Pronouns: "it", "they", "this", "that", "these", "those"
- Vague references: "the study", "the framework" (without specification)
- Temporal vague terms: "recently", "soon" (without dates)

**Example:**

✅ **Context-Dependent → Flag:**
- Claim: "The framework is widely used in systematic reviews"
- Decontextualization: 0.0 (pronoun "The framework")
- **Action:** `flagged_for_review: true`
- **quality_flags:** `["decontextualization: Requires context - needs rewriting (score 0.0)"]`

**Refinement Required:** "PICO framework is widely used in systematic reviews"

### Rule 7: Faithfulness Issues

**Trigger:** `faithfulness < 0.7` (claim may misrepresent source)

**Rationale:** Claims diverging from source meaning risk hallucination or inaccuracy. Requires verification against finding text.

**Common Causes:**
- Language strengthening ("may" → "does")
- Added information not in source
- Paraphrasing that changes meaning
- Omitted qualifiers or hedge words

**Example:**

✅ **Strengthened Language → Flag:**
- Finding: "Studies suggest green bonds may improve ESG outcomes"
- Claim: "Green bonds improve ESG outcomes"
- Faithfulness: 0.4 (removed "may", strengthened certainty)
- **Action:** `flagged_for_review: true`
- **quality_flags:** `["faithfulness: Source fidelity issue - may misrepresent finding (score 0.4)"]`

**Refinement Required:** Restore "may" to preserve source uncertainty

### Rule 8: Fluency Issues

**Trigger:** `fluency < 0.5` (grammatical problems impair readability)

**Rationale:** Poorly written claims reduce comprehension. While less critical than other dimensions, severe fluency issues need correction.

**Detection:**
- Broken grammar
- Missing articles or prepositions
- Awkward word order
- Unintelligible phrasing

**Example:**

✅ **Grammatically Broken → Flag:**
- Claim: "Reviews systematic months require 12-24"
- Fluency: 0.0 (unintelligible)
- **Action:** `flagged_for_review: true`
- **quality_flags:** `["fluency: Grammatical issues - needs correction (score 0.0)"]`

**Refinement Required:** "Systematic reviews require 12-24 months to complete"

## Quality Flags Array

### Format Specification

**Canonical Format:**
```
"{dimension}: {message} (score {X.X})"
```

**Components:**
- `{dimension}`: One of: atomicity, fluency, decontextualization, faithfulness
- `{message}`: Human-readable description of the issue
- `{score}`: Actual dimension score that triggered flag (2 decimal places)

**Example:** `"atomicity: Contains multiple relations - needs splitting (score 0.0)"`

**Rationale:** This format provides (1) machine-parseable dimension tag, (2) human guidance, (3) score context for severity assessment.

### Population Logic

`quality_flags` array is **additive** - include ALL failing dimensions, not just first detected.

**Mapping Table:**

| Dimension | Threshold | Flag Message |
|-----------|-----------|--------------|
| Atomicity | = 0.0 | "Contains multiple relations - needs splitting into atomic claims" |
| Fluency | < 0.5 | "Grammatical issues - needs correction" |
| Decontextualization | = 0.0 | "Requires context - needs rewriting with full references" |
| Faithfulness | < 0.7 | "Source fidelity issue - may misrepresent finding" |

### Bash Implementation Pattern

```bash
# Initialize empty array
quality_flags=()

# Check each dimension and add to array if threshold breached
# Atomicity is binary (0.0 or 1.0), so use equality check
if (( $(echo "$atomicity_score == 0.0" | bc -l) )); then
  quality_flags+=("atomicity: Contains multiple relations - needs splitting (score $atomicity_score)")
fi

if (( $(echo "$fluency_score < 0.5" | bc -l) )); then
  quality_flags+=("fluency: Grammatical issues - needs correction (score $fluency_score)")
fi

# Decontextualization is binary (0.0 or 1.0), so use equality check
if (( $(echo "$decontextualization_score == 0.0" | bc -l) )); then
  quality_flags+=("decontextualization: Requires context - needs rewriting (score $decontextualization_score)")
fi

if (( $(echo "$faithfulness_score < 0.7" | bc -l) )); then
  quality_flags+=("faithfulness: Source fidelity issue - may misrepresent finding (score $faithfulness_score)")
fi

# Convert to YAML array format when writing to file
# If array is empty, write "quality_flags: []"
# If array has items, write multi-line YAML array
```

### Examples

**Single Flag:**
```yaml
flagged_for_review: true
quality_flags:
  - "atomicity: Contains multiple relations - needs splitting (score 0.0)"
```

**Multiple Flags:**
```yaml
flagged_for_review: true
quality_flags:
  - "atomicity: Contains multiple relations - needs splitting (score 0.0)"
  - "decontextualization: Requires context - needs rewriting (score 0.0)"
  - "faithfulness: Source fidelity issue - may misrepresent finding (score 0.4)"
```

**No Flags:**
```yaml
flagged_for_review: false
quality_flags: []
```

## Composite Flagging Logic

### Decision Tree

```
IF (confidence_score < 0.60 AND is_critical = true)
   OR (cross_validation_score < 0.5)
   OR (source_ids missing)
   OR (claim_quality < 0.5)
   OR (atomicity = 0.0)
   OR (decontextualization = 0.0)
   OR (faithfulness < 0.7)
   OR (fluency < 0.5)
THEN
   flagged_for_review = true
ELSE
   flagged_for_review = false
```

### Tracking Metrics

**Counters to Maintain:**

```bash
flagged_for_review=0           # Total claims flagged (any reason)
flagged_by_evidence=0          # Evidence-based flags (Rules 1-3)
flagged_by_quality=0           # Quality-based flags (Rules 4-8)
critical_low_confidence=0      # Rule 1 specifically
atomicity_issues=0             # Rule 5
decontextualization_issues=0   # Rule 6
faithfulness_issues=0          # Rule 7
fluency_issues=0               # Rule 8
```

**Increment Pattern:**

```bash
# Check evidence flags
if [ $confidence_score < 0.60 ] && [ "$is_critical" = "true" ]; then
  flagged_by_evidence=$((flagged_by_evidence + 1))
  critical_low_confidence=$((critical_low_confidence + 1))
fi

# Check quality flags
if [ "$atomicity" = "0.0" ]; then
  flagged_by_quality=$((flagged_by_quality + 1))
  atomicity_issues=$((atomicity_issues + 1))
fi

# Set global flag if any condition met
if [ $flagged_by_evidence -gt 0 ] || [ $flagged_by_quality -gt 0 ]; then
  flagged_for_review="true"
fi
```

## Integration with Fact-Checker Workflow

**Phase 4.5: Apply Flagging Rules**

1. Calculate `evidence_confidence` (Phase 4.3)
2. Calculate `claim_quality` (Phase 4.4)
3. Calculate `confidence_score = (evidence_confidence × 0.6) + (claim_quality × 0.4)`
4. **Apply all flagging rules (Evidence Rules 1-3, Quality Rules 4-8)**
5. Set `flagged_for_review` boolean
6. Populate `quality_flags` array with all failing dimensions
7. Increment counters for statistics
8. Create claim entity with flags (Phase 4.6)

## Worked Example: Multiple Flags

**Scenario:** Poor extraction from good source

**Finding:** "Studies suggest PICO framework is important and widely used in systematic reviews"

**Claim Extracted:** "The framework is important and widely used"

### Evidence Layer
- Source: Tier 1 academic journal
- Evidence confidence: 0.815 (excellent)
- **Evidence flags:** None

### Quality Layer
1. **Atomicity:** 0.0 (two relations: "is important" + "is widely used") → **FLAG**
2. **Fluency:** 1.0 (grammatically correct)
3. **Decontextualization:** 0.0 (pronoun "The framework") → **FLAG**
4. **Faithfulness:** 0.4 (omitted "PICO" and "suggest") → **FLAG**

**Claim Quality:** (0.0 + 1.0 + 0.0 + 0.4) / 4 = **0.35 < 0.5** → **FLAG**

### Flagging Result

```yaml
flagged_for_review: true
is_critical: false
quality_flags:
  - "atomicity: Contains multiple relations - needs splitting (score 0.0)"
  - "decontextualization: Requires context - needs rewriting (score 0.0)"
  - "faithfulness: Source fidelity issue - may misrepresent finding (score 0.4)"

# Statistics
flagged_by_evidence: 0
flagged_by_quality: 1
atomicity_issues: 1
decontextualization_issues: 1
faithfulness_issues: 1
```

**Interpretation:** Excellent source but poor extraction. Claims need refinement, not rejection.

**Remediation:** Split into two atomic, decontextualized claims:
1. "PICO framework may be important in systematic reviews"
2. "PICO framework may be widely used in systematic reviews"

## Edge Cases

### Edge Case 1: High Quality, Low Evidence

**Scenario:**
- Evidence confidence: 0.42 (Tier 4 blog)
- Claim quality: 0.95 (perfect extraction)
- Is critical: No

**Flagging:**
- Not flagged (confidence > 0.60 OR not critical)
- Quality excellent, no quality flags

**Interpretation:** Well-formed claim from weak source. Acceptable for non-critical information, but may want stronger evidence for important decisions.

### Edge Case 2: High Evidence, Low Quality

**Scenario:**
- Evidence confidence: 0.82 (Tier 1 peer-reviewed)
- Claim quality: 0.35 (multiple issues)
- Is critical: Yes

**Flagging:**
- `flagged_for_review: true` (claim_quality < 0.5)
- Multiple quality flags

**Interpretation:** This is the example worked above. Excellent source but extraction needs refinement.

### Edge Case 3: Conflicting Sources, Perfect Extraction

**Scenario:**
- Cross-validation score: 0.3 (conflicting sources)
- Claim quality: 1.0 (perfect extraction)

**Flagging:**
- `flagged_for_review: true` (cross_validation < 0.5)
- Evidence flag, no quality flags

**Interpretation:** Well-extracted claim but sources disagree. Human needs to resolve conflict or note uncertainty.

### Edge Case 4: Missing Source, Critical Claim

**Scenario:**
- Source IDs: [] (missing)
- Is critical: Yes
- Claim: "Product X is FDA approved"

**Flagging:**
- `flagged_for_review: true` (missing source metadata + critical)
- Cannot score evidence factors accurately

**Interpretation:** Critical regulatory claim without source attribution. Unacceptable - requires source research before accepting.

## Quality Assurance

### Pre-Flagging Checklist

Before applying flags, verify:
- [ ] All 5 evidence factors calculated
- [ ] All 4 quality dimensions evaluated
- [ ] Confidence score calculated: (evidence × 0.6) + (quality × 0.4)
- [ ] `is_critical` determined based on content type
- [ ] Cross-validation score reflects source independence
- [ ] Source metadata checked for completeness

### Post-Flagging Validation

After applying flags, confirm:
- [ ] `flagged_for_review` boolean set correctly
- [ ] `quality_flags` array populated for ALL failing dimensions
- [ ] Counters incremented appropriately
- [ ] Flag reasons documented in claim notes
- [ ] Statistics variables updated

## Usage Notes

- **OR Logic:** Claims flagged by EITHER evidence OR quality rules trigger review
- **Additive Flags:** Multiple quality issues result in multiple flag messages
- **Counter Tracking:** Maintain separate counts for evidence vs quality flags
- **No False Negatives:** Better to over-flag than under-flag (human review filters)
- **Context Matters:** Critical claims have lower thresholds than informational claims

## References

**Source Document:**
- cogni-research/skills/fact-checker/SKILL.md (Phase 4.5)
- Extracted and expanded with edge cases and examples

**Related Frameworks:**
- Evidence Confidence (references/evidence-confidence.md)
- Claim Quality (references/claim-quality.md)
- Anti-Hallucination Protocol (references/anti-hallucination.md)

**Last Updated:** 2025-11-13 (Sprint 274: Added dimension-specific patterns and threshold rationale)

---

## Flagging Rate Benchmarks

### Expected Flagging Patterns by Dimension Type

**High Quantitative Dimensions** (production-technologies, market-data, financial-metrics)
- **Critical claim ratio:** 30-50%
- **Expected flagging:** 15-40% (typical range with 0.60 threshold)
- **Primary trigger:** Rule 1 (critical low confidence)
- **Source quality impact:** High (many professional/industry sources, fewer academic)
- **Recommendation:** Improve source mix (add academic sources, cross-validate critical claims)

**Balanced Dimensions** (business-model-innovation, organizational-transformation)
- **Critical claim ratio:** 20-35%
- **Expected flagging:** 0-10%
- **Primary triggers:** Mixed (evidence and quality-based)
- **Source quality impact:** Medium (mix of academic and industry sources)
- **Recommendation:** Maintain current source quality balance

**Qualitative Dimensions** (organizational-culture, strategic-frameworks, leadership-practices)
- **Critical claim ratio:** 10-20%
- **Expected flagging:** 0-5%
- **Primary triggers:** Quality-based (atomicity, decontextualization)
- **Source quality impact:** Low (qualitative claims less dependent on source tier)
- **Recommendation:** Focus on claim quality (atomicity, self-contained phrasing)

### Assessing Source Quality

**Good Indicators of High Source Quality:**
- Low flagging rate (<10%) with high critical claim ratio (>30%)
- High average evidence confidence (>0.75)
- Tier 1 (academic) sources represent >40% of claims
- Cross-validation present for critical quantitative claims
- Multiple evidence points per claim (evidence_count > 0.5)

**Red Flags Indicating Quality Issues:**
- High flagging rate (>25%) with Rule 1 as primary trigger
- Low average evidence confidence (<0.65)
- Tier 3/4 (professional/community) sources represent >60% of claims
- No cross-validation for critical claims (cross_validation = 0.5 consistently)
- Single finding per claim (evidence_count = 0.5 consistently)

### Diagnostic Workflow

**When a dimension shows high flagging (>20%):**

1. **Check evidence confidence distribution**
   - If avg <0.65: Source quality issue
   - If avg >0.75: Quality-based flagging (atomicity, decontextualization)

2. **Analyze source tier distribution**
   - Count Tier 1, 2, 3, 4 sources
   - If <30% Tier 1: Consider adding academic sources
   - If >50% Tier 3/4: Significant quality gap

3. **Review cross-validation scores**
   - If most claims have cross_validation = 0.5: No independent verification
   - Recommend targeted searches for cross-validation (see enhancement issue)

4. **Examine critical claim ratio**
   - If >40% critical: High quantitative dimension (expected higher flagging)
   - If <20% critical but high flagging: Quality-based issues

5. **Check quality dimension scores**
   - If atomicity_issues > 0: Claims need splitting
   - If decontextualization_issues > 0: Claims have pronouns/vague references
   - If faithfulness_issues > 0: Claims misrepresent sources

### Testing Threshold Changes

**If threshold is adjusted from 0.60 to a different value:**

**Expected Outcomes (0.60 → 0.55 example):**
- Flagging rate decrease: ~20-25 percentage points for high quantitative dimensions
- False negative risk: Borderline claims (0.55-0.59 evidence) accepted without review
- No change in quality-based flagging (atomicity, decontextualization, faithfulness, fluency)
- Average evidence confidence remains stable (source quality unchanged)

**Validation Criteria:**
- [ ] Flagging rate changes by expected amount (~20-25 points lower for 0.05 decrease)
- [ ] Average evidence confidence remains stable (±0.02)
- [ ] Quality dimension averages remain high (>0.95)
- [ ] Critical claims with evidence 0.55-0.59 now accepted (verify intentional)
- [ ] No regression in other dimensions

**Monitoring Post-Change:**
- Track flagging rate trends over next 5-10 research projects
- Compare critical claim acceptance rates before/after
- Review synthesis quality to detect false negatives (low-confidence claims accepted)
- Assess whether manual review capacity improved (fewer flagged claims)

### Cross-Validation Enhancement

**Current Limitation:**

Cross-validation scoring is **manual** - relies on sources already present in findings. If a claim has only one source, cross_validation = 0.5 (no independent verification), even if additional sources exist but weren't retrieved during initial research.

**Proposed Enhancement (See GitHub Issue):**

Automated cross-validation expansion for low-confidence flagged claims:

1. **Trigger:** Claim flagged with Rule 1 (critical low confidence) AND cross_validation = 0.5
2. **Action:** Generate targeted search queries for the specific claim
3. **Execute:** Perform additional web searches to find corroborating or conflicting sources
4. **Score:** Update cross_validation score based on results:
   - Multiple corroborating sources → 1.0 (strong validation)
   - Single corroborating source → 0.7 (moderate validation)
   - No additional sources found → 0.5 (unchanged)
   - Conflicting sources found → 0.3 (conflict detected)
5. **Recalculate:** Update evidence_confidence with new cross_validation score
6. **Re-evaluate:** If confidence now ≥0.60, remove flagging; otherwise keep flag

**Expected Impact:**
- Reduce false positive flagging for claims with verifiable but uncorroborated sources
- Increase evidence confidence for legitimate claims
- Detect conflicting information early (improve fact-checking rigor)
- Automate manual cross-validation step currently done during synthesis

**Implementation Scope:**
- New script: `cross-validation-expander.sh` (targeted search generator)
- Update: `fact-checker/SKILL.md` Phase 5.3 (optional cross-validation step)
- Update: `evidence-confidence.md` (document automated cross-validation scoring)

See GitHub enhancement issue for detailed specification.

### Case Study: Production-Technologies (Sprint 274)

**Dimension Stats:**
- Claims created: 33
- Critical claims: 11 (33%)
- Flagged for review: 12 (36.4%)
- Average evidence confidence: 0.70
- Average claim quality: 0.98
- Quality issues: 2 atomicity, 0 other

**Analysis:**

1. **High flagging rate (36%) explained:**
   - 11 critical claims × 0.70 avg evidence = many in 0.58-0.65 range
   - Rule 1 threshold (0.60) triggers for critical claims with evidence <0.60
   - Source quality: Primarily Tier 2/3 (industry/professional), few Tier 1 (academic)
   - Cross-validation: 0.5 for most claims (no independent verification)

2. **Evidence confidence breakdown:**
   - Source quality: 0.6-0.7 (Tier 2/3) × 0.35 = 0.21-0.245
   - Evidence count: 0.5 (single finding) × 0.25 = 0.125
   - Cross-validation: 0.5 (none) × 0.20 = 0.10
   - Recency: 1.0 (<1 year) × 0.10 = 0.10
   - Expertise match: 0.7 (good) × 0.10 = 0.07
   - **Total: 0.605-0.64** (borderline for critical claims)

3. **Comparison to business-model-innovation (0% flagging):**
   - Same critical claim ratio (33%)
   - Higher evidence confidence (0.79 vs 0.70)
   - Better source quality (10 Tier 1 academic sources)
   - **Result:** 36 percentage point flagging gap from source quality alone

4. **Conclusion:**
   - **Not a bug** - system correctly detecting lower source quality
   - Flagging is appropriate signal for human review
   - Recommended action: Accept flagging, improve sources in future research
   - Enhancement opportunity: Automated cross-validation for borderline claims

This case study demonstrates that anomalous flagging rates are often signals of legitimate quality differences, not system errors.
