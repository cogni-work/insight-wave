---
name: fact-checker
description: Transform research findings into verified claims with dual-layer scoring (evidence reliability + claim quality). Use as Phase 7 of deeper-research pipeline after findings/sources/publishers exist, or standalone for factual verification with research-grade confidence scoring. Not for opinion validation or content without verifiable sources.
---

# Fact-Checker

Extract atomic claims from research findings, calculate dual-layer confidence scores, and create verified claim entities with complete provenance chains.

---

## Immediate Action: Initialize TodoWrite

**⛔ MANDATORY:** Initialize TodoWrite immediately with all workflow phases:

1. Phase 1: Parameter Validation [in_progress]
2. Phase 2: Environment Setup [pending]
3. Phase 3: Load & Partition [pending]
4. Phase 4: Planning [pending]
5. Phase 5: Extraction & Verification [pending]
6. Phase 6: Statistics & Return [pending]

Update todo status as you progress through each phase.

**Note:** Each phase will add step-level todos when started (progressive expansion from 6 phase-level to ~15-20 step-level).

---

## Progressive TodoWrite Expansion

The fact-checker workflow uses **progressive disclosure** for TodoWrite tracking:

- **Initial state:** 6 phase-level todos (shown above)
- **Progressive expansion:** Each phase adds its step-level todos when started
- **Final state:** ~15-20 step-level todos across all phases

**Pattern:** As you enter each phase, add the step-level todos for that phase. This prevents overwhelming initial context while maintaining detailed tracking.

---

## Core Workflow

Execute phases sequentially with mandatory reference reading and TodoWrite tracking.

### Phase 1: Parameter Validation

#### Step 0.5: Initialize Phase 1 TodoWrite

Add step-level todos for Phase 1:

```markdown
USE: TodoWrite tool
ADD (in addition to phase-level todos):
- Phase 1, Step 1: Read shared-bash-patterns.md Section 1 [in_progress]
- Phase 1, Step 2: Validate required parameters [pending]
- Phase 1, Step 3: Validate optional parameters [pending]
- Phase 1, Step 4: Return error if validation fails [pending]

As you complete each step, mark the corresponding todo as completed.
```

#### Step 1: Read Parameter Parsing Reference

⛔ **MANDATORY:** Read parameter parsing reference BEFORE executing validation:

```bash
USE: Read tool
FILE: ${CLAUDE_PLUGIN_ROOT}/references/shared-bash-patterns.md
SECTION: Section 1 (parameter parsing)

EXTRACT:
- Parameter parsing patterns
- Required vs optional parameter handling
- Error JSON format for exit 2
- Partitioning parameter validation
```

**Note:** `CLAUDE_PLUGIN_ROOT` points to the `cogni-research` plugin directory.

**Mark Step 1 todo as completed** before proceeding to Step 2.

#### Step 2: Validate Required Parameters

**Required:** `--project-path` (research project directory)

If PROJECT_PATH missing → return error JSON (exit 2)

**Mark Step 2 todo as completed** before proceeding to Step 3.

#### Step 3: Validate Optional Parameters

**Optional:** `--partition-index`, `--total-partitions` (parallel execution), `--language` (default: en)

If partitioning params incomplete → return error JSON (exit 2)

**Mark Step 3 todo as completed** before proceeding to Step 4.

#### Step 4: Confirm Validation Complete

Update TodoWrite: Phase 1 → completed, Phase 2 → in_progress

**Mark Step 4 todo as completed** before proceeding to Phase 2.

---

## Output Language

**Language Parameter:** `--language` (ISO 639-1 code, default: en)

**CRITICAL - German Text Formatting (when --language=de):**

| Context | Format | Example |
|---------|--------|---------|
| **Body text** | Proper umlauts (ä, ö, ü, ß) | "Änderungen" NOT "Aenderungen" |
| **Section headings** | Proper umlauts | "Begründung" NOT "Begrundung" |
| **Explanations** | Proper umlauts | "für" NOT "fuer", "müssen" NOT "muessen" |
| **File names/slugs** | ASCII transliterations | ü→ue, ä→ae, ö→oe, ß→ss |
| **Frontmatter IDs** | ASCII only | dc:identifier, entity IDs |
| **JSON keys** | English | Data interchange format |

