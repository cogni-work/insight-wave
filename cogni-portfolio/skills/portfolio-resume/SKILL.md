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
| Propositions | N / expected (E excluded) | pct% |
| Solutions | N / propositions | pct% |
| Packages | N / packageable | pct% |
| Competitors | N / propositions | pct% |
| Customers | N / markets | pct% |
| Claims | N total | V verified, D deviated, U unverified, P pending propagation. If `claims.pending_stale > 0`, append: "(S on stale entities — deferred)" |
| Communicate | N files | A accepted, R revise, J rejected (if > 0), STALE if upstream changed |
| Architecture | exists/missing | STALE if products/features changed since last generation |
| Purpose | N / total features | coverage percentage — low coverage limits architecture and customer narrative quality |
| Context | N entries | breakdown by category (e.g., 3 pricing, 2 competitive, 1 strategic) |
| Sources | N (D docs, U urls) | S stale, C current (only if `source_lineage.has_registry` is true) |
| Uploads | N | pending ingestion (if > 0) |

The Propositions row uses `counts.expected_propositions` as the denominator — this value already subtracts excluded pairs. Do NOT compute your own expected count by multiplying features × markets. Show as `N / expected (E excluded)` where `E` is `counts.excluded_pairs`. Only show the "(E excluded)" suffix when E > 0. When N equals expected, show 100% — excluded pairs are design decisions, not gaps.

If `margin_health` is present in the status output and has `solutions_with_cost_model > 0`, add a margin health line after the table:
- **Margin health** — N solutions with cost models, N tiers below target (target: Y%), N negative-margin tiers. Show margins split by type: project avg margin X%, subscription avg gross margin X%. These are different metrics (effort-based vs. unit economics) so present them separately. Flag negative project margins and subscription LTV/CAC < 3 as urgent.

If `solutions_by_type` is present, show the type breakdown: "N project, N subscription, N partnership".

If `blueprint_status` is present and has `version_drifted > 0`, add a blueprint drift line:
- **Blueprint drift** — N solutions were generated from an older blueprint version and may need regeneration. List the drifted solution slugs (from `drifted_solutions`). Recommend: "Run the `solutions` skill in review mode to check drift and selectively regenerate." Also show blueprint coverage: "N products have delivery blueprints, N solutions were generated from blueprints."

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
- **Source drift** — if `source_lineage.has_registry` is true and drift is detected, show this section BEFORE stale entities (since source drift is often the root cause of entity staleness):
  - If `source_lineage.changed_uploads` is non-empty: "N source documents have been re-uploaded with changes (list filenames). These affect M entities." Group affected entities by source. Recommend: "Run `portfolio-lineage` to assess impact, or `portfolio-ingest` to re-process the updated documents."
  - If `source_lineage.new_uploads` is non-empty: "N new files in uploads/ have not been ingested yet." Distinguish from changed re-uploads.
  - If `source_lineage.stale_sources` > 0 and no changed_uploads: "N source entries are marked as stale in the registry." Recommend running `portfolio-lineage check` to investigate.
  - If `source_lineage.untracked_entities` > 0: "N entities have no source lineage tracking." This is informational, not urgent — mention it after other drift warnings. Recommend running `portfolio-lineage` to backfill.
- **Stale entities** — if `stale_entities` is non-empty, show them as priority actions before the regular next steps. Group by reason type: "N propositions need refresh because their upstream features were updated" is more useful than listing each one. If a stale entity also has quality warnings, lead with the quality issue (fix the root cause first, then refresh the proposition). When stale entities AND unverified claims coexist, note the interaction: if `claims.pending_stale > 0`, explain that those claims sit on entities about to be refreshed — verifying them now would be wasted work since the refresh will generate new claims. This helps the user understand why verify isn't the first recommended step despite having hundreds of pending claims.
- **Stale communicate files** — if `communicate.stale` is `true`, highlight this prominently: "Communicate files may need refresh — upstream data changed since they were generated." Present the reason from `communicate.stale_reason`. Recommend running `portfolio-communicate` to regenerate. This appears alongside stale entity warnings since it represents the same class of problem (downstream output invalidated by upstream changes).
- **Stale architecture diagram** — if `architecture.stale` is `true`, mention that the architecture diagram may be outdated because products or features changed since it was generated. Recommend running `portfolio-architecture` to refresh. If `architecture.exists` is `false` and features exist, suggest generating the architecture diagram as a visual checkpoint.
- **Purpose coverage** — if `purpose_coverage.total_features > 0` and `purpose_coverage.with_purpose` is less than half of `total_features`, note low purpose coverage: "N of M features have purpose statements. Adding purpose improves architecture diagrams and customer-facing materials." Recommend running the `features` skill to add purpose statements.
- **Context notice** — if `counts.context_entries > 0`, mention available context entries with a category breakdown. Read `context/context-index.json` for the `by_category` map to show counts per category. This helps the user understand what intelligence is available for downstream skills. If context exists but downstream skills haven't been run yet, highlight this: "N context entries from ingested documents are ready — these will automatically inform propositions, solutions, and other skills."
- **Uploads notice** — if `counts.uploads > 0`, always mention pending files regardless of phase. When `source_lineage.has_registry` is true, distinguish between new uploads (`source_lineage.new_uploads`) and re-uploads (`source_lineage.changed_uploads`): "N new uploads (never ingested) + M re-uploads (source changed since last ingestion)"
- **Gaps** — handle exclusions and missing pairs in this order:
  1. Check `excluded_pairs` from the script output FIRST. These are confirmed design decisions recorded in feature files with explicit reasons — not guesses. If non-empty, state definitively: "N Feature × Market Paare bewusst ausgeschlossen (Design-Entscheidung)." Never use speculative language like "vermutlich" or "möglicherweise" for excluded pairs.
  2. Check `missing_propositions` — this array already excludes excluded pairs, so any entries here are genuine gaps. List them as actionable items.
  3. If `missing_propositions` is empty, the proposition matrix is complete. Do NOT list excluded pairs as missing or suggest creating them. A brief mention of the exclusion count in the table row is sufficient.
  4. If the script reports `counts.excluded_pairs: 0` but `missing_propositions` contains pairs, cross-check by reading feature files for `excluded_markets` arrays as a fallback — the script may have failed to detect them.
  5. Note incomplete solutions/competitors/customers as separate items.

