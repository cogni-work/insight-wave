# Citation Formats Reference

## Supported Formats

The `citation_format` field in project config controls how inline citations and the reference list are formatted. The writer agent applies the format via its prompt — no code-level formatting logic.

### APA (default)

**Inline**: `([Author, Year](url))` at the end of the sentence or paragraph.
**Reference list**:
```
Author, A. A. (Year, Month Day). Title of article. *Publisher Name*. url
```
**Example**:
- Inline: `Cloud adoption grew 25% in 2025 ([Gartner, 2025](https://gartner.com/report))`
- Reference: `Gartner. (2025, March 10). Cloud Infrastructure Report 2025. *Gartner Research*. https://gartner.com/report`

### MLA

**Inline**: `([Author](url))` with page numbers where applicable.
**Reference list** (Works Cited):
```
Author Last, First. "Title of Article." *Publisher*, Day Month Year, url.
```

### Chicago (CMS)

**Inline**: Footnote-style superscript numbers: `text<sup>[1](url)</sup>`
**Reference list** (Bibliography):
```
Author Last, First. "Title." *Publisher*, Month Day, Year. url.
```

### Harvard

**Inline**: `([Author Year](url))` — similar to APA but without comma.
**Reference list**:
```
Author, A.A. Year. Title of article. *Publisher*. Available at: url [Accessed Day Month Year].
```

### IEEE

**Inline**: Superscript number linking directly to the source URL: `<sup>[N](url)</sup>`
**Reference list** (numbered, in citation order, bold visible `**[N]**` for prominence):
```
**[1]** A. Author, "Title," *Publisher*, Month Year. [https://example.com/article](https://example.com/article)
```

Number sources sequentially by order of first appearance in the report. Use the same number when citing the same source again. The inline superscript renders as a clickable `¹` in Obsidian / GitHub / Pandoc and opens the source URL directly — no anchor resolution, no footnote reuse counters.

### Wikilink (deprecated alias for IEEE)

`wikilink` was the v0.7.x–v0.8.2 name for a numbered-citation format that used Obsidian-style anchored references (`<sup>[[N]](#ref-N)</sup>` inline + `<a id="ref-N"></a>` anchors in the references section). In v0.8.3 the format is **deprecated and normalised to `ieee` on read** because:

1. `[[N]]` is parsed by Obsidian as a wikilink to a note named "N"; the trailing `(#ref-N)` falls through as plain text and the citation appears clickable but jumps to a missing note.
2. `[text](#anchor)` linking to `<a id="anchor">` is unreliable in Obsidian — its `#anchor` resolution targets heading slugs, not inline HTML ids.
3. Native markdown footnotes `[^N]` work but Obsidian appends reuse counters (`[4-1]`, `[4-2]`, `[4-3]`) for sources cited multiple times — visually noisy for high-reuse reports.

Both `wikilink` and `ieee` resolve to the same inline shape — superscript number linking directly to the source URL: `<sup>[N](url)</sup>`. The reference list is identical: numbered, in citation order, with the visible `[N]` bolded for prominence (`**[N]** Publisher, "Title", Year. [URL](URL)`). `initialize-project.sh` normalises `wikilink` → `ieee` so downstream consumers see one canonical value.

**Anti-pattern — double brackets `[[N]]`**: Never emit `[[N]]` (double square brackets) anywhere in inline citations. The bug shipped in v0.8.x deep-mode reports — `cogni-research/scripts/fix-citations.py` retroactively normalises legacy reports to `<sup>[N](url)</sup>`. Single-bracket superscripts only.

### Local-Wikilink

**Inline**: `([Author, Year](../02-sources/data/src-<slug>.md))` — APA author-date text linked to the project's local curated source file instead of the remote URL. Use the exact slug from the source entity's filename.

**Reference list**: same as APA, but the publisher/title link target is the local `src-<slug>.md` file.

**Example**:
- Inline: `The adoption gap widened in 2026 ([Plattform Lernende Systeme, 2026](../02-sources/data/src-plattform-lernende-systeme-164c1c24.md))`
- Reference: `[Plattform Lernende Systeme](../02-sources/data/src-plattform-lernende-systeme-164c1c24.md). (2026). *KI-Adoption im Mittelstand*.`

**When to use**: self-contained Obsidian-browsable projects where clicking a citation should open the curated source markdown file (with its Claude-written summary) offline, without needing an internet connection. Each `src-<slug>.md` file already contains the original URL in its YAML frontmatter, so a reader who wants to drill further still has the canonical link one hop away.

## Hard rule: inline citations must be clickable

**For all link-based formats (apa, mla, harvard, ieee, chicago, local-wikilink), plain-text inline citations like `(Publisher, 2026)` are a format violation, not a stylistic choice.** The writer and revisor agents must render every inline citation as a clickable markdown link matching the format's pattern. The only exception is a source with no URL at all (rare — internal portfolio reference, proprietary document) — in that case render `<sup>[N]</sup>` as a plain superscript without a link, and the appendix entry carries the source identifier without a clickable URL.

This rule exists because cogni-research v0.7.9 (issue #48) found that the writer was silently drifting to plain-text citations under deep-mode length pressure, and the revisor preserved the drift across two expansion iterations because its Citation density parity rule only measured density, not linking. See `cogni-research/agents/writer.md` Phase 2 Writing Guidelines and `cogni-research/agents/revisor.md` Phase 2 Preserve markdown citation syntax rule for the enforcement points.

## Default

When no `citation_format` is specified: **APA**.

## Writer Instructions

The writer agent should:
1. Read `citation_format` from `project-config.json` (default: "apa")
2. Apply the matching inline citation style throughout the report
3. Generate the reference list at the end in the matching format
4. Always render inline citations as clickable markdown links for link-based formats — plain-text cites are a format violation
5. Every reference list entry must also be clickable — the publisher/title is the link target, not a trailing plain-text URL
6. Maintain consistent formatting across all sections
7. **Before writing the draft to disk**, scan the drafted prose for any inline citation that does not match the selected format's link pattern (`\(\[.*\]\(.*\)\)` for apa/mla/harvard/local-wikilink; `<sup>\[[0-9]+\]\(.*\)</sup>` for chicago/ieee/wikilink-alias) and rewrite any that don't match. Also fail-fast on the legacy anti-pattern `\[\[[0-9]+\]\]` (double-bracket) anywhere in the draft — this was the v0.8.x drift that broke in Obsidian. This is a self-check, not a hard gate — but if the writer ships plain-text or `[[N]]` cites, the orchestrator's Phase 5 review will bounce the draft back.
