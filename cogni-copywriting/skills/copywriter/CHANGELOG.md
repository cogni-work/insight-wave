# Changelog - Copywriter Skill

All notable changes to the copywriter skill will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [7.1.0] - 2026-02-25

### Fixed - Language-Aware Flesch Targets for German

The Flesch readability target of 50-60 was applied uniformly to both English and German text. The Amstad formula inherently produces lower scores for German due to compound words, making 50-60 unreachable for German business writing. Introduced language-aware targets.

#### Target Ranges

| Language | Formula | Old Target | New Target |
|----------|---------|-----------|-----------|
| English | Standard Flesch | 50-60 | 50-60 (unchanged) |
| German | Amstad (1978) | 50-60 | 30-50 |

#### Changed Files

- **calculate_readability.py**: Returns `flesch_target_min` and `flesch_target_max` fields based on detected language (EN: 50/60, DE: 30/50)
- **readability.sh**: All display and assessment logic uses dynamic thresholds from script output instead of hardcoded 50-60
- **SKILL.md**: Step 8 validation and script documentation updated to reference language-aware targets
- **contracts/readability.yml**: Added `flesch_target_min` and `flesch_target_max` to output schema
- **readability-principles.md**: German target updated from 50-60 to 30-50 with explanation of why German scores lower
- **copywrite.md**: `--flesch-target` parameter documentation updated to describe language-aware defaults

### Rationale

Research on the Amstad (1978) formula shows German business writing typically scores 30-50, not 50-60. German compound words like "Qualitaetssicherungssysteme" produce many syllables per word, which the Amstad formula cannot fully compensate for. A German Amstad score of 30-50 corresponds roughly to the readability level of an English text scoring 50-60.

### Migration Notes

- **Non-breaking**: English targets unchanged at 50-60
- **Improved German scoring**: German documents that previously failed (e.g., scoring 22-40) will now be assessed against realistic 30-50 target
- **New JSON fields**: `flesch_target_min` and `flesch_target_max` added to script output; consumers should use these instead of hardcoded values

---

## [7.0.0] - 2026-02-24

### Added - Arc-Aware Polishing Mode

#### New Reference: arc-technique-map.md

- **references/09-preservation-modes/arc-technique-map.md**: Per-arc, per-element technique strengthening rules
  - Technique map tables for all 5 arcs (corporate-visions, technology-futures, competitive-intelligence, strategic-foresight, industry-transformation)
  - Element-specific Number Play variant selection (compound impact, ratio framing, comparative anchoring, etc.)
  - Element-specific polish rules (what to strengthen, what to preserve per element)
  - Cross-arc technique application table
  - Technique validation checklist

#### Rewritten Reference: arc-preservation.md

- **references/09-preservation-modes/arc-preservation.md**: Upgraded from blunt "don't touch headings" to arc-aware preservation
  - Arc detection logic: YAML frontmatter `arc_id`, pattern matching against known arc heading patterns
  - Structure preservation rules: FORBIDDEN vs ALLOWED modifications with arc-aware nuance
  - Technique-aware validation: verifies element techniques survived polishing
  - Integration patterns for cogni-narrative and cogni-tips
  - Localization support (EN/DE heading variants)

#### Enhanced SKILL.md Workflow

- **Step 1 (Parse Parameters)**: Added arc detection before framework loading. When arc detected, loads arc-preservation.md and arc-technique-map.md instead of messaging frameworks
- **Step 3 (Apply Structure)**: Skipped entirely in arc mode — the arc IS the structure
- **Step 5 (Apply Impact Techniques)**: Arc-aware mode applies techniques PER ELEMENT using the technique map, not generically across the whole document
- **Step 8 (Validate & Write)**: Added arc-specific technique validation checklist (heading integrity, technique integrity, word count targets, per-element citation counts)
- **Bundled Resources**: Added Arc Preservation section listing both new/updated references
- **Description**: Updated to mention arc-aware polishing of cogni-narrative stories
- **When to Use**: Added arc narrative polishing trigger

#### Updated 00-index.md

- **Loading Logic**: Arc detection takes priority over framework/deliverable loading
- **Tier 9**: New progressive disclosure tier for arc-aware preservation
- **Version**: Updated to 7.0

