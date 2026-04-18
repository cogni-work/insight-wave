# Index

This is the content catalog for **insight-wave**. Every wiki page is listed here with a one-line summary. Claude consults this file before drilling into specific pages.

## Categories

### Ecosystem

- [[ecosystem-overview]] — insight-wave is a 13-plugin monorepo for consulting, sales, and marketing on Claude Code, AGPL-3.

### Architecture

- [[arch-design-philosophy]] — The architectural principles that recur across insight-wave plugins.
- [[arch-er-diagram]] — The cross-plugin entity model and how data flows between plugins.
- [[arch-plugin-anatomy]] — How insight-wave plugins are structured on disk.

### Cross-cutting concepts

- [[concept-agent-model-strategy]] — Agents pick model tiers by role across insight-wave, with cost-per-task as the deciding factor.
- [[concept-bridge-files]] — Bridge files are explicit JSON exports written by one plugin and read by another according to a versioned contract.
- [[concept-brief-based-rendering]] — cogni-visual separates content specification from rendering.
- [[concept-claim-lifecycle]] — Claims in cogni-claims move through a three-state lifecycle.
- [[concept-claims-propagation]] — Claims propagation is the cross-plugin pattern that turns sourced assertions into a verifiable, self-correcting knowledge graph.
- [[concept-data-isolation]] — Each insight-wave plugin owns its data completely.
- [[concept-data-model-patterns]] — The recurring patterns across every entity-producing plugin in insight-wave.
- [[concept-four-layer-architecture]] — The ecosystem (see [[ecosystem-overview]]) organizes into four layers.
- [[concept-mcp-server-map]] — Three MCP servers ship with the insight-wave marketplace, mapped to the plugins that consume them.
- [[concept-multilingual-support]] — insight-wave is built for European multilingual operation, not English-only with translations bolted on.
- [[concept-naming-conventions]] — Names in insight-wave follow tiered patterns.
- [[concept-orchestrator-pattern]] — cogni-consulting does not produce content.
- [[concept-plugin-maturity-model]] — Plugin maturity is hard-derived from the version — there is no manual maturity field in `plugin.
- [[concept-progressive-disclosure]] — Skills and agents load reference material only at the step that needs it, never all at startup.
- [[concept-quality-gates]] — Most entity-producing plugins follow a three-layer pipeline that runs before downstream generation is allowed to proceed.
- [[concept-readme-convention]] — Every plugin README follows the same 16-section IS/DOES/MEANS structure.
- [[concept-script-output-format]] — Every utility script in insight-wave returns JSON in a single canonical shape:.
- [[concept-slug-based-lookups]] — All cross-plugin references use kebab-case slug identifiers.
- [[concept-theme-inheritance]] — All visual plugins read their theme from cogni-workspace.
- [[concept-trends-portfolio-bridge]] — The most complex single integration in the ecosystem.

### Plugins

- [[plugin-cogni-claims]] — cogni-claims manages the full lifecycle of sourced-claim verification within an insight-wave workspace.
- [[plugin-cogni-consulting]] — Double Diamond consulting orchestrator.
- [[plugin-cogni-copywriting]] — Professional copywriting toolkit providing document polishing with messaging frameworks (BLUF, Pyramid, SCQA, STAR, PSB, FAB, Inverted Pyramid), stakeholder review via parallel persona Q&A, readabi....
- [[plugin-cogni-help]] — Central help hub for the insight-wave ecosystem.
- [[plugin-cogni-marketing]] — B2B marketing content engine that bridges cogni-trends strategic themes (GTM paths) and cogni-portfolio propositions into channel-ready content.
- [[plugin-cogni-narrative]] — Story arc engine for the insight-wave ecosystem.
- [[plugin-cogni-portfolio]] — cogni-portfolio gives B2B companies a structured way to build market-specific messaging using the IS/DOES/MEANS (FAB) framework applied at the Feature × Market level.
- [[plugin-cogni-research]] — Multi-agent research report generator with localized search across 18 European and Anglo markets (DACH, DE, AT, FR, IT, ES, NL, PL, CZ, SK, HU, RO, HR, GR, MK, UK, US, EU).
- [[plugin-cogni-sales]] — B2B sales pitch generation using Corporate Visions Why Change methodology.
- [[plugin-cogni-trends]] — Strategic trend scouting and reporting pipeline.
- [[plugin-cogni-visual]] — Transform polished narratives and structured data into visual deliverables — presentation briefs, slide decks, scrollable web narratives, poster storyboards, single-page infographics, and visual as....
- [[plugin-cogni-website]] — Assembles multi-page customer websites from portfolio, marketing, trend, and research content produced by other insight-wave plugins.
- [[plugin-cogni-wiki]] — A better RAG for personal and small-team knowledge work.
- [[plugin-cogni-workspace]] — Foundation-layer plugin for the insight-wave marketplace.

### Workflows

- [[workflow-consulting-engagement]] — The full Double Diamond pipeline orchestrated by [[plugin-cogni-consulting]].
- [[workflow-content-pipeline]] — The end-to-end content production pipeline — from strategy to channel-ready deliverables.
- [[workflow-install-to-infographic]] — First-run workflow with insight-wave: install the marketplace, set up your workspace, extract a theme from your company website, and render your first infographic.
- [[workflow-portfolio-to-pitch]] — Generate a deal-specific or segment-reusable sales pitch from existing portfolio data.
- [[workflow-portfolio-to-website]] — Generate a deployable customer website from your portfolio model and a workspace theme.
- [[workflow-research-to-report]] — Produce a verified, polished research report as a themed visual deliverable.
- [[workflow-trends-to-solutions]] — Turn scouted trends into ranked solution blueprints with visual deliverables.

### Skills

One page per skill across all 14 plugins. Grouped by plugin, alphabetical within each.

#### cogni-claims

- [[skill-cogni-claims-claim-entity]] — Cross-plugin data model for claim verification — defines ClaimRecord, DeviationRecord, and ResolutionRecord schemas, status transitions, deviation types, severity levels, and workspace layout.
- [[skill-cogni-claims-claims]] — Manage claim verification lifecycle — submit, verify, review dashboard, inspect, resolve, and cobrowse claims.

#### cogni-consulting

- [[skill-cogni-consulting-consulting-define]] — Execute the Define phase of a Double Diamond engagement — converge from discovery insights to a clear problem statement.
- [[skill-cogni-consulting-consulting-deliver]] — Execute the Deliver phase of a Double Diamond engagement — converge on validated, actionable outcomes.
- [[skill-cogni-consulting-consulting-develop]] — Execute the Develop phase of a Double Diamond engagement — diverge to generate and explore solution options.
- [[skill-cogni-consulting-consulting-discover]] — Execute the Discover phase of a Double Diamond engagement — diverge to build a rich understanding of the problem landscape.
- [[skill-cogni-consulting-consulting-export]] — Generate the final deliverable package for a Double Diamond engagement.
- [[skill-cogni-consulting-consulting-resume]] — Resume, continue, or check status of a Double Diamond consulting engagement.
- [[skill-cogni-consulting-consulting-setup]] — Initialize a new Double Diamond consulting engagement with vision framing and project scaffolding.

#### cogni-copywriting

- [[skill-cogni-copywriting-audit-copywriter]] — Audit cogni-copywriting's arc-preservation references against cogni-narrative's upstream arc definitions.
- [[skill-cogni-copywriting-copy-json]] — Adapter skill that polishes text fields inside JSON files by extracting them, delegating to the copywriter skill for polishing, and writing the polished text back.
- [[skill-cogni-copywriting-copy-reader]] — This skill should be used when the user wants to review a document from different stakeholder perspectives, simulate how different audiences would read a document, or get multi-perspective feedback....
- [[skill-cogni-copywriting-copywriter]] — Polish, rewrite, or create business documents (memos, briefs, reports, proposals, one-pagers, executive summaries, emails, blog posts, business letters) using professional messaging frameworks (BLU....

#### cogni-help

- [[skill-cogni-help-cheatsheet]] — Generate quick-reference cards for any insight-wave plugin.
- [[skill-cogni-help-cogni-issues]] — File and track GitHub issues (bugs, feature requests, change requests, questions) against insight-wave ecosystem plugins using browser automation (claude-in-chrome).
- [[skill-cogni-help-course-deck]] — Generate professional PPTX slide decks for cogni-help courses.
- [[skill-cogni-help-guide]] — Help users find the right insight-wave plugin or skill for their task.
- [[skill-cogni-help-teach]] — Interactive course delivery for learning Claude Cowork and insight-wave plugins.
- [[skill-cogni-help-troubleshoot]] — Diagnose and fix common issues with insight-wave plugins.
- [[skill-cogni-help-workflow]] — Cross-plugin workflow templates for common multi-plugin pipelines.

#### cogni-marketing

- [[skill-cogni-marketing-abm]] — Generate account-based marketing content (account plans, personalized email sequences, executive briefings) tailored to specific named accounts using portfolio customer data and TIPS strategic themes.
- [[skill-cogni-marketing-campaign-builder]] — Build multi-channel marketing campaigns that orchestrate content across touchpoints with day-based timelines.
- [[skill-cogni-marketing-content-calendar]] — Generate and manage an editorial content calendar with publication dates, channel assignments, and cadence tracking.
- [[skill-cogni-marketing-content-strategy]] — This skill should be used when the user asks to plan a content strategy, build a content matrix, decide what content to create, map content to funnel stages, prioritize a content backlog, or plan G....
- [[skill-cogni-marketing-demand-generation]] — Generate demand generation content (SEO articles, LinkedIn posts, carousels, video scripts, infographic specs) that drives awareness and interest using trend hooks and portfolio value propositions.
- [[skill-cogni-marketing-lead-generation]] — Generate lead generation content (whitepapers, landing pages, email nurture sequences, webinar outlines, gated checklists) that converts interest into qualified leads using portfolio propositions a....
- [[skill-cogni-marketing-marketing-dashboard]] — Generate an interactive HTML dashboard visualizing marketing content coverage, campaign progress, funnel distribution, and channel mix.
- [[skill-cogni-marketing-marketing-resume]] — Resume a cogni-marketing project session by showing current status, content gaps, campaign progress, and recommended next actions.
- [[skill-cogni-marketing-marketing-setup]] — Initialize a cogni-marketing project by discovering cogni-trends and cogni-portfolio sources, configuring brand voice, and selecting markets with GTM paths.
- [[skill-cogni-marketing-sales-enablement]] — Generate sales enablement content (battle cards, one-pagers, demo scripts, objection handlers, proposal sections) that equips sales teams with competitive intelligence and deal-closing tools from p....
- [[skill-cogni-marketing-thought-leadership]] — Generate thought leadership content (blog posts, LinkedIn articles, keynote abstracts, podcast outlines, op-eds) that positions the brand as an industry expert using TIPS trend data and portfolio d....

#### cogni-narrative

- [[skill-cogni-narrative-narrative]] — Transform structured content into compelling executive narratives using story arc frameworks.
- [[skill-cogni-narrative-narrative-adapt]] — Transform existing narratives into derivative formats: executive briefs, talking points, and one-pagers.
- [[skill-cogni-narrative-narrative-review]] — Score and review existing narrative files against story arc quality gates.

#### cogni-portfolio

- [[skill-cogni-portfolio-compete]] — Analyze competitors for portfolio propositions — competitive landscape, battle cards, positioning, differentiation.
- [[skill-cogni-portfolio-customers]] — Create ideal customer profiles and buyer personas per target market.
- [[skill-cogni-portfolio-features]] — Define and manage market-independent product features (IS layer of FAB).
- [[skill-cogni-portfolio-markets]] — Discover, evaluate, and size target markets for the portfolio.
- [[skill-cogni-portfolio-packages]] — Bundle solutions into sellable packages per Product x Market combination.
- [[skill-cogni-portfolio-portfolio-architecture]] — Generate an interactive Excalidraw architecture diagram showing products and features in a clean hierarchy.
- [[skill-cogni-portfolio-portfolio-canvas]] — Bootstrap a cogni-portfolio project from a Lean Canvas or Business Model Canvas.
- [[skill-cogni-portfolio-portfolio-communicate]] — Generate portfolio documentation, pitch narratives, proposals, briefs, and workbooks for any audience.
- [[skill-cogni-portfolio-portfolio-dashboard]] — Generate an interactive HTML dashboard showing the full portfolio status.
- [[skill-cogni-portfolio-portfolio-ingest]] — Extract portfolio entities and structured context from uploaded documents (uploads/ folder).
- [[skill-cogni-portfolio-portfolio-lineage]] — Track source lineage, detect changes in input documents and URLs, and cascade refresh through the feature-proposition-solution chain.
- [[skill-cogni-portfolio-portfolio-resume]] — Resume, continue, or check status of a portfolio project.
- [[skill-cogni-portfolio-portfolio-scan]] — Discover what services a company offers by scanning their websites, classify findings against a portfolio taxonomy template, and import them as features and products into the portfolio data model.
- [[skill-cogni-portfolio-portfolio-setup]] — Initialize a new cogni-portfolio project with company context and directory structure.
- [[skill-cogni-portfolio-portfolio-verify]] — Verify web-sourced claims in portfolio entities against their cited sources.
- [[skill-cogni-portfolio-products]] — Define and manage the top-level product offerings in the portfolio.
- [[skill-cogni-portfolio-propositions]] — IS/DOES/MEANS (FAB) value-messaging engine: turns features into market-specific propositions per Feature × Market pair, with consulting-style critique and four mandatory tests built in.
- [[skill-cogni-portfolio-solutions]] — Define implementation plans and pricing tiers for propositions to build customer business cases.
- [[skill-cogni-portfolio-trends-bridge]] — Bidirectional integration between cogni-trends TIPS analysis and cogni-portfolio product portfolio.

#### cogni-research

- [[skill-cogni-research-research-report]] — Generate a multi-agent research report using parallel web, local document, or wiki research with structural review.
- [[skill-cogni-research-research-resume]] — Resume, continue, or check status of an existing cogni-research project — shows progress, the next recommended phase, and any interrupted runs.
- [[skill-cogni-research-research-setup]] — Configure and initialize a cogni-research project — interactive menu for report type, tone, citation style, target market (10 supported: DACH, DE, FR, IT, PL, NL, ES, US, UK, EU — each with per-mar....
- [[skill-cogni-research-verify-report]] — Verify claims in a research report against their cited sources using cogni-claims.

#### cogni-sales

- [[skill-cogni-sales-why-change]] — Create a Why Change sales pitch for a named customer or a reusable segment pitch for a market.

#### cogni-trends

- [[skill-cogni-trends-trend-report]] — Generate a strategic TIPS trend report organized around investment themes (Handlungsfelder) with inline citations and verifiable claims.
- [[skill-cogni-trends-trend-scout]] — Interactive trend scouting workflow with industry selection, bilingual support (DE/EN), and downstream pipeline integration.
- [[skill-cogni-trends-trends-catalog]] — Manage persistent industry catalogs that accumulate TIPS knowledge across pursuits.
- [[skill-cogni-trends-trends-dashboard]] — Generate an interactive HTML dashboard showing the full TIPS project lifecycle.
- [[skill-cogni-trends-trends-resume]] — Resume, continue, or check status of a TIPS trend scouting project.
- [[skill-cogni-trends-value-modeler]] — Build TIPS relationship networks and generate ranked Solution Templates from agreed trend candidates.

#### cogni-visual

- [[skill-cogni-visual-enrich-report]] — Use this skill whenever the user has an existing markdown report and wants it transformed into a polished visual deliverable.
- [[skill-cogni-visual-render-html-slides]] — Render a presentation-brief.
- [[skill-cogni-visual-review-brief]] — Review a visual brief from three stakeholder perspectives — design quality, audience experience, and usability.
- [[skill-cogni-visual-story-to-infographic]] — Transform any narrative (insight summary, trend report, strategy document, sales pitch, research report) into a single-page infographic brief optimized for visual scanning.
- [[skill-cogni-visual-story-to-slides]] — Transform any narrative (insight summary, trend report, strategy document, sales pitch, project update) into an optimized multi-slide presentation brief that the PPTX skill renders into PowerPoint.
- [[skill-cogni-visual-story-to-storyboard]] — Transform any narrative (insight summary, trend report, strategy document, sales pitch) into a multi-poster print storyboard brief for executive walkthroughs.
- [[skill-cogni-visual-story-to-web]] — Transform any narrative (insight summary, trend report, strategy document, sales pitch, project update) into an optimized scrollable web narrative brief that the web agent renders via Pencil MCP in....

#### cogni-website

- [[skill-cogni-website-website-build]] — This skill builds the static website by orchestrating CSS generation, parallel page generation, hero rendering, and site assembly.
- [[skill-cogni-website-website-legal]] — Generate legally required pages (Impressum, Datenschutzerklärung, Cookie-Hinweis, or the EU equivalents) for a cogni-website project based on the publishing jurisdiction (DE, AT, CH, EU).
- [[skill-cogni-website-website-plan]] — This skill plans the site structure for a cogni-website project interactively — discovering available content, proposing pages, mapping content to page sections, and generating website-plan.
- [[skill-cogni-website-website-preview]] — This skill previews the generated website in a browser, validates links, and reports structural issues.
- [[skill-cogni-website-website-resume]] — This skill resumes, continues, or checks status of a cogni-website project.
- [[skill-cogni-website-website-setup]] — This skill initializes a cogni-website project by discovering content sources from cogni-portfolio, cogni-marketing, cogni-trends, and cogni-research, selecting a theme, and scaffolding the project....

#### cogni-wiki

- [[skill-cogni-wiki-wiki-dashboard]] — Generate a self-contained HTML dashboard for a Karpathy-style wiki — pages by type, tag cloud, backlink graph, recent activity, and size/age histograms.
- [[skill-cogni-wiki-wiki-ingest]] — Ingest a source document (file, URL, pasted text, transcript, paper, article) into a Karpathy-style wiki — Claude reads the source, surfaces key takeaways, writes a summary page with YAML frontmatt....
- [[skill-cogni-wiki-wiki-lint]] — Audit a Karpathy-style wiki for health problems — broken "wikilinks" double-bracket references, orphan pages with no inbound links, stale dates, missing frontmatter fields, contradictions between p....
- [[skill-cogni-wiki-wiki-query]] — Answer a question by reading the Karpathy-style wiki — never from memory.
- [[skill-cogni-wiki-wiki-resume]] — Show status, activity, and recommended next action for a Karpathy-style wiki — entry count, days since last lint, recent log activity, stale drafts, and what the user should do next.
- [[skill-cogni-wiki-wiki-setup]] — Bootstrap a new Karpathy-style LLM wiki at a user-chosen directory — creates the raw/, wiki/, assets/, and .
- [[skill-cogni-wiki-wiki-update]] — Revise an existing Karpathy-style wiki page when knowledge has changed — shows the diff before writing, requires a source citation for every new claim, and sweeps related pages for now-stale statem....

#### cogni-workspace

- [[skill-cogni-workspace-ask]] — Answer a question about the insight-wave plugin ecosystem by reading the bundled insight-wave wiki — never from memory.
- [[skill-cogni-workspace-install-mcp]] — End-to-end MCP server installation for the insight-wave ecosystem — clone and build git-based MCPs, configure native app MCPs, and patch Claude Desktop's config so everything works without manual J....
- [[skill-cogni-workspace-manage-themes]] — Manage visual design themes for the workspace — extract themes from live websites (via claude-in-chrome), PowerPoint templates, or presets, then store and apply them to all visual outputs (slides, ....
- [[skill-cogni-workspace-manage-workspace]] — Initialize or update an insight-wave workspace — the shared foundation that all marketplace plugins depend on.
- [[skill-cogni-workspace-pick-theme]] — Standard theme picker for all insight-wave ecosystem plugins.
- [[skill-cogni-workspace-workspace-status]] — Diagnose and report on the health of an insight-wave workspace.

### Agents

One page per agent role across all 14 plugins. Grouped by plugin, alphabetical within each.

#### cogni-claims

- [[agent-cogni-claims-claim-verifier]] — Single-source verifier: fetch one URL via WebFetch, verify claims against the fetched content, return a strict JSON deviation report.
- [[agent-cogni-claims-source-inspector]] — Fetch a source URL via claude-in-chrome, locate the relevant passage, and present evidence to the user.

#### cogni-consulting

- [[agent-cogni-consulting-phase-analyst]] — Analyze diamond engagement state and assess phase readiness.

#### cogni-copywriting

- [[agent-cogni-copywriting-copywriter]] — Polish markdown documents for executive readability using McKinsey Pyramid Principle and messaging frameworks.
- [[agent-cogni-copywriting-reader]] — Review documents through parallel stakeholder persona Q&A simulation with synthesized feedback.

#### cogni-help

- [[agent-cogni-help-course-deck-generator]] — Generate PPTX course decks via the course-deck skill.

#### cogni-marketing

- [[agent-cogni-marketing-channel-adapter]] — Agent in cogni-marketing; see source.
- [[agent-cogni-marketing-content-writer]] — Agent in cogni-marketing; see source.
- [[agent-cogni-marketing-seo-researcher]] — Agent in cogni-marketing; see source.

#### cogni-narrative

- [[agent-cogni-narrative-narrative-adapter]] — Adapt narratives into derivative formats — executive briefs, talking points, or one-pagers.
- [[agent-cogni-narrative-narrative-reviewer]] — Review and score narrative files against story arc quality gates.
- [[agent-cogni-narrative-narrative-writer]] — Transform structured content into executive narratives via the narrative skill.

#### cogni-portfolio

- [[agent-cogni-portfolio-communicate-review-assessor]] — Assess portfolio communication quality from three stakeholder perspectives adapted to the use case.
- [[agent-cogni-portfolio-competitor-researcher]] — Research competitors for a specific proposition using web search.
- [[agent-cogni-portfolio-customer-narrative-writer]] — Generate a single customer-narrative markdown file (one scope) from portfolio entities.
- [[agent-cogni-portfolio-customer-researcher]] — Research named companies for a target market using web search.
- [[agent-cogni-portfolio-customer-review-assessor]] — Assess customer profile quality from three stakeholder perspectives (procurement, CSO, market expert).
- [[agent-cogni-portfolio-dashboard-refresher]] — Regenerate the portfolio dashboard HTML from current entity data without user interaction.
- [[agent-cogni-portfolio-feature-deduplication-detector]] — Detect set-wide duplicate features within a single product using lexical and semantic similarity — works in any language.
- [[agent-cogni-portfolio-feature-deep-diver]] — Deep research for a single feature — competitive landscape, differentiation, buyer perception.
- [[agent-cogni-portfolio-feature-quality-assessor]] — Assess feature description quality using LLM intelligence — works in any language.
- [[agent-cogni-portfolio-feature-review-assessor]] — Assess feature set quality from three stakeholder perspectives (PM, strategist, pre-sales).
- [[agent-cogni-portfolio-market-researcher]] — Research and size a target market using web search — produces TAM/SAM/SOM data.
- [[agent-cogni-portfolio-portfolio-web-researcher]] — Execute domain-scoped portfolio research for taxonomy-driven portfolio scanning.
- [[agent-cogni-portfolio-proposition-deep-diver]] — Deep research for a single proposition — buyer language, competitive messaging, evidence enrichment.
- [[agent-cogni-portfolio-proposition-generator]] — Generate IS/DOES/MEANS messaging for a single Feature x Market combination.
- [[agent-cogni-portfolio-proposition-quality-assessor]] — Assess DOES/MEANS messaging quality in propositions — works in any language.
- [[agent-cogni-portfolio-proposition-review-assessor]] — Assess proposition set quality from three stakeholder perspectives (buyer, sales, marketer).
- [[agent-cogni-portfolio-quality-enricher]] — Research company-specific information to improve a feature or proposition with quality gaps.
- [[agent-cogni-portfolio-solution-architect]] — Propose delivery blueprints and assess shared solution eligibility for a product.
- [[agent-cogni-portfolio-solution-planner]] — Plan implementation phases and pricing tiers for a single proposition.
- [[agent-cogni-portfolio-solution-review-assessor]] — Assess solution quality from three stakeholder perspectives (procurement, provider SA, client SA).

#### cogni-research

- [[agent-cogni-research-claim-extractor]] — Extract verifiable claims from a report draft for downstream verification via cogni-claims.
- [[agent-cogni-research-deep-researcher]] — Recursive tree exploration for deep research mode — single branch, multi-query internal search.
- [[agent-cogni-research-local-researcher]] — Research a single sub-question from local files (PDF, DOCX, TXT, MD, CSV) instead of web search.
- [[agent-cogni-research-reviewer]] — Evaluate report drafts against structural review criteria and claims verification data.
- [[agent-cogni-research-revisor]] — Incorporate reviewer feedback and claims deviation data into a revised draft.
- [[agent-cogni-research-section-researcher]] — Perform parallel web research for a single sub-question, creating context and source entities.
- [[agent-cogni-research-source-curator]] — Rank, filter, and annotate research sources by quality, relevance, and diversity.
- [[agent-cogni-research-wiki-researcher]] — Research a single sub-question by querying cogni-wiki instances.
- [[agent-cogni-research-writer]] — Compile aggregated research context and source entities into a report with inline citations.

#### cogni-sales

- [[agent-cogni-sales-pitch-review-assessor]] — Assess sales pitch quality from three stakeholder perspectives (buyer, sales, marketing).
- [[agent-cogni-sales-pitch-revisor]] — Revise sales pitch deliverables based on pitch-review-assessor feedback.
- [[agent-cogni-sales-pitch-synthesizer]] — Assemble final sales-presentation.
- [[agent-cogni-sales-why-change-researcher]] — Research and generate content for a specific phase of the Why Change pitch workflow.

#### cogni-trends

- [[agent-cogni-trends-trend-candidate-reviewer]] — Assess 60 trend candidates from three stakeholder perspectives (foresight analyst, domain expert, pipeline consumer).
- [[agent-cogni-trends-trend-deep-researcher]] — Recursive deep research on a single high-value trend candidate to enrich evidence before report writing.
- [[agent-cogni-trends-trend-generator]] — Generate 60 scored trend candidates using multi-framework analysis (TIPS, Ansoff, Rogers, CRAAP).
- [[agent-cogni-trends-trend-report-investment-theme-writer]] — Write a single investment theme (Handlungsfeld) section using the Corporate Visions arc (Why Change → Why Now → Why You → Why Pay) with investment thesis, strategic capabilities, and business case ....
- [[agent-cogni-trends-trend-report-reviewer]] — Evaluate a trend report against structural quality criteria across investment themes.
- [[agent-cogni-trends-trend-report-revisor]] — Revise a trend report after claims verification — apply corrections and find replacement evidence.
- [[agent-cogni-trends-trend-report-writer]] — Generate a narrative TIPS dimension section with inline citations and verifiable claims from trend candidates.
- [[agent-cogni-trends-trend-signal-curator]] — Evaluate and rank web research signals by quality, relevance, and diversity before candidate generation.
- [[agent-cogni-trends-trend-web-researcher]] — Execute bilingual web research (EN/DE) for trend scouting and return aggregated signals as compact JSON.

#### cogni-visual

- [[agent-cogni-visual-brief-review-assessor]] — Assess visual brief quality from three stakeholder perspectives adapted to the brief type.
- [[agent-cogni-visual-concept-diagram]] — Generate a single Excalidraw concept diagram (TIPS flow, relationship map, process flow, or concept sketch) from structured data and export as SVG.
- [[agent-cogni-visual-concept-diagram-svg]] — Generate a single concept diagram (TIPS flow, relationship map, process flow, or concept sketch) as clean inline SVG using LLM-crafted geometric primitives.
- [[agent-cogni-visual-editorial-sketch]] — Generate a single editorial-discipline line-art sketch as inline SVG and write it to disk.
- [[agent-cogni-visual-enrich-report]] — Transform a text-only markdown report into a themed HTML deliverable with Chart.
- [[agent-cogni-visual-enriched-report-reviewer]] — Visual quality review of an enriched HTML report via Browser MCP screenshots.
- [[agent-cogni-visual-html-slides]] — Render a presentation-brief.
- [[agent-cogni-visual-pptx]] — Create, edit, and analyze PowerPoint presentations.
- [[agent-cogni-visual-render-infographic-pencil]] — Render an infographic-brief.
- [[agent-cogni-visual-render-infographic-sketchnote]] — Render an infographic-brief.
- [[agent-cogni-visual-render-infographic-whiteboard]] — Render an infographic-brief.
- [[agent-cogni-visual-report-html-writer]] — Write a complete self-contained scroll-layout HTML file from a markdown report, enrichment plan, and design variables.
- [[agent-cogni-visual-slides-enrichment-artist]] — Generate prep slides and speaker notes, then write the complete presentation-brief.
- [[agent-cogni-visual-story-to-infographic]] — Transform any narrative into a single-page infographic brief.
- [[agent-cogni-visual-story-to-slides]] — Transform any narrative with a story arc into an optimized presentation brief.
- [[agent-cogni-visual-story-to-storyboard]] — Transform any narrative with a story arc into a storyboard brief for printed posters.
- [[agent-cogni-visual-story-to-web]] — Transform any narrative with a story arc into a scrollable web narrative brief.
- [[agent-cogni-visual-storyboard]] — Render a storyboard-brief.
- [[agent-cogni-visual-web]] — Render a web-brief.

#### cogni-website

- [[agent-cogni-website-hero-renderer]] — Render the homepage hero section using Pencil MCP for AI-generated imagery.
- [[agent-cogni-website-page-generator]] — Generate a single HTML page from source content and a page template specification.
- [[agent-cogni-website-site-assembler]] — Generate shared CSS stylesheet, navigation partials, and sitemap.
