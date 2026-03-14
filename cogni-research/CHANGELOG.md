# Changelog - cogni-research

All notable changes to the deeper-research plugin will be documented in this file.

## [0.9.55] - 2026-02-26

### Changed

- **Flatten plugin structure to Anthropic standard** — Plugin root moved from nested `cogni-research/cogni-research/` to repo root
  - All 25 skills and 19 agents registered at flat paths in `plugin.json`
  - Hooks, contracts, scripts, and references relocated to root-level directories
  - Environment variable `CLAUDE_PLUGIN_ROOT` now points directly to repo root
  - Removed dead bash fallback paths from flat plugin migration

### Fixed

- **Post-flattening path cleanup** — Remove stale references left behind by structural migration
  - Fix 17 contract YAML files with hardcoded absolute paths to old `dev-cogni-research/` repo
  - Remove dead `cogni-research/config/` fallback from `entity_config.py`
  - Update paths in 5 documentation files (references README, debugging guide, script-path-resolution, entity-tagging-taxonomy)
  - Delete 2 stale migration docs (UPDATE-INSTRUCTIONS.md, REFACTORING-UPDATES.md)
  - Delete 2 duplicate contracts from misplaced `scripts/contracts/` directory
  - Update contract count in CLAUDE.md (85 → 102)

## [0.9.54] - 2026-02-26

### Fixed

- **PDF report rendering** — Render trend names, confidence, and concept definitions correctly

## [0.9.53] - 2026-02-26

### Fixed

- **Export-RAG entity chain resolution** — Fix 3 bugs recovering ~580 dropped links

## [0.9.40–0.9.52] - 2026-02-25 – 2026-02-26

### Changed

- Various incremental improvements to export pipelines, entity handling, and plugin infrastructure
- See individual commits for details

## [0.9.39] - 2026-02-25

### Fixed

- **Complete 7999e6b audit gaps** — 7 items from badge redesign / panel toggle commit
  - Render insight hero metadata badges (story arc, research type, word count) that had CSS but no HTML output
  - Fix 4 stale SKILL.md references: Kanban dimension colors, badge variable system, navbar toggle button, right panel HTML structure
  - Add panel toggle documentation (collapsible rail, PanelToggle JS, localStorage persistence)
  - Store `.pen` design files in `skills/export-html-report/design/`

## [0.9.38] - 2026-02-25

### Fixed

- **Arc-aware synthesis audit completions** — 4 gaps from commit 8d4dc47 review
  - Phase 5 validation: add arc-aware success criteria branch (arc frontmatter, 4 element sections, overview paragraph)
  - Phase 2 loading: propagate ARC_ID/ARC_DISPLAY_NAME/ARC_TEMPLATE in prerequisites and outputs
  - Language templates: add 6 missing header variables (HEADER_RELATED_MEGATRENDS, HEADER_EVIDENCE_QUALITY_ANALYSIS, HEADER_VERIFICATION_ROBUSTNESS, HEADER_SOURCE_AUTHORITY, HEADER_EVIDENCE_FRESHNESS_DETAIL, HEADER_QUALITY_DIMENSION_INSIGHTS) with English and German translations
  - Generic template: remove stale reference to non-existent `synthesis-template-tips.md`

## [0.9.37] - 2026-02-25

### Added

- **New `polish-research` skill** — Post-pipeline copywriting orchestration for completed research projects
  - Parallel dispatch of `cogni-copywriting:copywriter` agents across all synthesis outputs
  - Optional 5-persona stakeholder review on executive summary via `cogni-copywriting:reader`
  - Scope filter (`--scope all|synthesis|insight|megatrends|trends`) for targeted polishing
  - Graceful skip for missing optional files (insight-summary.md, megatrends, trends)
  - New reference: `polishable-files.md` documenting file inventory and characteristics

## [0.9.35] - 2026-02-24

### Fixed

- **Move insight-summary generation to deeper-research-3 Phase 10.5** — synthesis-hub Phase 4b contained commented-out pseudocode that never executed; moved `cogni-narrative:narrative-writer` delegation to orchestrator level as new Phase 10.5
  - New phase reference file: `phase-10.5-insight-summary.md`
  - Conditional on `arc_id` in sprint-log.json; all failures are WARNING-only (non-blocking)
  - Resumption detection supports starting at Phase 10.5 when research-hub.md exists but insight-summary.md is missing
  - Removed Phase 4b from synthesis-hub SKILL.md and phase-5-validation.md
  - Updated downstream routing in phase-0.5-arc-detection.md and phase-13-finalization.md
  - Token budget updated: 65K → 68K (+3K for Phase 10.5)

## [0.9.34] - 2026-02-24

### Removed

- **Diagram injection pipeline removed** — Removed Phase 11 (Diagram Resolution) and all supporting diagram-placeholder logic
  - Deleted Phase 11 reference file (`phase-11-diagram-resolution.md`)
  - Deleted diagram template/reference files (`diagram-placeholder-format.md`, `diagram-generation-workflow.md`, `example-executive-with-diagrams.md`, `framework-diagram-mappings.md`)
  - Removed `<diagram-placeholder>` XML generation from synthesis-dimension and synthesis-hub templates
  - Removed diagram validation (Step 3) from synthesis-hub Phase 5
  - Removed `embed_svg_assets()` function from export-html-report
  - Removed diagram-expert dependency references across all skills
  - Phase 12 now gates on Phase 10 completion instead of Phase 11
  - Mermaid inline diagrams remain available (unaffected)

## [0.9.32] - 2026-02-24

### Changed

- **synthesis-hub: Phase 4b delegates to cogni-narrative** (v2.5.0)
  - Replaced local `phase-4b-synthesis-{arc_id}.md` workflow files with Task tool delegation to `cogni-narrative:narrative-writer`
  - Phase 4b is non-blocking: failure logs a warning but does not abort synthesis
  - Updated Phase 5 validation to match new output expectations
  - Updated downstream routing in phase-0.5-arc-detection.md
  - Updated documentation references (PROPAGATION-PROTOCOL, DESIGN-PRINCIPLES, README, DEVELOPMENT-KIT)

## [0.9.17] - 2026-02-24

### Added

- **McKinsey/BCG consulting redesign**: Complete visual overhaul of export-html-report with professional consulting aesthetic (`72812a9`)
- **Persistent left navigation sidebar**: Always-visible sidebar across all report tabs (`c06dec6`)
- **Top navbar entity tabs**: Migrated entity tabs from sidebar to top navbar, right panel always visible (`5256f14`)
- **Graph wikilink visualization**: Graph shows all wikilinks with entity type filter toggles (`28e8e3b`)
- **Obsidian-style local graph**: Replaced global graph with focused local graph per entity (`1a8ce5d`)

### Changed

- **Sidebar alphabetical sorting**: Moved Konzepte tab after Trends, sidebar entries sorted alphabetically (`281631f`)
- **Graph node labels**: All nodes now display entity names (not just center node); neighbors use lighter secondary text with 20-char truncation

### Fixed

- **Version alignment**: Synchronized version across plugin.json, CLAUDE.md, marketplace.json, and README.md

## [4.3.16] - 2026-02-04

### Changed

- **synthesis-hub: Phase-4a always executes + hub file rename** (v2.4.0)
  - Renamed output file: `research-report.md` → `research-hub.md`
  - Renamed workflow file: `phase-4a-synthesis-generic.md` → `phase-4a-synthesis-hub-cross.md`
  - Phase-4a now ALWAYS executes (generates 6-file hub ecosystem)
  - Phase-4b conditionally executes if arc_id exists (enhances synthesis-cross-dimensional.md + creates insight-summary.md)
  - Updated frontmatter: `hub_version: "3.0"`, `type: "hub-catalog"`
  - Updated all references throughout codebase from research-report → research-hub
  - Files modified:
    - `synthesis-hub/SKILL.md`: Sequential phase-4a/4b execution logic (lines 218-254)
    - `synthesis-hub/references/phase-workflows/phase-4a-synthesis-hub-cross.md`: File renamed and updated
    - `synthesis-hub/references/phase-workflows/phase-5-validation.md`: Updated validation checks
    - `CHANGELOG.md`: Updated all historical references
    - Documentation files: Updated wikilink references

### Rationale

