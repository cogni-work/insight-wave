# Citation Formats Reference

> **Forked** from `cogni-research/references/citation-formats.md` (point-in-time copy; drift acceptable). Adapted for the inverted pipeline: the `local-wikilink` format and the `fix-citations.py` retro-normaliser are dropped (cogni-knowledge has no `02-sources/data/` local-source layout — it is wiki-first), and the default is **`ieee`**, not APA, because numbered superscripts are what the pipeline defaults to; the author-date family renders alongside them.

The `citation_format` field controls how the `wiki-composer` renders inline citations and the reference list. It is resolved in `knowledge-plan` Step 0.5 (precedence: `--citation-format` flag > `binding.research_defaults.citation_format` > `ieee`), written into `plan.json::citation_format`, and threaded to the composer as `CITATION_FORMAT`. The writer applies the inline shape via its prompt; the reference-list string and its ordering are code-level, in `_knowledge_lib` (`author_date_reference_entry` / `build_author_date_reference_list` for the author-date family, and `knowledge-finalize`'s own `**[N]**` arm for the numbered one).

## Wiring status

| Format | Family | Status |
|--------|--------|--------|
| **ieee** (default) | numbered | **Wired end-to-end.** |
| **chicago** | numbered | **Wired end-to-end** (same inline shape as IEEE; the reference-list *string* differs). |
| **apa** | author-date | **Wired end-to-end** — `([Author, Year](url))` inline, alphabetical un-numbered reference list. |
| **mla** | author-date | **Wired end-to-end** — `([Author](url))` inline (no year), same list discipline as APA. |
| **harvard** | author-date | **Wired end-to-end** — `([Author Year](url))` inline (no comma), same list discipline as APA. |

Both numbered formats render the identical inline superscript shape, so the reviewer's density gate, the revisor's marker handling, and `knowledge-finalize`'s numbered renumber pass behave identically across `ieee` and `chicago` — only the reference-list string differs. That is a statement about the numbered family, not about the pipeline: the author-date family carries its own marker shape through the same surfaces, each of which resolves the family (via `_knowledge_lib.citation_family`) rather than assuming numbered.

### IEEE (default)

**Inline**: Superscript number linking directly to the source URL: `<sup>[N](url)</sup>`.
**Reference list** (numbered, in first-appearance order, bold visible `**[N]**` for prominence):
```
**[1]** A. Author, "Title," *Publisher*, Month Year. [https://example.com/article](https://example.com/article)
```
Number sources sequentially by order of first appearance. Reuse the same number when citing the same source again. The inline superscript renders as a clickable `¹` in Obsidian / GitHub / Pandoc and opens the source URL directly.

### Chicago (CMS)

**Inline**: identical to IEEE — superscript number `<sup>[N](url)</sup>` (numbered family).
**Reference list** (Bibliography style, still numbered `**[N]**` so the inline markers line up with the finalize renumber pass):
```
**[1]** Author Last, First. "Title." *Publisher*, Month Day, Year. [https://example.com/article](https://example.com/article)
```
The only difference from IEEE is the entry *string* (author-last-name-first + full date), not the inline marker or the numbering.

### APA / MLA / Harvard (author-date family)

These use an author-date **inline** shape — `([Author, Year](url))` (APA), `([Author](url))` (MLA), `([Author Year](url))` (Harvard) — and an alphabetical, un-numbered reference list, sorted by author surname with no `**[N]**` prefix. Author and year resolve from the cited page's frontmatter, explicit key first: `author:` else the `publisher:` surrogate, and the leading four digits of `published_date:` else of `fetched_at:` — so a page ingested before those keys existed still renders, and a base already persisting `apa` needs no migration. A missing year renders `n.d.`; an entry with no resolvable author leads with its title and sorts last.

That inline shape carries no `[N]`, so every surface that reads markers resolves the citation **family** first: `knowledge-finalize` assembles the reference list alphabetically and bypasses the `renumber_inline_citations` pass, and the `wiki-reviewer` density gate and `revisor` read-back check count the author-date shape alongside the numbered ones. Reference-list entries render as `Author. (Year). "Title". Publisher.` (APA), `Author. "Title." Publisher, Year.` (MLA), and `Author (Year) "Title". Publisher. Available at: …` (Harvard).

## Hard rule: inline citations must be clickable

For every link-based format, **unbracketed** plain-text inline citations like `(Publisher, 2026)` are a **format violation**, not a stylistic choice. The composer renders every inline citation as a clickable markdown link. The only exception is a source with no URL at all (a synthesis, distilled `dcl-NNN` or question-node `acl-NNN` page whose `sources:` are `wiki://…` backlinks), and that exception is stated **per family**:

- **Numbered** (`ieee`, `chicago`) — render `<sup>[N]</sup>` as a plain superscript without a link.
- **Author-date** (`apa`, `mla`, `harvard`) — render the **destination-less** form of that format's own inline shape: `([Publisher, 2026])` (APA), `([Publisher])` (MLA), `([Publisher 2026])` (Harvard). This is sanctioned rather than a violation because the **single-bracketed label** is what distinguishes a marker from prose — an unbracketed `(Publisher, 2026)` remains a violation in every format. A numbered `<sup>[N]</sup>` must not appear in an author-date draft: the reference list is alphabetical and un-numbered, and `knowledge-finalize` bypasses the renumber pass for this family, so the numeral could never be resolved.

On both legs the reference-list entry carries the `[[<slug>]]` wikilink.

**Anti-pattern — double brackets `[[N]]`**: Never emit `[[N]]` (double square brackets) anywhere in inline citations. Obsidian parses `[[N]]` as a wikilink to a missing note named "N", so the citation appears clickable but jumps nowhere. Single-bracket superscripts only — `<sup>[N](url)</sup>`. The `wiki-reviewer` density gate independently flags any `[[N]]` as a high-severity citation-format violation.

## Default

When no `citation_format` is specified: **ieee**.
