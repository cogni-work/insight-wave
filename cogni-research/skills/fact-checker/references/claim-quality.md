# Claim Quality Framework

4-dimension evaluation system for assessing claim extraction quality based on peer-reviewed research (Wright et al. 2022, Agh et al. 2025).

## Research Foundation

**Primary Source:** Wright et al. (2022) - "Generating Scientific Claims for Zero-Shot Scientific Fact Checking" (ACL)

**Operationalization:** Agh et al. (2025) - "Claim Extraction for Fact-Checking: Data, Models, and Automated Metrics" (arXiv:2502.04955v1)

**Why 4 Dimensions (not 6):** Original papers define 6 dimensions (atomicity, fluency, decontextualization, faithfulness, focus, coverage), but Focus and Coverage require human-annotated reference claims for comparison. Since we create claims in real-time without gold standards, we implement only the 4 reference-free dimensions.

## Dual-Layer Architecture

**Layer 1:** Evidence Reliability (5 factors) → Evidence Confidence Score

**Layer 2:** Claim Quality (4 dimensions) → Claim Quality Score

**Final Confidence:** (Evidence Confidence × 0.6) + (Claim Quality × 0.4)

**Rationale:** Separates "is the evidence good?" from "is the claim well-formed?" - allows flagging high-quality sources with poor extraction vs low-quality sources with good extraction.

## Dimension 1: Atomicity (Binary)

### Definition

Wright et al. (2022): "Does the claim describe a single entity, relation, or process?"

### Scoring Method

Count distinct factual relations in the claim.

| Score | Criterion | Example |
|-------|-----------|---------|
| **1.0** | ≤1 relation (atomic) | "PICO elements are most extracted entities" |
| **0.0** | >1 relation (needs splitting) | "PICO is important and widely used" (2 relations) |

### Evaluation Process

Ask: "How many distinct factual assertions are in this claim? Can it be split further while remaining meaningful?"

### Examples

✅ **Score 1.0 (Atomic):**
- "PICO elements are most extracted entities in systematic reviews"
  - Relations: 1 ("are most extracted")
  - Atomic: Yes

- "The Cochrane Collaboration was established in 1993"
  - Relations: 1 ("was established")
  - Atomic: Yes

❌ **Score 0.0 (Non-Atomic):**
- "PICO is important and widely used in systematic reviews"
  - Relations: 2 ("is important", "is widely used")
  - Atomic: No - split into two claims

- "Green bonds have lower yields and attract institutional investors"
  - Relations: 2 ("have lower yields", "attract investors")
  - Atomic: No - split required

## Dimension 2: Fluency (Continuous 0-1)

### Definition

Wright et al. (2022): "Is the claim grammatically correct and intelligible?"

### Scoring Method

Assess grammatical quality and natural reading flow.

| Score | Quality Level | Characteristics |
|-------|---------------|-----------------|
| **1.0** | Perfect | Flawless grammar, natural flow |
| **0.7** | Minor issues | Small grammatical errors, comprehensible |
| **0.4** | Awkward | Difficult phrasing, requires re-reading |
| **0.0** | Broken | Unintelligible, major errors |

### Evaluation Process

Read the claim aloud. Does it sound natural? Are there grammatical errors?

### Examples

✅ **Score 1.0 (Perfect):**
- "Systematic reviews require 12-24 months to complete"
  - Grammar: Perfect
  - Readability: Natural

⚠️ **Score 0.4 (Awkward):**
- "Systematic review time is 12-24 months requirement period"
  - Grammar: Awkward structure
  - Readability: Difficult

❌ **Score 0.0 (Broken):**
- "Reviews systematic months require 12-24"
  - Grammar: Broken
  - Readability: Unintelligible

## Dimension 3: Decontextualization (Binary)

### Definition

Wright et al. (2022): "Can the claim be understood without additional context?"

### Scoring Method

Check for pronouns, vague references, or context-dependent terms.

| Score | Criterion | Example |
|-------|-----------|---------|
| **1.0** | Fully self-contained | "The Cochrane Collaboration was established in 1993" |
| **0.0** | Requires context | "It was established in 1993" (pronoun "It") |

### Red Flags (Automatic 0.0)

**Pronouns:**
- English: "it", "they", "this", "that", "these", "those", "he", "she"
- German: "es", "sie", "dies", "das", "diese", "jene", "er"
- French: "il", "elle", "ce", "cela", "ces", "ceux"