- "Hub" better describes the file's role as navigation catalog vs. full report
- Always executing phase-4a ensures consistent 6-file ecosystem for every project
- Arc enhancement (phase-4b) becomes optional additive layer
- Naming emphasizes hub-and-spoke architecture + cross-dimensional synthesis

## [4.3.15] - 2026-02-02

### Changed

- **synthesis-hub: Enhanced pipeline metrics visibility**: Total wikilinks now prominently displayed in Pipeline Summary section (v2.2.1)
  - Added "Total Wikilinks: N" line to Pipeline Summary
  - Clarified "Entities Cited" to show "unique entities" for clarity
  - Preserves detailed wikilink breakdown in Wikilink Density subsection
  - Improves metric visibility without structural changes
  - Files modified:
    - `synthesis-hub/references/phase-workflows/phase-5-validation.md`: Added LABEL_TOTAL_WIKILINKS and updated pipeline summary output
    - `synthesis-hub/references/templates/generic-report.md`: Updated example with prominent total wikilinks display
    - `synthesis-hub/IMPLEMENTATION_NOTES.md`: Added v2.2.1 implementation notes

## [4.3.14] - 2026-02-02

### Changed

- **synthesis-hub: Added appendix structure to dimension synthesis output** (v2.2.0)
  - Dimension synthesis files now include Research Scope appendix with full pipeline metrics table
  - Enhanced Phase 5 validation with 12-phase pipeline table, entity statistics, and wikilink density breakdown
  - Added language-aware labels for bilingual EN/DE support
  - Full pipeline metrics now visible in both hub (research-hub.md) and spoke (dimension synthesis) outputs

## [4.3.13] - 2026-02-02

### Added

- **synthesis-hub: Full pipeline metrics in research-hub.md** (v2.2.0)
  - Added comprehensive 12-phase pipeline table showing Generated/Used/Coverage for all entity types
  - Added entity statistics breakdown (dimensions, trends, megatrends, concepts, citations)
  - Added wikilink density analysis (total + breakdown by type)
  - Integrated into Research Scope appendix with {STATISTICS_PLACEHOLDER} replacement
  - Bilingual support (EN/DE) for all metric labels and headers

## [4.3.12] - 2026-02-02

### Fixed

- **export-html-report: Preserve escaped pipes in wikilinks for Obsidian compatibility**
  - Fixed regex to preserve `\|` in wikilink display text (e.g., `[[path\|Display]]`)
  - Prevents mangled HTML output when Obsidian-escaped pipes are present
  - Updated markdown-to-html.sh to handle both escaped and unescaped pipe formats

## [4.3.11] - 2026-02-02

### Fixed

- **cogni-research: Repair wikilinks and fix citation publisher matching**
  - Fixed broken wikilink format from `[[../06-megatrends/megatrend-slug.md|Display]]` to `[[06-megatrends/megatrend-slug.md|Display]]`
  - Removed invalid `../` parent references that break Obsidian navigation
  - Fixed citation-to-publisher matching to use basename comparison (handle relative vs absolute paths)
  - Updated `synthesis-dimension/references/phase-workflows/phase-5-validation.md`
  - Updated `synthesis-hub/references/phase-workflows/phase-5-validation.md`

## [4.3.4] - 2026-02-02

### Fixed

- **Wikilink generation in synthesis templates**: Updated synthesis templates to include wikilinks for concepts, trends, claims, and megatrends mentioned in narrative text
  - Updated `synthesis-dimension/references/templates/synthesis-template-generic.md`: Added wikilink examples in Executive Summary and Domain Concepts sections
  - Updated `synthesis-hub/references/templates/generic-report.md`: Added wikilink guidance in Executive Summary with examples
  - Updated `synthesis-dimension/SKILL.md`: Added wikilink requirement to Phase 4 synthesis generation instructions
  - Updated `synthesis-hub/references/phase-workflows/phase-4-synthesis-generic.md`: Added wikilink writing standard
  - Fixed trailing backslash issue in kanban table wikilinks (markdown pipe escaping conflict)
  - All future synthesis generation now automatically includes wikilinks using format: `[[entity-path|Display Title]]`

### Changed

- **Synthesis regeneration approach**: Instead of retroactively fixing existing files with audit scripts, templates now generate wikilinks automatically during synthesis creation
  - Cleaner approach: Regenerate with updated templates rather than retroactive fixing
  - Consistent quality: All syntheses use same wikilink logic from templates
  - Future-proof: All future projects automatically include wikilinks

## [4.3.3] - 2026-02-02

### Added

- **Wikilink audit tool for synthesis files**: Automated detection and fixing of missing wikilinks
  - New scripts in `skills/research-editor/scripts/`:
    - `audit-wikilinks.sh`: Main orchestrator with report and auto-fix modes
    - `build-entity-registry.sh`: Scans project to build searchable entity catalog
    - `extract-concepts.sh`: Extracts narrative sections from synthesis files
    - `fuzzy-match.sh`: Multi-pass concept detection with exact matching
    - `generate-wikilinks.sh`: Applies wikilink fixes with backup protection
    - `utils/levenshtein.sh`: String distance calculator for fuzzy matching
    - `utils/language-detector.sh`: Detects English vs German content
  - Audit report generation in `.logs/wikilink-audit-report-YYYYMMDD-HHMMSS.md`
  - Backup protection: Creates `.backups/` before file modification
  - Command-line options: `--fix` (auto-fix mode), `--scope` (all|hub|dimensions)
  - First-mention-only wikilink insertion per section
  - Excludes frontmatter, Domain Concepts, References, and Evidence Assessment tables
  - Documentation: `skills/research-editor/references/wikilink-audit.md`

- **Wikilink guidance in synthesis templates and prompts**:
  - Updated `synthesis-dimension/references/templates/synthesis-template-generic.md` with wikilink examples
  - Updated `synthesis-hub/references/templates/generic-report.md` with wikilink examples
  - Updated `synthesis-dimension/SKILL.md` Phase 4 with wikilink requirement
  - Updated `synthesis-hub/references/phase-workflows/phase-4-synthesis-generic.md` with wikilink writing standard

### Impact

- **Enhanced Knowledge Graph**: Synthesis files now properly link to concept entities for improved Obsidian navigation
- **Automated Quality Control**: Missing wikilinks detected and fixed automatically
- **Template Future-Proofing**: Future synthesis generation includes wikilinks from the start
- **Traceability**: Full backup and audit trail for all wikilink modifications

## [4.3.2] - 2026-02-02

### Added

- **Mandatory planning_horizon for all trend entities**: Extended planning horizon classification from smarter-service to ALL research types
  - Created trend-entity.schema.json with mandatory `planning_horizon` field (act|plan|observe)
  - Added Step 2.5 "Compute Planning Horizon Classification" to phase-4-synthesis-standard.md
  - Evidence-based classification algorithm: avg claim confidence + proven implementations + timeframe signals
  - Time-based criteria aligned with megatrends: act (0-6mo), plan (6-18mo), observe (18+mo)
  - Updated validation workflow to check planning_horizon presence and valid enum values
  - Export tools now read planning_horizon unconditionally with backward compatibility (default to 'plan')
  - Updated SKILL.md documentation removing "Only for smarter-service" comment (line 514)

### Changed

- **trends-creator workflow**: Renumbered Step 2.5 → 2.6 (quality scores) to accommodate new planning horizon step
- **Gate Check #2**: Added verification for planning horizon classification completion
- **Gate Check #3**: Added verification for planning_horizon field presence and valid values
- **export_html.py**: Added backward compatibility for missing planning_horizon field, defaults to 'plan' with warning

### Impact

- **Universal Classification**: All trends now have actionable timeline classification regardless of research type
- **Backward Compatible**: Existing projects without planning_horizon will continue to work with default 'plan' value
- **Enhanced Filtering**: Export tools can now filter/sort trends by horizon across all research types
- **Consistent Architecture**: Trends now follow same planning horizon pattern as megatrends

## [4.3.1] - 2026-02-01

### Changed

- Version bump for arc-specific context loading feature

## [4.3.0] - 2026-02-01

### Added

