# Anti-Hallucination Protocol

Verification protocol to prevent claim corruption through language strengthening, compound statement merging, or source misrepresentation.

## Foundation

This protocol builds on [deeper-research anti-hallucination foundations](../../../references/anti-hallucination-foundations.md).

**Read the foundations for:**
- Complete entity loading protocol
- Verification checkpoint pattern
- Evidence-based processing principles
- No fabrication rule
- Provenance integrity

This document focuses on **claim-specific** anti-hallucination patterns: hedge word preservation, language strengthening detection, compound statement splitting, and atomicity enforcement.

## Purpose

Ensure claims accurately represent source findings without introducing:
- Strengthened language ("may" → "does")
- Compound statements (merging multiple facts)
- Fabricated confidence metrics
- Misrepresented qualifiers or hedging

## Core Principles

**Fidelity:** Claims must preserve exact meaning and uncertainty level of source text

**Atomicity:** One fact per claim (no compound statements)

**Verbatim Preference:** Quote verbatim when possible; paraphrase only to improve clarity while preserving meaning

**Uncertainty Preservation:** Never remove or weaken hedge words ("may", "suggests", "likely", "appears to", "could")

## 4-Step Verification Protocol

Before creating each claim entity, verify:

### Step 1: Claim Text Exists in Source

**Check:** Does the claim text appear verbatim or accurately paraphrased in the source finding?

**Invalid:**
- Claim introduces information not in finding
- Claim synthesizes across multiple findings without attribution
- Claim extrapolates beyond stated facts

**Valid:**
- Claim quotes finding verbatim
- Claim paraphrases finding accurately
- Claim preserves all factual elements

### Step 2: No Merging of Multiple Facts

**Check:** Does the claim contain only ONE factual relation?

**Invalid (Multiple Relations):**
- "PICO is important and widely used" (2 relations: importance + usage)
- "Green bonds have lower yields and attract institutional investors" (2 relations: yields + investors)
- "The study found X, Y, and Z" (3 relations)

**Valid (Atomic):**
- "PICO elements are most extracted entities" (1 relation)
- "Green bonds issued $500 billion in 2023" (1 relation)
- "Systematic reviews require 12-24 months" (1 relation)

### Step 3: No Language Strengthening

**Check:** Are uncertainty qualifiers preserved exactly as in source?

**Invalid (Strengthened):**
- Source: "may improve" → Claim: "improves" ❌
- Source: "suggests a correlation" → Claim: "proves correlation" ❌
- Source: "likely effective" → Claim: "effective" ❌
- Source: "appears to reduce" → Claim: "reduces" ❌
- Source: "could increase" → Claim: "increases" ❌

**Valid (Preserved):**
- Source: "may improve" → Claim: "may improve" ✅
- Source: "suggests correlation" → Claim: "suggests correlation" ✅
- Source: "likely effective" → Claim: "likely effective" ✅
- Source: "appears to reduce" → Claim: "appears to reduce" ✅

### Step 4: Confidence Metrics Grounded in Evidence

**Check:** Are all confidence scores calculated from loaded evidence (not fabricated)?

**Invalid:**
- Assigning high source quality score without reading source metadata
- Estimating evidence count without counting findings
- Guessing recency without checking publication date
- Scoring expertise match without researching author credentials

**Valid:**
- All 5 evidence factors scored from actual data
- Cross-validation based on loaded sources
- Evidence count matches actual findings processed
- Recency calculated from publication timestamps

## Common Violations & Corrections

### Violation 1: Strengthened Language

❌ **Incorrect:**
- **Finding:** "Studies suggest green bonds may improve ESG outcomes"
- **Claim:** "Green bonds improve ESG outcomes"
- **Issue:** Removed hedge word "may" - strengthened certainty beyond source

✅ **Correct:**
- **Finding:** "Studies suggest green bonds may improve ESG outcomes"
- **Claim:** "Green bonds may improve ESG outcomes"
- **Why:** Preserved "may" - maintains source uncertainty level

