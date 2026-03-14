# Phase 0.5: Arc Detection & Configuration

**Objective:** Detect and persist synthesis arc for downstream hub routing.

**When to Run:** Before Phase 8 (first phase of deeper-research-3)

**Output:** `arc_id` and `arc_display_name` persisted to `.metadata/sprint-log.json`

---

## Arc Registry (Inline Reference)

5 story arcs optimized for different research purposes:

| arc_id | Display Name | Elements | Best For | Context Tier |
|--------|-------------|----------|----------|--------------|
| `corporate-visions` | Corporate Visions | Why Change → Why Now → Why You → Why Pay | B2B acquisition pitches, market opportunity framing | Tier 2 |
| `technology-futures` | Technology Futures | What's Emerging → Converging → Possible → Required | Technology scouting, innovation roadmaps | Tier 4 |
| `competitive-intelligence` | Competitive Intelligence | Landscape → Shifts → Positioning → Implications | Market analysis, strategic positioning | Tier 1 |
| `strategic-foresight` | Strategic Foresight | Signals → Scenarios → Strategies → Decisions | Future planning, scenario development | Tier 3 |
| `industry-transformation` | Industry Transformation | Forces → Friction → Evolution → Leadership | Industry disruption analysis, transformation strategy | Tier 3 |

**Arc Context Tiers** (entity loading requirements for synthesis-hub):

- **Tier 1:** Findings + Sources (~5.6K tokens)
- **Tier 2:** + Trends (Act horizon) (~8.2K tokens)
- **Tier 3:** + Trends (all horizons) + Megatrends (~16.6K tokens)
- **Tier 4:** + Trends (Watch+Act) + Concepts (~13.6K tokens)

---

## Step 0.5.1: Read Research Type

Read `research_type` from sprint-log.json to inform arc auto-detection:

```bash
echo "=== PHASE 0.5: ARC DETECTION & CONFIGURATION ==="

# Read research_type from sprint-log
research_type=$(jq -r '.research_type // "generic"' "${project_path}/.metadata/sprint-log.json")

echo "Research Type: ${research_type}"
```

**Mark Step 0.5.1 complete** before proceeding to Step 0.5.2.

---

## Step 0.5.2: Auto-Detect Arc

Map research_type to recommended arc using predefined mappings:

```bash
echo "Auto-detecting synthesis arc..."

# Arc mapping logic
case "${research_type}" in
  "technology")
    detected_arc_id="technology-futures"
    detected_arc_display="Technology Futures"
    ;;
  "competitive")
    detected_arc_id="competitive-intelligence"
    detected_arc_display="Competitive Intelligence"
    ;;
  "foresight"|"scenarios")
    detected_arc_id="strategic-foresight"
    detected_arc_display="Strategic Foresight"
    ;;
  "industry"|"transformation")
    detected_arc_id="industry-transformation"
    detected_arc_display="Industry Transformation"
    ;;
  "market"|"generic"|*)
    detected_arc_id="corporate-visions"
    detected_arc_display="Corporate Visions"
    ;;
esac

echo "Detected Arc: ${detected_arc_display} (${detected_arc_id})"
```

**Arc Mapping Table:**

| research_type | Detected arc_id | Rationale |
|---------------|-----------------|-----------|
| `technology` | `technology-futures` | Technology research benefits from emerging/converging/possible framework |
| `competitive` | `competitive-intelligence` | Competitive research needs landscape/shifts/positioning structure |
| `foresight`, `scenarios` | `strategic-foresight` | Scenario planning aligns with signals/scenarios/strategies/decisions |
| `industry`, `transformation` | `industry-transformation` | Industry analysis needs forces/friction/evolution framework |
| `market`, `generic`, (default) | `corporate-visions` | Default acquisition pitch framework (Why Change → Why Pay) |

**Mark Step 0.5.2 complete** before proceeding to Step 0.5.3.

---

## Step 0.5.3: Interactive Arc Confirmation

Present detected arc to user with AskUserQuestion for confirmation or selection:

```markdown
USE: AskUserQuestion tool

QUESTION:
"Detected synthesis arc: **{detected_arc_display}** ({element1} → {element2} → {element3} → {element4}). This framework shapes how the research report organizes cross-dimensional insights. Should we use this arc or select a different one?"

HEADER: "Synthesis Arc"

OPTIONS (multiSelect: false):

1. **{detected_arc_display} (Recommended)**
   Description: "{Best use case from arc registry}. Elements: {element1} → {element2} → {element3} → {element4}."

2. **Corporate Visions**
   Description: "B2B acquisition framing (Why Change → Why Now → Why You → Why Pay). Best for market opportunity and value propositions."

3. **Technology Futures**
   Description: "Innovation roadmap framework (What's Emerging → Converging → Possible → Required). Best for technology scouting and R&D."

4. **Competitive Intelligence**
   Description: "Market positioning framework (Landscape → Shifts → Positioning → Implications). Best for competitive analysis."

5. **Strategic Foresight**
   Description: "Scenario planning framework (Signals → Scenarios → Strategies → Decisions). Best for future planning."

6. **Industry Transformation**
   Description: "Disruption analysis framework (Forces → Friction → Evolution → Leadership). Best for transformation strategy."

[Note: Option 1 is the detected arc marked as "(Recommended)"]
```

**User Response Handling:**

