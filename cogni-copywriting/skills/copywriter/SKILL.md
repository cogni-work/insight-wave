---
name: copywriter
description: Polish, rewrite, or create business documents (memos, briefs, reports, proposals, one-pagers, executive summaries, emails, blog posts, business letters) using professional messaging frameworks (BLUF, McKinsey Pyramid, SCQA, STAR, PSB, FAB) and persuasion techniques (number plays, power words, rhetorical devices). Use this skill when the user asks to polish a document, improve writing, make something more readable, restructure a brief, apply BLUF or Pyramid Principle, rewrite for executives, strengthen messaging, create a proposal, write a one-pager, clean up a report, compress a document to minimum length without losing facts, shorten a synthesis for circulation, tighten a document while keeping every citation and number, or apply any named messaging framework. Also handles German documents (Wolf Schneider style), arc-aware narrative polishing (cogni-narrative arcs with arc_id), and IS/DOES/MEANS sales messaging. Even simple requests like "make this better" about a markdown file should trigger this skill.
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

| Step | full | structure | tone | formatting | compress |
|------|------|-----------|------|------------|----------|
| 1. Parse & load | YES | YES | YES | YES | YES |
| 2. Structure | YES | YES | SKIP | SKIP | SKIP |
| 3. Writing & formatting | YES | SKIP | YES | YES | YES (compression pass) |
| 4. Review | YES | SKIP | SKIP | SKIP | optional |
| 5. Validate & write | YES | YES | YES | YES | YES (+ precision gate) |

`compress` makes minimizing word count the **primary** objective, subject to zero precision loss — no citation, number, named entity, or distinct claim may be dropped. This is a different trade-off than the readability-driven conciseness of `--scope=tone`: Step 3 runs as a compression pass and Step 5 adds a precision-preservation gate. See `references/01-core-principles/compression-principles.md`.

When `arc_mode` is active, arc-preservation rules override scope. See `arc-preservation.md`. **`compress` is incompatible with `arc_mode`** — arc preservation enforces per-element word bands (±50 words) that directly conflict with word-count minimization; when both are requested, abort with a message naming the conflict rather than silently picking one.

**When `TARGET_LANG` is set**, scope is overridden to ensure a complete translate-and-polish cycle:

- Step 2 (Structure) is **always skipped** — translation preserves the source document's structure; do not impose a framework on the translated output.
- Step 2.5 (Translate) runs.
- Steps 3 and 5 always run, regardless of input `--scope` value (the translated draft needs full polish to clean up literal translation artefacts and to enforce target-language style/readability).
- Step 4 (Review) follows the normal rules (skipped for informal deliverables or `skip_review: true`).
- **`--scope=compress` + `TARGET_LANG` is rejected, not fused.** Compression and translation are two distinct passes and must not run as one. When both are requested, abort with guidance to translate first (`/copywrite <file> --translate=<lang>`) and then compress the translated output as a separate run. The `TARGET_LANG` scope override above must **not** silently re-expand a `compress` request into a full translate-and-polish.

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
- `AUDIENCE` (optional): expert | mixed | lay (default: mixed) — tunes audience-aware disciplines such as acronym expansion depth
- `TARGET_LANG` (optional): de | en | fr | it | pl | nl | es — when set, runs a translate-then-polish two-pass flow (see Step 2.5). When unset, the skill polishes in the source language only. Translation requires EN or DE on one end of the pair (the pivot); direct non-EN/DE pairs (e.g. fr↔it) are rejected — see pre-check #5.

**Audience resolution order** (used by acronym handling and any future audience-aware discipline):

1. Explicit `AUDIENCE` skill arg
2. Document frontmatter `audience:` field
3. Default: `mixed`

**Target-language resolution order** (used by Step 2.5 translate pass):

1. Explicit `TARGET_LANG` skill arg
2. Document frontmatter `target_language:` field
3. Unset (no translation; polish in source language)

**Translation pre-checks** (run only when `TARGET_LANG` resolves to a value):