**Vague References:**
- "the study", "the framework", "the method" (without specification)
- "the approach", "the model", "the system", "the tool"

**Demonstrative Adjectives (Context-Dependent):**
- "this framework", "that method", "these findings"
- **Note:** Only if "framework"/"method"/"findings" not specified in same claim
- **Example Violation:** "This framework improves outcomes" (which framework?)
- **Example OK:** "The PICO framework improves outcomes" (framework specified)

**Temporal Vague:**
- "recently", "soon", "later", "earlier" (without dates)
- "in recent years", "in the near future"

**Anaphora:**
- "such", "aforementioned", "said" (referring to prior text)

**Implicit Subjects:**
- "was established in 1993" (by whom? Missing subject)
- "reduces costs by 40%" (what reduces costs? Missing subject)
- **Note:** If subject can be inferred from context, claim is context-dependent

### Language Support

**Supported Languages:** English, German, French (pronoun lists provided above)

**Unsupported Languages (Fallback Strategy):**

For claims in languages not explicitly covered (Spanish, Chinese, Arabic, etc.):

1. **Apply English pronoun rules** as baseline detection
2. **Check for vague references** (language-agnostic patterns)
3. **Log warning** to execution log: "Decontextualization check using fallback - language {ISO_CODE} not fully supported"
4. **Flag for review** if uncertainty exists about context-dependence
5. **Recommend:** Flag borderline cases for human review rather than false acceptance

**Adding Language Support:** To add a new language, contribute pronoun/demonstrative lists to this section with native speaker verification.

### Evaluation Process

Ask: "Can someone read just this claim (without the source sentence) and fully understand it?"

### Examples

✅ **Score 1.0 (Self-Contained):**
- "The Cochrane Collaboration was established in 1993"
  - No pronouns or vague references
  - Self-contained: Yes

- "Green bond issuance reached $500 billion in 2023"
  - Specific, no context needed
  - Self-contained: Yes

❌ **Score 0.0 (Requires Context):**
- "It was established in 1993"
  - Pronoun: "It" (unclear antecedent)
  - Self-contained: No

- "The study found positive results"
  - Vague reference: "The study" (which study?)
  - Self-contained: No

## Dimension 4: Faithfulness (Continuous 0-1)

### Definition

Wright et al. (2022): "Does the claim accurately represent the source finding?"

### Scoring Method

Verify alignment between claim text and source finding text.

| Score | Fidelity Level | Characteristics |
|-------|----------------|-----------------|
| **1.0** | Exact | Verbatim quote or accurate paraphrase |
| **0.7** | Minor paraphrase | Small changes preserving core meaning |
| **0.4** | Interpretation | Generalization or inference added |
| **0.0** | Misrepresentation | Adds unsupported info or distorts meaning |

### Verification Checks

1. Are uncertainty qualifiers preserved? ("may", "suggests", "likely", "appears to")
2. Is language strengthened beyond source? (changed "could" to "does")
3. Is information added that's not in source?
4. Are numbers and specifics exactly as stated?

### Evaluation Process

Compare claim text directly to finding text. Would the original author agree this is an accurate representation?

### Examples

✅ **Score 1.0 (Exact):**
- Finding: "Studies suggest green bonds may improve ESG outcomes"
- Claim: "Green bonds may improve ESG outcomes"
- Qualifier "may" preserved: Yes
- Faithfulness: Exact representation

⚠️ **Score 0.7 (Minor Paraphrase):**
- Finding: "The PRISMA 2020 checklist contains 27 items"
- Claim: "PRISMA 2020 includes 27 checklist items"
- Paraphrasing: Minor ("contains" → "includes")
- Faithfulness: Preserves meaning

⚠️ **Score 0.4 (Interpretation):**
- Finding: "Studies suggest green bonds may improve ESG outcomes"
- Claim: "Green bonds improve ESG outcomes"
- Qualifier "may" removed: Yes (strengthened language)
- Faithfulness: Interpretation introduced

❌ **Score 0.0 (Misrepresentation):**
- Finding: "One study observed a 15 basis point spread"
- Claim: "Green bonds always have 15 basis point spreads"
- Added "always" (not in source)
- Faithfulness: Misrepresents

## Composite Scoring

### Step 1: Calculate Individual Dimensions

- Atomicity: Binary (0 or 1)
- Fluency: Continuous (0.0-1.0)
- Decontextualization: Binary (0 or 1)
- Faithfulness: Continuous (0.0-1.0)

### Step 2: Calculate Claim Quality Average