```bash
# Parse user selection
selected_option=$(echo "$user_response" | jq -r '.answers.arc_selection')

# Map selection to arc_id
case "${selected_option}" in
  *"Corporate Visions"*)
    arc_id="corporate-visions"
    arc_display_name="Corporate Visions"
    ;;
  *"Technology Futures"*)
    arc_id="technology-futures"
    arc_display_name="Technology Futures"
    ;;
  *"Competitive Intelligence"*)
    arc_id="competitive-intelligence"
    arc_display_name="Competitive Intelligence"
    ;;
  *"Strategic Foresight"*)
    arc_id="strategic-foresight"
    arc_display_name="Strategic Foresight"
    ;;
  *"Industry Transformation"*)
    arc_id="industry-transformation"
    arc_display_name="Industry Transformation"
    ;;
  *)
    # Default: use detected arc
    arc_id="${detected_arc_id}"
    arc_display_name="${detected_arc_display}"
    ;;
esac

echo "Selected Arc: ${arc_display_name} (${arc_id})"
```

**Mark Step 0.5.3 complete** before proceeding to Step 0.5.4.

---

## Step 0.5.4: Persist Arc to Metadata

Write `arc_id` and `arc_display_name` to sprint-log.json:

```bash
echo "Persisting arc selection to metadata..."

# Update sprint-log.json with jq
jq --arg arc_id "${arc_id}" --arg arc_display "${arc_display_name}" \
  '.arc_id = $arc_id | .arc_display_name = $arc_display' \
  "${project_path}/.metadata/sprint-log.json" > "${project_path}/.metadata/sprint-log.json.tmp"

# Replace original file
mv "${project_path}/.metadata/sprint-log.json.tmp" "${project_path}/.metadata/sprint-log.json"

echo "Arc persisted: arc_id=${arc_id}, arc_display_name=${arc_display_name}"
```

**Validation:**

```bash
# Verify persistence
persisted_arc_id=$(jq -r '.arc_id // ""' "${project_path}/.metadata/sprint-log.json")
persisted_arc_display=$(jq -r '.arc_display_name // ""' "${project_path}/.metadata/sprint-log.json")

if [ "${persisted_arc_id}" = "${arc_id}" ] && [ "${persisted_arc_display}" = "${arc_display_name}" ]; then
  echo "✅ Arc persistence verified"
else
  echo "❌ ERROR: Arc persistence failed"
  exit 1
fi
```

**Mark Step 0.5.4 complete** before proceeding to Phase 8.

---

## Phase 0.5 Completion Checklist

Before proceeding to Phase 8, verify:

- [ ] research_type read from sprint-log.json
- [ ] Arc auto-detected using mapping table
- [ ] User confirmed or selected arc via AskUserQuestion
- [ ] arc_id and arc_display_name persisted to sprint-log.json
- [ ] Persistence validated (read-back check passed)
- [ ] All Step 0.5.x todos marked completed

**Output:**

```json
{
  "arc_id": "corporate-visions",
  "arc_display_name": "Corporate Visions",
  "persisted_to": ".metadata/sprint-log.json",
  "next_phase": "Phase 8: Parallel Trend Generation"
}
```

---

## TodoWrite Template (for orchestrator)

When initializing Phase 0.5 todos:

```markdown
- Phase 0.5: Arc detection [in_progress]
  - Step 0.5.1: Read research_type [in_progress]
  - Step 0.5.2: Auto-detect arc [pending]
  - Step 0.5.3: User confirmation [pending]
  - Step 0.5.4: Persist to metadata [pending]
```

**Progressive updates:**
- Mark each step completed as you finish it
- Mark Phase 0.5 completed before starting Phase 8
- Add Phase 8 todos once Phase 0.5 complete

---

## Error Handling

| Failure | Recovery |
|---------|----------|
| sprint-log.json missing | HALT - deeper-research-0/1/2 prerequisite |
| research_type missing | Default to "generic" → corporate-visions |
| User cancels arc selection | Use detected arc (no user input treated as acceptance) |
| jq persistence fails | HALT - filesystem write issue |
| Persistence validation fails | HALT - data integrity issue |

---

## Integration with Synthesis-Hub

**Downstream consumption (synthesis-hub Phase 3 Step 0.95):**

synthesis-hub reads arc_id to determine entity loading tier:

```bash
# In synthesis-hub/references/phase-workflows/phase-3-loading.md Step 0.95
arc_id=$(jq -r '.arc_id // ""' "${PROJECT_PATH}/.metadata/sprint-log.json")

if [ -z "${arc_id}" ]; then
  echo "No arc specified - skipping arc-aware loading"
else
  echo "Arc detected: ${arc_id}"
  # Proceed with arc-tier entity loading...
fi
```

**Downstream routing (deeper-research-3 Phase 10.5):**

deeper-research-3 delegates arc-specific narrative to cogni-narrative plugin after Phase 10 (synthesis-hub) completes:

```bash
# In deeper-research-3 Phase 10.5
arc_id=$(jq -r '.arc_id // ""' "${project_path}/.metadata/sprint-log.json")

if [ -n "${arc_id}" ]; then
  echo "Delegating arc-specific narrative to cogni-narrative: ${arc_id}"
  # DELEGATE via Task tool:
  # Task(
  #   subagent_type="cogni-narrative:narrative-writer",
  #   prompt="source_path: ${project_path}/12-synthesis/
  #           arc_id: ${arc_id}
  #           language: ${project_language}
  #           output_path: ${project_path}/insight-summary.md"
  # )
  # Non-blocking: if success=false, log warning and continue to Phase 12
fi
```

**Note:** This delegation was moved from synthesis-hub Phase 4b to deeper-research-3 Phase 10.5 to avoid 3-level agent nesting and keep narrative delegation at the orchestrator level.

---

**End of Phase 0.5 Workflow**