- **research-editor arc-specific context loading**: Tiered context loading system for research entities
  - Tier 1 (Competitive Intelligence): Executive Summary only (~1,400 tokens)
  - Tier 2 (Corporate Visions): + Trends Act column (~4,000 tokens)
  - Tier 3 (Strategic Foresight, Industry Transformation): + Trends all + Megatrends (~10,000 tokens)
  - Tier 4 (Technology Futures): + Trends Watch+Act + Concepts (~7,000 tokens)
  - Three loading scripts: load-trends.sh, load-megatrends.sh, load-concepts.sh
  - Graceful degradation if entity directories don't exist (returns empty arrays)
  - Context validation in Phase 5 (checks loaded entities match arc requirements)
  - Updated arc definitions with source content mapping examples (4 files)
  - Added context requirements section to arc-registry.md (102 lines)
  - Added Step 3b context loading to phase-2-extract.md (236 lines)
  - Maximum context usage: 10,000 tokens (5% of 200K window)
  - Backward compatible: No breaking changes, Competitive Intelligence unchanged

### Impact

- Corporate Visions "Why Now": Now includes specific deadlines from Trends (e.g., "EU AI Act Q1 2027")
- Strategic Foresight "Signals": Extracts weak signals from Trends Watch column (e.g., "Nordic blockchain pilots 2028-2030")
- Technology Futures "What's Emerging": Maps Concepts + Trends to deployment timelines (e.g., "Federated Learning 2026-2027")

## [4.2.1] - 2026-02-01

### Added

- **research-editor multi-arc system**: Expanded from single story arc to 5 arc types with auto-detection
  - 5 story arcs: Corporate Visions (default), Technology Futures, Competitive Intelligence, Strategic Foresight, Industry Transformation
  - Auto-detection: 3-step algorithm (research_type mapping → content analysis → fallback)
  - Interactive selection: User can confirm or override auto-detected arc with transparent reasoning
  - Arc-specific processing: Extraction, transformation, and validation branching by arc_id
  - Arc registry: Master index at story-arc/arc-registry.md with detection logic
  - Arc definitions: 5 complete arc-definition.md files with metadata, quality gates, German translations
  - Pattern files: 20 element pattern files (4 per arc) with transformation examples
  - Phase modifications: Updated phase-0-init.md (detection + selection), phase-2-extract.md (arc branching), phase-3-transform.md (arc loading), phase-5-validate.md (arc validation)
  - Quality gates: Arc-specific validation rules in quality/arc-specific-quality-gates.md
  - Backward compatible: Corporate Visions remains default, no breaking changes
  - Updated documentation: SKILL.md v2.0.0, README.md with all 5 arc types
  - Deprecated: story-arc-mapping.md marked deprecated with migration notice

## [4.2.0] - 2026-02-01

### Added

- **research-editor skill**: Transform synthesis-hub's academic Executive Summary into compelling 2-3 page journalistic narrative
  - Story arc transformation: Why Change → Why Now → Why You → Why Pay (1,450-1,900 words)
  - Journalistic techniques: Inverted Pyramid, Number Plays, Power Words, active voice (80%+ target)
  - Zero-question approach: Auto-configures from sprint-log.json, single consent question
  - Language support: English + German (with mandatory umlaut preservation)
  - Quality gates: 5-dimension self-assessment (lead strength, evidence quality, number plays, story arc, scannability)
  - Preservation-first: Never corrupts citations, German characters, diagrams, or wikilinks
  - Non-destructive: Creates .research-hub.md.backup before writing
  - Graceful degradation: Optional copywriter polish (Phase 4) with fallback to unpolished output
  - Replaces Executive Summary section in research-hub.md with Management Summary
  - Compatible with export-html-report and export-rag (no breaking changes)
  - Comprehensive documentation: 12 reference files (~41,000 words)

## [4.1.33] - 2026-02-01

### Fixed

- **synthesis-hub wikilink pipe escaping**: Fixed broken wikilinks in research report trend tables
  - Corrected algorithm instructions (lines 338, 353) to use escaped pipes `\|` instead of unescaped `|`
  - Updated cell format rules (lines 366-367) for consistency with template examples
  - Added explicit "CRITICAL: Pipe Escaping in Markdown Tables" documentation note
  - Updated phase-5-validation.md format example for megatrends
  - Prevents table rendering breakage in Obsidian when wikilinks contain display text

## [4.2.0] - 2026-01-31

### Added

- **Wikilink Generation Protocol (Pattern 6)**: Comprehensive prevention system for broken wikilinks
  - Added wikilink format validation sections to 5 agent prompts (citation-generator, findings-creator, trends-creator, knowledge-merger, knowledge-extractor)
  - New Pattern 6 in anti-hallucination-foundations.md with complete validation protocol
  - Enhanced entity-schema-guide.md with prominent wikilink format requirements section
  - Added LLM artifact detection to validate-wikilink-format.sh (v1.1.0):
    - Detects trailing backslashes (JSON escaping artifacts)
    - Detects trailing spaces (formatting artifacts)
    - Detects .md extensions (path completion artifacts)
  - Enhanced post-write-validate-wikilinks.sh (v3.0.1) with specific error messages for common LLM artifacts

### Fixed

- **Root cause of broken wikilinks**: Agents now required to:
  1. Read entity-index.json BEFORE generating any wikilinks
  2. Validate format matches `[[NN-type/data/slug-hash]]` pattern
  3. Check for trailing backslashes, spaces, and .md extensions
  4. Verify entity existence before creating wikilinks
- Prevention targets 81 auto-repairable trailing backslash errors and 80 manual review cases

### Changed

- Agent prompts now include mandatory wikilink validation requirements
- All agents must delegate to skills with entity-index.json pre-loading
- Post-write hook provides actionable error messages for specific artifact types

## [4.1.0] - 2026-01-19

### Added

- **publisher-generator two-phase architecture (v4.0)**: Scalable batch processing for large projects
  - **Phase A (Atomic Creation)**: New `create-publishers-batch.py` script creates all publisher skeletons with single atomic entity-index.json write
  - **Phase B (Parallel Enrichment)**: New `--enrich-only --files` mode enables parallel agent enrichment without index race conditions
  - New `--batch-mode` flag for orchestration agent (recommended for 100+ sources)
  - Performance: ~4 minutes for 200+ publishers (7x speedup vs sequential)
  - Added `batch_add_entities_to_index()` to entity_index.py

### Changed

- **deeper-research-2 Phase 6**: Deprecated parallel execution with `run_in_background=true`
  - Sequential `--all` flag now recommended for under 100 sources
  - Batch mode recommended for 100+ sources

## [4.0.0] - 2025-01-19

### Changed
- **BREAKING:** Split deeper-research-1 into deeper-research-0 and deeper-research-1
  - deeper-research-0: Phases 0-2.5 (project initialization, question refinement, dimensional planning, megatrend validation, batch creation)
  - deeper-research-1: Phase 3 only (parallel findings creation)
- Updated all internal component references to point to correct parent skill
- Updated plugin.json to register deeper-research-0 as first skill

## [3.67.0] - 2026-01-15

### Fixed

- **Backfill CHANGELOG for v3.66.0**: Added missing changelog entry for dimension_affinity feature

## [3.66.0] - 2026-01-15

### Changed

- **Explicit dimension_affinity in all megatrend templates**: All megatrend creation workflows now populate `dimension_affinity` field
  - knowledge-extractor Phase 5: Generic and TIPS templates include dimension_affinity from majority vote
  - knowledge-merger Phase 3: Seed megatrends get dimension_affinity from seed config; clustered megatrends use majority vote
  - Ensures all megatrends (seeded AND clustered) have lead dimension assignment for proper kanban board display

## [3.65.0] - 2026-01-15

### Fixed

- **Megatrends missing from kanban board**: Megatrends without explicit `dimension_affinity` now appear in Research Landscape
  - Added `infer_megatrend_dimension()` helper with 3 fallback methods:
    1. Direct `dimension_affinity` metadata field
    2. `dimension/` tag prefix extraction
    3. Majority vote from linked findings' dimensions
  - Observe horizon column now correctly shows megatrends with `observe` planning_horizon

## [3.64.0] - 2026-01-15

### Changed

- **Replaced radar with kanban board**: Research Landscape visualization now uses a kanban-style grid
  - Rows = Research Dimensions (color-coded)
  - Columns = Planning Horizons (Act/Plan/Observe)
  - Megatrends and Trends displayed as cards in cells

## [3.61.0] - 2026-01-15

### Added

