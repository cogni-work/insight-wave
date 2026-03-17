# Standalone Mode Reference

When verify-report operates on a markdown file outside a cogni-gpt-researcher project, it creates a lightweight workspace and adapts its behavior for the absence of source entities.

## Citation Detection

The claim-extractor scans the markdown for three citation patterns:

### Inline links
```markdown
According to [Source Title](https://example.com/article), the metric improved by 40%.
```
→ Extracts URL `https://example.com/article` and title "Source Title"

### Footnote references
```markdown
The metric improved by 40%[^1].

[^1]: https://example.com/article "Source Title"
```
→ Resolves footnote to URL and optional title

### Numbered reference sections
```markdown
The metric improved by 40% [1].

## References
1. Author Name. "Article Title." *Publication*, 2025. https://example.com/article
```
→ Matches `[1]` to reference list entry, extracts URL from reference text

## Workspace Layout

Created as a sibling to the markdown file:

```
parent-directory/
├── report.md                          # The file being verified
└── .verify-report/
    └── report/                        # Slug derived from filename
        ├── .metadata/
        │   ├── project-config.json    # standalone_mode: true
        │   ├── execution-log.json
        │   ├── user-claims-review.json
        │   └── review-verdicts/
        ├── 03-report-claims/
        │   └── data/                  # Report-claim entities
        └── cogni-claims/
            ├── claims.json            # Verification results
            └── sources/               # Cached source content
```

## project-config.json (standalone)

```json
{
  "topic": "report.md",
  "report_type": "basic",
  "language": "en",
  "standalone_mode": true,
  "source_path": "/absolute/path/to/report.md"
}
```

## Limitations

- **No source entity cross-referencing.** In Mode A, claim-extractor uses `02-sources/data/` entities for O(1) URL lookup. In standalone mode, it extracts URLs directly from citation syntax in the markdown — slower but functional.
- **No context validation.** Cannot verify whether the draft faithfully represents the research findings, since no research contexts exist.
- **No execution-log continuity.** The standalone workspace has its own execution-log, not connected to any prior research pipeline.
- **Draft path is fixed.** The original markdown file is the draft. If the revisor produces a revised version, it writes to `output/draft-v{N}.md` within the `.verify-report/` workspace, not alongside the original file.
