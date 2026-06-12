---
name: consulting-scope
description: |
  ARCHIVED PLUGIN — applies only to existing legacy Double Diamond engagements;
  start all new consulting work with the cogni-consult plugin instead.
  Execute the 0-scope phase of a Double Diamond engagement — frame one SMART Key Question and the
  five scoping dimensions (Strategic Context, Scope, Stakeholder, Constraints/Barriers, Success
  factors) before divergent Discover work begins. Use whenever the user wants to scope, frame, or
  anchor a consulting engagement. Trigger on: "scope the engagement", "what's the key question",
  "frame the engagement", "define the scope", "what are we actually solving", "scoping phase",
  "0-scope", "key question", "who are the stakeholders", "what's in and out of scope",
  "how will we measure success", or any request to sharpen an engagement's framing before research
  starts. Also trigger right after consulting-setup completes — scoping is the first phase of
  every engagement.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Skill
---

# Diamond Scope — Anchor the Engagement

Frame the engagement in one SMART Key Question and five scoping dimensions. This is the 0-scope phase — the convergent framing work that today's engagements otherwise do implicitly inside setup or Discover. A sharp scope makes every downstream phase cheaper: Discover researches the action fields, Define tests the question's assumptions, Develop and Deliver converge against the success factors.

## Diamond Coach Protocol

Read `$CLAUDE_PLUGIN_ROOT/references/diamond-coach.md` and adopt the Diamond Coach persona.

**Scope opening**: "We're in 0-Scope — before we diverge into research, we anchor. One question, framed SMART, that the whole engagement answers; five dimensions that bound it. Twenty minutes here saves days later: every research topic, assumption, and option will trace back to what we write now."

**Prerequisite gate**: Verify `consulting-project.json` exists (setup complete). If it is missing, redirect: "There's no engagement yet — let's run `consulting-setup` first to scaffold one." No other prerequisite — 0-scope is the first phase.

**Iteration check**: If `phase_state["0-scope"].status` is `complete`, this is a re-entry. Read the existing `0-scope/key-question.md` and ask what changed — the sponsor, the market context, the scope boundary? Refine the affected dimension rather than re-running the full interview, then mark the phase in-progress via `update-phase.sh` — re-entry increments the iteration counter automatically.

**Task list**: After loading context, create a task list:

1. Load engagement context and vision
2. Draft and stress-test the SMART Key Question
3. Work through the five scoping dimensions
4. Capture action fields
5. Write `0-scope/key-question.md` and close the phase

## Workflow

### 1. Load Context

Mark the phase started:

```bash
bash "$CLAUDE_PLUGIN_ROOT/scripts/update-phase.sh" "<project-dir>" 0-scope in-progress
```

Read `consulting-project.json` — the engagement vision, vision class, client, industry, and language drive the framing. Read `$CLAUDE_PLUGIN_ROOT/references/methods/key-question-scoping.md` for the full method.

### 2. Frame the Key Question

Run the method's SMART convergence protocol (candidate framings, criteria stress-test, converge on one) — the full protocol and criteria table live in `key-question-scoping.md`.

### 3. Work the Five Dimensions

Guide the consultant through the five dimensions conversationally — **Strategic Context**, **Scope**, **Stakeholder**, **Constraints / Barriers**, **Success factors** — capturing concise structured notes per the method file's dimension prompts.

Keep the coach's convergent discipline: this phase narrows. If the conversation starts generating solutions, park them as candidate action fields and return to framing.

### 4. Capture Action Fields

Name the 3–6 main areas of action needed to resolve the central problem — one line each. These seed Discover's research topics.

### 5. Write the Artifact and Close

Write `0-scope/key-question.md` following the method's output convention (key question + SMART check + the five dimensions + action fields). Record the chosen framing (and the rejected candidate framings, with why) in `.metadata/decision-log.json` and the method in `.metadata/method-log.json` — the Deliver phase reads these logs. Then close the phase:

```bash
bash "$CLAUDE_PLUGIN_ROOT/scripts/update-phase.sh" "<project-dir>" 0-scope complete
```

**Accomplishment summary**: Recap the key question verbatim, the sharpest boundary decision (what's out of scope), and the action fields. Then hand forward: "Scope is anchored. Discover comes next — `consulting-discover` will diverge into research along the action fields we just named."

## Lightweight Engagements

For `how-might-we` engagements assessed as lightweight, compress this phase to the Key Question + the Scope and Success-factors dimensions only (one short conversation) — the HMW question often *is* the key question, so test it against SMART and move on.

## Out of Scope

- No plugin dispatch — scoping is guided conversation, not research (Discover owns research)
- Does NOT create the engagement — `consulting-setup` scaffolds; this skill frames
- Does NOT verify claims — assumptions surfaced here are tested in Define via cogni-claims