**Anti-pattern (WRONG):**
```markdown
## Begrundung
Das Jahr 2026 bringt wichtige arbeitsrechtliche Aenderungen, die fuer Personalstrategien beachtet werden muessen.
```

**Correct pattern:**
```markdown
## Begründung
Das Jahr 2026 bringt wichtige arbeitsrechtliche Änderungen, die für Personalstrategien beachtet werden müssen.
```

---

### Phase 2: Environment Setup

#### Step 0.5: Initialize Phase 2 TodoWrite

Add step-level todos for Phase 2:

```markdown
USE: TodoWrite tool
ADD (in addition to phase-level todos):
- Phase 2, Step 1: Read shared-bash-patterns.md Sections 2-3 [in_progress]
- Phase 2, Step 2: Validate PROJECT_PATH with validate-working-directory.sh [pending]
- Phase 2, Step 3: Initialize partition-aware logging [pending]
- Phase 2, Step 4: Resolve entity directory names [pending]
- Phase 2, Step 5: Confirm environment setup complete [pending]

As you complete each step, mark the corresponding todo as completed.
```

#### Step 1: Read Environment Setup Reference

⛔ **MANDATORY:** Read environment setup reference BEFORE executing setup:

```bash
USE: Read tool
FILE: ${CLAUDE_PLUGIN_ROOT}/references/shared-bash-patterns.md
SECTIONS: Sections 2-3 (environment validation and logging)

EXTRACT:
- Working directory validation patterns
- Partition-aware logging initialization
- Environment variable setup
- Error handling for invalid environments
```

**Mark Step 1 todo as completed** before proceeding to Step 2.

#### Step 2: Validate PROJECT_PATH

Execute `validate-working-directory.sh` to ensure PROJECT_PATH is valid.

**Mark Step 2 todo as completed** before proceeding to Step 3.

#### Step 3: Initialize Partition-Aware Logging

Set up logging system with partition awareness if parallel execution enabled.

**Mark Step 3 todo as completed** before proceeding to Step 4.

#### Step 4: Resolve Entity Directory Names

⛔ **MANDATORY:** Resolve entity directory placeholders from centralized config. Other phases depend on these variables.

```bash
# === MANDATORY: Directory Resolution ===
# Try both direct and monorepo paths for entity-config.sh
ENTITY_CONFIG=""
if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ]; then
    if [ -f "${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh" ]; then
        ENTITY_CONFIG="${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh"
    # CLAUDE_PLUGIN_ROOT points directly to plugin root in flat structure
    fi
fi

if [ -n "$ENTITY_CONFIG" ]; then
    source "$ENTITY_CONFIG"
    FINDINGS_DIR=$(get_directory_by_key "findings")
    CLAIMS_DIR=$(get_directory_by_key "claims")
    CITATIONS_DIR=$(get_directory_by_key "citations")
    MEGATRENDS_DIR=$(get_directory_by_key "megatrends")
else
    # Fallback to hardcoded values if entity-config.sh unavailable
    FINDINGS_DIR="04-findings"
    CLAIMS_DIR="10-claims"
    CITATIONS_DIR="09-citations"
    MEGATRENDS_DIR="06-megatrends"
fi
export FINDINGS_DIR CLAIMS_DIR CITATIONS_DIR MEGATRENDS_DIR

# Log resolved directories
log_conditional INFO "Entity directories resolved:"
log_conditional INFO "  FINDINGS_DIR=${FINDINGS_DIR}"
log_conditional INFO "  CLAIMS_DIR=${CLAIMS_DIR}"
log_conditional INFO "  CITATIONS_DIR=${CITATIONS_DIR}"
log_conditional INFO "  MEGATRENDS_DIR=${MEGATRENDS_DIR}"
```

**Output:** Exported variables `FINDINGS_DIR`, `CLAIMS_DIR`, `CITATIONS_DIR`, `MEGATRENDS_DIR` available for all subsequent phases.

**Mark Step 4 todo as completed** before proceeding to Step 5.

#### Step 5: Confirm Environment Setup Complete

Update TodoWrite: Phase 2 → completed, Phase 3 → in_progress

**Mark Step 5 todo as completed** before proceeding to Phase 3.

### Phase 3: Load & Partition

#### Step 0.5: Initialize Phase 3 TodoWrite

