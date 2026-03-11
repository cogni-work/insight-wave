---
name: copywriter
description: Polish, rewrite, or create business documents (memos, briefs, reports, proposals, one-pagers, executive summaries, emails, blog posts, business letters) using professional messaging frameworks (BLUF, McKinsey Pyramid, SCQA, STAR, PSB, FAB) and persuasion techniques (number plays, power words, rhetorical devices). Use this skill when the user asks to polish a document, improve writing, make something more readable, restructure a brief, apply BLUF or Pyramid Principle, rewrite for executives, strengthen messaging, create a proposal, write a one-pager, clean up a report, or apply any named messaging framework. Also handles German documents (Wolf Schneider style), arc-aware narrative polishing (cogni-narrative arcs with arc_id), and IS/DOES/MEANS sales messaging. Even simple requests like "make this better" about a markdown file should trigger this skill.
allowed-tools: Read, Write, Edit, Bash, TodoWrite
---

# Copywriter Skill

## Guiding Principles

Three non-negotiable preservation rules protect document integrity. Understanding *why* they matter will help you apply them consistently even in edge cases.

### German Character Preservation

German characters (ä, ö, ü, ß and their uppercase forms) must stay exactly as written. Converting them to ASCII equivalents (ae, oe, ue, ss) changes meaning — "Masse" (mass) vs "Maße" (measurements) — and signals to German readers that the text was processed by a tool that doesn't understand their language. This undermines trust in the entire document.

### Citation Preservation

Citations are evidence markers for audit trail integrity, not style elements. Every `[P1-1](https://...)`, `[P1-1]`, `<sup>[1]</sup>`, or `[portfolio-validated]` marker must remain exactly where it is, with its URL intact. When conciseness goals conflict with keeping citations, reduce prose — never citations. If the polished output has fewer citations than the source, the output will be rejected.

Specifically: do not remove URLs from inline citations, change marker formats, relocate citations, merge/split markers, or summarize citations into a footer reference.

### Protected Content

Documents may contain content destined for other processing tools. Preserve these exactly:

- **Diagram placeholder blocks** — Complete `<diagram-placeholder>` XML structures
- **Figure references and captions** — `Figure/Abbildung {N}` text and `**Figure N:** Title` lines
- **Obsidian embeds** — `![[assets/*.svg]]`
- **Kanban tables** — Tables with `| Dimension | Act | Plan | Observe |` headers, wikilinks, legends, and `<!-- kanban-board -->` placeholders

## Workflow

The workflow has 5 core steps. Initialize a TodoWrite checklist, then execute sequentially.

1. Parse parameters and load references
2. Apply structure (if creating or restructuring)
3. Apply writing and formatting
4. Review (optional)
5. Validate and write

### Scope Handling

When polishing an existing document, scope determines which steps run:

| Step | full | structure | tone | formatting |
|------|------|-----------|------|------------|
| 1. Parse & load | YES | YES | YES | YES |
| 2. Structure | YES | YES | SKIP | SKIP |
| 3. Writing & formatting | YES | SKIP | YES | YES |
| 4. Review | YES | SKIP | SKIP | SKIP |
| 5. Validate & write | YES | YES | YES | YES |

When `arc_mode` is active, arc-preservation rules override scope. See `arc-preservation.md`.

### Baseline Formatting (all scopes)

Every polished output meets these readability fundamentals, regardless of scope:

1. **Paragraph separation**: Max 5 sentences or ~70 words. Split at logical boundaries.
2. **Bold anchoring**: Bold 2-4 words around key data points (percentages, counts, ratios, dates). Target 2-3 bold instances per paragraph. Never bold entire sentences.
3. **White space**: Blank lines between every paragraph, heading, list, table, and block quote.

These apply even in `--scope=tone` because they are readability essentials, not decorative formatting.

### Step 1: Parse Parameters & Load References

**Extract from user request:**

- `deliverable_type`: memo | email | brief | report | proposal | one-pager | executive-summary | business-letter | blog
- `framework` (optional): bluf | pyramid | scqa | star | psb | fab | inverted-pyramid
- `impact_level` (optional): standard | high
- `MODE` (optional): standard | sales (default: standard)

**Load the reference index first:**

```text
READ: references/00-index.md
```