### Changed

- **Arc preservation philosophy**: From "preserve headings only" to "preserve structure AND strengthen element-specific techniques"
- **Impact technique application**: In arc mode, techniques are element-tuned (e.g., compound impact for Why Pay, forcing functions for Why Now) rather than generic
- **Validation**: Arc mode adds per-element technique validation on top of existing checks

### Rationale

cogni-narrative creates story arc narratives with specific narrative techniques per element (PSB for Why Change, Forcing Functions for Why Now, IS-DOES-MEANS for Why You, etc.). The previous arc-preservation mode treated all elements identically — "don't touch headings, improve body text." This was too blunt:

- The copywriter couldn't strengthen arc-specific techniques because it didn't know what they were
- Number Plays were applied generically, not tuned to element purpose
- No validation that arc techniques survived polishing

The new arc-aware mode gives the copywriter element-level intelligence: it knows Why Now needs forcing functions, Why Pay needs compound impact calculations, and Why You needs You-Phrasing in the DOES layer. This produces polished narratives that are both structurally sound AND technique-rich.

### Migration Notes

- **Non-breaking for standard mode**: All standard copywriting workflows (memos, emails, reports, etc.) are unchanged
- **Enhanced for arc mode**: Narratives with `arc_id` frontmatter now get element-specific technique strengthening
- **Backward compatible**: Old arc preservation constraints still work — the new system is a superset

---

## [6.2.0] - 2025-12-06

### Added - Citation Formatting Standards

#### New Reference: citation-formatting.md

- **references/03-formatting-standards/citation-formatting.md**: Comprehensive citation formatting standards
  - **Rule 1**: Move citations from section headers to specific claims (granular placement)
  - **Rule 2**: Citations in recommendation lists (Begruendung → Umsetzung pattern)
  - **Rule 3**: Superscript commas between consecutive citations for visual separation
  - Pattern recognition and replacement guidelines
  - Edge case handling (single, dual, multiple citations)
  - Validation checklist for citation quality
  - Optional automation script for batch processing

#### Enhanced SKILL.md Workflow

- **Step 6 (Validate & Write)**: Added citation formatting validation checkpoint
- **New workflow section**: "Apply citation formatting" with two-step process:
  1. Move citations to specific claims in Begruendung/Umsetzung sections
  2. Add superscript commas between consecutive citations using perl
- **Updated output summary**: Added "Citation Formatting" status line
- **Updated bundled resources**: Added Formatting Standards section with citation-formatting.md
- **Version updated**: 6.2 with changelog

### Changed

- **Citation placement philosophy**: From header-level to claim-level citations for improved academic rigor
- **Citation visual separation**: Consecutive citations now use superscript commas for consistency
- **Validation checklist**: Expanded to include citation formatting compliance

### Rationale

Research synthesis and TIPS-style documents benefit from precise citation placement and visual clarity:

- **Granular citations** enable readers to verify specific claims rather than entire sections
- **Superscript commas** maintain visual consistency and improve readability of citation sequences
- **Academic rigor** is enhanced when each claim has its own supporting evidence

These standards were developed through real-world application on German-language research reports (smarter-service trend analysis) and address common citation formatting challenges in multi-source documents.

### Technical Implementation

```bash
# Automatic superscript comma insertion
perl -pi -e 's/<\/sup><sup>/<\/sup><sup>,<\/sup> <sup>/g' document.md
```

**Pattern detection:**
- Before: `<sup>[15](path)</sup><sup>[16](path)</sup>`
- After: `<sup>[15](path)</sup><sup>,</sup> <sup>[16](path)</sup>`

### Migration Notes

- **Non-breaking change**: Citation formatting is applied only when citations are present
- **Backward compatible**: Documents without citations are unaffected
- **Opt-in enhancement**: Skill automatically detects and applies citation formatting
- **Manual override**: Users can skip citation formatting if needed

---

## [6.0.0] - 2025-12-03

### Breaking Changes

- **Removed diagram placeholder preservation** - Documents with `<diagram-placeholder>` tags are no longer specially handled. Copywriter now focuses purely on text copywriting.
- **Removed diagram parameters from agent** - `DIAGRAM_GENERATION` and `DIAGRAM_TYPES` parameters removed from copywriter agent.

