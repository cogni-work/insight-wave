# Entity Relationships and Cross-Plugin Data Flow

This document places the insight-wave entity model in context. The canonical data flow diagram is at [`/docs/er-diagram.md`](../er-diagram.md) — this document adds the explanation layer: what each entity layer does, how the bridges work, and what the data isolation principle means in practice.

---

## Architectural Groups

The ecosystem splits along one line: cogni-workspace is **horizontal** infrastructure, and the business plugins are **vertical**, each keeping its own project lifecycle. The dividing rule is not the `setup → resume → dashboard` arc itself but what it is *about*: a capability owning a **project lifecycle** — many projects, each with its own state, advancing across sessions — is a vertical business plugin. cogni-workspace runs the same shape, but over configuration rather than projects: one workspace, not a portfolio of them. Owning the shape does not make a plugin vertical; owning projects does. The vertical plugins are grouped below by the role they play; that grouping is descriptive, not a dependency ordering.

```
horizontal   cogni-workspace  (shared workspace state: themes, env vars, discovery)
─────────────────────────────────────────────────────────────────────────────────
vertical     Orchestration   cogni-consult
             Data            cogni-portfolio  cogni-trends  cogni-knowledge  cogni-workspace
             Output          cogni-workspace (narrative + copywriter + rendering)
                             cogni-sales      cogni-marketing
```

**Shared workspace** (cogni-workspace) provides shared infrastructure: themes, environment variables, Obsidian vault configuration. Every plugin that produces visual HTML output reads theme files from cogni-workspace. No plugin writes to cogni-workspace except through the `manage-themes` and `manage-workspace` skills.

**Data group** plugins each own a specialized knowledge domain:
- cogni-portfolio owns product and market knowledge (features, propositions, competitors)
- cogni-trends owns trend and value model knowledge (TIPS paths, solution templates, catalogs)
- cogni-knowledge owns research artifacts in the bound wiki (sources, syntheses, distilled concepts, question nodes, claims)
- cogni-workspace owns the verification state for sourced assertions from any plugin

**Output group** plugins transform data-group content into deliverables. They consume but do not produce data-group entities.

**Orchestration group** (cogni-consult) manages engagement state. It dispatches research through the engagement's bound cogni-knowledge base and routes deliverable work to data and output group plugins, but does not produce content itself. (It succeeds the archived cogni-consulting Double Diamond plugin.)

---

## Key Entity Types by Plugin

| Plugin | Persistent Entities | Storage Format |
|--------|-------------------|----------------|
| cogni-portfolio | Product, Feature, Market, Proposition, Solution, Package, Competitor, Customer | JSON files in project directory |
| cogni-trends | TipsProject, TrendCandidate, TrendReport, InvestmentTheme, SolutionTemplate, Catalog | JSON + YAML in project directory |
| cogni-knowledge | Binding, WikiSource, Synthesis, Concept, Question (wiki pages) | Markdown with YAML frontmatter (Obsidian-browsable) |
| cogni-workspace | ClaimRecord, DeviationRecord, ResolutionRecord | JSON in `cogni-claims/` directory |
| cogni-sales | PitchLog, BuyingCenter, PhaseDeliverable | JSON + Markdown per phase |
| cogni-marketing | MarketingProject, ContentStrategy, ContentPiece, Campaign, Calendar | JSON + Markdown with YAML frontmatter |
| cogni-workspace (`narrative`) | Narrative (arc_id, sections, techniques) | Markdown with YAML frontmatter |
| cogni-workspace (rendering) | Brief (YAML frontmatter + Markdown body) | Per-deliverable brief files |
| cogni-workspace | Theme, WorkspaceConfig, VaultConfig | Markdown (theme.md) + JSON |
| cogni-consult | Engagement (consult-project.json), ActionField (field.json), Persona | JSON + Markdown |

The `copywriter` skill has no persistent entities — it modifies documents in place and detects `arc_id` frontmatter for arc-aware polishing.

