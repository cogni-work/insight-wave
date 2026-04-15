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

**Inline**: Numbered brackets: `[[1](url)]`
**Reference list** (numbered):
```
[1] A. Author, "Title," *Publisher*, Month Year. [Online]. Available: url
```

### Wikilink

**Inline**: Superscript number linking to an anchored reference entry: `<sup>[[N]](#ref-N)</sup>`
**Reference list** (numbered, anchored):
```
<a id="ref-1"></a>[1] A. Author, "Title," *Publisher*, Month Year. https://example.com/article
```

Number sources sequentially by order of first appearance in the report. Each reference entry starts with an `<a id="ref-N"></a>` HTML anchor so the inline superscript links directly to it. Every reference entry must end with the full clickable URL.

**Variant — Wikilink with URL**: The writer agent may produce `[[N]](url)` — a hybrid where the number uses double-bracket wikilink notation but links directly to the source URL instead of an anchor. This is functionally equivalent to the anchored form above but embeds the URL inline. The export skill normalizes both variants identically.

Example: `AI adoption reached 65% [[3]](https://example.com/report)` — the export skill converts this to a superscript `[3]` linking to the URL.

**Full paragraph example**:

> Cloud adoption grew 25% year-over-year in 2025<sup>[[1]](#ref-1)</sup>, driven primarily by AI workload
> migration. Gartner projects that by 2028, over 70% of enterprise AI workloads will run on
> hyperscaler infrastructure<sup>[[2]](#ref-2)</sup>. However, cost optimization remains a challenge —
> a recent Flexera survey found that 32% of cloud spend is wasted<sup>[[3]](#ref-3)</sup>, suggesting
> that governance has not kept pace with adoption.
>
> ## References
>
> <a id="ref-1"></a>[1] Gartner, "Cloud Infrastructure Report 2025," *Gartner Research*, March 2025. https://gartner.com/cloud-report-2025
>
> <a id="ref-2"></a>[2] Gartner, "Top Strategic Technology Trends 2028," *Gartner*, October 2025. https://gartner.com/strategic-trends-2028
>
> <a id="ref-3"></a>[3] Flexera, "2025 State of the Cloud Report," *Flexera*, February 2025. https://flexera.com/state-of-cloud-2025

### Local-Wikilink

**Inline**: `([Author, Year](../02-sources/data/src-<slug>.md))` — APA author-date text linked to the project's local curated source file instead of the remote URL. Use the exact slug from the source entity's filename.

**Reference list**: same as APA, but the publisher/title link target is the local `src-<slug>.md` file.

**Example**:
- Inline: `The adoption gap widened in 2026 ([Plattform Lernende Systeme, 2026](../02-sources/data/src-plattform-lernende-systeme-164c1c24.md))`
- Reference: `[Plattform Lernende Systeme](../02-sources/data/src-plattform-lernende-systeme-164c1c24.md). (2026). *KI-Adoption im Mittelstand*.`

**When to use**: self-contained Obsidian-browsable projects where clicking a citation should open the curated source markdown file (with its Claude-written summary) offline, without needing an internet connection. Each `src-<slug>.md` file already contains the original URL in its YAML frontmatter, so a reader who wants to drill further still has the canonical link one hop away.

## Hard rule: inline citations must be clickable

**For all link-based formats (apa, mla, harvard, ieee, local-wikilink), plain-text inline citations like `(Publisher, 2026)` are a format violation, not a stylistic choice.** The writer and revisor agents must render every inline citation as a clickable markdown link matching the format's pattern. The `chicago` (footnote superscripts) and `wikilink` (anchored numbered references) formats have their own link forms and are exempt from the `([...](...))` shape but still require clickable links.

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
7. **Before writing the draft to disk**, scan the drafted prose for any inline citation that does not match the selected format's link pattern (`\(\[.*\]\(.*\)\)` for apa/mla/harvard/ieee/local-wikilink; `<sup>\[\[[0-9]+\]\]\(#ref-[0-9]+\)</sup>` for wikilink; `<sup>\[[0-9]+\]\(.*\)</sup>` for chicago) and rewrite any that don't match. This is a self-check, not a hard gate — but if the writer ships plain-text cites, the orchestrator's Phase 5 review will bounce the draft back.
