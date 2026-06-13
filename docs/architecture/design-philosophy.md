# Design Philosophy

This document describes the architectural principles that appear consistently across insight-wave plugins. Understanding these patterns makes it easier to read plugin source, contribute changes that fit naturally, and design new plugins that integrate without friction.

---

## Data Isolation

Each plugin owns its data completely. There is no shared database, no global state store, and no registry that plugins write to in common.

When plugin A needs to consume data from plugin B, it does so through one of three mechanisms:

- **Path references** — plugin A stores a path string pointing to a file in plugin B's directory, and reads it at runtime
- **Bridge files** — an explicit JSON export written by one plugin and read by another (e.g., `portfolio-context.json`, `tips-value-model.json`)
- **YAML frontmatter contracts** — a downstream plugin reads fields like `arc_id`, `theme_path`, or `portfolio_path` from files produced by an upstream plugin

The practical consequence is that every plugin can be understood, developed, and tested without loading any other plugin's code or data model. A change to cogni-portfolio's entity schema does not break cogni-trends unless the bridge file contract changes, and bridge contracts are versioned explicitly.

This isolation also means the ecosystem scales horizontally. A new plugin can consume cogni-portfolio output by reading `portfolio-context.json` without any change to cogni-portfolio itself.

The ROADMAP.md describes this as loose coupling with independent evolution:

```
cogni-trends/catalogs/manufacturing/automotive/solution-templates.json
  └── portfolio_ref: "cogni-portfolio/{project}/features/predictive-analytics"

cogni-portfolio/{project}/features/predictive-analytics.json
  └── tips_ref: "cogni-trends/{pursuit}/tips-value-model.json#st-001"
```

Each side stores a path to the other. The bridge skill resolves the reference at runtime.

---

## Progressive Disclosure

Skills and agents load reference material only at the step that needs it. This pattern appears in cogni-visual, cogni-portfolio, cogni-knowledge, and cogni-consult consistently.

The motivation is context window management. A research report skill that loaded every reference file at startup would fill its context before the user's first sub-question was answered. Instead, each phase of the pipeline loads only what that phase requires:

- Phase 0: read project config, check workspace state
- Phase 1: load sub-question templates, not yet the writer's tone guide
- Phase 3: load the writer's style reference only when writing begins
- Phase 4: load the reviewer's checklist only when reviewing begins

cogni-visual's CLAUDE.md describes this directly: "Reference files are read only at the step that needs them, not all at once."

The same principle applies to entity data. cogni-portfolio's `portfolio.json` is a lightweight manifest that stores entity counts and status flags — the full entity content lives in subdirectories and is read only when a skill actively works on that entity type. Browsing portfolio status costs almost nothing; deep research on a single feature loads only that feature's files.

At the agent level, progressive disclosure means agents receive compact task instructions and load reference materials themselves at their first step, rather than receiving the full skill context pre-loaded.

---

## Slug-Based Lookups

All cross-plugin references use kebab-case slug identifiers. Slugs are derived from entity names at creation time and remain stable through the entity's lifecycle.

```
cloud-monitoring--mid-market-saas-dach    (cogni-portfolio proposition)
automotive-ai-predictive-maintenance-abc12345  (cogni-trends trend)
siemens-manufacturing-pitch              (cogni-sales pitch)
acme-market-entry                        (cogni-consult engagement)
```

Slugs serve as both the file name and the cross-plugin identifier. When cogni-consult stores a reference to a cogni-knowledge base, it stores the base's slug and path, not an internal ID. When cogni-trends exports a bridge file referencing a portfolio feature, it uses the feature slug.

The double-dash convention in cogni-portfolio (`feature--market`) distinguishes paired entities from single entities visually and programmatically. The `cascade-rename.sh` script handles slug renaming across dependent entities when a user renames a feature or market after the fact.

cogni-claims uses UUID-v4 slugs (`claim-550e8400-...`) rather than name-derived slugs, because claims have no natural name — their identifier is their identity.

---

## Brief-Based Rendering

cogni-visual separates content specification from rendering. The pipeline has three stages:

```
cogni-narrative → cogni-copywriting → cogni-visual
(compose)         (polish)            (visualize)
```

Between the compose/polish phase and the render phase, cogni-visual inserts a brief: a structured Markdown file with YAML frontmatter that describes what to render without describing how to render it.

A presentation brief lists slides with headlines, body copy, and CTA proposals. It does not specify colors, fonts, layout coordinates, or element types. An infographic brief lists content blocks with block types, headlines, and data points. It does not specify element composition or spatial relationships — those decisions belong to the rendering agents.

This separation has two practical benefits:

1. The brief can be reviewed, edited, or regenerated independently of the rendering step. A user can run `story-to-slides` to produce a brief, adjust the headline on slide 3, and then render without re-running the content pipeline.

2. The rendering agents can evolve independently. When rendering pipelines upgrade, existing briefs remain valid because brief formats make no assumptions about rendering technique.

cogni-visual's CLAUDE.md: "Briefs are YAML frontmatter + Markdown. Frontmatter holds metadata (type, version, theme, arc_type, arc_id, confidence_score). Body holds the content specification."


---

## Quality Gates

cogni-portfolio implements a three-layer quality pipeline that runs before downstream generation is allowed to proceed.

**Layer 1 — Structural validation.** Scripts check JSON schema compliance: required fields are present, slugs are well-formed, references resolve. This layer runs in milliseconds and catches mechanical errors before any LLM work begins.

**Layer 2 — Quality assessment.** LLM-based assessor agents evaluate content dimensions specific to the entity type. For features, this means mechanism clarity, differentiation, and specificity. For propositions, this means buyer-specificity, differentiation from table stakes, and outcome grounding. Each dimension gets a score; scores below threshold flag the entity for improvement before proceeding.

**Layer 3 — Stakeholder review.** Assessor agents simulate reader perspectives. A feature set is reviewed from the perspective of a product manager, a strategist, and a pre-sales engineer. Each perspective produces an accept/warn/fail verdict. The proposition review simulates a buyer, a sales rep, and a marketer.

Quality gates block downstream generation by default. Features must pass quality assessment before propositions can be generated. Propositions that fail high-weight criteria were excluded from Option Synthesis in the archived cogni-consulting's Develop phase unless the consultant explicitly reinstated them.

The pattern is intentional: it is cheaper to fix a vague feature description now than to regenerate 12 propositions after the problem is discovered downstream.

---

## Orchestrator Pattern

cogni-consult does not produce content. It tracks engagement state and dispatches to plugins that produce content.

This is the central design principle of the orchestration layer. cogni-consult knows which action fields exist, which deliverables are mid-loop, and which await persona review. It does not know how to run a research pipeline or produce propositions — those capabilities live in cogni-knowledge, cogni-trends, and cogni-portfolio respectively.

When a deliverable's design-thinking loop needs evidence, cogni-consult routes the research through the engagement's bound cogni-knowledge base and stores the output paths. The pattern was established by the archived cogni-consulting (Double Diamond) plugin, whose phase-dispatch flow worked the same way against `cogni-knowledge:knowledge-compose`, `cogni-trends:trend-scout`, and `cogni-portfolio:portfolio-scan`.

From cogni-consult's CLAUDE.md: "Orchestrator, not producer — manages engagement state; content work dispatches to existing plugins."

The warn-not-block principle governs quality checks: most are advisory. In cogni-consult, acting stakeholder personas challenge each deliverable at the test stage, but the consultant decides whether to address or override the objections. (In the archived cogni-consulting, the same principle governed phase gates — advisory by default, with the Develop proposition quality gate as the blocking exception.)

Path references are stored in `consult-project.json` as relative paths. The engagement never copies data from other plugins — it only remembers where to find it.

---

## Related Documents

- [er-diagram.md](er-diagram.md) — cross-plugin entity relationships and data flow
- [plugin-anatomy.md](plugin-anatomy.md) — standard directory structure and file conventions
- [contributing/plugin-development.md](../contributing/plugin-development.md) — how to build a plugin that follows these patterns
