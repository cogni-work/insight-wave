# Cross-Plugin Data Flow

How data flows between insight-wave plugins. No shared database — all cross-references are resolved at runtime via slug-based lookups, bridge files, and YAML frontmatter contracts.

## Architecture Layers

```mermaid
graph LR
    subgraph Orchestration["Orchestration Layer"]
        DM[cogni-consult<br/>engagements, action fields<br/>deliverable state, personas]
    end

    subgraph Foundation["Foundation Layer"]
        WS[cogni-workspace<br/>themes, env vars, discovery<br/>obsidian, terminal, notes]
    end

    subgraph Data["Data Layer"]
        PF[cogni-portfolio<br/>products, features, markets<br/>propositions, solutions]
        TI[cogni-trends<br/>trends, investment themes<br/>value models, catalogs]
        GR[cogni-knowledge<br/>binding, wiki sources<br/>syntheses, concepts, claims]
        CL[cogni-claims<br/>claims, deviations<br/>resolutions]
    end

    subgraph Output["Output Layer"]
        NA[cogni-narrative<br/>arc-driven narratives]
        CW[cogni-copywriting<br/>polished documents]
        VI[cogni-visual<br/>slides, web, storyboard<br/>infographic, enrich-report]
        SA[cogni-sales<br/>pitches, proposals]
        MK[cogni-marketing<br/>content, campaigns<br/>calendars]
    end

    %% Orchestration → Data + Output (diamond dispatches)
    DM -->|dispatches discover| GR
    DM -->|dispatches discover/develop| TI
    DM -->|dispatches discover/develop/deliver| PF
    DM -->|dispatches define/deliver| CL
    DM -->|dispatches export| VI

    %% Foundation → All
    WS -.->|themes| VI
    WS -.->|env vars| PF
    WS -.->|env vars| TI

    %% Portfolio ↔ TIPS (bidirectional)
    PF -->|portfolio-context.json| TI
    TI -->|portfolio-opportunities.json| PF

    %% Data → Claims (verification)
    GR -->|claim submission| CL
    TI -->|claim submission| CL
    PF -->|claim submission| CL
    SA -->|claim submission| CL

    %% Portfolio → Output
    PF -->|propositions, markets| SA
    PF -->|propositions, competitors| MK

    %% TIPS → Output
    TI -->|themes, Handlungsfelder| MK
    TI -->|value-modeler output| VI

    %% Narrative pipeline
    NA -->|arc output| CW
    NA -->|arc patterns| SA
    NA -->|narratives| VI
    CW -->|polished content| VI

    %% Teacher (standalone, not shown — teaches all plugins)
```

## Entity Summary

