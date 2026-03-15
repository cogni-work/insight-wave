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

## Default

When no `citation_format` is specified: **APA**.

## Writer Instructions

The writer agent should:
1. Read `citation_format` from `project-config.json` (default: "apa")
2. Apply the matching inline citation style throughout the report
3. Generate the reference list at the end in the matching format
4. Always include the URL as a clickable markdown hyperlink in citations
5. Maintain consistent formatting across all sections
