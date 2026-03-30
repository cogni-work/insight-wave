# Entity Relationships and Cross-Plugin Data Flow

This document places the insight-wave entity model in context. The canonical data flow diagram is at [`/docs/er-diagram.md`](../er-diagram.md) — this document adds the explanation layer: what each entity layer does, how the bridges work, and what the data isolation principle means in practice.

---

## Four Architectural Layers

The ecosystem organizes into four layers. Plugins in higher layers depend on plugins in lower layers, but not the reverse.

```
Orchestration   cogni-consulting
                     |
Foundation      cogni-workspace
                     |
Data            cogni-portfolio  cogni-trends  cogni-research  cogni-claims
                     |
Output          cogni-narrative  cogni-copywriting  cogni-visual
                cogni-sales      cogni-marketing
```

**Foundation layer** (cogni-workspace) provides shared infrastructure: themes, environment variables, Obsidian vault configuration. Every plugin that produces visual HTML output reads theme files from cogni-workspace. No plugin writes to cogni-workspace except through the `pick-theme` and `manage-workspace` skills.

**Data layer** plugins each own a specialized knowledge domain:
- cogni-portfolio owns product and market knowledge (features, propositions, competitors)
- cogni-trends owns trend and value model knowledge (TIPS paths, solution templates, catalogs)
- cogni-research owns research artifacts (sub-questions, contexts, sources, report-claims)
- cogni-claims owns the verification state for sourced assertions from any plugin

**Output layer** plugins transform data-layer content into deliverables. They consume but do not produce data-layer entities.

**Orchestration layer** (cogni-consulting) manages engagement state. It dispatches to data and output layer plugins at phase-appropriate moments but does not produce content itself.

---

## Key Entity Types by Plugin

| Plugin | Persistent Entities | Storage Format |
|--------|-------------------|----------------|
| cogni-portfolio | Product, Feature, Market, Proposition, Solution, Package, Competitor, Customer | JSON files in project directory |
| cogni-trends | TipsProject, TrendCandidate, TrendReport, InvestmentTheme, SolutionTemplate, Catalog | JSON + YAML in project directory |
| cogni-research | SubQuestion, Context, Source, ReportClaim | Markdown with YAML frontmatter (Obsidian-browsable) |
| cogni-claims | ClaimRecord, DeviationRecord, ResolutionRecord | JSON in `cogni-claims/` directory |
| cogni-sales | PitchLog, BuyingCenter, PhaseDeliverable | JSON + Markdown per phase |
| cogni-marketing | MarketingProject, ContentStrategy, ContentPiece, Campaign, Calendar | JSON + Markdown with YAML frontmatter |
| cogni-narrative | Narrative (arc_id, sections, techniques) | Markdown with YAML frontmatter |
| cogni-visual | Brief (YAML frontmatter + Markdown body) | Per-deliverable brief files |
| cogni-workspace | Theme, WorkspaceConfig, VaultConfig | Markdown (theme.md) + JSON |
| cogni-consulting | Engagement (consulting-project.json), PhaseState, LeanCanvas | JSON + Markdown |

cogni-copywriting has no persistent entities — it modifies documents in place and detects `arc_id` frontmatter for arc-aware polishing.

---

## Bridge Files

Bridge files are explicit JSON exports that carry data between plugins. They are written by one plugin and read by another according to a versioned contract.

| Bridge File | Written by | Read by | What it carries |
|------------|-----------|--------|-----------------|
| `portfolio-context.json` | cogni-portfolio | cogni-trends | Products, features, markets for trend-to-portfolio mapping |
| `portfolio-opportunities.json` | cogni-trends | cogni-portfolio | Ranked growth opportunities from trend analysis |
| `tips-value-model.json` | cogni-trends | cogni-visual | Solution templates, TIPS paths, BR scores for Big Block rendering |
| `claims.json` | various | cogni-claims | Claim records with source URLs submitted for verification |
| `consulting-project.json` | cogni-consulting | (internal) | Engagement config, phase state, plugin path references |
| `canvas-{slug}.md` | cogni-consulting | cogni-portfolio | Lean Canvas sections for entity extraction |

The bidirectional bridge between cogni-portfolio and cogni-trends is the most complex: `portfolio-context.json` flows from portfolio to trends so that value-modeler Phase 2 can generate solution templates that are grounded in existing products. `portfolio-opportunities.json` flows back so cogni-portfolio's `trends-bridge` skill can turn high-ranked TIPS opportunities into feature and proposition stubs.

---

## YAML Frontmatter Contracts

Downstream plugins read YAML frontmatter fields from files produced by upstream plugins. These are lightweight contracts that avoid the overhead of bridge files for simple references.

| Field | Set by | Read by | Purpose |
|-------|-------|--------|---------|
| `arc_id` | cogni-narrative | cogni-copywriting, cogni-visual | Arc type for arc-aware polishing and visual theme selection |
| `theme_path` | cogni-workspace | cogni-visual | Path to the active theme file |
| `portfolio_path` | cogni-portfolio | cogni-consulting | Path to the project directory |
| `arc_type` | cogni-visual (from arc_id mapping) | rendering agents | Visual arc type from libraries/arc-taxonomy.md |

---

## Data Isolation in Practice

The entity diagram shows many arrows between plugins, but each arrow is a read-only reference resolved at runtime, not a live connection or shared write path.

When cogni-research produces a research report, it writes SubQuestion, Context, and Source entities to its own directory. A claims pipeline reads those source URLs from the entity files to verify claims — but it does not write back to cogni-research's directories. The verification result is written to cogni-claims' own `claims.json`.

When cogni-portfolio generates propositions, the proposition-generator agent reads the feature entity and the market entity from cogni-portfolio's own directories. If those entities have trend-bridge enrichments (from `portfolio-opportunities.json`), the agent reads them as additional context, but cogni-trends' files remain unchanged.

The boundary is the bridge file or frontmatter field. Everything on each side of that boundary is private to the owning plugin.

---

## Claim Lifecycle

Claims flow from multiple sources into cogni-claims, where they go through a three-state lifecycle:

```
unverified → verified (no deviation found)
          → deviated (source does not support claim)
               → resolved (user reviewed and acted on deviation)
```

Any data-layer plugin that produces sourced assertions writes claim records to `cogni-claims/claims.json` via append operations. cogni-portfolio's research agents use `scripts/append-claim.sh`. cogni-trends logs claims from market data. cogni-research produces ReportClaim entities that feed into the `verify-report` skill.

cogni-claims owns the verification logic but never generates the claims itself — that boundary is enforced by design.

---

## Full Data Flow Diagram

See [`/docs/er-diagram.md`](../er-diagram.md) for the complete Mermaid diagram showing all plugin relationships and data flow directions.

---

## Related Documents

- [design-philosophy.md](design-philosophy.md) — the Data Isolation principle and why it matters
- [plugin-anatomy.md](plugin-anatomy.md) — how bridge files and frontmatter fields appear in plugin structure