| Plugin | Key Entities | Storage Format | Cross-Plugin Contract |
|--------|-------------|---------------|----------------------|
| **cogni-portfolio** | Product, Feature, Market, Proposition, Solution, Package, Competitor, Customer, Scan | JSON files in project directory | Exports `portfolio-context.json` (schema v3.1) to TIPS. Imports `portfolio-opportunities.json` from TIPS |
| **cogni-trends** | TipsProject, TrendCandidate, TrendReport, InvestmentTheme, SolutionTemplate, Catalog | JSON + YAML in project directory | Exports themes + value-model to Marketing, Sales. Bidirectional bridge with Portfolio |
| **cogni-knowledge** | Binding (binding.json), WikiSource, Synthesis, Concept, Question (wiki pages) | Markdown + YAML frontmatter (Obsidian-browsable) | Vendors the Karpathy wiki engine; submits resweep claims to cogni-claims via the claim-entity contract |
| **cogni-claims** | ClaimRecord, DeviationRecord, ResolutionRecord | JSON in `cogni-claims/` directory | Receives claims from all data-layer plugins. Status: unverified → verified/deviated → resolved |
| **cogni-sales** | PitchLog, BuyingCenter, PhaseDeliverable (research.json + narrative.md) | JSON + Markdown per phase | Consumes portfolio propositions + narrative arc patterns. Registers claims |
| **cogni-marketing** | MarketingProject, ContentStrategy, ContentPiece, Campaign, Calendar | JSON + Markdown with YAML frontmatter | Consumes portfolio propositions + TIPS themes. 16 content formats |
| **cogni-narrative** | Narrative (arc_id, sections, techniques) | Markdown with YAML frontmatter | Consumed by Visual, Copywriting, Sales via `arc_id` frontmatter |
| **cogni-copywriting** | (no persistent entities) | In-place document modification | Detects `arc_id` frontmatter for arc-aware polishing |
| **cogni-visual** | Brief (YAML frontmatter + Markdown body) | Per-deliverable brief files | Reads theme from cogni-workspace. Reads narrative via `arc_id` |
| **cogni-workspace** | Theme, WorkspaceConfig, VaultConfig, TerminalProfile | Markdown (theme.md) + JSON (settings, `.obsidian/` configs) | Theme files consumed by all visual plugins. Env vars consumed by all plugins. Obsidian browsing layer for all plugin outputs |
| **cogni-consult** | Engagement (consult-project.json), ActionField (field.json), Deliverable state, Persona, ExecutionLog, MethodLog, DecisionLog | JSON state files + Obsidian-browsable Markdown deliverables in `action-fields/{field}/` | Binds one cogni-knowledge base per engagement as the research spine; deliverables feed cogni-narrative, cogni-visual, cogni-sales |

## Cross-Plugin Bridge Files

| Bridge File | From | To | Purpose |
|------------|------|-----|---------|
| `portfolio-context.json` | cogni-portfolio | cogni-trends | Portfolio products, features, markets for trend-to-portfolio mapping |
| `portfolio-opportunities.json` | cogni-trends | cogni-portfolio | Growth opportunities scored by ranking, TAM alignment, competitive whitespace |
| `tips-value-model.json` | cogni-trends | cogni-portfolio | Solution templates, investment themes, TIPS paths for trends-bridge import |
| `pitch-log.json` | cogni-sales | (internal) | Workflow state, buying center config, phase tracking |
| `marketing-project.json` | cogni-marketing | (internal) | Brand voice, source paths, market-GTM path configuration |
| `claims.json` | various | cogni-claims | Claim records with source URLs, status, and deviation evidence |
| `consult-project.json` | cogni-consult | (internal) | Engagement config, key question, action-field list, knowledge-base binding |

## Naming Conventions

| Plugin | Slug Pattern | Example |
|--------|-------------|---------|
| cogni-portfolio | `{entity}--{context}` (double-dash) | `cloud-monitoring--mid-market-saas-dach` |
| cogni-trends | `{subsector}-{topic}-{hash8}` | `automotive-ai-predictive-maintenance-abc12345` |
| cogni-sales | `{customer-or-segment}-pitch` | `siemens-manufacturing-pitch` |
| cogni-marketing | `{market}--{gtm-path}--{format}` | `dach-enterprise--ai-automation--whitepaper` |
| cogni-knowledge | `{slug}` (wiki page / synthesis slugs) | `eu-ai-act-overview` |
| cogni-claims | `claim-{uuid-v4}` | `claim-550e8400-e29b-41d4-a716-446655440000` |
| cogni-consult | `{client}-{engagement-topic}` | `acme-market-entry` |

## Data Isolation Principle

No shared database. Cross-references are resolved at runtime via:
- **Slug-based lookups** — portfolio market slugs in TIPS projects
- **Bridge files** — explicit JSON exports between plugins (portfolio-context, portfolio-opportunities)
- **Wikilinks** — Obsidian-browsable entity references (cogni-knowledge)
- **YAML frontmatter** — `arc_id`, `theme_path`, `portfolio_path` fields for downstream consumption
- **File system conventions** — standard directory structures per plugin, discoverable via cogni-workspace scripts
