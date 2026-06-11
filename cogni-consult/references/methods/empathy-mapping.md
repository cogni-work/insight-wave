---
name: Empathy Mapping
stage: empathize
type: divergent
inputs: [personas, deliverable-framing, knowledge-base-synthesis]
outputs: [enriched-personas]
duration_estimate: "15-30 min per persona"
---

# Empathy Mapping

Build a rich understanding of each persona by mapping what they think, feel, say, and do. This method bridges the gap between knowing *about* someone and understanding *what it's like to be them* — which is the difference between deliverables that look good on slides and deliverables stakeholders actually adopt. In cogni-consult it runs at the **empathize stage** of a deliverable's design-thinking loop, scoped to the personas that matter for *this* deliverable.

## When to Use

- At the empathize stage of any deliverable whose adoption depends on people — before sharpening the spec, understand who it must serve
- When personas exist in `personas/` (even as hypotheses) and the engagement's knowledge base or prior deliverables have produced evidence to ground them
- Skip when the deliverable is purely mechanical (e.g. a data extract) and no persona's reality changes the outcome — note the skip in the deliverable's define-stage spec

## Guided Prompt Sequence

### Step 1: Select a Persona

Present the available personas from `personas/`. For each, show: name, role, context, core tension, current maturity level.

Ask: "Which persona should we map first for this deliverable? I'd recommend the one whose reality most shapes whether it lands."

### Step 2: Map Each Quadrant

For each quadrant, draw from evidence first (knowledge-base synthesis, prior deliverables in this or other action fields), then supplement with consultant knowledge. The distinction matters — evidence-based entries carry more weight than assumptions, and gaps reveal where understanding is thin.

**Thinks** — What occupies their mind? What worries them? What do they believe about the situation?
- Prompt: "When this person thinks about [the deliverable's topic], what goes through their mind? What are they worried about? What assumptions do they carry?"

**Feels** — What emotions drive their behavior? What frustrates, excites, or frightens them?
- Prompt: "How does this person feel about the current situation? About the prospect of change? What past experiences color their feelings?"

**Says** — What do they actually say out loud? What language do they use?
- Prompt: "If you overheard this person talking to a colleague about [the deliverable's topic], what would they say? Use their actual words, not a polished version."

**Does** — What behaviors can you observe? What workarounds have they created?
- Prompt: "What does this person actually do day-to-day that relates to this deliverable? What workarounds have they invented? What do they avoid?"

### Step 3: Surface Gaps and Contradictions

After mapping all four quadrants, look for:

- **Gaps**: Quadrants with thin or no evidence — these are where understanding is weakest and assumptions are most dangerous. Flag them explicitly; they are candidates for a knowledge-base research pass.
- **Say-Do contradictions**: What people say often differs from what they do. These contradictions are rich design inputs — a person who says "I want data-driven decisions" but relies on gut feeling is telling you something important about trust and tools.
- **Think-Feel tensions**: Internal conflicts (e.g., "thinks the change is necessary" but "feels anxious about losing control") predict adoption barriers that rational arguments won't resolve.

### Step 4: Extract Needs

From the empathy map, distill 2-5 need statements. Good needs:

- Are framed from the persona's perspective, not the organization's
- Describe the desired state, not the solution: "Needs to trust the data before making decisions" not "Needs a dashboard"
- Connect to the core tension: each need should relate to what makes the current situation unsatisfying

### Step 5: Update the Persona

Write the enriched data back to `personas/{slug}.json` via `Edit`:
- Populate `empathy_map` with the four quadrants
- Add extracted needs to `needs`
- Promote `maturity` to `"researched"` if substantive evidence was added (at least 2 quadrants have evidence-based entries)
- Append to `work_log`: `{"action_field": "<field-slug>", "deliverable": "<deliverable-slug>", "action": "empathy-mapped", "date": "<ISO date>"}`

### Step 6: Repeat for Additional Personas

If 2-4 personas matter for this deliverable, map each one. Between personas, note where their empathy maps overlap or conflict — a tension between two personas' needs is often the most important design constraint, and feeds the define-stage spec directly.

## Output

The primary output is the enriched persona files in `personas/`. No separate artifact is needed — the empathy map lives inside the persona entity, and the key insights flow into the deliverable's define-stage spec.

Optionally, present a summary to the consultant:

> **Empathy mapping complete for [N] personas.**
> - [Persona 1]: [one-line summary of key insight]
> - [Persona 2]: [one-line summary]
> - Key tension between personas: [if applicable]
> - Gaps: [quadrants where evidence is thin]

## Tips

- Real quotes are gold — if the consultant has heard the persona say something, capture the exact words
- Emotions are harder to surface than facts — give the consultant time to reflect rather than rushing to the next quadrant
- Resist the urge to make the empathy map "nice" — contradictions, frustrations, and irrational behaviors are the most valuable inputs for design
- If the consultant has no evidence for a quadrant, mark it as assumed rather than fabricating entries