### Removed

**From SKILL.md:**

- Line 18: Delegation reference to diagram-expert skill (`**Not for:** Diagrams or visualizations`)
- Lines 86-156: Entire "Placeholder & Figure Preservation" section (71 lines)
- Lines 223-228: Placeholder integrity validation from Step 6

**From copywriter.md (agent):**

- `DIAGRAM_GENERATION` and `DIAGRAM_TYPES` input parameters
- Diagram types validation step
- "Generate diagrams (if enabled)" from skill execution list
- `diagrams_generated` and `diagram_types` JSON output fields
- "Invalid diagram types" error recovery row

### Rationale

Complete separation between text copywriting and diagram generation. Copywriter skill now focuses 100% on traditional copywriting:

- Messaging frameworks (BLUF, Pyramid, SCQA, STAR, PSB, FAB)
- Persuasion techniques (number plays, power words, rhetorical devices)
- Document quality standards
- Executive impact optimization

Diagram functionality belongs exclusively in the diagram-expert skill.

### Migration Notes

- If you were using `DIAGRAM_GENERATION: true`, use the diagram-expert skill instead
- Documents with `<diagram-placeholder>` tags should be processed separately for diagram generation
- The copywriter skill remains focused on text quality and structure

---

## [5.0.0] - 2025-12-02

### Added - Impact Techniques Enhancement

#### New Reference Tier: 07-impact-techniques/

- **number-plays.md**: Quantification techniques for transforming vague claims into concrete, memorable data
  - Ratio framing (percentages → "X in Y" format)
  - Specific quantification (vague → precise numbers)
  - Comparative anchoring (raw numbers → familiar references)
  - Before/after contrasts with improvement calculations
  - Compound impact chains for cumulative effect
  - Rule of Three numbers for memorability

- **power-words.md**: Emotional trigger vocabulary organized by category
  - Urgency words (now, deadline, limited, immediate)
  - Exclusivity words (exclusive, insider, select, elite)
  - Trust words (proven, guaranteed, validated, certified)
  - Achievement words (breakthrough, transform, accelerate, unlock)
  - Strategic placement guidelines and density control (3-5 per page)

- **rhetorical-devices.md**: Structural persuasion techniques
  - Rule of Three (tricolon) patterns
  - Anaphora (repetition at start)
  - Antithesis (contrasting pairs)
  - Cadence (rhythmic flow) patterns
  - Device selection by purpose and placement guidelines

- **executive-impact.md**: C-suite and decision-maker optimization
  - 5 Executive Imperatives (lead with ask, quantify everything, respect time, decision clarity, signal credibility)
  - Board memo and executive summary templates
  - Decision request structures
  - Executive-appropriate vocabulary guidance

#### Enhanced SKILL.md

- Added Step 5 (Apply Impact Techniques) to workflow
- Added `impact_level` parameter (standard | high)
- Enhanced content requirements gathering for high-impact documents
- Added Impact Techniques Quick Reference section
- Expanded Quick Reference table with recommended techniques per deliverable
- Updated validation checklist with impact audit

#### Updated 00-index.md

- Added Tier 7: Impact Techniques section
- Updated loading logic for executive/high-impact documents
- Version bumped to 5.0

### Changed

- SKILL.md workflow expanded from 5 steps to 6 steps
- Description enhanced to include persuasion techniques
- Version updated to 5.0 (Impact Techniques Enhancement)

### Rationale

Business documents benefit from sophisticated persuasion techniques that go beyond structural frameworks. Research shows:
- Real numbers create 2x more engagement than percentages
- Strategic power words boost click-through rates by up to 121%
- 95% of decisions are driven by emotion, then rationalized
- Executives spend only 30-60 seconds on first-pass reading

The new impact techniques tier provides evidence-based guidance for creating documents that persuade, not just inform.

---

## [4.0.0] - 2025-12-02

### Changed - Further Simplification

#### Removed All Diagram Artifacts

