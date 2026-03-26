---
name: portfolio-resume
description: |
  Resume, continue, or check status of a portfolio project.
  Use whenever the user mentions "continue portfolio", "resume portfolio",
  "pick up where I left off", "portfolio status", "what's next", "show progress",
  "where was I", "how far along", or opens a session that involves an existing
  cogni-portfolio project — even if they don't say "resume" explicitly.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Portfolio Resume

Session entry point for returning to portfolio work. This skill orients the user by showing where they left off and what to do next — think of it as the dashboard view that keeps multi-session projects on track.

## Core Concept

Portfolio projects span multiple sessions and skills. Without a clear re-entry point, users lose context between sessions and waste time figuring out what they already did. This skill bridges that gap: it reads the project state, surfaces progress at a glance, and recommends the most valuable next step. The goal is to get the user back into productive flow within seconds.

## Workflow

### 1. Find Portfolio Projects

Scan the workspace for portfolio projects:

```bash
find . -maxdepth 3 -name "portfolio.json" -path "*/cogni-portfolio/*"
```

Each match represents a project (extract the slug from the directory name). If no projects are found, say so and suggest the `setup` skill.

### 2. Select Project

- One project found — use it automatically.
- Multiple projects — present them and ask which one to continue.

### 3. Run Project Status with Health Check

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/project-status.sh "<project-dir>" --health-check
```

The script returns JSON with `counts`, `phase`, `next_actions`, `completion`, `claims`, and `stale_entities`. The `--health-check` flag enables staleness detection — it compares upstream `updated` dates (or file mtimes as fallback) against downstream entities and flags propositions/solutions that may need refresh.

### 4. Present Status Summary

Show a concise, scannable dashboard. Lead with the company name and project slug, then the progress table:

| Entity | Count | Status |
|--------|-------|--------|
| Products | N | |
| Features | N | |
| Markets | N | |
| Propositions | N / expected | pct% |
| Solutions | N / propositions | pct% |
| Packages | N / packageable | pct% |
| Competitors | N / propositions | pct% |
| Customers | N / markets | pct% |
| Claims | N total | V verified, D deviated, U unverified |
| Context | N entries | breakdown by category (e.g., 3 pricing, 2 competitive, 1 strategic) |
| Uploads | N | pending ingestion (if > 0) |

If `margin_health` is present in the status output and has `solutions_with_cost_model > 0`, add a margin health line after the table:
- **Margin health** — N solutions with cost models, N tiers below target (target: Y%), N negative-margin tiers. Show margins split by type: project avg margin X%, subscription avg gross margin X%. These are different metrics (effort-based vs. unit economics) so present them separately. Flag negative project margins and subscription LTV/CAC < 3 as urgent.

If `solutions_by_type` is present, show the type breakdown: "N project, N subscription, N partnership".

After the table:
- **Phase** — translate the `phase` value into plain language (see reference below)
- **Quality audit** — if `quality_audit` is present and has flagged entities (`features_flagged` or `propositions_flagged` non-empty), show them grouped by issue type before stale entities. Present actionable summaries, not raw data:
  - Group by dimension: "2 features have descriptions outside 20-35 word target (cloud-monitoring: 48 words, api-gateway: 12 words)"
  - For parity language: "1 feature uses parity language ("innovative", "robust")"
  - For proposition issues: "1 proposition DOES is too long (42 words, target 15-30)"
  - If a flagged feature has downstream propositions, note the cascade risk: fixing the feature description may require refreshing its propositions
  - **Deferred vs new warnings**: If the quality assessment data includes deferred features (features where the user chose to skip a warning), present them separately: "Deferred from previous session: cogni-sales (12 words — you chose to skip this)". New warnings (features created or edited since the last quality check) are presented normally. This distinction prevents surprise — the user should recognize deferred items as conscious decisions, not new problems.
  - End with actionable guidance: "Consider running features or propositions skill to review and fix these before generating downstream content."
  - Offer deep assessment: "For thorough quality assessment including mechanism and customer-relevance checks, ask for a full quality audit."
  - If no entities are flagged, skip this section entirely (don't show "0 flagged")
- **Stale entities** — if `stale_entities` is non-empty, show them as priority actions before the regular next steps. Group by reason type: "N propositions need refresh because their upstream features were updated" is more useful than listing each one. If a stale entity also has quality warnings, lead with the quality issue (fix the root cause first, then refresh the proposition).
- **Context notice** — if `counts.context_entries > 0`, mention available context entries with a category breakdown. Read `context/context-index.json` for the `by_category` map to show counts per category. This helps the user understand what intelligence is available for downstream skills. If context exists but downstream skills haven't been run yet, highlight this: "N context entries from ingested documents are ready — these will automatically inform propositions, solutions, and other skills."
- **Uploads notice** — if `counts.uploads > 0`, always mention pending files regardless of phase
- **Gaps** — if `missing_propositions` is non-empty, list the first few missing pairs; note incomplete solutions/competitors/customers

Keep the tone warm and oriented toward action — this is a welcome-back moment, not a status report. The user should feel oriented, not overwhelmed.

### 5. Recommend Next Action

Present each entry from `next_actions` with the skill name and reason. Offer to proceed with the top recommendation immediately.

If the phase is `complete`, congratulate the user and suggest reviewing outputs or running `export` for additional deliverables.

## Phase Reference

| Phase | Meaning | What to do |
|-------|---------|------------|
| `products` | No products defined yet | Run `products` skill |
| `features` | Products exist, no features | Run `features` skill |
| `markets` | Features defined, no markets | Run `markets` skill |
| `propositions` | Feature x Market pairs need messaging | Run `propositions` skill |
| `enrichment` | Propositions exist, customer/solution/competitor gaps remain | Run `customers`, `solutions`, and/or `compete` |
| `verification` | Unverified or deviated claims pending | Run `verify` skill |
| `synthesis` | All entities complete, claims clean | Run `synthesize` skill |
| `export` | Overview generated, deliverables pending | Run `export` skill |
| `complete` | All workflow stages finished | Review outputs or re-export |

## Multi-Session Design

This skill is the recommended re-entry point after heavy sessions. Portfolio work naturally spans multiple sessions — batch proposition generation, competitive analysis, solution design, and dashboard generation each consume significant context. Other portfolio skills proactively recommend `/portfolio-resume` when they detect a heavy session (multiple batch operations, 3+ skills invoked, or capstone operations like portfolio-dashboard/synthesize/export completed).

When presenting the status summary, acknowledge what the user accomplished in previous sessions if recent entity timestamps suggest a productive recent session. This continuity helps users feel their work persists and builds confidence in the multi-session workflow.

## Language

- **Communication Language**: Read `portfolio.json` in the project root. If a `language` field is present, communicate with the user in that language (status messages, instructions, recommendations, questions). Technical terms, skill names, and CLI commands remain in English. If no `language` field is present, default to English.