1. Resolve `source_lang` via the existing detector in Step 3 (`--lang` → workspace config → content analysis).
2. If `source_lang == TARGET_LANG`, log "source language already matches target — skipping translation pass" and fall through to standard polish. **Also unset the translation scope override below** so the user's explicit `--scope` is honoured (a user invoking `--scope=full` on a same-language doc expects Step 2 to run normally).
3. **Arc-mode gate.** Determine the document's arc: use frontmatter `arc_id` if present; otherwise, if the H2 headings match a known in-scope arc pattern (per `arc-preservation.md` detection), use that `arc_id`. If neither yields an arc, skip this gate (proceed as a non-arc translation). When an arc is identified:
   - If the arc is **not** one of `corporate-visions`, `jtbd-portfolio` → abort (coverage), **regardless of language**, with: "Arc-mode translation currently covers corporate-visions and jtbd-portfolio; arc `{arc_id}` is future expansion (tracked under #255)." Do not modify the file.
   - Else (the arc is in scope) **and** at least one of `source_lang`/`TARGET_LANG` is in `{en, de}` → **allow**: set `arc_mode = true` and proceed. The arc-element and bridge headings will be **substituted** (not freely translated) in Step 2.5. This covers en↔de, en/de→fr/it/pl/nl/es, and the fr/it/pl/nl/es→en/de reverse.
   - Else (the arc is in scope but **neither** end is in `{en, de}` — e.g. a French source with `TARGET_LANG=it`) → do **not** abort here; fall through to pre-check #4 (accept-set) and #5 (pivot guard), which emits the correct direct-non-EN/DE message.
   - If `TARGET_LANG` is not in the accept-set at all → do **not** abort here; fall through to pre-check #4, which emits the correct "not a supported language" message.
   (Arc-mode translation pivots on EN/DE for these two arcs across `{de,en,fr,it,pl,nl,es}`; the FR/IT/PL/NL/ES coverage is Slice 3 of #255. The remaining 9 arcs — any language — and direct non-EN/DE pairs stay blocking here.)
4. **Accept-set check.** Accept only `de`, `en`, `fr`, `it`, `pl`, `nl`, `es`. Any other value: abort with "TARGET_LANG=`{value}` is not a supported language. Supported: de, en, fr, it, pl, nl, es."
5. **Pivot guard.** Translation pivots on EN or DE. If **neither** `source_lang` **nor** `TARGET_LANG` is in `{en, de}` (e.g. a French source with `TARGET_LANG=it`), abort with: "Direct {source_lang}→{TARGET_LANG} translation is not supported — every direction must include English or German on one end. Pivot via EN or DE (translate to en/de first, then to the final language), or follow #255 for direct non-EN/DE pairs (Phase 3)." Do not modify the file.

**Pre-check order:** resolve source (1) → no-op (2) → arc gate (3) → accept-set (4) → pivot guard (5). The arc and accept-set messages are the most actionable, so they win when multiple conditions hold.

The scope override and Step 2.5 below apply only when `TARGET_LANG` is set **and** the source==target no-op did not fire (i.e. translation actually runs). When translation runs, the pre-checks guarantee a valid direction pair (one end EN or DE, both in the accept-set), so a `translation-{source_lang}-to-{TARGET_LANG}.md` file is guaranteed to exist.

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

### Step 2.5: Translate Pass (only when TARGET_LANG is set)

Skip entirely when `TARGET_LANG` is unset. When set, this pass runs after Step 2 (which was skipped per the scope override above) and before Step 3.

**Load translation references:**

```text
READ: references/01-core-principles/translation-principles.md
```

Then load the direction-specific guide by constructing its filename deterministically from the resolved languages (the Step 1 pre-checks guarantee a valid pair, so this file always exists):

```text
READ: references/01-core-principles/translation-{source_lang}-to-{TARGET_LANG}.md
```

For example: `en`→`fr` loads `translation-en-to-fr.md`; `pl`→`de` loads `translation-pl-to-de.md`. The validity matrix in `translation-principles.md` lists all 22 supported directions. DE-pivot composition files (e.g. `translation-de-to-fr.md`) cross-reference the matching EN-pivot file for the full target-language production rules; X→de files cross-reference `translation-en-to-de.md` for German production.

When `arc_mode` is active, the arc references (`references/09-preservation-modes/arc-preservation.md`, `arc-technique-map.md`) are loaded **in addition** to the translation references (per `00-index.md` CHECK 0). `arc-preservation.md` supplies the canonical target-language headings for the substitution below.

**Perform the translation (Pass A):**

Translate the entire document to `TARGET_LANG`, holding to these invariants:

1. **Citation markers byte-identical** — every `[P\d+-\d+]`, `[P\d+-\d+](url)`, `<sup>[N]</sup>`, `[portfolio-validated]` stays exactly as written, URL included. Count must match the source.
2. **URLs byte-identical** — never translate URLs, even in inline `[text](url)` links.
3. **Protected content byte-identical** — `<diagram-placeholder>` XML blocks, `Figure N`/`Abbildung N` numeric refs, `![[assets/*.svg]]` Obsidian embeds, kanban tables with `| Dimension | Act | Plan | Observe |` headers.
4. **Frontmatter technical IDs unchanged** — `arc_id`, `source_url`, `entity_ref`, schema keys, filenames. Update `target_language:` to the new value (add the field if absent).
5. **Code blocks** — fenced and inline code never translated.
6. **Power Position structure markers** — `**IS**:`, `**DOES**:`, `**MEANS**:` stay unchanged (structural, not vocabulary).
7. **Acronyms pass through unchanged** — the audience-tuned first-mention expansion is Step 3's job, running on the translated text. Do not expand here.

**Arc-heading substitution (runs only when `arc_mode` is active):**

Arc-element and bridge headings are NOT freely translated — they are **substituted** from the canonical table in `references/09-preservation-modes/arc-preservation.md` (the downstream mirror; do **not** read cogni-narrative files at runtime):

1. Read `arc_id` from frontmatter and load that arc's canonical headings from `arc-preservation.md`: the 4 element headings (index 1–4) from the canonical heading table, **and** the bridge heading from the bridge list immediately below that table (the bridge is a prose list, not a table row).
2. Identify the document's headings **positionally**:
   - The **bridge** is the trailing H2 whose text matches **any language's** bridge form in the bridge list in `arc-preservation.md` — `Further Reading` (en), `Weiterführende Lektüre` (de; also accept the ASCII form `Weiterfuehrende Lektuere` on input), `Pour aller plus loin` (fr), `Approfondimenti` (it), `Dalsza lektura` (pl), `Verder lezen` (nl), `Lecturas adicionales` (es). Match against every form, not just the source/target pair — a reverse-direction doc (e.g. a French source) carries its bridge in the source language. A document may have no bridge — that is fine; substitute only what is present.
   - A **subtitle** rendered as an H2 (the single H2 that is neither an arc element nor the bridge — match it against the document's H2 subtitle text / frontmatter `subtitle:`) is preserved byte-identical, never substituted. Both in-scope arcs emit the subtitle as italic text, not an H2.
   - The remaining H2s, in document order, are arc elements 1..4. **If the remaining count is not exactly 4, do not substitute** — log `fallback_reason="arc_elements_not_resolved"`, leave all headings as-is, and continue with body translation only. This guards against mis-indexed substitution (e.g. an unexpected extra H2).
   - Prefix-match each element heading against the source-language column as a **sanity guard** — if positional index and prefix-match disagree, trust the position and note the discrepancy. (A real narrative's source headings may legitimately differ from any cached form.)
3. Replace arc-element heading *i* with the **`TARGET_LANG`** canonical full heading for index *i*; replace the bridge (if present) with the `TARGET_LANG` bridge form. The canonical strings already carry the target language's required diacritics (FR é/è/ê/ç, IT à/è/é/ì/ò/ù, PL ą/ć/ę/ł/ń/ó/ś/ź/ż, ES á/é/í/ó/ú/ñ, DE ä/ö/ü/ß; NL is ASCII) — copy them byte-for-byte, never ASCII-fold them. See `translation-principles.md` § "Per-Language Charset Rules".
4. Translate the body prose under each heading per the invariants above (citations, URLs, protected content byte-identical).
5. Preserve H2 count, element order, and heading hierarchy exactly — substitution changes heading *text*, never structure.

**Do NOT in this pass:**

- Apply target-language style discipline (Wolf-Schneider clause-length rules, Flesch tuning, Floskel elimination) — that is Step 3.
- Expand acronyms — that is Step 3.
- Restructure paragraphs or change the heading hierarchy — preserve the source structure.
- Apply messaging frameworks — Step 2 was already skipped.

The translate pass output is an intermediate draft. Step 3 will tighten clause length, break Satzklammer (for DE output), apply acronym expansion per `AUDIENCE`, and validate against language-specific readability targets.

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
6. **Acronym handling on first mention**: expand acronyms once at first occurrence per document; depth tuned to AUDIENCE (expert / mixed / lay). See `references/01-core-principles/acronym-handling-principles.md`. Subsequent mentions verbatim; proper nouns, brand names, and arc/sales discipline markers (`**IS**:`, `**DOES**:`, `**MEANS**:`) excluded.

**Compression pass (`--scope=compress`)**: when scope is `compress`, Step 3 runs as a compression pass whose **primary** objective is minimizing word count subject to zero precision loss — not the readability transformation above. Load `references/01-core-principles/compression-principles.md` and apply its passes (the five lossless conciseness passes, then structural merging). Two relaxations and one hard floor:

- **Relax decorative formatting** — drop the bold-anchoring density target (item 2 above, "2-3 bold instances per paragraph") and the visual-element rhythm (item 4 above, "a visual element every 2-3 paragraphs"). These spend words the brevity objective wants back; add bold or a visual element only where it genuinely prevents a misread or is itself shorter than the prose it replaces.
- **Keep baseline readability** — paragraph separation, white space between blocks, and heading levels (items 1, 3, 5 above) still hold. A wall of unbroken text is not "compressed", it is unreadable. The `### Baseline Formatting (all scopes)` rules are NOT suspended; only the decorative-density rules are.
- **Precision floor** — never drop a citation, number, named entity, or distinct claim to save words. Step 5's precision-preservation gate enforces this and rejects the output on any violation.

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
- Readability: Flesch target (EN 50-60, DE 30-50 via Amstad formula) — applies only when `TARGET_LANG` is unset; translation runs use the relative-to-source rule in the Translation-specific validation block below.
- Active voice: 80%+
- Framework pattern applied (standard mode)
- Baseline formatting met (paragraphs, bold anchoring, white space)
- Acronyms expanded once on first mention (audience-tuned); subsequent mentions verbatim; proper nouns/brands/arc markers excluded

**Translation-specific validation** (only when `TARGET_LANG` was set):

- **Target charset matches** — validate against the per-language diacritic rules in `references/01-core-principles/translation-principles.md` § "Per-Language Charset Rules" (the single source of truth). In summary:
  - `de`: output contains ä/ö/ü/ß where German prose requires them; never ASCII substitutes (ae/oe/ue/ss).
  - `fr`: required accents é/è/ê/ç (and à/â/ë/î/ï/ô/û/ù); no bare-vowel substitutes.
  - `it`: required accents à/è/é/ì/ò/ù; note è (is) vs e (and).
  - `pl`: required ą/ć/ę/ł/ń/ó/ś/ź/ż; no bare-Latin substitutes.
  - `es`: required á/é/í/ó/ú/ñ (and inverted ¿/¡ on questions/exclamations); no bare-vowel substitutes, n→ñ never dropped.
  - `nl`: ASCII — Dutch needs no special set; ensure no German umlauts leaked from the source.
  - `en`: output contains no ä/ö/ü/ß or other diacritics except inside preserved proper nouns or quoted source-language terms.
- **Citation count exactly preserved** — for each of the four citation-marker patterns supported by the skill, the regex count in the output equals the source count, and every URL is byte-identical to its source URL:
  1. Inline cite with URL: `\[P\d+-\d+\]\([^)]+\)`
  2. Inline cite without URL: `\[P\d+-\d+\](?!\()`
  3. Superscript footnote: `<sup>\[\d+\]</sup>`
  4. Source tag: `\[(portfolio-validated|claim-verified|[a-z-]+-validated)\]`
  (These mirror the four marker types enumerated in `translation-principles.md` § "Preserve byte-identical".)
- **Frontmatter technical IDs unchanged** — `arc_id`, `source_url`, `entity_ref`, and any other technical identifier fields in the frontmatter are byte-identical to source values. The `target_language:` field is set to the new value (added if absent).
- **Protected content byte-identical** — diagram-placeholder blocks, figure/Abbildung numeric refs, Obsidian embeds, kanban tables match the source byte-for-byte.
- **Readability relative to source** — when `TARGET_LANG` is set, score source and output on the **target-language Flesch scale**, then compare. Invocation (read `flesch_score` from each JSON result):
  - `python3 scripts/calculate_readability.py <source.md> --lang $TARGET_LANG` → `source_score` (= `flesch_score`)
  - `python3 scripts/calculate_readability.py <output.md> --lang $TARGET_LANG` → `output_score` (= `flesch_score`)
  - **Pass rule**: `output_score >= source_score - 5`. The 5-point soft floor absorbs measurement noise and unavoidable cross-language structural drift (e.g., German compound length pushing Amstad down 2–4 points for a faithful EN→DE rendering).
  - **Absolute band reporting**: also print the absolute band (`EN 50-60` / `DE 30-50`) as an aspirational note. If `output_score` lands in the band, report `in absolute band`. If it lands below the band but at or above `source_score - 5`, report `below absolute band, faithful to source — pass`. Only fail when `output_score < source_score - 5`.
  - **Rationale**: see `references/01-core-principles/translation-principles.md` § "Readability in Translation Mode".

**Compress-specific validation** (only when `--scope=compress`): the precision-preservation gate. Every check below must pass; on any failure the compressed output is **rejected** (re-compress less aggressively, restoring whatever the failing check protects). Full rules in `references/01-core-principles/compression-principles.md` § "Validation Checklist".

- **Citation count exactly preserved** — for each of the four citation-marker patterns (the same patterns enumerated in the Translation-specific block above), the regex count in the output equals the source count, and every URL is byte-identical to its source URL. Citation markers are never counted toward word-count reduction.
- **Every number / data point retained** — every percentage, count, ratio, date, and monetary figure present in the source is present in the output. A number is never deleted to save words.
- **Every named entity retained** — every named organization, person, product, regulation, or place in the source is present in the output (do not generalize "the Bundesnetzagentur" to "the regulator").
- **Every distinct claim retained** — no distinct factual assertion is silently dropped to save words. Merging two sentences is allowed; dropping the claim one of them made is not.
- **Charset preserved** — per-language diacritics exactly per `references/01-core-principles/translation-principles.md` § "Per-Language Charset Rules"; never ASCII substitutes.
- **Protected content byte-identical** — diagram-placeholder blocks, figure/Abbildung numeric refs, Obsidian `![[assets/*.svg]]` embeds, and kanban tables match the source byte-for-byte.
- **Frontmatter technical IDs unchanged** — `arc_id`, slugs, synthesis IDs, `source_url`, `entity_ref`, and any other technical identifier fields are byte-identical to source values.
- **Word count materially reduced** — the output is shorter than the source. If it is not, either the source was already minimal or the lossless passes were not applied aggressively enough.

**German-specific validation** (when detected language is German):
- Average clause length: target 10-12 words
- Floskel count: 0
- Sentence length variation: std dev > 3 words
- No attribute chains > 2 before a noun

**Arc-aware validation** (when `arc_mode` is active):

Run the technique validation checklist from `arc-technique-map.md`:
- Heading text unchanged — **except in translation mode** (`TARGET_LANG` set), where arc-element + bridge headings must instead **match the `TARGET_LANG` canonical set** in `arc-preservation.md` byte-for-byte, carrying the target language's required diacritics per `translation-principles.md` § "Per-Language Charset Rules" (e.g. ä/ö/ü/ß for `de`, é/è/ê/ç for `fr`, à/è/é/ì/ò/ù for `it`, ą/ć/ę/ł/ń/ó/ś/ź/ż for `pl`, á/é/í/ó/ú/ñ for `es`; `nl` is ASCII) — never ASCII substitutes
- Primary technique intact per element
- Number Play variant applied per element
- Word count within +-50 words of arc targets — **in translation mode** use the relative band instead (see `arc-technique-map.md` Post-Polish Validation: `source_element_words × factor × (1 ± 0.20)`, factor per the per-target table there — ≈ 1.20 →de, ≈ 0.83 →en, ≈ 1.15 →fr, ≈ 1.10 →it, ≈ 1.20 →es, ≈ 1.05 →nl, ≈ 1.10 →pl)
- Citations preserved per element
- H2 count + element order unchanged from the source (the absolute "exactly 6" expectation does not apply — a document may legitimately carry an italic subtitle and 5 H2s)
- No content moved between elements

If arc validation fails for an element, revert that element to its original text. Partial polish is acceptable. (In translation mode a heading mismatch is a substitution error, not a free-translation error — re-apply the canonical heading rather than reverting to the source-language heading.)

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

Language-aware Flesch-family scoring with German Wolf-Schneider analysis:

```bash
python3 scripts/calculate_readability.py <file_path> [--lang de|en|fr|it|pl|nl|es|auto]
```

Auto-detects language. Returns `flesch_score`, `flesch_target_min/max`, `avg_paragraph_length`, `visual_elements`, `header_levels`, and German-specific style metrics when applicable. FR/IT/PL/NL/ES use Flesch-family formulas (Kandel-Moles, Flesch-Vacca, generic fallback, Flesch-Douma, Szigriszt-Pazos); their absolute target bands are aspirational — translation Step 5 enforces the relative-to-source rule.

## Bundled Resources

All references are organized in progressive disclosure tiers. Start with `references/00-index.md` — it routes you to exactly the files needed for any given task.

**Core Principles** (01-core-principles/) — Clarity, conciseness, active voice, German style (Wolf Schneider), German hooks, plain language, readability, acronym handling (audience-tuned first-mention expansion), translation (two-pass translate-then-polish; EN/DE-pivot directions for de/en/fr/it/pl/nl/es via `translation-{src}-to-{tgt}.md`)

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

## Cross-Plugin Next Steps

When polishing a research report (detected by project directory containing `project-config.json` or `00-sub-questions/`), include this guidance after the quality metrics:

> **Next: Visual pipeline**
> 1. `/story-to-infographic` + `/render-infographic` — Infographic header (Pencil, 10-step validated)
> 2. `/enrich-report` — Themed HTML with charts (reuses infographic from step 1)
>
> Running story-to-infographic first gives enrich-report a validated, Pencil-rendered header instead of its simplified inline fallback.