- **Figure hover zoom effect**: Figures in HTML reports now scale up on hover for better inspection
  - SVG embeds and Mermaid diagrams scale to 115% on hover
  - Smooth 0.3s transition animation
  - Cursor changes to zoom-in for visual feedback

## [3.57.0] - 2026-01-15

### Changed

- **HTML report responsive width**: Main content area now adapts to available screen width
  - Changed `max-width` from fixed `1000px` to fluid `min(1400px, calc(100vw - 360px))`
  - On 1920px displays: content expands to 1400px (vs fixed 1000px before)
  - Improves reading experience on wider screens while capping at 1400px for readability

## [3.50.0] - 2026-01-15

### Fixed

- **Stale references after synthesis-hub consolidation**: Updated broken links to deleted phase-4 files
  - Fixed `PROPAGATION-PROTOCOL.md` references (3 occurrences)
  - Fixed `trends-creator/phase-4-synthesis-customer-value-mapping.md` link to synthesis-hub
  - Updated `DEVELOPMENT-KIT.md` to reflect consolidated architecture

## [3.49.0] - 2026-01-15

### Changed

- **synthesis-hub Phase 4 consolidation**: All research types now use single generic workflow
  - Removed `phase-4-synthesis-smarter-service.md`
  - Removed `phase-4-synthesis-lean-canvas.md`
  - Removed `phase-4-synthesis-b2b-ict-portfolio.md`
  - Removed `phase-4-synthesis-customer-value-mapping.md`
  - All types now route to `phase-4a-synthesis-generic.md` (generic) or `phase-4b-synthesis-{arc_id}.md` (arc-specific)
  - SKILL.md Phase 4 section simplified from routing table to single reference

## [3.22.0] - 2026-01-14

### Fixed

- **Phase 11 diagram generation**: Updated Task invocation pattern to properly trigger diagram-expert automated mode
  - Added explicit `DIAGRAM_ID` parameter in prompt (triggers automated mode)
  - Clarified that `OUTPUT_PATH` must be absolute directory path
  - Added documentation for critical parameters required for automated mode

## [3.3.16] - 2026-01-13

### Fixed

- **dimension-planner SKILL.md misleading Phase 4b instructions**: Fixed instructions that told sub-agent to do user validation
  - Removed "User Validation: Present seeds for user approval" step (sub-agents cannot use AskUserQuestion)
  - Added explicit warning: "NO USER INTERACTION: dimension-planner runs as a sub-agent"
  - Clarified that user validation happens in deeper-research-1 Phase 2b AFTER agent completes
  - Updated required outputs to show `user_validated: false` and `pending_validation: true`

## [3.3.15] - 2026-01-12

### Fixed

- **Phase 2b AskUserQuestion skipped**: Fixed critical bug where Phase 2b (megatrend user validation) was never executed
  - Root cause: `phase-4b-megatrend-proposal.md` Step 4.2 Output Format showed `user_validated: true` instead of `false`
  - dimension-planner wrote seeds with `user_validated: true`, causing deeper-research-1 to skip Phase 2b
  - Fixed Step 4.2 template to show `user_validated: false` (pending orchestrator validation)
  - Fixed per-seed `user_validated` to `false` (pending user confirmation)
  - Fixed `proposed_by: "user"` → `"llm"` (at this stage all seeds are LLM-proposed)

## [3.3.14] - 2026-01-12

### Fixed

- **Phase 2b orchestrator routing not triggered**: Fixed critical issue where deeper-research-1 never called Phase 2b after dimension-planner returned
  - Root cause: `phase-2-dimensional-planning.md` was only 15 lines and had no routing logic for Phase 2b
  - Expanded to ~80 lines with full Phase 2b routing based on `seed_megatrends.pending_validation`
  - Orchestrator now checks dimension-planner response for seed megatrends and triggers Phase 2b

- **workflow-overview.md missing Phase 4b**: Fixed workflow diagram that showed Phase 4 → Phase 5 directly
  - Added Phase 4b routing section with generic/smarter-service vs lean-canvas/b2b-ict-portfolio branching
  - Updated Phase Loading Guide table to include Phase 4b and Phase 6
  - Added Phase 4b Note explaining sub-agent/orchestrator responsibility split

- **phase-5-entity-creation.md return JSON missing seed_megatrends**: Fixed Phase 5.4 response format
  - Added Extended Response section for generic/smarter-service with `seed_megatrends` object
  - Added Response Fields table documenting all fields including conditional `seed_megatrends`
  - Added integration note explaining deeper-research-1 Phase 2b trigger

- **RUNTIME-CHECKLIST.md missing Phase 4b and Phase 6**: Fixed runtime checklist that jumped from Phase 4 to Phase 5
  - Added Phase 4b section with 4 sub-phases (4b.1-4b.4)
  - Added Phase 6 section with 4 sub-phases (6.1-6.4)
  - Updated version to 1.2 with Phase 4b + Phase 6

### Changed

- **deeper-research-1/phase-2-dimensional-planning.md**: Expanded from 15 to 163 lines
  - Added verification checksum `DIMENSIONAL-PLANNING-V2`
  - Added Step 2 with response validation and seed megatrend detection
  - Added Step 3 with conditional Phase 2b execution logic
  - Added Expected Response Format section with field documentation
  - Added Phase 2b Trigger Conditions section

- **dimension-planner/workflow-overview.md**: Updated diagram and version
  - Diagram now shows 7 sequential phases (0-6) instead of 6
  - Version updated to 2.1 (Phase 4b Integration)

- **dimension-planner/RUNTIME-CHECKLIST.md**: Updated version and scope
  - Version updated to 1.2 (Phase 4b + Phase 6)
  - Now tracks phases 0-6 with Phase 4b conditionals

## [3.3.13] - 2026-01-12

### Fixed

- **Phase 4b megatrend proposal not executing**: Fixed workflow routing that skipped Phase 4b entirely
  - Root cause: phase-4-validation.md ended with "Proceed to Phase 5" with no mention of Phase 4b
  - dimension-planner SKILL.md documented Phase 4b but workflow files bypassed it

### Added

- **phase-4-validation.md**: Added "Phase 4b/5 Routing" section after Phase 4.6
  - Route A: Execute Phase 4b for `generic`/`smarter-service` research types
  - Route B: Skip Phase 4b for `lean-canvas`/`b2b-ict-portfolio`

- **phase-5-entity-creation.md**: Added Phase 4b gate check in Phase 5.0.2
  - Verifies `seed-megatrends.yaml` exists for applicable research types
  - Prevents proceeding without megatrend seeds

- **phase-2b-megatrend-validation.md**: New orchestrator phase in deeper-research-1
  - Handles user validation of seed megatrends via AskUserQuestion
  - dimension-planner (sub-agent) cannot use AskUserQuestion, so validation moved to orchestrator
  - Executes between Phase 2 and Phase 2.5

### Changed

- **phase-4b-megatrend-proposal.md**: Removed user interaction, now generates seeds with `user_validated: false`
  - Sub-agents cannot use AskUserQuestion tool
  - User validation handled by deeper-research-1 Phase 2b

- **deeper-research-1/SKILL.md**: Added Phase 2b section for megatrend seed validation
  - Conditional execution for `generic`/`smarter-service` research types

## [3.3.12] - 2026-01-12

### Fixed

- **Findings output localization**: Fixed hardcoded English section headers in finding entities
  - findings-creator-llm: 5-section template now uses `{HEADER_CONTENT}`, `{HEADER_KEY_INSIGHTS}`, etc.
  - findings-creator-smarter-service: Same 5-section template variables
  - findings-creator phase-4-finding-extraction.md: Updated language-aware header table
  - finding-quality-standards.md: Updated comprehensive template reference

- **Synthesis output localization**: Fixed hardcoded English section headers in synthesis documents
  - synthesis-hub generic-report.md: All section headers now use template variables
  - synthesis-dimension template: All section headers and table headers now use variables
  - synthesis-dimension SKILL.md: Updated example structure
  - synthesis-dimension phase-4-synthesis.md: Updated example to use `{HEADER_KEY_INSIGHTS}`
  - export-html-report entity-formats.md: Updated finding body format

### Added

- **language-templates.md**: New header sections for synthesis and findings
  - `12-synthesis (Hub Report)`: 22 variables for research-hub.md headers
  - `04-findings`: Added `HEADER_CONTENT`, `HEADER_RELEVANCE_ASSESSMENT` variables

