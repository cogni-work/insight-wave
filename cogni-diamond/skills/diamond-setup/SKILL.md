---
name: diamond-setup
description: |
  Initialize a new Double Diamond consulting engagement with vision framing and project scaffolding.
  Use whenever the user wants to start any structured consulting or strategy project — even if they
  don't mention "diamond" at all. Trigger on: "new engagement", "start a project for [client]",
  "I have a new client", "kick off a strategy engagement", "set up a consulting project",
  "let's work on [client topic]", "I need to frame a problem", "new diamond project",
  "vision framing", "double diamond", "set up the engagement", "begin a new analysis",
  "scope a new piece of work", "new consulting project", or any mention of starting structured
  problem-to-solution work for a client. Also trigger when the user describes a client situation
  that implies a new engagement is needed (e.g., "Telekom wants us to look at their cloud strategy").
---

# Diamond Engagement Setup

Initialize a cogni-diamond engagement by framing the desired outcome and creating the project structure. This is the entry point for every Double Diamond engagement — getting the vision right here determines which methods, plugins, and deliverables the downstream phases will use.

## Core Concept

A diamond engagement is a structured consulting process that moves from problem understanding (Diamond 1: Discover → Define) to solution design (Diamond 2: Develop → Deliver). Setup captures the engagement vision — what outcome the client needs — and scaffolds everything downstream skills depend on.

The vision class drives the entire engagement: it determines which methods are proposed in each phase, which plugins are dispatched, and which deliverables appear in the final package. A few minutes of clarity here prevents weeks of misdirected effort.

If an engagement already exists for this client/topic, redirect to the `diamond-resume` skill instead of creating a duplicate.

## Workflow

### 1. Gather Engagement Context

Collect these fields:

- **Engagement name**: Descriptive name (e.g., "Acme Cloud Portfolio Expansion")
- **Client**: Company or organization name
- **Vision class**: The type of outcome needed. Present the options from `$CLAUDE_PLUGIN_ROOT/references/vision-class-summary.md`.
- **Desired outcome**: One-sentence description of what success looks like
- **Scope**: Market, geography, product line, or segment boundaries
- **Constraints**: Timeline, budget, exclusions, or non-negotiables
- **Industry**: Primary industry sector (used for cogni-tips trend scouting)

If the user has provided some context already, extract what is available and ask only for missing fields.

**Language detection**: Check if a `.workspace-config.json` exists in the workspace root. If it contains a `language` field, use it. Otherwise ask the user (default: `"en"`).

### 2. Review with User

Present the gathered context as a summary for confirmation:

| Field | Value |
|---|---|
| Engagement | Acme Cloud Portfolio Expansion |
| Client | Acme Cloud Services |
| Vision class | `strategic-options` |
| Desired outcome | Identify 3-5 strategic investment options for cloud portfolio |
| Scope | DACH market, mid-market segment |
| Constraints | 6-week timeline, no M&A options |
| Industry | Cloud Infrastructure |
| Proposed slug | `acme-cloud-expansion` |
| Language | `en` |

The slug is derived from the engagement name in kebab-case — keep it short and recognizable.

Ask explicitly:
- Does this look right?
- Anything to add or correct?
- Happy with the engagement slug?

Iterate until the user confirms.

### 3. Create Engagement Structure

Run the init script:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/engagement-init.sh "<workspace-dir>" "<engagement-slug>"
```

If the script returns `"status": "exists"`, inform the user and suggest `diamond-resume` instead.

### 4. Write diamond-project.json

After the script creates directories, write `diamond-project.json` in the engagement root:

```json
{
  "engagement": {
    "name": "<engagement name>",
    "slug": "<slug>",
    "client": "<client>",
    "vision_class": "<selected class>",
    "industry": "<industry>",
    "language": "<language>",
    "created": "<ISO date>",
    "updated": "<ISO date>"
  },
  "vision": {
    "desired_outcome": "<one-sentence outcome>",
    "scope": "<scope description>",
    "constraints": ["<constraint 1>", "<constraint 2>"],
    "deliverables": []
  },
  "phase_state": {
    "current": "discover",
    "discover": { "status": "pending", "started": null, "completed": null },
    "define": { "status": "pending", "started": null, "completed": null },
    "develop": { "status": "pending", "started": null, "completed": null },
    "deliver": { "status": "pending", "started": null, "completed": null }
  },
  "plugin_refs": {
    "research_project": null,
    "tips_project": null,
    "portfolio_project": null
  },
  "methods_used": [],
  "decisions": []
}
```

### 5. Map Vision to Deliverables

Read `$CLAUDE_PLUGIN_ROOT/references/deliverable-map.md` and look up the deliverables for the selected vision class. Present the recommended deliverable package:

> Based on the **strategic-options** vision class, your engagement will produce:
> - Strategic Options Brief (PPTX/DOCX)
> - Decision Board (Excalidraw)
> - Executive Summary (PPTX/PDF)
> - Action Roadmap (PPTX/XLSX)
> - Claim Verification Log (MD)
>
> Want to add or remove any deliverables?

Update `vision.deliverables` in diamond-project.json with confirmed list.

### 6. Preview Phase Plan

Read `$CLAUDE_PLUGIN_ROOT/references/vision-classes.md` for the selected vision class and present the recommended method sequence:

> **Your Diamond engagement plan:**
>
> **Discover** (diverge) — Build understanding of the problem landscape
> - Desk research via cogni-gpt-researcher
> - Industry trend scan via cogni-tips
> - Competitive baseline via cogni-portfolio
>
> **Define** (converge) — Frame the core challenge
> - Assumption verification via cogni-claims
> - Affinity clustering + HMW synthesis (guided)
>
> **Develop** (diverge) — Generate and explore options
> - Value modeling via cogni-tips
> - Proposition framing via cogni-portfolio
> - Scenario planning (guided)
>
> **Deliver** (converge) — Validate and package outcomes
> - Final claims verification
> - Business case modeling (guided)
> - Deliverable generation via diamond-export
>
> This is a starting framework — methods adapt as understanding deepens. Ready to begin Discover?

### 7. Transition to Discover (Optional)

If the user seems eager to dive in, transition directly to the `diamond-discover` skill. If they seem uncertain, end with a clear next-step pointer — they can start any time with `diamond-discover` or check status with `diamond-resume`. Read the room rather than always asking.

## Example

A consultant says: "I need to build a business case for migrating our telco client's BSS stack to a cloud-native platform. Budget is around €2M, they want a decision by end of Q2."

Setup would extract:
- **Engagement**: "CloudCo BSS Cloud Migration"
- **Client**: CloudCo (or whatever the client name is)
- **Vision class**: `business-case`
- **Desired outcome**: Investment justification for BSS-to-cloud migration
- **Scope**: BSS stack, cloud-native target architecture
- **Constraints**: ~€2M budget, Q2 deadline
- **Industry**: Telecommunications

Then confirm, scaffold, map to deliverables (Business Case XLSX+DOCX, Executive Summary PPTX, Action Roadmap, Claim Verification Log), and preview the phase plan.

## Important Notes

- Engagements are isolated in separate directories (`cogni-diamond/<slug>/`) so multiple client projects can coexist without file conflicts
- If an engagement already exists, the init script returns without overwriting — no risk of data loss
- Downstream skills use the `updated` timestamp to detect stale engagements, so keep it current when state changes
- **Communication Language**: If `language` is set in diamond-project.json, communicate in that language. Technical terms, skill names, and CLI commands remain in English.