---

## Bridge Files

Bridge files are explicit JSON exports that carry data between plugins. They are written by one plugin and read by another according to a versioned contract.

| Bridge File | Written by | Read by | What it carries |
|------------|-----------|--------|-----------------|
| `portfolio-context.json` | cogni-portfolio | cogni-trends | Products, features, markets for trend-to-portfolio mapping |
| `portfolio-opportunities.json` | cogni-trends | cogni-portfolio | Ranked growth opportunities from trend analysis |
| `tips-value-model.json` | cogni-trends | cogni-portfolio | Solution templates, TIPS paths, BR scores for trends-bridge import |
| `claims.json` | various | cogni-workspace | Claim records with source URLs submitted for verification |
| `consult-project.json` | cogni-consult | (internal) | Engagement config, key question, action-field list, knowledge-base binding |

The bidirectional bridge between cogni-portfolio and cogni-trends is the most complex: `portfolio-context.json` flows from portfolio to trends so that value-modeler Phase 2 can generate solution templates that are grounded in existing products. `portfolio-opportunities.json` flows back so cogni-portfolio's `trends-bridge` skill can turn high-ranked TIPS opportunities into feature and proposition stubs.

---

## YAML Frontmatter Contracts

Downstream plugins read YAML frontmatter fields from files produced by upstream plugins. These are lightweight contracts that avoid the overhead of bridge files for simple references.

| Field | Set by | Read by | Purpose |
|-------|-------|--------|---------|
| `arc_id` | cogni-workspace (`narrative`) | cogni-workspace (`copywriter`, rendering) | Arc type for arc-aware polishing and visual theme selection |
| `theme_path` | cogni-workspace | cogni-workspace (rendering) | Path to the active theme file |
| `portfolio_path` | cogni-portfolio | cogni-sales, cogni-marketing, cogni-trends | Path to the project directory |
| `arc_type` | cogni-workspace (from arc_id mapping) | rendering agents | Visual arc type from libraries/arc-taxonomy.md |

---

## Data Isolation in Practice

The entity diagram shows many arrows between plugins, but each arrow is a read-only reference resolved at runtime, not a live connection or shared write path.

When cogni-knowledge runs its inverted pipeline, it writes Source, Synthesis, and distilled Concept pages into the bound wiki. A claims pipeline reads those source URLs from the page frontmatter to verify claims — but it does not write back to cogni-knowledge's wiki. The verification result is written to cogni-workspace' own `claims.json`.

When cogni-portfolio generates propositions, the proposition-generator agent reads the feature entity and the market entity from cogni-portfolio's own directories. If those entities have trend-bridge enrichments (from `portfolio-opportunities.json`), the agent reads them as additional context, but cogni-trends' files remain unchanged.

The boundary is the bridge file or frontmatter field. Everything on each side of that boundary is private to the owning plugin.

---

## Claim Lifecycle

Claims flow from multiple sources into cogni-workspace, where they go through a three-state lifecycle:

```
unverified → verified (no deviation found)
          → deviated (source does not support claim)
               → resolved (user reviewed and acted on deviation)
```

Any data-layer plugin that produces sourced assertions writes claim records to `cogni-claims/claims.json` via append operations. cogni-portfolio's research agents use `scripts/append-claim.sh`. cogni-trends logs claims from market data. cogni-knowledge extracts per-source claims at ingest and re-checks them against live source URLs via its `knowledge-refresh --resweep` pass.

cogni-workspace owns the verification logic but never generates the claims itself — that boundary is enforced by design.

---

## Full Data Flow Diagram

See [`/docs/er-diagram.md`](../er-diagram.md) for the complete Mermaid diagram showing all plugin relationships and data flow directions.

---

## Related Documents

- [design-philosophy.md](design-philosophy.md) — the Data Isolation principle and why it matters
- [plugin-anatomy.md](plugin-anatomy.md) — how bridge files and frontmatter fields appear in plugin structure
