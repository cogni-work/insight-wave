---
name: consult-resume
description: |
  This skill should be used when the user wants to resume, continue, or check
  the status of a cogni-consult engagement across sessions. Trigger on:
  "continue the engagement", "resume the engagement", "engagement status",
  "where was I with the engagement", "what's next for the engagement", "show
  engagement progress", "consult resume", or ANY session start that references
  an existing cogni-consult engagement — even if the user doesn't say "resume"
  explicitly. Double Diamond phrasing ("resume diamond", "diamond status",
  phase talk like "continue discover") refers to a legacy engagement model no
  longer in the ecosystem; cogni-consult engagements have no
  phases; progress lives in the action-fields WBS.
allowed-tools: Read, Bash, Skill
---

# Engagement Re-entry

Re-enter a cogni-consult engagement: discover what exists, show progress
against the action-fields WBS (fields × deliverables × status), and route to
the most valuable next action. This skill is a read-only orienter — it never
edits engagement state; every write belongs to the skill it routes to.

## Workflow

### 1. Discover Engagements

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/discover-projects.sh --json
```

When discovery returns **zero engagements**, there is nothing to resume here.
If the user was working a phase-based (Double Diamond) engagement, that engagement
model is no longer part of the ecosystem — those engagements live in git history.
Otherwise recommend scaffolding
an engagement and dispatch `Skill("cogni-consult:consult-setup")`, then stop —
setup owns scaffolding and the knowledge-base binding.

### 2. Select the Engagement

- **One engagement** → select it silently.
- **Multiple** → list them (name, slug, `scope_state`, scope config
  `updated`) and ask
  which to resume — unless the user already named one; then fuzzy-match on
  name or slug and confirm only when the match is ambiguous.

When `language` is set on the selected engagement, hold the conversation in
that language; technical terms, slugs, and file names stay English.

### 3. Read the Engagement Status

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/engagement-status.sh <engagement-path>
```

`<engagement-path>` is the `path` field from discovery. The script derives
the rollups at read time: `scope_state`, and per field its `state` plus each
deliverable's `state`, `dt_stage`, `producing_route`, and `persona_review`.
Surface any `warnings[]` verbatim (an `unreadable` field manifest is a
problem for the consultant to see, not to paper over).

### 4. Present the Dashboard

Lead with the key question, then one table row per action field:

```
Engagement: <name> (<slug>) — scope config updated <date>
Key question: <key_question>

| Action Field | Status | Deliverables | Next Deliverable |
|--------------|--------|--------------|------------------|
| market-evidence | complete | 2/2 complete | — |
| portfolio-fit | in-progress | 1/3 complete | competitor-map (ideate) |
| go-to-market | pending | 0/2 started | channel-strategy (empathize) |
```

`Deliverables` counts `complete` over total; `Next Deliverable` names the
first non-complete deliverable with its `dt_stage` in parentheses, or the
first whose `persona_review` is still open when everything else is done.
Keep it to this one table — the deep WBS view (planning deliverable sets,
splitting fields) belongs to `consult-action-fields`, not here.

### 5. Recommend the Next Action

Branch on the derived state, first match wins, and say *why*:

- **`scope_state` is not `complete`** → the WBS doesn't exist yet; recommend
  `consult-scope` ("scope not done — let's frame the key question and derive
  the action fields").
- **A field's `state` is `unreadable`** → its manifest is broken, not
  unplanned; the surfaced warning *is* the recommendation — fix or inspect
  that `field.json` before any routing.
- **A field has an empty `deliverables[]`** (and is not `unreadable`) → the
  WBS has an unplanned container; recommend `consult-action-fields` to plan
  that field's deliverable set.
- **A deliverable is `in-progress`** → resume it where it stands; recommend
  `consult-design-thinking` naming the field, the deliverable, and its
  `dt_stage` ("competitor-map is mid-ideate — pick the loop back up there").
- **A deliverable is `complete` but its `persona_review` is `pending` or
  `in-progress`** → the acting-persona challenge hasn't closed; recommend
  `consult-personas` to run (or finish) the challenge pass.
- **A deliverable is `pending`** → start the next one; recommend
  `consult-design-thinking` (or the deliverable's own `producing_route` when
  it names a different skill).
- **Everything is `complete`** → say so — the engagement is complete by
  derivation — and offer `consult-action-fields` to extend the WBS if the
  consultant wants to add fields or deliverables.

Recommend one action, not a menu. On the consultant's confirmation, dispatch
the named skill via `Skill(...)` with the engagement path as the in-session
handoff (the target skills skip rediscovery on handoff).

## Important Notes

- **Read-only**: this skill never writes `consult-project.json`,
  `field.json`, personas, or logs — state writes belong to the routed
  skills. See `$CLAUDE_PLUGIN_ROOT/references/data-model.md` for ownership.
- **Derived, not stored**: field and engagement completion are computed at
  read time by `engagement-status.sh`; never trust a stale summary over a
  fresh script run.
- **One recommendation**: the dashboard orients, the recommendation commits —
  a single next action with its reason beats a list of options.