Follow the index's decision tree to detect the operating mode (arc, sales, or standard) and load exactly the references needed. The index handles all conditional loading — deliverable types, frameworks, language-specific principles, impact techniques, and formatting standards.

**Key mode behaviors:**

- **Arc mode** (triggered by `arc_id` in frontmatter or arc heading patterns): The arc IS the structure — skip framework and deliverable loading. Load arc-preservation and arc-technique-map references instead.
- **Sales mode** (triggered by `MODE: sales` or Power Position markers): Load power-positions plus impact techniques, then continue with standard deliverable/framework loading.
- **Standard mode**: Load deliverable type, messaging framework (user-specified or deliverable's default), and core principles.

### Step 2: Apply Structure & Framework

**If polishing an existing document:** Skip this step unless `--scope=full` or `--scope=structure`.

**If arc_mode is active:** Skip entirely — the arc provides the structure.

**If creating a new document:** Ask the user for:
- Main message (the bottom line)
- Audience (role, seniority)
- Desired action from readers
- 2-3 supporting key points
- Output path

Then apply the framework pattern from the loaded framework reference. If the user didn't specify a framework, use the deliverable type's recommended default.

### Step 3: Apply Writing & Formatting

**Detect document language:** (1) `--lang` parameter, (2) workspace preference from `.workspace-config.json` (via `${PROJECT_AGENTS_OPS_ROOT}/.workspace-config.json` or CWD), (3) content analysis. Load language-appropriate principles via the reference index.

**For German documents**, apply Wolf Schneider rules:

```text
READ: references/01-core-principles/german-style-principles.md
```

Key targets: max 12 words per clause, Satzklammer breaking, Mittelfeld shortening, Floskel elimination, rhythmic sentence variation.

**For English documents**, apply clarity and conciseness principles: 15-20 word sentences, 3-5 sentence paragraphs, 80%+ active voice, concrete language, strong verbs.

**Both languages — formatting:**

1. **Paragraph splitting**: Scan each paragraph. If it exceeds 5 sentences or covers more than one logical point, split it. Target: 3-5 sentences, 40-70 words.
2. **Bold anchoring**: Identify key data points and bold 2-4 words around each. Target: 2-3 per paragraph.
3. **Heading levels**: Max 3 (H1, H2, H3). Restructure if H4 is needed.
4. **Visual element rhythm**: Insert a visual element (table, list, callout) every 2-3 consecutive prose paragraphs.
5. **White space**: Blank line between every paragraph, around every heading, list, table, and block quote.

**Impact techniques** (when `impact_level: high` or executive audience):

Load techniques from the reference index. The reference files contain detailed decision processes, examples, and checklists for:

- **Number plays** — Transform vague claims into concrete data (ratio framing, comparative anchoring, before/after contrasts, compound impact)
- **Power words** — Strategic emotional triggers at decision points (3-5 per page, concentrated in headlines and CTAs)
- **Rhetorical devices** — Structural persuasion (Rule of Three, anaphora, antithesis, cadence — 2-3 per document)
- **Executive impact** — C-suite optimization (lead with ask, quantify everything, one-page max)

**Arc-aware technique application**: When `arc_mode` is active, apply techniques per-element using the arc-technique-map rather than generically across the document. Each arc element has its own technique profile.

**Sales mode enhancement**: When `MODE: sales`, enhance Power Positions (IS-DOES-MEANS structure) while preserving structure markers. Apply number plays primarily to DOES layer, power words primarily to MEANS layer. Never merge layers or modify structure markers.

### Step 4: Review (Optional)

Skip if `skip_review: true`, or for informal deliverables (emails, casual memos).

**Two modes available:**

**Option A — Interactive Reader Skill (recommended for formal deliverables):**

```text
Skill: cogni-copywriting:reader
Args: FILE_PATH={{output_path}} PERSONAS={{stakeholders}} AUTO_IMPROVE=true
```

The reader skill runs parallel multi-persona Q&A, synthesizes feedback, and applies one auto-improvement loop directly to the document. Use for reports, proposals, executive summaries, and briefs.

**Option B — Automated Checklist Review (lighter weight):**

Load stakeholder review profiles from `references/10-stakeholder-review/`. Default stakeholders by audience:

| Audience | Default Stakeholders |
|----------|---------------------|
| executive | executive, technical, end-user |
| technical | technical, executive |
| general | end-user, marketing, executive |
| legal | legal, executive, technical |
| sales/marketing | marketing, executive, end-user |

Evaluate against each stakeholder's 5 weighted criteria. Aggregate feedback, prioritize (3+ stakeholders = CRITICAL, 2 = HIGH, 1 = OPTIONAL), and apply CRITICAL/HIGH improvements. Load `references/10-stakeholder-review/synthesis-guidelines.md` for conflict resolution patterns.

**Review mode parameter:** `reader` (Option A), `automated` (default, Option B), or `skip`.

Review enhances quality but never blocks delivery — if review fails, continue to Step 5 with the document as-is.

### Step 5: Validate & Write

**Validation checklist:**

- German characters preserved (ä, ö, ü, ß unchanged)
- Citations preserved (count >= original)
- Protected content unchanged
- Readability: Flesch target (EN 50-60, DE 30-50 via Amstad formula)
- Active voice: 80%+
- Framework pattern applied (standard mode)
- Baseline formatting met (paragraphs, bold anchoring, white space)

**German-specific validation** (when detected language is German):
- Average clause length: target 10-12 words
- Floskel count: 0
- Sentence length variation: std dev > 3 words
- No attribute chains > 2 before a noun

**Arc-aware validation** (when `arc_mode` is active):

Run the technique validation checklist from `arc-technique-map.md`:
- Heading text unchanged
- Primary technique intact per element
- Number Play variant applied per element
- Word count within +-50 words of arc targets
- Citations preserved per element
- H2 count exactly 6 (subtitle + 4 elements + bridge)
- No content moved between elements

If arc validation fails for an element, revert that element to its original text. Partial polish is acceptable.

**Backup original** before writing:

```bash
dir=$(dirname "{output_path}")
filename=$(basename "{output_path}")
[[ -f "{output_path}" ]] && cp "{output_path}" "${dir}/.${filename}"
```

**Apply citation formatting** (if document contains citations):

Read `references/03-formatting-standards/citation-formatting.md` for complete rules. Key steps:
1. Move citations to specific claims they support
2. Add superscript commas between consecutive citations:
   ```bash
   perl -pi -e 's/<\/sup><sup>/<\/sup><sup>,<\/sup> <sup>/g' "{output_path}"
   ```

**Write document** using Write tool, then present summary:

```text
Document: {deliverable_type} using {framework}
File: {path}
Backup: {backup_path or "None (new file)"}
Quality: Framework + Structure + Readability ✓
```

## Readability Script

Language-aware Flesch scoring with German Wolf-Schneider analysis:

```bash
python3 scripts/calculate_readability.py <file_path> [--lang de|en|auto]
```

Auto-detects language. Returns `flesch_score`, `flesch_target_min/max`, `avg_paragraph_length`, `visual_elements`, `header_levels`, and German-specific style metrics when applicable.

## Bundled Resources

All references are organized in progressive disclosure tiers. Start with `references/00-index.md` — it routes you to exactly the files needed for any given task.

**Core Principles** (01-core-principles/) — Clarity, conciseness, active voice, German style (Wolf Schneider), German hooks, plain language, readability

**Messaging Frameworks** (02-messaging-frameworks/) — BLUF, Pyramid, SCQA, Inverted Pyramid, STAR, PSB, FAB

**Formatting Standards** (03-formatting-standards/) — Citation formatting, visual elements, heading hierarchy, markdown basics

**Deliverable Types** (04-deliverable-types/) — Memos, emails, briefs, reports, proposals, one-pagers, executive summaries, business letters, blogs

**Examples** (05-examples/) — Memo-BLUF, email-SCQA, brief-Pyramid, proposal-FAB

**Templates** (06-templates/) — Memo, email, brief, proposal

**Impact Techniques** (07-impact-techniques/) — Number plays, power words, rhetorical devices, executive impact

**Sales Techniques** (08-sales-techniques/) — Power Positions (IS-DOES-MEANS)

**Arc Preservation** (09-preservation-modes/) — Arc detection and preservation rules, per-element technique map

**Stakeholder Review** (10-stakeholder-review/) — Executive, technical, legal, marketing, end-user perspectives, synthesis guidelines

**Workflow** (workflow/) — Detailed sub-steps and validation checklists