## [3.3.11] - 2026-01-12

### Fixed

- **Megatrend UI localization**: Fixed hardcoded English strings for German language support
  - Phase 4b proposal (dimension-planner): Added ~23 template variables for user-facing seed proposal UI
  - Phase 5 gap report (knowledge-extractor): Added ~10 template variables for coverage reporting
  - All strings now use language template variables from `language-templates.md`

- **knowledge-extractor SKILL.md**: Updated Phase 5 description to reflect v3.3.9+ dual-source synthesis
  - Was: Simple keyword extraction (outdated v3.3.5 logic)
  - Now: Documents seed loading, dual-source matching, TIPS narrative generation, gap reporting

### Added

- **language-templates.md**: New UI string sections for megatrend workflows
  - `06-megatrends UI Strings (Phase 4b Proposal)`: 23 variables for seed proposal workflow
  - `06-megatrends UI Strings (Phase 5 Gap Report)`: 13 variables for gap reporting

## [3.3.10] - 2026-01-12

### Fixed

- **Phase 4b workflow integration**: Added missing Phase 4b execution section to dimension-planner SKILL.md
  - Updated core workflow diagram to show conditional Phase 4b step
  - Added gate checks, execution conditions, and required outputs
  - Documented skip behavior for lean-canvas and b2b-ict-portfolio research types

- **German language support in synthesis-hub**: Fixed hardcoded English in phase-4-synthesis-generic.md
  - Replaced literal classification values with language template variables
  - Added language template reference table for megatrend badges
  - Now uses `{LABEL_SOURCE}`, `{VALUE_SEEDED}`, `{MSG_HYPOTHESIS_WARNING}` etc.

### Added

- **entity-templates.md enhancements**:
  - Expanded field definitions table with missing schema fields (dc:creator, dc:created, dc:type, dc:subject, entity_type, seed_name, parent_megatrend_ref, submegatrend_refs, description)
  - Added "Conditional Requirements" section documenting planning_horizon → possibility structure constraint
  - Added "Seed-to-Megatrend Field Mapping" section explaining how Phase 4b seeds map to megatrend entities
  - Added megatrend confidence score formula: `min(1.0, 0.5 + (finding_count * 0.1) + (claim_count * 0.05))`

- **Planning horizon selection guidance** in phase-4b-megatrend-proposal.md
  - Added Step 2.4 with selection criteria table for act/plan/observe horizons
  - Added examples showing how to classify megatrends by maturity indicators

## [3.3.9] - 2026-01-12

### Added

- **Megatrend entity enhancement**: Elevated megatrends from classification containers to strategic megatrend documents
  - Megatrends now 600-900 words (was 200-300) with TIPS-style narrative (Trend-Implication-Possibility-Solution)
  - Dual-source synthesis: Bottom-up clustering + top-down seed megatrends from expert knowledge
  - Evidence strength classification: strong (5+), moderate (3-4), weak (1-2), hypothesis (0 findings)
  - Planning horizons: act (0-6 months), plan (6-18 months), observe (18+ months)
  - Quality scores: evidence_strength, strategic_relevance, actionability
  - Claim integration support (graceful degradation if unavailable)

- **Seed megatrend proposal phase** (Phase 4b in dimension-planner)
  - LLM proposes 5-10 expected megatrends based on research question and dimensions
  - User validates/modifies/adds custom seeds via interactive feedback loop
  - Validated seeds stored in `.metadata/seed-megatrends.yaml`
  - Validation modes: ensure_covered (warning if gap), must_match (error if gap)

- **New schema**: `schemas/seed-megatrend.schema.json` for seed configuration validation

### Changed

- **megatrend-entity.schema.json**: Added megatrend enrichment fields
  - source_type (clustered/seeded/hybrid), seed_validated, evidence_strength
  - confidence_score, planning_horizon, dimension_affinity, claim_refs
  - strategic_narrative object with TIPS structure
  - quality_scores object

- **phase-5-megatrend-clustering.md** (knowledge-extractor): Complete rewrite for dual-source
  - Step 0: Load seed megatrends from project metadata
  - Step 2: Bottom-up clustering + seed matching and validation
  - Step 3: Generate 600-900 word TIPS strategic narrative
  - Step 5: Validate seed coverage, generate gap report

- **entity-templates.md**: Expanded megatrend template to 600-900 words with TIPS structure

- **phase-4-synthesis-generic.md**: Enhanced megatrend display in research report
  - Megatrend summary table with Source/Evidence/Horizon/Confidence
  - Full TIPS content (Trend/Implication/Possibility/Solution)
  - Visual indicators for hypothesis megatrends
  - Updated word count: 6,000-9,000 words (was 3,000-4,500)

- **language-templates.md**: Added German translations for megatrend sections
  - TIPS headers: Trend/Implikation/Möglichkeit/Lösung
  - Evidence labels: Quelle/Konfidenz/Planungshorizont/Ergebnisabdeckung
  - Classification values: geclustert/vordefiniert/hybrid/stark/moderat/schwach/Hypothese

## [3.3.7] - 2026-01-12

### Fixed

- **findings-creator agent**: Fixed language detection defaulting to English
  - Root cause: Agent defaulted to 'en' when no explicit language parameter passed, ignoring available metadata
  - Added language resolution cascade:
    1. Explicit `language` parameter (if provided)
    2. `content_language` from refined question frontmatter
    3. `project_language` from `.metadata/sprint-log.json`
    4. Final fallback to "en" only if neither source available
  - Updated Phase 1 documentation with bash pattern for language extraction

## [3.3.6] - 2026-01-12

### Changed

- **Phase 4 synthesis workflows**: Propagated generic improvements to all research types
  - Added Research Question section (Step 2.5/3.5) to all phase-4 workflows
  - Added Overarching Themes section (Step 3/3.6) with full megatrend content (200-300 words each)
  - Updated word count targets to accommodate megatrend integration
  - Added `megatrend_count` to YAML frontmatter across all research types
  - Files updated:
    - `phase-4-synthesis-smarter-service.md`: 3200-4100 → 4500-6000 words
    - `phase-4-synthesis-b2b-ict-portfolio.md`: 3500-5000 → 5000-7000 words
    - `phase-4-synthesis-lean-canvas.md`: 2500-3500 → 3500-5000 words (conditional)
    - `phase-4-synthesis-customer-value-mapping.md`: 2000-3000 → 3500-5000 words (conditional)

## [3.3.5] - 2026-01-12

### Changed

- **Megatrend entities**: Expanded from ~50 words to 200-300 words
  - Overview section: 150-200 words (comprehensive synthesis)
  - New Key Themes section: 50-100 words (3-5 sub-themes)
  - Updated `entity-templates.md`, `phase-5-megatrend-clustering.md` (knowledge-extractor), `phase-3-megatrend-clustering.md` (knowledge-merger)

- **Synthesis hub (generic)**: Restructured research-hub.md outline
  - Added Section 2: Research Question (refined question from initial entity)
  - Added Section 3: Overarching Themes (mermaid from megatrends README + full megatrend content)
  - Changed Section 4: Research Dimensions (narrative + mermaid from refined-questions README, removed table)
  - Word count target: 1,500-2,100 → 3,000-4,500 words
  - Updated `phase-4-synthesis-generic.md` and `generic-report.md`

## [3.3.4] - 2026-01-12

### Added

- **validate-wikilinks.sh**: Added `trailing_backslash` error category (v3.2.0)
  - Detects wikilinks with trailing backslashes (common LLM generation artifact)
  - Automatically marks as auto-repairable with correct fix suggestion
  - Added to JSON output and text report broken link categories
- **repair-wikilinks.sh**: Updated documentation for new category (v1.2.0)
  - Added `trailing_backslash` to list of auto-repairable categories
- **trends-creator**: Added wikilink format requirements section
  - Explicit rules for correct wikilink format in Entity Index tables
  - Examples of correct vs incorrect wikilinks (no trailing backslashes)
- **knowledge-merger**: Added wikilink format requirements section
  - Same format requirements as trends-creator
  - Added self-verification question for wikilink format compliance

### Fixed

- Fixed issue where 74 broken wikilinks were detected in deeper-research-3 Phase 12 validation
- Wikilinks like `[[data/trend-abc123\]]` are now auto-repairable to `[[data/trend-abc123]]`

