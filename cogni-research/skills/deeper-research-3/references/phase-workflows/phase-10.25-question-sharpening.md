# Phase 10.25: Research Question Sharpening

**Objective:** Distill the original (often 40+ word) research question into a concise, dual-structure formulation (max 20 words) based on synthesis results now available in conversation context.

**When to Run:** After Phase 10 (synthesis-hub complete), before Phase 10.5 (insight summary). Runs ALWAYS (not conditional on arc_id).

**Output:** `sharpened_research_question` and `original_research_question` persisted to `.metadata/sprint-log.json`

---

## Phase Entry Verification

**Self-Verification:** Before running verification, check TodoWrite to verify Phase 10 is marked complete. Phase 10.25 cannot begin until Phase 10 is completed.

**THEN verify Phase 10 artifact exists:**

```bash
test -f {project_path}/research-hub.md
```

**IF research-hub.md missing:** HALT - Phase 10 must complete first.

**IF research-hub.md exists:** Continue to Step 10.25.1.

---

## Step 10.25.1: Read Original Question

**Add step-level todos via TodoWrite:**
- Phase 10.25, Step 1: Read original research question [in_progress]
- Phase 10.25, Step 2: Sharpen question [pending]
- Phase 10.25, Step 3: Persist to sprint-log [pending]
- Phase 10.25, Step 4: Report completion [pending]

**Read research question and project language:**

```bash
research_question=$(jq -r '.research_question // ""' "{project_path}/.metadata/sprint-log.json")
project_language=$(jq -r '.project_language // "en"' "{project_path}/.metadata/sprint-log.json")
```

**IF research_question is empty:** Log WARNING and skip phase (nothing to sharpen).

**Mark Step 10.25.1 complete** before proceeding to Step 10.25.2.

---

## Step 10.25.2: Sharpen Question (Orchestrator-Inline)

**This step is performed by the orchestrator directly** — no agent delegation. The orchestrator has full synthesis context from Phase 10 already in its conversation window.

### Sharpening Rules

1. **Max 20 words** (hard limit — count before persisting)
2. **Dual structure preferred:** "Was X — und wie Y?" / "What X — and how Y?"
3. **KEEP:** time horizon, target audience, core intent, industry/domain
4. **ELIMINATE:** enumerations, redundant qualifiers, methodological framing
5. **Language:** Match `project_language` (de/en)

### Language-Specific Templates

**German pattern:**
```
[Was/Welche/Wie] {Kern-Thema} {Branche/Zielgruppe} {Zeithorizont} — und [wie/was/welche] {strategische Handlung}?
```

**English pattern:**
```
[What/How/Which] {core topic} {industry/audience} {time horizon} — and [how/what] {strategic action}?
```

### Examples

**German Example 1:**
- Original (46 Wörter): "Welche technologischen, regulatorischen, marktbezogenen und organisatorischen Trends mit konkreten Anwendungsfällen werden das Geschäft mittelständischer Maschinenbau- und Anlagenbauunternehmen in Deutschland in den kommenden fünf Jahren (2026–2031) maßgeblich beeinflussen — und wie können Unternehmenslenker diese Trends für strategische Geschäftsinnovationen und Wettbewerbsvorteile nutzen?"
- Sharpened (17 Wörter): "Welche Trends prägen den deutschen Maschinenbau-Mittelstand bis 2031 — und wie wird aus Disruption strategischer Wettbewerbsvorteil?"

**German Example 2:**
- Original (38 Wörter): "Wie entwickeln sich die relevanten Technologie-, Markt- und Regulierungstrends im Bereich der industriellen Automatisierung in Europa bis 2030 und welche strategischen Handlungsoptionen ergeben sich daraus für mittelständische Systemintegratoren?"
- Sharpened (16 Wörter): "Wie verändert sich industrielle Automatisierung in Europa bis 2030 — und was bedeutet das für Systemintegratoren?"

**English Example 1:**
- Original (41 words): "What are the key technological, regulatory, market, and organizational trends that will significantly impact the business of mid-sized manufacturing and plant engineering companies in Germany over the next five years (2026-2031) — and how can business leaders leverage these trends?"
- Sharpened (18 words): "What trends will reshape German mid-size manufacturing by 2031 — and how can leaders turn disruption into advantage?"