### Violation 2: Compound Statement

❌ **Incorrect:**
- **Finding:** "Studies suggest PICO framework is important and widely used in systematic reviews"
- **Claim:** "The framework is important and widely used"
- **Issue:** Two relations ("is important" + "is widely used") + pronoun "The framework"

✅ **Correct (Split):**
- **Claim 1:** "PICO framework may be important in systematic reviews"
- **Claim 2:** "PICO framework may be widely used in systematic reviews"
- **Why:** Atomic claims (1 relation each) + decontextualized + preserved "may"

### Violation 3: Vague Reference

❌ **Incorrect:**
- **Finding:** "One study observed a 15 basis point spread"
- **Claim:** "Green bonds always have 15 basis point spreads"
- **Issue:** Added "always" (not in source) + generalized "one study" to universal claim

✅ **Correct:**
- **Claim:** "One study observed a 15 basis point spread in green bonds"
- **Why:** Preserved "one study" qualifier + no universal generalization

### Violation 4: Decontextualization Failure

❌ **Incorrect:**
- **Finding:** "The PRISMA 2020 checklist contains 27 items"
- **Claim:** "The checklist contains 27 items"
- **Issue:** Pronoun "The checklist" - which checklist?

✅ **Correct:**
- **Claim:** "PRISMA 2020 checklist contains 27 items"
- **Why:** Replaced pronoun with specific entity name

## Integration with Quality Framework

Anti-hallucination protocol enforces quality dimensions:

| Dimension | Protocol Enforces |
|-----------|-------------------|
| **Atomicity** | Step 2: No merging multiple facts |
| **Fluency** | Maintain grammatical correctness |
| **Decontextualization** | Step 4 (Violation 4): Remove pronouns, add entity names |
| **Faithfulness** | Steps 1, 3: Preserve source meaning, no strengthening |

Violations of anti-hallucination protocol cause quality dimension failures, triggering `flagged_for_review: true`.

## Hedge Word Preservation Guide

### Common Hedge Words (ALWAYS PRESERVE)

**Modal verbs:** may, might, could, would, should
**Adverbs:** possibly, probably, likely, potentially, apparently, seemingly
**Verbs:** suggests, indicates, appears, seems, tends
**Phrases:** it is possible that, there is evidence that, research indicates

### Strengthening Transformations (NEVER DO)

| Source Language | WRONG Strengthening | CORRECT Preservation |
|-----------------|---------------------|---------------------|
| may improve | improves | may improve |
| suggests correlation | proves correlation | suggests correlation |
| likely effective | effective | likely effective |
| appears to reduce | reduces | appears to reduce |
| could increase | increases | could increase |
| potentially harmful | harmful | potentially harmful |
| research indicates | definitively shows | research indicates |

## Workflow Integration

1. Extract claim candidate from finding (Phase 2)
2. **Run 4-step verification (this protocol)**
3. If violations detected → Correct claim before proceeding
4. Calculate evidence confidence (Phase 3)
5. Calculate claim quality (Phase 4) - faithfulness dimension validates no strengthening
6. If faithfulness < 0.7 → Flag triggered by anti-hallucination violation

## Quality Assurance Checklist

Before creating claim entity, confirm:
- [ ] Claim text quotes or accurately paraphrases source (Step 1)
- [ ] Claim contains exactly 1 factual relation (Step 2)
- [ ] All hedge words from source preserved (Step 3)
- [ ] No certainty language added beyond source (Step 3)
- [ ] All scores calculated from actual evidence (Step 4)
- [ ] Specific entity names used (no pronouns like "it", "the study")
- [ ] If claim references "the study" → Rewritten with actual entity name

## Notes

- Anti-hallucination violations are detected by faithfulness dimension (< 0.7)
- Preventing violations during extraction is better than detecting them after scoring
- When in doubt, preserve exact source language (even if awkward)
- If claim can be split, it should be split (atomicity principle)