Add step-level todos for Phase 3:

```markdown
USE: TodoWrite tool
ADD (in addition to phase-level todos):
- Phase 3, Step 1: Read implementation-patterns.md for partition algorithm [in_progress]
- Phase 3, Step 2: List findings from ${FINDINGS_DIR}/data/ directory [pending]
- Phase 3, Step 3: Handle 0 findings case if applicable [pending]
- Phase 3, Step 4: Calculate partition slice or full set [pending]
- Phase 3, Step 5: Confirm load & partition complete [pending]

As you complete each step, mark the corresponding todo as completed.
```

#### Step 1: Read Partition Algorithm Reference

⛔ **MANDATORY:** Read partition algorithm reference BEFORE executing partitioning:

```bash
USE: Read tool
FILE: ${CLAUDE_PLUGIN_ROOT}/skills/fact-checker/references/implementation-patterns.md

EXTRACT:
- Partition algorithm (slice calculation)
- Parallel vs sequential execution logic
- Edge cases (0 findings, partition boundaries)
- Data structure patterns
```

**Mark Step 1 todo as completed** before proceeding to Step 2.

#### Step 2: List Findings

List all findings from `${PROJECT_PATH}/${FINDINGS_DIR}/data/` directory.

**Mark Step 2 todo as completed** before proceeding to Step 3.

#### Step 3: Handle Zero Findings Case

If 0 findings found → return success JSON with 0 claims and exit gracefully.

**Mark Step 3 todo as completed** before proceeding to Step 4.

#### Step 4: Calculate Partition Slice

Calculate partition slice (parallel mode) or process all findings (sequential mode).

**Mark Step 4 todo as completed** before proceeding to Step 5.

#### Step 5: Confirm Load & Partition Complete

Update TodoWrite: Phase 3 → completed, Phase 4 → in_progress

**Mark Step 5 todo as completed** before proceeding to Phase 4.

### Phase 4: Planning

#### Step 0.5: Initialize Phase 4 TodoWrite

Add step-level todos for Phase 4:

```markdown
USE: TodoWrite tool
ADD (in addition to phase-level todos):
- Phase 4, Step 1: Read anti-hallucination.md for verification protocol [in_progress]
- Phase 4, Step 2: Plan extraction with structured thinking [pending]
- Phase 4, Step 3: Document planning output [pending]
- Phase 4, Step 4: Confirm planning complete [pending]

As you complete each step, mark the corresponding todo as completed.
```

#### Step 1: Read Verification Protocol Reference

⛔ **MANDATORY:** Read verification protocol reference BEFORE planning extraction:

```bash
USE: Read tool
FILE: ${CLAUDE_PLUGIN_ROOT}/skills/fact-checker/references/anti-hallucination.md

EXTRACT:
- Anti-hallucination verification checklist
- Quote extraction protocols
- Accuracy validation steps
- Uncertainty preservation guidelines
```

**Mark Step 1 todo as completed** before proceeding to Step 2.

#### Step 2: Plan Extraction with Structured Thinking

Use structured thinking to plan extraction:

```xml
<thinking>
<assigned_findings>List findings to process with indices</assigned_findings>
<extraction_strategy>Atomic splitting, uncertainty preservation</extraction_strategy>
<scoring_methodology>5-factor evidence + 4-dimension quality</scoring_methodology>
<anti_hallucination_verification>Quote extraction, accuracy checklist</anti_hallucination_verification>
</thinking>
```

**Mark Step 2 todo as completed** before proceeding to Step 3.

#### Step 3: Document Planning Output

Record planning decisions for reference during extraction phase.

**Mark Step 3 todo as completed** before proceeding to Step 4.

#### Step 4: Confirm Planning Complete

Update TodoWrite: Phase 4 → completed, Phase 5 → in_progress

**Mark Step 4 todo as completed** before proceeding to Phase 5.

### Phase 5: Extraction & Verification

#### Step 0.5: Initialize Phase 5 TodoWrite

Add step-level todos for Phase 5:

```markdown
USE: TodoWrite tool
ADD (in addition to phase-level todos):
- Phase 5, Step 1: Read variable-tracking.md for data structures [in_progress]
- Phase 5, Step 2: Initialize required data structures [pending]
- Phase 5, Step 3: Read wikilink-extraction.md for provenance algorithms [pending]
- Phase 5, Step 4: Read evidence-confidence.md for scoring methodology [pending]
- Phase 5, Step 5: Read claim-quality.md for quality framework [pending]
- Phase 5, Step 6: Read flagging-rules.md for flagging decision tree [pending]
- Phase 5, Step 7: Read entity-templates.md for YAML structure [pending]
- Phase 5, Step 8: Process each finding with extraction & verification [pending]
- Phase 5, Step 9: Update megatrend and citation backlinks [pending]
- Phase 5, Step 10: Confirm extraction & verification complete [pending]

As you complete each step, mark the corresponding todo as completed.
```

#### Step 1: Read Variable Tracking Reference

⛔ **MANDATORY:** Read variable tracking reference BEFORE initializing data structures:

```bash
USE: Read tool
FILE: ${CLAUDE_PLUGIN_ROOT}/skills/fact-checker/references/variable-tracking.md

EXTRACT:
- Counter patterns
- Associative array declarations
- Data structure initialization
- Variable naming conventions
```

**Mark Step 1 todo as completed** before proceeding to Step 2.

#### Step 2: Initialize Data Structures

Required (Bash 3.2 compatible - use parallel indexed arrays):

- `CLAIMS_BY_MEGATREND_KEYS=()` / `CLAIMS_BY_MEGATREND_VALUES=()` - megatrend → claim IDs mapping
- `SOURCE_TO_CITATIONS_KEYS=()` / `SOURCE_TO_CITATIONS_VALUES=()` - source → citation IDs mapping
- `CLAIMS_BY_CITATION_KEYS=()` / `CLAIMS_BY_CITATION_VALUES=()` - citation → claim IDs mapping

Build SOURCE_TO_CITATIONS by scanning `${PROJECT_PATH}/${CITATIONS_DIR}/data/` for source_id fields.

**Mark Step 2 todo as completed** before proceeding to Step 3.

#### Step 3: Read Wikilink Extraction Reference

⛔ **MANDATORY:** Read wikilink extraction reference BEFORE processing findings:

```bash
USE: Read tool
FILE: ${CLAUDE_PLUGIN_ROOT}/skills/fact-checker/references/wikilink-extraction.md

EXTRACT:
- 5 wikilink extraction algorithms
- Provenance tracking patterns
- Source/publisher/citation linking
- Edge cases and validation
```

**Mark Step 3 todo as completed** before proceeding to Step 4.

#### Step 4: Read Evidence Confidence Reference

⛔ **MANDATORY:** Read evidence confidence reference BEFORE scoring:

```bash
USE: Read tool
FILE: ${CLAUDE_PLUGIN_ROOT}/skills/fact-checker/references/evidence-confidence.md

EXTRACT:
- 5-factor evidence scoring methodology
- Weighted formula calculation
- Source quality tiers
- Cross-validation patterns
- Recency and expertise scoring
```

**Mark Step 4 todo as completed** before proceeding to Step 5.

#### Step 5: Read Claim Quality Reference

⛔ **MANDATORY:** Read claim quality reference BEFORE quality assessment:

```bash
USE: Read tool
FILE: ${CLAUDE_PLUGIN_ROOT}/skills/fact-checker/references/claim-quality.md

EXTRACT:
- Wright et al. 2022 framework
- 4-dimension quality scoring
- Atomicity, fluency, decontextualization, faithfulness
- Composite confidence calculation
```

**Mark Step 5 todo as completed** before proceeding to Step 6.

#### Step 6: Read Flagging Rules Reference

⛔ **MANDATORY:** Read flagging rules reference BEFORE applying flags:

```bash
USE: Read tool
FILE: ${CLAUDE_PLUGIN_ROOT}/skills/fact-checker/references/flagging-rules.md

EXTRACT:
- Evidence flagging decision tree
- Quality flagging thresholds
- Critical claim identification
- Flag prioritization logic
```

**Mark Step 6 todo as completed** before proceeding to Step 7.

#### Step 7: Read Entity Templates Reference

⛔ **MANDATORY:** Read entity templates reference BEFORE creating claims:

```bash
USE: Read tool
FILE: ${CLAUDE_PLUGIN_ROOT}/skills/fact-checker/references/entity-templates.md

EXTRACT:
- Claim YAML structure
- Required and optional fields
- Metadata formatting
- File naming conventions
```

**Mark Step 7 todo as completed** before proceeding to Step 8.

#### Step 8: Process Each Finding

For each finding, execute the following sub-steps:

**A. Read** finding content

**B. Extract atomic claims** - One fact per claim, preserve uncertainty qualifiers ("may", "suggests", "likely")

Anti-pattern:

- ❌ Finding: "Studies suggest X may improve Y" → Claim: "X improves Y"
- ✅ Finding: "Studies suggest X may improve Y" → Claim: "Studies suggest X may improve Y"

**C. Extract provenance** via 5 wikilink algorithms (using patterns from wikilink-extraction.md)

**D. Calculate evidence confidence** (5 factors, weighted):

```text
evidence_confidence = (source_quality × 0.35) + (evidence_count × 0.25) +
                      (cross_validation × 0.20) + (recency × 0.10) +
                      (expertise_match × 0.10)
```

Quick tiers (see evidence-confidence.md for full methodology):

- Source: Academic (1.0), Industry (0.8), Professional (0.6), Community (0.4)
- Count: 3+ (1.0), 2 (0.7), 1 (0.5)
- Validation: Multiple (1.0), Single (0.7), None (0.5), Conflicts (0.3)
- Recency: <1yr (1.0), 1-3yr (0.8), 3-5yr (0.6), >5yr (0.4)

**E. Calculate claim quality** (4 dimensions, averaged, using claim-quality.md framework):

```text
claim_quality = (atomicity + fluency + decontextualization + faithfulness) / 4.0
```

- **Atomicity** (binary): 1.0 single relation, 0.0 multiple
- **Fluency** (continuous): 1.0 perfect, 0.7 minor issues, 0.4 awkward
- **Decontextualization** (binary): 1.0 self-contained, 0.0 needs context
- **Faithfulness** (continuous): 1.0 exact, 0.7 paraphrase, 0.4 interpretation

**Composite:** `confidence_score = (evidence_confidence × 0.6) + (claim_quality × 0.4)`

**F. Determine criticality** - Set `is_critical: true` for quantitative data, security/safety, benchmarks, regulatory, or cost info.

**G. Apply flagging rules** (using flagging-rules.md decision tree):

Evidence flags: confidence < 0.60 on critical claims, conflicts, missing metadata
Quality flags: claim_quality < 0.5, atomicity 0.0, decontextualization 0.0, faithfulness < 0.7

**H. Create claim entity** in `${PROJECT_PATH}/${CLAIMS_DIR}/data/claim-{semantic}-{6-char-hash}.md` (using entity-templates.md structure)

- Generate a **bold title** (3-5 descriptive words, title case) summarizing the claim's key subject
- Place the bold title between `## Claim` header and the claim text
- Example: `**Global Green Bond Issuance**`

**I. Track relationships** - Update CLAIMS_BY_MEGATREND and CLAIMS_BY_CITATION mappings.

**Mark Step 8 todo as completed** before proceeding to Step 9.

#### Step 9: Update Megatrend and Citation Backlinks

##### A. Megatrend Backlink Update

For each megatrend in CLAIMS_BY_MEGATREND, insert `claim_ids` field with wikilinks to referencing claims.

##### B. Citation Backlink Update

For each citation in CLAIMS_BY_CITATION, insert `claim_ids` field with wikilinks to referencing claims.

**Mark Step 9 todo as completed** before proceeding to Step 10.

#### Step 10: Confirm Extraction & Verification Complete

Update TodoWrite: Phase 5 → completed, Phase 6 → in_progress

**Mark Step 10 todo as completed** before proceeding to Phase 6.

### Phase 6: Statistics & Return

#### Step 0.5: Initialize Phase 6 TodoWrite

Add step-level todos for Phase 6:

```markdown
USE: TodoWrite tool
ADD (in addition to phase-level todos):
- Phase 6, Step 1: Calculate statistics (averages for all scores) [in_progress]
- Phase 6, Step 2: Write JSON report to .metadata/ directory [pending]
- Phase 6, Step 3: Return concise summary [pending]
- Phase 6, Step 4: Confirm fact-checking complete [pending]

As you complete each step, mark the corresponding todo as completed.
```