**English Example 2:**
- Original (35 words): "How are emerging AI capabilities and automation technologies transforming the European financial services industry, and what strategic opportunities and risks do these developments create for mid-market banks and insurance companies?"
- Sharpened (19 words): "How will AI and automation transform European mid-market financial services — and what strategic moves should banks and insurers make?"

### Self-Verification (MANDATORY before persisting)

1. **Count words** → IF > 20, revise or fall back to original
2. **Check dual structure** → IF missing, acceptable if question is already concise (< 15 words)
3. **Verify core intent preserved** → original and sharpened must answer the same research scope
4. **Verify language match** → sharpened must match `project_language`

**Mark Step 10.25.2 complete** before proceeding to Step 10.25.3.

---

## Step 10.25.3: Persist to Sprint-Log

Write `sharpened_research_question` and `original_research_question` to sprint-log.json:

```bash
jq --arg sharpened "${sharpened_question}" --arg original "${research_question}" \
  '.sharpened_research_question = $sharpened | .original_research_question = $original' \
  "${project_path}/.metadata/sprint-log.json" > "${project_path}/.metadata/sprint-log.json.tmp"
mv "${project_path}/.metadata/sprint-log.json.tmp" "${project_path}/.metadata/sprint-log.json"
```

**Three sprint-log fields after execution:**

| Field | Content | Backward Compat |
|-------|---------|-----------------|
| `research_question` | **Unchanged** — original question from Phase 0 | Existing consumers unaffected |
| `original_research_question` | Copy of original (explicit audit trail) | New field, `// ""` fallback safe |
| `sharpened_research_question` | Concise dual-structure version (max 20 words) | New field, `// ""` fallback safe |

**Validation:**

```bash
persisted=$(jq -r '.sharpened_research_question // ""' "${project_path}/.metadata/sprint-log.json")
if [ -z "${persisted}" ]; then
  echo "WARNING: sharpened_research_question not persisted"
fi
```

**Mark Step 10.25.3 complete** before proceeding to Step 10.25.4.

---

## Step 10.25.4: Report Completion

**Report Completion (success case):**

```text
Phase 10.25: Research question sharpened
- Original ({original_word_count} words): "{research_question}"
- Sharpened ({sharpened_word_count} words): "{sharpened_question}"
```

**Report Completion (fallback case):**

```text
Phase 10.25: Sharpening skipped — original question used unchanged
- Reason: {reason: exceeded 20 words / lost intent / empty question}
```

**Self-Verification Before Completion:**

1. Did you read `research_question` from sprint-log.json? YES / NO
2. Did you apply sharpening rules (max 20 words, dual structure)? YES / NO
3. Did you verify word count before persisting? YES / NO
4. Did you persist both `sharpened_research_question` and `original_research_question`? YES / NO

**Update TodoWrite:** Phase 10.25 -> completed, Phase 10.5 -> in_progress

**Mark Step 10.25.4 complete** before proceeding to Phase 10.5.

---

## TodoWrite Template (for orchestrator)

When initializing Phase 10.25 todos:

```markdown
- Phase 10.25: Research question sharpening [in_progress]
  - Step 1: Read original question [in_progress]
  - Step 2: Sharpen question [pending]
  - Step 3: Persist to sprint-log [pending]
  - Step 4: Report completion [pending]
```

**Fallback variant (empty question):**

```markdown
- Phase 10.25: Research question sharpening [completed] (skipped: empty research_question)
```

---

## Error Handling

| Failure | Recovery |
|---------|----------|
| research_question empty in sprint-log | WARNING only - skip phase, proceed to Phase 10.5 |
| Sharpened question exceeds 20 words | Use original question unchanged |
| Sharpened question loses core intent | Use original question unchanged |
| jq persistence fails | WARNING only - proceed without sharpened question |
| sprint-log.json missing | HALT - prerequisite failure |

All failures in Phase 10.25 are **non-blocking** (WARNING-only). The sharpened question is an enhancement — all downstream consumers fall back to `research_question` via `// ""` guards.

---

**End of Phase 10.25 Workflow**