```
claim_quality = (atomicity + fluency + decontextualization + faithfulness) / 4.0
```

### Step 3: Calculate Final Confidence Score

```
confidence_score = (evidence_confidence × 0.6) + (claim_quality × 0.4)
```

**Weighting Rationale (60% Evidence / 40% Quality):**

Evidence confidence receives higher weight (60%) because source reliability fundamentally determines factual accuracy. A well-formed claim (high quality) from unreliable source (low evidence) remains untrustworthy. Conversely, a poorly-extracted claim (low quality) from authoritative source (high evidence) can be refined while preserving factual accuracy.

**Design Decision:**
- 60% Evidence: Prioritizes "is this information trustworthy?"
- 40% Quality: Ensures "is this claim well-extracted and usable?"

This weighting emphasizes epistemic value (source reliability) over extraction mechanics (claim structure), while still penalizing poor extraction enough to trigger review workflows.

### Interpretation Matrix

| Evidence | Claim Quality | Interpretation | Action |
|----------|---------------|----------------|--------|
| High | High | Excellent claim from reliable source | Accept |
| High | Low | Good source but poor extraction | Flag for refinement |
| Low | High | Well-formed claim but weak evidence | Verify |
| Low | Low | Poor on both dimensions | Reject or major revision |

## Quality Flagging Rules

### Trigger Conditions (OR logic)

Set `flagged_for_review: true` when ANY condition met:
- `claim_quality < 0.5` (poor overall extraction quality)
- `atomicity = 0.0` (multiple relations - needs splitting)
- `decontextualization = 0.0` (requires context - needs rewriting)
- `faithfulness < 0.7` (source fidelity issue)

### Quality Flags Array (Additive)

Populate `quality_flags` array with message for EACH failing dimension:

| Dimension | Threshold | Flag Message |
|-----------|-----------|--------------|
| Atomicity | = 0.0 | "Contains multiple relations - needs splitting into atomic claims" |
| Fluency | < 0.5 | "Grammatical issues - needs correction" |
| Decontextualization | = 0.0 | "Requires context - needs rewriting with full references" |
| Faithfulness | < 0.7 | "Source fidelity issue - may misrepresent finding" |

### Example Flagging

```yaml
# 2 failing dimensions
flagged_for_review: true
quality_flags:
  - "atomicity: Contains multiple relations - needs splitting (score 0.0)"
  - "faithfulness: Source fidelity issue - may misrepresent finding (score 0.4)"

# No failing dimensions
flagged_for_review: false
quality_flags: []
```

## Complete Worked Example

**Finding:** "Studies suggest PICO framework is important and widely used in systematic reviews"

**Claim Extracted:** "The framework is important and widely used"

### Dimension Scoring

1. **Atomicity:** 0.0 (Two relations: "is important" + "is widely used")
2. **Fluency:** 1.0 (Grammatically correct)
3. **Decontextualization:** 0.0 (Pronoun "The framework" - which framework?)
4. **Faithfulness:** 0.4 (Omitted "PICO" and "suggest")

**Claim Quality:** (0.0 + 1.0 + 0.0 + 0.4) / 4 = **0.35**

### With Evidence Confidence

**Evidence Confidence:** 0.815 (Tier 1 source, good factors)

**Final Confidence:** (0.815 × 0.6) + (0.35 × 0.4) = 0.489 + 0.14 = **0.629**

### Flagging

- `flagged_for_review: true` (claim_quality 0.35 < 0.5)
- `quality_flags`:
  - "atomicity: Contains multiple relations - needs splitting (score 0.0)"
  - "decontextualization: Requires context - needs rewriting with full references (score 0.0)"
  - "faithfulness: Source fidelity issue - may misrepresent finding (score 0.4)"

### Suggested Refinement

Split into two atomic, decontextualized claims:
1. "PICO framework may be important in systematic reviews"
2. "PICO framework may be widely used in systematic reviews"

## Integration with Fact-Checker Workflow

1. Extract claim from finding (Phase 2)
2. Calculate evidence confidence (Phase 3)
3. **Calculate claim quality (Phase 4)** ← This framework
4. Calculate composite confidence score
5. Apply quality flagging rules
6. Create claim entity with all scores

## Usage Notes

- Always evaluate all 4 dimensions (no skipping)
- Binary dimensions must be exactly 0.0 or 1.0 (no intermediate values)
- Document dimension scores in claim frontmatter
- Use decimal precision (2 places)
- Populate quality_flags array for all failing dimensions