#### Step 1: Calculate Statistics

Calculate averages for all scores:

- Average evidence confidence
- Average claim quality
- Average composite confidence
- Flag counts (evidence flags, quality flags)

**Mark Step 1 todo as completed** before proceeding to Step 2.

#### Step 2: Write JSON Report

Write JSON to `.metadata/fact-checker-stats.json` (or `partition-{N}-stats.json` for parallel execution)

**Mark Step 2 todo as completed** before proceeding to Step 3.

#### Step 3: Return Concise Summary

**Pipeline mode (5 lines max):**
```
✅ Partition {N} fact-checking complete.
- Findings processed: {count}
- Claims created: {count} ({flagged} flagged)
- Avg evidence: {score} | Avg quality: {score} | Final: {score}
- Review required: {evidence_flags} evidence, {quality_flags} quality
```

**Standalone mode:** Add 2-3 sentences with findings and next steps.

**Mark Step 3 todo as completed** before proceeding to Step 4.

#### Step 4: Confirm Fact-Checking Complete

Update TodoWrite: Phase 6 → completed

**Mark Step 4 todo as completed**. All phases complete.

## Error Handling

| Scenario | Recovery |
|----------|----------|
| PROJECT_PATH missing | Error JSON, exit 2 |
| Validation fails | Error JSON, exit 1 |
| Finding not found | Skip, log warning, continue |
| No claims extractable | Success JSON with 0 claims |

**Read:** `${CLAUDE_PLUGIN_ROOT}/references/shared-bash-patterns.md` Section 5.

## Examples

### High-Quality Claim

**Finding:** "Green bonds issued $500B globally in 2023 (Climate Bonds Initiative, 2024)"
**Claim:** "Green bonds issued $500 billion globally in 2023"

| Layer | Score | Details |
|-------|-------|---------|
| Evidence | 0.74 | Source 1.0, Count 0.5, Validation 0.7, Recency 1.0, Expertise 1.0 |
| Quality | 1.0 | All dimensions perfect |
| **Final** | **0.84** | (0.74 × 0.6) + (1.0 × 0.4) |

### Poor Extraction (Flagged)

**Finding:** "Studies suggest PICO framework is important and widely used"
**Claim:** "The framework is important and widely used" ❌

| Dimension | Score | Issue |
|-----------|-------|-------|
| Atomicity | 0.0 | Two relations |
| Decontextualization | 0.0 | "The framework" - which? |
| Faithfulness | 0.4 | Omitted "PICO" and "suggest" |

**Quality:** 0.35 → flagged for review

**Correct split:**
1. "PICO framework may be important in systematic reviews"
2. "PICO framework may be widely used in systematic reviews"

## Debugging

Three-layer architecture:
- **Layer 1:** `log_phase`, `log_conditional`, `log_metric`
- **Layer 2:** Enhanced logging via `enhanced-logging.sh`
- **Layer 3:** Hooks for validation/artifacts

Enable: `export DEBUG_MODE=1`

**Read:** [Debugging Guide](https://github.com/cogni-work/dev-work/blob/main/references/debugging-guide.md)

## Quality Checklist

- [ ] All claims atomic (single relation)
- [ ] Uncertainty qualifiers preserved
- [ ] 5 evidence factors + 4 quality dimensions scored
- [ ] All 5 wikilink algorithms executed
- [ ] Claim entities created in `${CLAIMS_DIR}/data/`
- [ ] Megatrend/citation backlinks updated
- [ ] Statistics JSON written
- [ ] All phases logged

## Reference Files

- [references/evidence-confidence.md](references/evidence-confidence.md) - 5-factor scoring
- [references/claim-quality.md](references/claim-quality.md) - Wright et al. 2022 framework
- [references/flagging-rules.md](references/flagging-rules.md) - Dual-layer flagging
- [references/implementation-patterns.md](references/implementation-patterns.md) - Bash patterns
- [references/variable-tracking.md](references/variable-tracking.md) - Counters
- [references/wikilink-extraction.md](references/wikilink-extraction.md) - Provenance algorithms
- [references/anti-hallucination.md](references/anti-hallucination.md) - Verification protocol
- [references/entity-templates.md](references/entity-templates.md) - Claim YAML structure