## [3.3.3] - 2026-01-12

### Added

- **synthesis-dimension**: Added multilingual support (English/German)
  - Created `references/language-templates.md` with complete header translations
  - Updated phase-1-setup.md with language loading protocol and validation
  - Updated phase-4-synthesis.md with language-aware section headers
  - Updated synthesis-template-generic.md with language reference and quick reference table
  - Updated SKILL.md with expanded language documentation
  - Matches pattern established by dimension-planner and publisher-generator

## [3.3.0] - 2026-01-12

### Changed

- **Skill Rename**: Renamed findings creator skills for consistency
  - `llm-findings-creator` → `findings-creator-llm`
  - `smarter-service-findings-creator` → `findings-creator-smarter-service`
  - Updated all agents, skills, plugin.json, phase-3 workflow, and documentation
  - Naming now follows `findings-creator-{source}` pattern for all findings creators

## [3.2.0] - 2026-01-12

### Changed

- **Skill Rename**: Renamed synthesis skills for clarity
  - `dimension-synthesis-creator` → `synthesis-dimension`
  - `synthesis-creator` → `synthesis-hub`
  - Updated all agents, skills, plugin.json, hooks, contracts, and documentation
  - Hub-and-spoke naming now reflects architecture: hub aggregates, dimension provides depth

## [3.1.1] - 2026-01-12

### Removed

- **dimension-synthesizer**: Removed deprecated skill
  - Superseded by `synthesis-dimension` (introduced in v1.10.0)
  - Removed agent, skill directory, and all references from plugin configuration
  - Updated documentation: wrapper-agent-patterns.md, research-types/README.md, model-recommendation.md

## [1.10.3] - 2026-01-11

### Fixed

- **deeper-research-2**: Fixed zsh shell compatibility issue (v1.10.3)
  - Converted inline bash with `$()` command substitution to temp script pattern
  - Fixed ENTRY GATE section to use `/tmp/dr2-entry-gate.sh` wrapper
  - Fixed Input: Project Path section to use `/tmp/dr2-get-project.sh` wrapper
  - Added shell compatibility note referencing `references/shell-compatibility.md`
  - Resolves `(eval):1: parse error near '('` error on macOS zsh

## [1.10.2] - 2026-01-11

### Added

- **export-html-report**: Added dimension synthesis support (v1.10.2)
  - HTML reports now include `synthesis-*.md` files from `11-trends/` directory
  - New "Dimension Syntheses" section appears after Trends in TOC and report
  - Synthesis cards display dimension, trend count, average confidence, and word count badges
  - Wikilink hover previews show synthesis metadata and excerpt
  - CSS styling with accent border and tertiary background for synthesis cards
  - Updated SKILL.md documentation with synthesis entity type

## [1.10.1] - 2026-01-11

### Fixed

- **synthesis-dimension**: Clarified documentation
  - Added explicit instruction to load ALL dimension-scoped claim_refs in Phase 2
  - Added strategic_score calculation table (0.0-1.0 scale) in Phase 3
  - Documented pre-existing synthesis overwrite behavior
  - Updated regex patterns for dimension slug validation

## [1.10.0] - 2026-01-11

### Added

- **synthesis-dimension**: New skill for rich dimension narratives
  - Transforms basic dimension-scoped trend collections into comprehensive synthesis documents (800-1,200 words)
  - 5-phase workflow: Setup, Entity Loading, Pattern Analysis, Synthesis Generation, Validation
  - Evidence-based narratives with cross-trend connection analysis
  - Complete citation provenance (dual format: numbered links + wikilinks)
  - Evidence quality metrics and anti-hallucination architecture
  - Integrated into deeper-research-3 as Phase 8.5 (parallel execution per dimension)

## [1.9.9] - 2026-01-11

### Changed

- **smarter-service-findings-creator**: Removed authentication phase (v1.1.0)
  - Custom GPTs work without login - authentication is not required
  - Reduced from 7-phase to 6-phase workflow
  - Removed Phase 2 (Authenticate to ChatGPT)
  - Removed `AUTH_REQUIRED` and `AUTH_EXPIRED` error codes
  - Updated chatgpt-selectors.md to remove auth detection selectors

## [1.9.8] - 2026-01-11

### Added

- **Language-aware section headers**: Entity templates now support localized headings (en/de)
  - New file: `references/language-templates.md` - Central reference for all header translations
  - Updated 8 skill/reference files with language header tables
  - Affects all 12 entity types (00-initial-question to 11-trends)

### Changed

- **trends-creator**: Added language header table (Context→Kontext, Evidence→Beweise, etc.)
- **phase-4-synthesis-standard.md**: Added language tables and German text formatting rules
- **phase-4-synthesis-tips.md**: Added language table (TIPS framework sections stay English)
- **knowledge-extractor**: Added language tables for concepts & megatrends
- **findings-creator**: Added language header table for findings
- **dimension-planner**: Added language tables for dimensions & refined questions
- **citation-generator**: Added language tables and date formatting rules
- **template-entity-pipeline.md**: Added Language Support section with localization rules

### Localization Rules

- Section headings are localized to project language
- Body text uses proper umlauts (ä, ö, ü, ß) in German
- Entity IDs and filenames use ASCII transliterations (ue, ae, oe, ss)
- Framework terms (TIPS, MECE, SWOT) remain in English

## [1.9.7] - 2026-01-10

### Added

- **User documentation**: Created comprehensive functional overview for B2B marketing managers
  - New file: `docs/user/functional-overview.md` (~2,100 words)
  - Explains Deeper Research methodology in accessible, non-technical language
  - Covers: trust architecture, three-phase process, anti-hallucination controls
  - Includes engagement model (managed service vs. internal deployment)
  - References German Mittelstand expert network

- **Visual diagrams**: Added consulting-style SVG diagrams for documentation
  - `docs/user/assets/three-phase-process.svg` - Foundation → Structure → Finishing flow
  - `docs/user/assets/trust-architecture.svg` - Five-layer verification stack

- **Documentation brief**: Added `docs/user/documentation-brief.md` for future doc maintenance

### Changed

- **Implementation Details section**: Added new section explaining Claude Code plugin architecture and research algorithm for technical evaluators

## [1.9.6] - 2026-01-02

### Fixed

- **zsh compatibility:** Convert Phase 1 validation blocks in findings-creator to temp script pattern
  - Parameter validation (lines 290-366) now uses `/tmp/validate-findings-params.sh`
  - Batch validation (lines 379-431) now uses `/tmp/validate-batch.sh`
  - Follows shell-compatibility.md patterns established in v1.9.4

- **PRE-VALIDATION GATE messaging:** Improved error messages with visual box formatting
  - Clear line number references (Step 0.1 at line ~145)
  - Explicit "DO NOT SKIP" language to prevent LLM from bypassing parameter extraction

### Technical Details

Addresses two bash errors:
1. Exit code 112: LLM skipping Step 0.1 parameter extraction before Phase 1 validation
2. zsh inline execution parse errors from complex bash blocks

Pattern: Complex bash with `$()` substitutions and nested if/then/else now written to temp scripts and executed via `bash /tmp/script.sh` for cross-shell compatibility.

## [1.3.4] - 2025-11-24 (Sprint 349)

### Changed

- **BREAKING:** Renamed `domain-synthesizer` to `dimension-synthesizer` for semantic clarity
  - Skill directory: `skills/domain-synthesizer/` → `skills/dimension-synthesizer/`
  - Agent file: `agents/domain-synthesizer.md` → `agents/dimension-synthesizer.md`
  - Output files: `domain-findings-*.md` → `dimension-findings-*.md`
  - Updated 15+ references across codebase (plugin.json, deeper-synthesis, documentation)

### Added

- **Reference organization improvement:** Reorganized dimension-synthesizer references into phase-workflows/ pattern
  - Created `references/phase-workflows/` directory with phase-N-*.md files (5 phases + README)
  - Added navigation README for phase references
  - Split implementation-patterns and validation-protocol by phase
  - Maintains progressive disclosure architecture
  - Total: 7 files (~58KB) organized by workflow phase

### Migration Guide

**Agent invocations:**
- Update: `cogni-research:domain-synthesizer` → `cogni-research:dimension-synthesizer`

