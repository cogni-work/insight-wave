# cogni-copywriting

Professional copywriting toolkit for the insight-wave ecosystem — polishes documents with 7 messaging frameworks, runs parallel multi-stakeholder persona reviews, adapts JSON text fields, and audits arc-preservation contracts against cogni-narrative.

## Plugin Architecture

```
skills/                                   4 copywriting skills
  copywriter/                              Executive document polishing (main skill)
    SKILL.md                               5-step workflow: parse, structure, write, review, validate
    CHANGELOG.md                           Skill version history
    contracts/
      readability.yml                      Readability contract thresholds (Flesch/Amstad)
    scripts/
      calculate_readability.py             Language-aware Flesch scoring with German Wolf-Schneider analysis
      readability.sh                       Shell wrapper for readability calculation
    references/
      00-index.md                          Decision tree routing to correct references per mode
      01-core-principles/                  7 writing principle files
        active-voice-principles.md          80%+ active voice targets
        clarity-principles.md               Concrete language, strong verbs
        conciseness-principles.md           15-20 word sentences, 3-5 sentence paragraphs
        german-hook-principles.md           German-specific hook patterns
        german-style-principles.md          Wolf Schneider 7 rules (Satzklammer, Mittelfeld, Floskeln)
        plain-language-principles.md        Plain language guidelines
        readability-principles.md           Flesch/Amstad scoring targets
      02-messaging-frameworks/             7 messaging framework definitions
        bluf-framework.md                   Bottom Line Up Front
        pyramid-framework.md                McKinsey Pyramid Principle
        scqa-framework.md                   Situation-Complication-Question-Answer
        star-framework.md                   Situation-Task-Action-Result
        psb-framework.md                    Problem-Solution-Benefit
        fab-framework.md                    Feature-Advantage-Benefit
        inverted-pyramid-framework.md       News-style inverted pyramid
      03-formatting-standards/             4 formatting standard files
        citation-formatting.md              Citation preservation and superscript rules
        heading-hierarchy.md                Max 3 heading levels
        markdown-basics.md                  Markdown formatting conventions
        visual-elements.md                  Tables, callouts, lists rhythm
      04-deliverable-types/                9 deliverable type definitions
        memos.md                            Internal memos
        emails.md                           Professional emails
        briefs.md                           Executive briefs
        reports.md                          Full reports
        proposals.md                        Business proposals
        one-pagers.md                       One-page summaries
        executive-summaries.md              Executive summaries
        business-letters.md                 Formal business letters
        blogs.md                            Blog posts
      05-examples/                         4 framework-applied examples
        example-memo-bluf.md                Memo using BLUF
        example-email-scqa.md               Email using SCQA
        example-brief-pyramid.md            Brief using Pyramid
        example-proposal-fab.md             Proposal using FAB
      06-templates/                        4 deliverable templates
        template-memo.md
        template-email.md
        template-brief.md
        template-proposal.md
      07-impact-techniques/                4 persuasion technique files
        number-plays.md                     Ratio framing, comparative anchoring, before/after
        power-words.md                      Strategic emotional triggers (3-5 per page)
        rhetorical-devices.md               Rule of Three, anaphora, antithesis, cadence
        executive-impact.md                 C-suite optimization (lead with ask, quantify)
      08-sales-techniques/                 1 sales technique file
        power-positions.md                  IS-DOES-MEANS (Power Positions) structure
      09-preservation-modes/               2 arc-preservation files
        arc-preservation.md                 Arc detection table, localized headings, validation rules
        arc-technique-map.md                Per-arc element technique assignments and word targets
      10-stakeholder-review/               7 stakeholder review files
        00-index.md                         Stakeholder selection by audience type
        executive-review.md                 Executive perspective criteria
        technical-review.md                 Technical perspective criteria
        legal-review.md                     Legal perspective criteria
        marketing-review.md                 Marketing perspective criteria
        end-user-review.md                  End-user perspective criteria
        synthesis-guidelines.md             Conflict resolution and deduplication
      workflow/
        step-by-step-guide.md              Detailed sub-steps and validation checklists
  copy-reader/                             Multi-stakeholder document review
    SKILL.md                               6-step workflow: parse, backup, parallel personas, synthesize, improve, report
    references/
      synthesis-protocol.md                Cross-persona theme identification and conflict resolution
      personas/                            7 stakeholder persona profiles
        executive.md                        Decision-readiness, quantification, clarity
        technical.md                        Accuracy, logic, precision, completeness
        legal.md                            Risk language, compliance, liability
        marketing.md                        Audience resonance, persuasiveness, CTA
        end-user.md                         Plain language, actionability, empathy
        cdo-utility.md                      CDO of energy utility (buyer persona)
        cmo-provider.md                     CMO of IT provider (seller persona)
  copy-json/                               JSON text field polishing adapter
    SKILL.md                               4-step workflow: extract, build temp MD, copywriter delegate, write back
  audit-copywriter/                        Arc contract audit against cogni-narrative
    SKILL.md                               6-step workflow: resolve paths, extract upstream, extract downstream, 8 checks, report

agents/                                   2 delegation agents
  copywriter.md                            Document polishing orchestrator (opus)
  reader.md                                Stakeholder review orchestrator (sonnet)

commands/                                 2 slash commands
  copywrite.md                             /copywrite — polish MD or JSON files
  review-doc.md                            /review-doc — multi-stakeholder persona review
```

