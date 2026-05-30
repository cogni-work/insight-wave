# Citation Formats Reference

> **Forked** from `cogni-research/references/citation-formats.md` (point-in-time copy; drift acceptable). Adapted for the inverted pipeline: the `local-wikilink` format and the `fix-citations.py` retro-normaliser are dropped (cogni-knowledge has no `02-sources/data/` local-source layout — it is wiki-first), and the default is **`ieee`**, not APA, because the whole pipeline (composer inline markers, verifier/reviewer density scans, finalize numbered renumber pass) is built on numbered superscripts.

The `citation_format` field controls how the `wiki-composer` renders inline citations and the reference list. It is resolved in `knowledge-plan` Step 0.5 (precedence: `--citation-format` flag > `binding.research_defaults.citation_format` > `ieee`), written into `plan.json::citation_format`, and threaded to the composer as `CITATION_FORMAT`. The writer applies the format via its prompt — there is no code-level inline-formatting logic.

## Wiring status

| Format | Family | Status |
|--------|--------|--------|
| **ieee** (default) | numbered | **Wired end-to-end.** |
| **chicago** | numbered | **Wired end-to-end** (same inline shape as IEEE; the reference-list *string* differs). |
| **apa** | author-date | **Staged.** Accepted + persisted, but rendered as numbered until the format-aware finalize follow-up lands (see below). |
| **mla** | author-date | **Staged** (as APA). |
| **harvard** | author-date | **Staged** (as APA). |

Both numbered formats render the identical inline superscript shape, so the verifier's `<sup>[N](url)</sup>` scan, the reviewer's density gate, the revisor's marker handling, and `knowledge-finalize`'s numbered renumber pass all work unchanged across `ieee` and `chicago`. Only the reference-list string differs.

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

### APA / MLA / Harvard (staged — author-date family)

These use an author-date **inline** shape — `([Author, Year](url))` (APA), `([Author](url))` (MLA), `([Author Year](url))` (Harvard) — and an alphabetical, un-numbered reference list. That inline shape has no `[N]`, so it is **not compatible** with the current numbered pipeline: `knowledge-finalize`'s `renumber_inline_citations` pass and the `<sup>[N]` scans in `wiki-verifier` / `wiki-reviewer` / `revisor` all assume numbered markers. Until those are made citation-family-aware (the named P2 follow-up — see `references/absorption-roadmap.md`), selecting `apa` / `mla` / `harvard` is accepted and persisted but the composer renders the **numbered** form. No data is lost; the choice is remembered for when author-date rendering ships.

## Hard rule: inline citations must be clickable

For every link-based format, plain-text inline citations like `(Publisher, 2026)` are a **format violation**, not a stylistic choice. The composer renders every inline citation as a clickable markdown link. The only exception is a source with no URL at all (a synthesis or distilled page whose `sources:` are `wiki://…` backlinks) — render `<sup>[N]</sup>` as a plain superscript without a link, with the reference-list entry carrying the `[[<slug>]]` wikilink.

**Anti-pattern — double brackets `[[N]]`**: Never emit `[[N]]` (double square brackets) anywhere in inline citations. Obsidian parses `[[N]]` as a wikilink to a missing note named "N", so the citation appears clickable but jumps nowhere. Single-bracket superscripts only — `<sup>[N](url)</sup>`. The `wiki-reviewer` density gate independently flags any `[[N]]` as a high-severity citation-format violation.

## Default

When no `citation_format` is specified: **ieee**.
