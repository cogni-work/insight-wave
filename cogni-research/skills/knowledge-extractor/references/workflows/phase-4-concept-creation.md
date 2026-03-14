# Phase 4: Concept Creation

Transform recurring technical terms into concept entities with definitions, characteristics, and dimension assignments.

---

## Entry Gate

Verify Phase 3 artifacts exist before proceeding:

```bash
# Phase 3 must provide these data structures
test ${#RECURRING_TERMS[@]} -ge 0      # May be 0 (valid early exit)
test ${#TERM_FINDINGS[@]} -ge 0
test ${#FINDING_TO_DIMENSION[@]} -gt 0
```

**IF tests fail:** Return to Phase 3.

---

## Step 0.5: TodoWrite Expansion

```markdown
ADD to TodoWrite:
- Phase 4.1: Process term batch with duplicate/semantic checks [in_progress]
- Phase 4.2: Complete entity creation and backlink tracking [pending]
```

---

## Step 1: Initialize

```bash
log_phase "Phase 4: Concept Creation" "start"

concepts_created=0
concepts_skipped_confidence=0
concepts_skipped_duplicate=0
# Bash 3.2 compatible - use parallel indexed arrays
CONCEPTS_DIM_KEYS=()    # dimension files
CONCEPTS_DIM_VALUES=()  # concept wikilinks (space-separated)
```

---

## Step 2: Process Each Term

For each term in `RECURRING_TERMS`, execute the following pipeline:

### 2.1 Duplicate Check (Script-Delegated)

Check for existing concepts with the same normalized name using entity-index lookup:

```bash
# Normalize term for comparison
normalized=$(echo "$term" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')

# Check entity-index first (authoritative)
PLUGIN_SCRIPTS="${CLAUDE_PLUGIN_ROOT}/scripts"

# Use lookup-entity.py for authoritative check
LOOKUP_RESULT=$(python3 "${PLUGIN_SCRIPTS}/lookup-entity.py" \
  --project-path "${PROJECT_PATH}" \
  --entity-type "05-domain-concepts" \
  --name "$term" \
  --json 2>/dev/null || echo '{"exists": false}')

ENTITY_EXISTS=$(echo "$LOOKUP_RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('exists', False))" 2>/dev/null || echo "False")

if [ "$ENTITY_EXISTS" = "True" ]; then
  # Duplicate found in entity-index
  concepts_skipped_duplicate=$((concepts_skipped_duplicate+1))
  continue  # Skip to next term
fi

# Fallback: scan filesystem for concepts created during this extraction run
for existing in "${PROJECT_PATH}"/${DOMAIN_CONCEPTS_DIR}/data/concept-*.md; do
  [ -f "$existing" ] || continue
  existing_name=$(grep "^concept:" "$existing" | head -1 | cut -d'"' -f2)
  existing_norm=$(echo "$existing_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')
  [ "$normalized" = "$existing_norm" ] && { concepts_skipped_duplicate=$((concepts_skipped_duplicate+1)); continue 2; }
done
```

**Note:** The entity-index lookup is the primary deduplication check. The filesystem scan is a fallback for concepts created in the current extraction run that may not yet be in the index.

### 2.2 Semantic Analysis (LLM Reasoning)

Locate all findings mentioning this term from `TERM_FINDINGS[$term]`.

**Synthesize from findings ONLY using IS/DOES/MEANS structure:**

| Output | Requirement |
|--------|-------------|
| **What it is** | 150-200 words defining what the concept encompasses, core terminology, scope, and key characteristics. Synthesize from findings only. |
| **What it does** | 100-150 words describing practical applications, how concept manifests in research domain, key activities/processes, real-world examples from findings. |
| **What it means** | 150-200 words on implications: qualitative impact (strategic significance, stakeholder effects) and quantitative indicators (metrics table if data available in findings). |
| **Category** | One of: Framework, Metric, Technique, Tool, Method, Standard |
| **Confidence** | Base 0.90 + bonuses (see scoring below) |

**German Language Requirement:** When `language: "de"`, all body text and section headings MUST use proper German umlauts (ä, ö, ü, ß). Never use ASCII transliterations (ae, oe, ue, ss) in content. Only filenames/slugs use ASCII.

**Confidence Scoring:**

```text
Base: 0.90
+ min(0.05, finding_count/2 * 0.01)   # More mentions = higher confidence
+ 0.02 if definition is clear
+ 0.03 if consistent across findings
Maximum: 0.99
```

**IF confidence < 0.90:** Skip term, increment `concepts_skipped_confidence`.

### 2.3 Filename Generation (Script-Delegated)

```bash
slug=$(echo "$term" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | \
  sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//' | cut -c1-50)
hash=$(echo -n "$term" | shasum -a 256 | cut -c1-8)
filename="concept-${slug}-${hash}.md"
```

### 2.4 Dimension Assignment (Majority Vote)

Count findings per dimension using `FINDING_TO_DIMENSION`:

```bash
# Bash 3.2 compatible - use parallel indexed arrays for counting
DIM_COUNT_KEYS=()
DIM_COUNT_VALUES=()

# Helper to get or add dimension count
get_or_add_dim_count() {
  local dim="$1"
  local i=0
  for key in "${DIM_COUNT_KEYS[@]}"; do
    if [[ "$key" == "$dim" ]]; then
      echo "$i"
      return 0
    fi
    i=$((i + 1))
  done
  DIM_COUNT_KEYS+=("$dim")
  DIM_COUNT_VALUES+=(0)
  echo "$i"
}

for finding in ${term_findings}; do
  dim=$(lookup_finding_dimension "$finding")
  if [ -n "$dim" ]; then
    idx=$(get_or_add_dim_count "$dim")
    DIM_COUNT_VALUES[$idx]=$((DIM_COUNT_VALUES[$idx] + 1))
  fi
done

best_dimension=""
max=0
for i in "${!DIM_COUNT_KEYS[@]}"; do
  if [ ${DIM_COUNT_VALUES[$i]} -gt $max ]; then
    best_dimension="${DIM_COUNT_KEYS[$i]}"
    max=${DIM_COUNT_VALUES[$i]}
  fi
done
```

### 2.5 Build Finding References (Script-Delegated)

**CRITICAL:** Iterate through ALL findings in `TERM_FINDINGS[$term]` to build wikilinks:

```bash
finding_refs=""
related_findings=""
for finding_file in ${TERM_FINDINGS[$term]}; do
  finding_basename=$(basename "$finding_file" .md)
  finding_refs+="  - \"[[${FINDINGS_DIR}/data/${finding_basename}]]\"\n"
  # Extract title from finding for display alias
  finding_title=$(grep "^dc:title:" "$finding_file" 2>/dev/null | cut -d'"' -f2 | head -1)
  [ -z "$finding_title" ] && finding_title="$finding_basename"
  related_findings+="- [[${FINDINGS_DIR}/data/${finding_basename}|${finding_title}]]\n"
done
```

**Verification:** `finding_refs` must contain one wikilink per finding in `TERM_FINDINGS[$term]`.

### 2.6 Write Entity File

Write to `${PROJECT_PATH}/${DOMAIN_CONCEPTS_DIR}/data/${filename}`:

```yaml
---
tags: [finding, concept-category/{category}, confidence/{level}]
entity_type: domain-concept
dc:creator: knowledge-extractor
dc:title: "{2-4 word heading}"
concept: "{Concept Name}"
category: "{Category}"
confidence: {score}
finding_refs:
{finding_refs}
created_at: "{ISO 8601 UTC}"
language: "{content_language}"
---

# {Concept Name}

## What it is

{150-200 words - Definition, terminology, scope, key characteristics from findings}

## What it does

{100-150 words - Practical applications, how it manifests, activities/processes, examples from findings}

## What it means

**Qualitative Impact:**

{Strategic significance and stakeholder effects from findings}

**Quantitative Indicators:**

| Metric | Value/Range | Source |
|--------|-------------|--------|
| {Metric} | {Value} | [[finding-ref]] |

{Include metrics table only if findings contain quantitative data}

## Related Findings

{related_findings}
```

**⚠️ LANGUAGE REQUIREMENT:** When `language: "de"`:
- Use German headers: "Was es ist", "Was es tut", "Was es bedeutet", "Qualitative Auswirkungen", "Quantitative Indikatoren", "Zugehörige Ergebnisse"
- Body text MUST use proper umlauts (ä, ö, ü, ß), NOT ASCII transliterations (ae, oe, ue, ss)

**⚠️ WIKILINK REQUIREMENT:** Each concept MUST include:

1. `finding_refs` array in frontmatter with `[[${FINDINGS_DIR}/data/{basename}]]` for EVERY source finding
2. `## Related Findings` section with `[[${FINDINGS_DIR}/data/{basename}|Title]]` for EVERY source finding

**Template Reference:** [../domain/entity-templates.md](../domain/entity-templates.md)

### 2.7 Track for Backlinks

```bash
if [ -n "$best_dimension" ]; then
  dim_file=$(basename "$best_dimension")
  CONCEPTS_BY_DIMENSION["$dim_file"]+="[[${DOMAIN_CONCEPTS_DIR}/data/${filename%.md}]] "
fi
concepts_created=$((concepts_created+1))
```

**Mark 4.1 complete.** Proceed to completion.

---

## Step 3: Completion

```bash
log_conditional INFO "Concepts created: $concepts_created"
log_conditional INFO "Skipped (confidence): $concepts_skipped_confidence"
log_conditional INFO "Skipped (duplicate): $concepts_skipped_duplicate"
log_phase "Phase 4: Concept Creation" "complete"
```

**Mark 4.2 complete.**

---

## Anti-Hallucination Protocol

| Rule | Enforcement |
|------|-------------|
| No external knowledge | Definitions synthesized from findings ONLY |
| No fabrication | Wikilinks reference actual finding files |
| Source attribution | All content traceable to specific findings |

**Reference:** [../patterns/anti-hallucination.md](../patterns/anti-hallucination.md)

---

## Phase Completion

**Verification (4 checks):**

- [ ] All `RECURRING_TERMS` processed
- [ ] Entity files written to `${DOMAIN_CONCEPTS_DIR}/data/`
- [ ] `CONCEPTS_BY_DIMENSION` populated for backlinks
- [ ] All step todos completed

**Output:**

```text
Phase 4 Complete: Concept Creation

Processed: {RECURRING_TERMS count} terms
Created: {concepts_created} concepts
Skipped: {concepts_skipped_confidence} (confidence) + {concepts_skipped_duplicate} (duplicate)
Backlinks: {CONCEPTS_BY_DIMENSION dimension count} dimensions

-> Phase 5: Megatrend Clustering
```

**Mark Phase 4 complete.** Proceed to [phase-5-megatrend-clustering.md](phase-5-megatrend-clustering.md).