## Component Inventory

| Type | Count | Items |
|------|-------|-------|
| Skills | 4 | copywriter, copy-reader, copy-json, audit-copywriter |
| Agents | 2 | copywriter (opus), reader (sonnet) |
| Commands | 2 | /copywrite, /review-doc |
| Messaging Frameworks | 7 | BLUF, Pyramid, SCQA, STAR, PSB, FAB, Inverted Pyramid |
| Deliverable Types | 9 | memos, emails, briefs, reports, proposals, one-pagers, executive summaries, business letters, blogs |
| Impact Techniques | 4 | number plays, power words, rhetorical devices, executive impact |
| Stakeholder Personas | 7 | executive, technical, legal, marketing, end-user, cdo-utility, cmo-provider |

## Key Workflows

### Copywriter Polish Flow

5-step sequential workflow with scope-dependent step skipping:

1. **Parse parameters and load references** -- reads `00-index.md` decision tree to detect mode (arc/sales/standard) and load exactly the references needed
2. **Apply structure** -- applies messaging framework pattern (Pyramid, BLUF, etc.); skipped in arc mode (arc IS the structure) or `--scope=tone|formatting`
3. **Apply writing and formatting** -- language detection (EN/DE), voice transformation, paragraph splitting, bold anchoring, visual rhythm; loads impact techniques for high-impact or executive audiences
4. **Review** -- optional stakeholder review via copy-reader skill (parallel personas) or automated checklist; never blocks delivery
5. **Validate and write** -- German chars preserved, citations intact, readability scored, arc validation if active; backs up original before writing

Scope matrix determines which steps run: `full` runs all, `structure` runs 1+2+5, `tone` runs 1+3+5, `formatting` runs 1+3+5.

### Copy-Reader Stakeholder Review Flow

6-step parallel persona simulation:

1. **Parse parameters** -- extract FILE_PATH, PERSONAS (default: all 5 generic), AUTO_IMPROVE flag; load persona profile references
2. **Create backup** -- `.{filename}.pre-reader-review`
3. **Parallel persona analysis** -- launches one Task agent per persona; each evaluates against 5 weighted criteria, generates 3-5 questions, identifies concerns with line references
4. **Synthesize feedback** -- cross-persona themes (3+ personas = CRITICAL, 2 = HIGH); conflict resolution via tiebreaker hierarchy (primary audience > safety > clarity > impact)
5. **Auto-improvement loop** -- applies CRITICAL and HIGH recommendations; validates German chars, citations, protected content after each edit; reverts to backup on validation failure
6. **Report results** -- persona score table, stakeholder questions, improvements applied/skipped, overall score

### Copy-JSON Adapter Flow

4-step JSON-to-markdown-to-JSON bridge:

1. **Parse and extract** -- validate `.json` file, resolve FIELDS dot-path selectors (`plugins[*].description`), collect string values >= 10 chars
2. **Build temp MD and invoke copywriter** -- assemble extracted texts with `<!-- FIELD: ... -->` delimiters into temp markdown file, delegate to copywriter skill with scope (default: `tone`)
3. **Parse back and validate** -- split polished MD by delimiters, validate: German chars preserved, no markdown injection (`**`, `#`, `- `), length guard (max 2x original), citations preserved
4. **Write and report** -- backup original, update JSON with polished values preserving indentation, show before/after diff table

### Audit-Copywriter Arc Audit Flow

6-step contract verification between cogni-narrative (upstream) and cogni-copywriting (downstream):

1. **Resolve paths** -- find monorepo root, locate 4 upstream files (arc-registry, per-arc definitions, language-templates, techniques-overview) and 3 downstream files (arc-preservation, arc-technique-map, 00-index)
2. **Extract upstream contract** -- parse master arc list, full element headings EN/DE, section proportions, technique assignments
3. **Extract downstream state** -- parse detection tables, localized headings, technique maps, word targets, validation rules
4. **Run 8 audit checks** -- C1: Arc Coverage (CRITICAL), C2: Element Heading Match (HIGH), C3: Localized Heading Match (HIGH), C4: Word Target Consistency (MEDIUM), C5: Technique Assignment (MEDIUM), C6: Section Proportion (MEDIUM), C7: Version Alignment (INFO), C8: Validation Rule Compatibility (HIGH)
5. **Generate report** -- severity summary, per-check findings, recommended actions ordered by severity
6. **Summary line** -- finding counts; flags immediate action if CRITICAL findings exist

## Cross-Plugin Integration

| Plugin | Direction | Integration |
|--------|-----------|-------------|
| cogni-narrative | upstream | Detects `arc_id` frontmatter and applies arc-specific polishing techniques per element; audit-copywriter verifies arc contracts stay in sync |
| cogni-sales | downstream | Consumes copywriter as optional polish step for sales documents |
| cogni-marketing | downstream | Consumes copywriter as optional polish step for marketing content |
| cogni-research | downstream | Consumes copywriter as optional polish step for research reports |

## Pipeline Position

```
cogni-research --> cogni-narrative --> cogni-copywriting --> cogni-visual
  (research)        (compose)          (polish)             (visualize)
```

## 7 Messaging Frameworks

| Framework | Pattern | Best For |
|-----------|---------|----------|
| BLUF | Bottom Line Up Front | Memos, emails, status updates |
| Pyramid | McKinsey Pyramid Principle (answer-first, MECE groups) | Reports, briefs, executive summaries |
| SCQA | Situation-Complication-Question-Answer | Emails, proposals, problem-framing |
| STAR | Situation-Task-Action-Result | Case studies, project updates |
| PSB | Problem-Solution-Benefit | Proposals, one-pagers |
| FAB | Feature-Advantage-Benefit | Product descriptions, sales copy |
| Inverted Pyramid | Most important first, supporting details descend | Blog posts, news-style content |

## Key Conventions

- Three non-negotiable preservation rules: German characters (never convert to ASCII), citations (count >= original), and protected content (diagram placeholders, figure refs, Obsidian embeds, kanban tables)
- Reference loading always starts at `references/00-index.md` which routes to exactly the files needed -- never load all references at once
- Arc mode is triggered by `arc_id` in YAML frontmatter or arc heading patterns; when active, the arc provides structure and element-specific techniques override generic frameworks
- Sales mode (`MODE: sales`) enables Power Positions (IS-DOES-MEANS) enhancement with number plays on DOES layer and power words on MEANS layer
- Bilingual support: English uses Flesch Reading Ease (target 50-60), German uses Amstad formula (target 30-50) with Wolf Schneider style rules
- Readability script: `python3 scripts/calculate_readability.py <file> [--lang de|en|auto]`
- Output backup convention: original saved as `.{filename}` (hidden file) before overwrite
- Copy-json adapter never polishes text itself -- it only handles JSON-to-MD format conversion and delegates all polishing to the copywriter skill
- Stakeholder review uses parallel Task agents (one per persona) with cross-persona synthesis; 3+ personas on same issue = CRITICAL priority
- Plugin version lives in `.claude-plugin/plugin.json` as the `version` field. Claude Code reads this when displaying plugin info; marketplace sync itself is driven by git commit hash, not the version string