- **07-diagram-templates/**: Entire directory removed (12 files)
- **scripts/generate-diagram.sh**: Removed
- **contracts/generate-diagram.yml**: Removed
- Copywriter is now 100% text-focused

#### Simplified SKILL.md

- Reduced from 254 lines to 146 lines (~43% reduction)
- Consolidated 7-step workflow to 5 steps
- Removed verbose TodoWrite expansion instructions
- Applied Anthropic metaprompt patterns for clarity
- Removed delegation references to diagram-expert

#### Updated References

- **00-index.md**: Updated to version 4.0
- Maintained 6-tier progressive disclosure (no changes needed)

### Rationale

Complete separation of concerns: copywriter handles text, diagram-expert handles visuals. No cross-references or delegation needed.

---

## [3.0.0] - 2025-12-02

### Changed - Initial Simplification

#### Removed Diagram from Workflow

- **SKILL.md**: Removed Step 5.5 (Generate Diagrams) and all diagram-related content
- **00-index.md**: Removed Tier 7 (Diagram Templates) section entirely
- **step-by-step-guide.md**: Removed Step 5.5 diagram generation and Step 6.7 diagram validation
- All diagram functionality moved to dedicated `diagram-expert` skill

#### Updated Files

- **SKILL.md**: Simplified from 356 lines to 254 lines (~29% reduction)
- **00-index.md**: Reduced from 6 tiers to 6 tiers (removed Tier 7)
- **step-by-step-guide.md**: Streamlined validation workflow

### Rationale

The copywriter skill is now focused purely on text-based business document creation. Diagram generation is a separate concern handled by the `diagram-expert` skill, which provides:

- Consulting-style SVG/HTML diagrams
- SWOT analysis, trend radars, 2x2 matrices
- Professional black & white design
- Obsidian compatibility

### Migration Notes

- **Breaking Change**: Diagram requests should now use `diagram-expert` skill
- Text-based document creation unchanged
- All 8 deliverable types still supported
- All 7 messaging frameworks still supported

---

## [2.0.0] - 2025-10-29

### Added - Major Enhancement Release

#### Examples (Tier 5)
- **example-memo-bluf.md**: Complete memo example using BLUF framework with quality metrics and analysis
- **example-email-scqa.md**: Business email example using SCQA framework with subject line analysis
- **example-brief-pyramid.md**: Executive brief example using Pyramid Principle with financial analysis
- **example-proposal-fab.md**: Consulting proposal example using FAB framework with ROI analysis

#### Templates (Tier 6)
- **template-memo.md**: Fillable memo template with writing tips and common pitfalls
- **template-email.md**: Business email template with subject line guidance and mobile optimization tips
- **template-brief.md**: Executive brief template with MECE framework guidance
- **template-proposal.md**: Business proposal template with comprehensive structure and best practices

#### Core Principles (Tier 1)
- **plain-language-principles.md**: Comprehensive plain language guide with government standards and word choice tables
- **readability-principles.md**: Detailed scannability guide with visual hierarchy, white space, and mobile optimization principles

#### Scripts & Tools
- **readability.sh**: Bash wrapper for calculate_readability.py with error handling, colored output, and user-friendly reporting
  - Validates Python 3 availability
  - Checks file existence and readability
  - Provides formatted output with target range validation
  - Displays overall quality assessment

#### Documentation
- **CHANGELOG.md**: Version tracking and change documentation
- Enhanced **Step 6 validation** in SKILL.md with comprehensive TodoWrite checklist integration
  - 6 validation sections (Metrics, Framework, Deliverable, Principles, Content, Polish)
  - Framework-specific requirements for all 7 frameworks
  - Deliverable-specific requirements for all 8 deliverable types
  - Example TodoWrite integration workflow

### Changed
- **SKILL.md**: Enhanced Step 6 from basic checklist to comprehensive validation workflow
- **Architecture**: Completed all 6 tiers of progressive disclosure system
- **Documentation**: Added detailed examples throughout validation sections

### Fixed
- Broken references in 00-index.md to plain-language-principles.md and readability-principles.md (files now exist)
- Missing examples directory (was empty, now contains 4 comprehensive examples)
- Missing templates directory (was empty, now contains 4 fillable templates)
- Incomplete validation workflow (now has complete TodoWrite integration)

## [1.0.0] - 2025-10-27

### Added - Initial Release

#### Core Structure
- **SKILL.md**: Main skill definition with 7-step workflow
- **00-index.md**: Master index with progressive disclosure loading logic

#### Core Principles (Tier 1)
- **clarity-principles.md**: Wolf-Schneider clarity rules
- **conciseness-principles.md**: Economy of language principles
- **active-voice-principles.md**: Active vs passive voice guidance

#### Messaging Frameworks (Tier 2)
- **bluf-framework.md**: Bottom Line Up Front (military/executive)
- **pyramid-framework.md**: McKinsey Pyramid Principle (consulting)
- **scqa-framework.md**: Situation-Complication-Question-Answer (narrative)
- **star-framework.md**: Situation-Task-Action-Result (case studies)
- **psb-framework.md**: Problem-Solution-Benefit (marketing)
- **fab-framework.md**: Feature-Advantage-Benefit (product)
- **inverted-pyramid-framework.md**: Journalism style (web content)

#### Formatting Standards (Tier 3)
- **markdown-basics.md**: Standard markdown syntax reference
- **visual-elements.md**: Tables, callouts, lists, emphasis
- **heading-hierarchy.md**: H1-H3 standards and scannable headers

#### Deliverable Types (Tier 4)
- **memos.md**: Internal communication structure
- **emails.md**: Email format and conventions
- **briefs.md**: Brief structure and length
- **reports.md**: Report organization and sections
- **proposals.md**: Proposal structure and persuasion
- **one-pagers.md**: Single-page layout and density
- **executive-summaries.md**: Summary structure and conciseness
- **business-letters.md**: Formal correspondence

#### Scripts
- **calculate_readability.py**: Python script for calculating Flesch score, paragraph metrics, visual elements, and header hierarchy

#### Architecture
- Progressive disclosure system design (Tiers 1-6)
- Modular reference architecture with no circular dependencies
- Loading logic based on deliverable type and framework selection

## Versioning Policy

### Version Numbers
- **Major (X.0.0)**: Breaking changes, complete architecture redesign
- **Minor (0.X.0)**: New deliverable types, frameworks, or major features
- **Patch (0.0.X)**: Bug fixes, documentation improvements, minor enhancements

### Release Cycle
- **Continuous**: Documentation and example improvements
- **As-needed**: New deliverable types or frameworks when demand emerges
- **Quarterly review**: Quality assessment and user feedback integration

## Upgrade Notes

### From 1.0.0 to 2.0.0

**Breaking Changes:** None

**New Features:**
- 4 complete examples in 05-examples/
- 4 fillable templates in 06-templates/
- 2 new core principle references
- Enhanced validation workflow with TodoWrite integration
- Bash wrapper for readability metrics

**Migration:** No migration needed. All existing workflows continue to function. New features are additive.

**Benefits:**
- **Progressive disclosure now complete**: All 6 tiers functional
- **Better validation**: Comprehensive checklist with TodoWrite tracking
- **Easier adoption**: Templates provide starting points for new users
- **Learning resource**: Examples demonstrate framework application

## Future Roadmap

### Planned for 3.0.0
- **Additional examples**: One-pager, report, business letter examples
- **Video tutorials**: Screen recordings of skill usage
- **Language variants**: British English vs American English guidance
- **Industry-specific adaptations**: Legal, healthcare, finance variants

### Under Consideration
- **AI readability improvements**: Automated suggestions for improving metrics
- **Integration tests**: Validate all examples meet stated quality metrics
- **Multi-language support**: Templates and examples in German, Spanish, French
- **Style guide generator**: Create custom style guides based on organization preferences

## Contributing

When adding new features:
1. Update appropriate tier (01-06 directories)
2. Add entry to CHANGELOG.md
3. Update 00-index.md if adding new deliverable or framework
4. Create examples demonstrating new features
5. Update SKILL.md if workflow changes
6. Increment version number appropriately

## Support & Documentation

- **Main Documentation**: SKILL.md
- **Quick Start**: 00-index.md
- **Examples**: references/05-examples/
- **Templates**: references/06-templates/
- **Architecture**: See SKILL.md "Progressive Disclosure Benefits" section

## License

Copyright 2025-2026. Part of cogni-workspace plugin.
