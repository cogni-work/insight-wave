---
name: consulting-resume
description: |
  Resume, continue, or check status of a Double Diamond consulting engagement. This is the
  primary re-entry point for returning to engagement work across sessions.
  Use whenever the user returns to an existing engagement — even if they don't say "resume".
  Trigger on: "continue the engagement", "resume diamond", "pick up where I left off",
  "what's the status", "where was I", "how far along", "show progress", "diamond status",
  "what's next", "continue working on [client name]", "back to the [project name]",
  "let's keep going on [topic]", "open the [client] engagement", "check on [engagement]",
  "engagement status", any mention of a known engagement slug or client name in the context
  of continuing work, or ANY session start that references an existing diamond project.
  This skill should be the default when the user mentions an existing client/engagement name
  without specifying a particular phase — it orients first, then routes to the right phase skill.
---

# Diamond Resume

Session entry point for returning to engagement work. This skill orients the consultant by showing where they left off and what to do next — the dashboard view that keeps multi-session engagements on track.

## Core Concept

Diamond engagements span multiple sessions and phases. Without a clear re-entry point, consultants lose context between sessions and waste time reconstructing what happened. This skill bridges that gap: it reads the engagement state, surfaces progress at a glance, and recommends the most valuable next step. The goal is to get the consultant back into productive flow within seconds.

## Workflow

### 1. Find Diamond Engagements

Scan the workspace for diamond engagements:

```bash
find . -maxdepth 3 -name "consulting-project.json" -path "*/cogni-consulting/*"
```

Each match represents an engagement (extract the slug from the directory name). If no engagements are found, say so and suggest the `consulting-setup` skill.

### 2. Select Engagement

- **One engagement found** — use it automatically.
- **Multiple engagements** — present them with client name and vision class, ask which one to continue.
- **Client-name matching**: When the user says "continue working on Telekom", match against the `client` field in consulting-project.json across all engagements. Fuzzy matching is fine — "Telekom", "Deutsche Telekom", "DT" should all match if the engagement client contains "Telekom".

### 3. Run Engagement Status

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/engagement-status.sh "<project-dir>"
```

The script returns JSON with engagement details, phase state, plugin status, methods used, decisions, and recommended next actions.

### 4. Present Status Dashboard

The consultant should feel like picking up a well-organized notebook, not reading a database report. Lead with the engagement name and client, then the phase progress:

**Acme Cloud Portfolio Expansion** (acme-cloud-expansion)
Client: Acme Cloud Services | Vision: strategic-options | Language: en

| Phase | Status | Files | Plugin Projects |
|-------|--------|-------|-----------------|
| Discover | complete | 12 | research: acme-landscape, tips: b2b-ict/acme, portfolio: acme-cloud |
| Define | in-progress | 3 | claims: verified 8/12 assumptions |
| Develop | pending | 0 | — |
| Deliver | pending | 0 | — |

After the table:

- **Current phase** — translate the phase and status into plain language (e.g., "You're in the middle of Define — 8 of 12 assumptions verified, clustering and HMW still ahead.")
- **Methods used** — list methods applied so far from the method log
- **Key decisions** — surface recent decisions from the decision log
- **Plugin projects** — for each non-null plugin_ref, check if the project exists and show brief status
- **Gaps** — note incomplete prerequisites for the next phase

### 5. Recommend Next Action

Present the recommended next action from the status output:

> **Recommended next step**: Continue the Define phase — 4 assumptions still unverified. Run `consulting-define` to complete assumption verification and synthesize the problem statement.

Offer to proceed with the recommendation immediately.

If all phases are complete, congratulate the consultant and suggest `consulting-export` for the final deliverable package.

## Example

**Returning to an innovation-portfolio engagement after 3 days:**

> **NovaTech Innovation Portfolio** (novatech-innovation)
> Client: NovaTech Solutions | Vision: innovation-portfolio | Language: de
>
> | Phase | Status | Files | Plugin Projects |
> |-------|--------|-------|-----------------|
> | Discover | complete | 9 | research: novatech-landscape, tips: deep-tech/novatech |
> | Define | complete | 5 | claims: verified 14/17 assumptions |
> | Develop | in-progress | 4 | tips: value model in progress |
> | Deliver | pending | 0 | — |
>
> You left off in the Develop phase — value modeling is underway with 12 TIPS paths generated. Scenario planning hasn't started yet.
>
> **Methods used**: desk research, trend scan (deep), stakeholder mapping, assumption verification, affinity clustering, HMW synthesis, value modeling (in progress)
>
> **Last decision**: Focused HMW questions on Horizon 2 opportunities after discovery showed Horizon 1 is well-covered.
>
> **Recommended next step**: Continue `consulting-develop` to finish value modeling and run scenario planning.

## Multi-Session Design

Diamond engagements naturally span multiple sessions. Each phase involves significant work — desk research, trend analysis, stakeholder synthesis, option modeling — that benefits from focused sessions. This skill is the recommended re-entry point after breaks.

When presenting the status summary, acknowledge what the consultant accomplished in previous sessions if timestamps suggest recent productive work. This continuity helps consultants feel their work persists across sessions.

## Language

- **Communication Language**: Read `consulting-project.json` for the `language` field. If present, communicate in that language (status messages, instructions, recommendations). Technical terms, skill names, and CLI commands remain in English.