**Output file references:**
- Update glob patterns: `domain-findings-*.md` → `dimension-findings-*.md`
- executive-synthesizer Phase 4 updated to load dimension-findings files

**Reference paths:**
- Old: `domain-synthesizer/references/*.md` (flat topic-based)
- New: `dimension-synthesizer/references/phase-workflows/*.md` (hierarchical phase-based)
- SKILL.md now references phase-workflow files for progressive disclosure

### Rationale

- **Semantic clarity:** "dimension" is more accurate than "domain" for dimension-scoped synthesis
- **Consistency:** Aligns with executive-synthesizer's phase-workflow reference organization
- **Maintainability:** Phase-based organization improves long-term maintainability

### Files Modified

- plugin.json - 2 entries updated (agents + skills arrays)
- deeper-synthesis/references/phase-workflows/phase-8-synthesis-pipeline.md - 10 occurrences updated
- executive-synthesizer Phase 4 data loading - glob pattern updated
- 11+ documentation files - cross-references updated (READMEs, docs, examples)
- Cross-plugin references: workplace-manager, issue templates

### Files Created

- dimension-synthesizer/SKILL.md (12KB)
- dimension-synthesizer/references/phase-workflows/README.md (4.4KB)
- dimension-synthesizer/references/phase-workflows/phase-1-setup.md (6.4KB)
- dimension-synthesizer/references/phase-workflows/phase-2-mapping.md (6.2KB)
- dimension-synthesizer/references/phase-workflows/phase-3-loading.md (12KB)
- dimension-synthesizer/references/phase-workflows/phase-4-synthesis.md (12KB)
- dimension-synthesizer/references/phase-workflows/phase-5-validation.md (10KB)
- dimension-synthesizer/references/citation-registry.md (7.5KB)
- agents/dimension-synthesizer.md (11KB)

## [1.3.3] - 2025-11-24 (Sprint 348)

### Removed

- **dimension-synthesizer agent and skill:** Deprecated and removed to simplify synthesis workflow
- **Phase 8.2 (Dimension Analysis):** Removed from deeper-synthesis workflow
- **Component files:** Deleted dimension-synthesizer agent (346 lines) and skill directory (13 files)

### Changed

- **deeper-synthesis workflow:** Simplified Phase 8 - removed dimension synthesis step
- **Phase renumbering:** Phase 8.3 → 8.2 (Evidence Synthesis), Phase 8.4 → 8.3 (Executive Synthesis)
- **plugin.json:** Removed dimension-synthesizer from agents and skills arrays
- **Documentation:** Updated cross-references across 26 files (validation scripts, templates, READMEs)

### Context

- Sprint 348 removed dimension-synthesizer to streamline synthesis pipeline
- The dimension synthesis functionality was replaced by simplified workflow in Phase 8
- No breaking changes to public API - deeper-synthesis remains functional

### Impact

- **Simplified workflow:** One less synthesis phase to execute
- **Reduced complexity:** Fewer agent invocations in synthesis pipeline
- **Maintained quality:** Core synthesis functionality preserved

### Files Modified

- deeper-synthesis/SKILL.md - Phase 8.2 removed, phases renumbered
- phase-workflows/phase-8-synthesis-pipeline.md - Phase 8.2 section deleted (~175 lines)
- agent-invocation-patterns.md - dimension-synthesizer patterns removed
- plugin.json - 2 entries removed (agents + skills arrays)
- 26 documentation files - cross-references updated

### Files Deleted

- agents/dimension-synthesizer.md (346 lines)
- skills/dimension-synthesizer/ (13 files including SKILL.md, references/)

## [1.3.2] - 2025-11-20 (Sprint 287)

### Changed

- **Error handling enhancement:** Added explicit error handling to 16 script calls across 9 skills
- **Improved robustness:** Script exit codes now checked with `||` operators
- **Better debugging:** Descriptive error messages added following be-clear-and-direct.md principles
- **Standards compliance:** Implements script-interface-standards.md Step 5 (validate execution)

### Context

- Sprint 287 resolved 17 WARNING issues identified in Sprint 275 prompt-contract audit
- Validation status improved from PASS (17 warnings) to PERFECT (0 warnings)
- All scripts already function correctly; this improves error visibility and debugging

### Impact

- **No breaking changes:** Only successful execution paths unaffected
- **Better error reporting:** Failures now include script name, operation, and impact
- **Easier debugging:** Clear error messages guide troubleshooting

### Files Modified

- log-analyzer/SKILL.md (3 script calls)
- test-cogni-research/SKILL.md (5 script calls)
- deeper-synthesis/SKILL.md (2 script calls)
- query-builder/SKILL.md (1 script call)
- deeper-analysis/SKILL.md (1 script call)
- dimension-planner/SKILL.md (1 script call)
- evidence-synthesizer/SKILL.md (1 script call)
- publisher-generator/SKILL.md (1 script call)
- research-executor/SKILL.md (1 script call)

### Migration Notes

- No action required - backward compatible enhancement
- Error handling makes failures more explicit but doesn't change success behavior

## [1.3.1] - 2025-11-18 (Sprint 266)

### Changed
- **Skill renaming:** Improved clarity and conciseness of skill names
  - `deeper-research-collect` → `deeper-analysis`
  - `deeper-research-synthesize` → `deeper-synthesis`
- **Documentation updates:** Updated all cross-references across agents, skills, and plugin configuration
- **Git history:** Preserved via `git mv` for renamed directories

### Rationale
- Shorter, more intuitive skill names
- Better alignment with skill purpose (analysis vs. collection)
- Improved user experience for skill invocation
- No functional changes - pure refactoring

### Migration Notes
- Users invoking skills: Update from `deeper-research-collect` to `deeper-analysis`
- Users invoking skills: Update from `deeper-research-synthesize` to `deeper-synthesis`
- All functionality preserved - no breaking changes

## [1.3.0] - 2025-11-18 (Sprint 002)

### Removed
- **data-quality-manager agent:** Removed centralized quality management agent
  - Agent file: `agents/data-quality-manager.md`
  - Skill directory: `skills/data-quality-manager/`
  - Phase 6.1 (Data Quality Assessment) removed from workflow
  - Phase 6.5 (Data Quality Gate) removed from workflow

### Changed
- **Quality management approach:** Transitioned from centralized to distributed quality management
  - Quality checks now handled within individual processing skills (publisher-generator, citation-generator, source-creator)
  - In-process validation replaces post-hoc quality gates
  - Faster feedback loops and more contextual error messages
- **Documentation updates:**
  - Updated `quality-gates.md` to document distributed quality standards
  - Removed Phase 6.1 and 6.5 references from workflow documentation
  - Updated architecture diagrams to reflect streamlined workflow
  - Simplified phase numbering (Phases 0-6, 7-10)

### Rationale
- Quality concerns are better managed within the skills that generate entities
- Eliminates centralized bottleneck in Phase 6
- Reduces complexity and maintenance burden
- Aligns with modern data quality best practices (shift-left testing)
- Publisher-generator, citation-generator, and source-creator already perform validation during entity creation

### Migration Notes
- Existing research projects: No migration required - quality checks now inline
- Plugin users: Update any custom workflows referencing Phase 6.1 or 6.5
- For detailed quality standards, see `references/quality-gates.md`

## [1.2.4] - 2025-11-11 (Sprint 203)

### Removed
- **Citation-manager skill:** Decommissioned unused skill `skills/citation-manager/`
  - Functionality replaced by `publisher-generator` sub-agent (Phase 6) and `citation-generator.sh` script (Phase 6.2)
  - Skill was not invoked in current workflow architecture
- **Related artifacts:**
  - Contract: `contracts/parse-citation-manager-output.yml`
  - Script: `skills/deeper-research/scripts/parse-citation-manager-output.sh`

### Changed
- **Documentation:** Updated architecture diagrams to reflect current workflow (removed outdated citation-manager references)

### Rationale
- Citation management workflow evolved to use specialized components:
  - Publisher creation/enrichment: `publisher-generator` sub-agent with dimension-based partitioning
  - Citation generation: Direct `citation-generator.sh` script invocation
  - Data quality: `data-quality-manager` agent for deduplication and integrity
- Removing unused skill reduces maintenance burden and prevents architectural confusion

## [1.2.3] - 2025-11-08 (Sprint 144)

