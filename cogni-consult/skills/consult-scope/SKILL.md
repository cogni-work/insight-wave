---
name: consult-scope
description: |
  This skill should be used when the user wants to scope a cogni-consult engagement —
  framing the SMART key question, working the five scoping dimensions, and deriving
  the 3-6 action fields that become the engagement's work-breakdown structure.
  Trigger on: "scope the engagement", "consult scope", "frame the key question",
  "define action fields", "run scoping for the consult engagement", or when
  consult-setup hands off a freshly scaffolded engagement for scoping. Route Double
  Diamond phrasing ("0-scope phase", "diamond scoping") to
  cogni-consulting:consulting-scope instead.
allowed-tools: Read, Write, Edit, Bash, Skill
---

# Engagement Scoping

Produce the keystone deliverable of a cogni-consult engagement: one SMART key question, five scoping dimensions, and 3-6 action fields declared as the work-breakdown structure every later skill works inside. The method itself — SMART table, dimension prompts, output template, quality signals — lives in `$CLAUDE_PLUGIN_ROOT/references/methods/scope-dimensions.md`; this skill owns the conversation flow and the state writes.

## Workflow

### 1. Prerequisite Gate

When arriving via an in-session `consult-setup` handoff, the engagement directory is already known — skip discovery. Otherwise locate the engagement:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/discover-projects.sh --json
```

and confirm the intended engagement with the user when more than one is registered. When discovery returns zero engagements, treat it the same as a missing `consult-project.json` — redirect to `consult-setup` as below.

Read `<engagement-dir>/consult-project.json`. If it is missing, redirect: "There's no engagement yet — let's run `consult-setup` first to scaffold one." Then dispatch `Skill("cogni-consult:consult-setup")` and stop — write nothing. The same Read supplies everything this skill needs (name, language, `workflow_state.scope`) and anchors the later `Edit` calls.

When `workflow_state.scope` is already `complete`, this is a re-scope (pivot): confirm with the consultant before proceeding, and follow the re-run guard in step 4.

### 2. Open the Scoping Conversation

Read `$CLAUDE_PLUGIN_ROOT/references/methods/scope-dimensions.md`, then set `workflow_state.scope` to `"in-progress"` and `updated` to today's ISO date in one `Edit` — never rewrite `consult-project.json` (the `created` timestamp and `plugin_refs` set by setup must survive; `updated` covers scope edits per the data model, so an interrupted session still shows fresh modification).

When `language` is set, hold the conversation in that language; technical terms, slugs, and file names stay English.

### 3. Key Question, Then the Five Dimensions

Draft the key question collaboratively with the consultant following the method reference's SMART procedure, and `Edit` the converged question into `consult-project.json` `key_question`.

Then walk the five dimensions (Strategic Context, Scope, Stakeholder, Constraints/Barriers, Success factors) as a guided conversation per the method reference, capturing concise structured notes per dimension.

When a dimension needs evidence the consultant cannot supply from their own knowledge (market sizing for Strategic Context, regulatory constraints, competitor moves), route the research per `$CLAUDE_PLUGIN_ROOT/references/research-routing.md` — through the engagement's bound knowledge base, never raw web search. Scoping-stage syntheses land in `scope/research/<topic-slug>.md` per that rule's storage contract.

### 4. Derive the Action Fields (WBS Close)

Close by naming 3-6 action fields per the method reference — each with a kebab-case slug, a title, and a one-line framing. Confirm the set with the consultant, then persist it in two writes:

1. One `Edit` of `consult-project.json`: set `action_fields` to the complete ordered list of **slug strings** (e.g. `["market-evidence", "portfolio-fit", "go-to-market"]`). The root never holds field objects — `engagement-status.sh` rejects non-string entries as a malformed project file.
2. One `Write` per field of the stub `action-fields/<field-slug>/field.json` (the `Write` scaffolds the directory; schema owner is `$CLAUDE_PLUGIN_ROOT/references/data-model.md`):

```json
{
  "slug": "<field-slug>",
  "title": "<Field Title>",
  "framing": "<one-line intent>",
  "deliverables": []
}
```

**Re-run guard**: on a re-scope, never overwrite an existing `field.json` — it is the single source of truth for that field's deliverable states. For a field that survives the pivot, leave its file untouched; only add stubs for genuinely new fields. When a field is dropped from `action_fields[]`, leave its directory in place and note the removal in the conversation summary — deleting deliverable history is the consultant's call, not the skill's.

### 5. Write the Scope Deliverable

`Write` `scope/key-question.md` following the Output Convention template in the method reference.

### 6. Close the Scope

`Edit` `consult-project.json`: set `workflow_state.scope` to `"complete"` and `updated` to today's ISO date. Summarize what now exists — the key question, one line per dimension, and the action-field WBS. Then recommend planning the first action field's deliverables as the next step and dispatch `Skill("cogni-consult:consult-action-fields")` to plan each field's deliverable set and pick the next deliverable.

## Important Notes

- **State ownership**: `consult-project.json` holds only the `scope` workflow state and the action-field slug list; everything per-field lives in that field's `field.json`. See `$CLAUDE_PLUGIN_ROOT/references/data-model.md`.
- **One deliverable file**: scoping produces a single `scope/key-question.md` — key question, dimensions, and action-field list are one guided conversation and one artifact, not three files.
- **Edit, never rewrite**: all `consult-project.json` changes go through `Edit` so setup-owned fields (`created`, `plugin_refs`, `language`) survive.
- **Research routing**: any scoping research runs through the engagement's bound knowledge base per `$CLAUDE_PLUGIN_ROOT/references/research-routing.md` — the canonical rule shared by every cogni-consult skill.