Keep the tone warm and oriented toward action — this is a welcome-back moment, not a status report. The user should feel oriented, not overwhelmed.

### 5. Recommend Next Action

Present entries from `next_actions` **sorted by `priority` (ascending)**. Lower priority numbers represent upstream work that must complete before higher-numbered downstream actions can produce quality output.

**Presentation rules:**
- Lead with the lowest-priority (most upstream) action as the primary recommendation
- If multiple actions share the same priority, present them as parallel options the user can tackle in any order
- When a higher-priority action (e.g., communicate at 10) appears alongside a lower-priority action (e.g., packages at 8), explicitly note the dependency: explain *why* the upstream action should come first
- Offer to proceed with the top (lowest priority number) recommendation immediately

**Common dependency pairs — explain these when both appear:**
- packages (8) before communicate (10) — communicate generates deliverables from package data; without current packages, output will be incomplete
- solutions (7) before packages (8) — packages bundle solutions into tiers; missing solutions mean incomplete bundles
- propositions (6) before solutions (7) — solutions implement proposition DOES/MEANS; no propositions means nothing to implement
- features (3) before propositions (6) — propositions map features to markets; feature changes invalidate downstream propositions
- propositions (6) before verify (9) when propositions are stale — refreshing generates new claims, making verification of old claims on those entities wasted work. The `claims.pending_stale` count tells you how many claims fall into this category.
- ingest (1) before everything — new document data may change features, markets, or other entities

If the phase is `complete`, congratulate the user and suggest reviewing outputs or running `portfolio-communicate` for additional deliverables. If communicate files are stale (indicated by a communicate action in `next_actions`), mention that `portfolio-communicate` should be re-run to refresh customer-facing documentation.

## Phase Reference

| Phase | Meaning | What to do |
|-------|---------|------------|
| `products` | No products defined yet | Run `products` skill |
| `features` | Products exist, no features | Run `features` skill |
| `markets` | Features defined, no markets | Run `markets` skill |
| `customers` | Markets defined, no customer profiles yet | Run `customers` skill (or skip to `propositions` for weaker messaging) |
| `propositions` | Feature x Market pairs need messaging | Run `propositions` skill |
| `enrichment` | Propositions exist, solution/competitor gaps remain | Run `solutions`, `compete`, and/or `customers` for remaining markets |
| `verification` | Unverified or deviated claims pending | Run `verify` skill |
| `propagation` | Resolved claims with corrections not yet applied to entity files | Run `verify` skill (Step 8 propagates corrections) |
| `communicate` | All entities complete, claims clean, corrections propagated | Run `communicate` skill |
| `complete` | All workflow stages finished | Review outputs or refresh `communicate` if upstream data changed |

## Multi-Session Design

This skill is the recommended re-entry point after heavy sessions. Portfolio work naturally spans multiple sessions — batch proposition generation, competitive analysis, solution design, and dashboard generation each consume significant context. Other portfolio skills proactively recommend `/portfolio-resume` when they detect a heavy session (multiple batch operations, 3+ skills invoked, or capstone operations like portfolio-dashboard/portfolio-communicate completed).

When presenting the status summary, acknowledge what the user accomplished in previous sessions if recent entity timestamps suggest a productive recent session. This continuity helps users feel their work persists and builds confidence in the multi-session workflow.

## Language

- **Communication Language**: Read `portfolio.json` in the project root. If a `language` field is present, communicate with the user in that language (status messages, instructions, recommendations, questions). Technical terms, skill names, and CLI commands remain in English. If no `language` field is present, default to English.