### Fixed
- **Plugin manifest:** Removed stale reference to deleted `publisher-enricher.md` agent from plugin.json
  - Agent was removed in v1.2.2 but manifest still referenced it, causing plugin validation errors
- **Plugin manifest:** Added missing agent references that existed in directory but were not registered:
  - `data-quality-manager.md` - Source deduplication and integrity management
  - `publisher-generator.md` - Publisher creation and enrichment delegation
  - `test-env-vars.md` - Environment variable validation for plugin operation

### Changed
- **Agent registration:** Plugin manifest now accurately reflects all 15 active agents in the agents/ directory
- **Manifest integrity:** Complete 1:1 mapping between plugin.json agents array and filesystem

### Impact
- **Plugin validation:** Plugin now loads without errors
- **Agent availability:** All active agents properly registered and discoverable
- **Maintenance:** Manifest accurately documents plugin capabilities

## [1.2.2] - 2025-11-08 (Sprint 143)

### Removed
- **Deprecated agents directory:** Removed `agents/deprecated/` containing 3 deprecated agents:
  - author-enricher.md (replaced by publisher-generator skill in v1.2.0)
  - institution-enricher.md (replaced by publisher-generator skill in v1.2.0)
  - publisher-enricher.md (replaced by publisher-generator skill in v1.2.0)
- **Orphaned agent:** Moved `agents/publisher-enricher.md` to `agents/deprecated-publisher-enricher.md`
  - Not used by current workflow (publisher-generator skill handles this functionality)
- **Unused test scripts:** Removed 5 test/debug scripts with no active references:
  - test-title-extraction.sh
  - test-wikilink-consistency.sh
  - test-wikilink-fix.sh
  - benchmark-dimension-planner.sh
  - validate-citations.sh
- **Unused utility scripts:** Removed 4 utility/migration scripts:
  - batch-write-entities.sh
  - cleanup-workspace-pollution.sh
  - export-json-ld.sh
  - migrate-tags-v2.sh
- **Analysis directory:** Removed `analysis/` directory containing historical documentation:
  - author-enricher-improvement-analysis.md
  - author-enricher-optimization-results.md
- **Test documentation:** Removed `skills/test-cogni-research/references/agents/publisher-enricher-testing.md`

### Changed
- **Documentation:** Updated `docs/agent-audit-script-paths.md` to reflect removed components
- **Active agents:** Now 15 active agents (down from 16 with deprecated cleanup)
- **Active scripts:** Now 5 active scripts (down from 14)

### Impact
- **Breaking:** None - all removed components were unused or deprecated
- **Maintenance:** Reduced codebase complexity and maintenance burden
- **Clarity:** Eliminated confusion between active and deprecated publisher enrichment workflows

## [1.2.1] - 2025-11-06 (Sprint 121)

### Fixed
- **dimension-planner:** Agent now reads and considers COMPLETE question content including Research Question, Context, and all additional fields when generating dimensions and sub-questions
  - Previous behavior used ambiguous "extract core research question" phrasing that could lead to missing important context
  - Context field details (geographic scope, timeframes, technology focus, exclusions, audience, market segments) now explicitly parsed and integrated into dimension planning
  - Fixes issue where rich contextual information was potentially ignored, leading to generic dimensions

### Added
- **dimension-planner:** New Step 1a provides explicit instructions for parsing and using all question components
  - Systematically extracts 4 components: Research Question, Context, Expected Output, Additional Details
  - Documents how context informs downstream steps (DOK classification, template selection, MECE validation, PICOT generation)
  - Includes 2 integration examples showing transformation from generic to context-specific dimensions
- **dimension-planner:** Enhanced Step 1 with comprehensive field extraction requirements
  - Lists all fields to extract: Research Question, Context, Expected Output, Additional Text
  - Explicit warning against truncating or summarizing at extraction stage
  - Includes example showing complete content structure
- **dimension-planner:** Updated Step 9 (Systematic Analysis) to require quoting COMPLETE question content in `<research_planning>` block
  - Applies to both domain-based and research-type-specific workflow modes
  - Ensures all context is visible in agent's thinking process

### Testing
- Added 3-test validation suite for complete question reading behavior
  - test-minimal-question.md: Baseline with only Research Question field
  - test-rich-context-question.md: Comprehensive context (European markets, 2025-2030, solar/wind, exclude nuclear/fossil, policy makers)
  - test-research-type-question.md: Lean-canvas type with B2B SaaS business context (mid-market, Zendesk/Intercom competitors)
  - test-readme.md: Execution instructions with 18-point validation checklist

### Migration Notes
- **No breaking changes** to dimension-planner agent interface
- Existing question files work without modification
- Enhanced behavior: Agent now better utilizes Context field content for dimension planning
- Recommended: When creating initial question files in Phase 1, populate Context field with rich details:
  - Geographic scope (countries, regions, markets)
  - Temporal boundaries (timeframes, date ranges)
  - Technology/domain focus areas
  - Explicit exclusions (what NOT to research)
  - Market segments or audience specifications
  - Expected output format or analysis requirements

### Quality Impact
- Dimension planning now produces context-aware dimensions instead of generic categories
- Sub-questions integrate specific constraints from Context field
- MECE validation considers complete question scope
- Example improvement:
  - Before: "Economic dimension: Analyze cost factors"
  - After: "Economic dimension: Analyze solar and wind installation costs in EU-27 countries during 2020-2030, focusing on residential market segments in Germany, France, Spain, and Nordic regions"

## [1.2.0] - 2025-10-30 (Sprint 050)

### Changed
- **BREAKING:** Split citation-manager into two focused sub-agents for improved maintainability
  - `source-creator`: Handles Phase 6.1 source creation from findings (replaces citation-manager Modes 1-2)
  - `citation-generator`: Handles Phase 6.2 citation generation from sources/publishers (replaces citation-manager Mode 3)
- Updated deeper-research skill orchestration to invoke new agents
- citation-generator now supports optional partitioning for parallel execution (NEW capability)

### Deprecated
- `citation-manager` agent (use source-creator or citation-generator instead)
  - Agent file remains for reference but is marked deprecated
  - Will be removed in v2.0.0

### Added
- Registered source-creator and citation-generator in plugin.json
- Parallelization support for citation generation (previously sequential)
- Comprehensive migration tests for compatibility validation

### Migration Guide

**For Phase 6.1 (Source Creation):**
```diff
- Task(subagent_type="cogni-research:citation-manager",
-      prompt="Create sources at {path} --finding-files {files} --sources-only")
+ Task(subagent_type="cogni-research:source-creator",
+      prompt="Create sources at {path} --finding-files {files}")
```

**For Phase 6.2 (Citation Generation):**
```diff
- Task(subagent_type="cogni-research:citation-manager",
-      prompt="Generate citations at {path} --citations-only")
+ Task(subagent_type="cogni-research:citation-generator",
+      prompt="Generate citations at {path}")
```

**NEW - Optional Parallelization:**
```python
# citation-generator can now run in parallel for large projects
Task(subagent_type="cogni-research:citation-generator",
     prompt="Generate citations at {path} --partition-index 0 --total-partitions 4")
```

### Benefits
- ✅ Separation of concerns (single responsibility principle)
- ✅ Simpler testing (no mode conflict testing needed)
- ✅ Better parallelization (citations can now run parallel)
- ✅ Reduced cognitive load (~500 lines vs 1,477 lines original)
- ✅ Easier debugging and maintenance

## [1.1.0] - 2025-10-30

### Added
- Registered all 11 specialized agents in plugin.json for Task tool invocation
- Agents now callable via `cogni-research:{agent-name}` pattern

### Fixed
- Fixed "Request interrupted by user for tool use" error in deeper-research skill
- Agents can now be properly delegated to via Task tool

### Technical Details
- Added `agents` array to `.claude-plugin/plugin.json` with explicit paths to all 11 agent markdown files
- Agents registered:
  - citation-manager
  - concept-extractor
  - dimension-planner
  - dimension-synthesizer
  - dimension-synthesizer
  - evidence-synthesizer
  - executive-synthesizer
  - fact-checker
  - publisher-enricher
  - query-builder
  - research-executor

## [1.0.0] - 2025-10-23

### Added
- Comprehensive Obsidian tagging system for knowledge pipeline entities
