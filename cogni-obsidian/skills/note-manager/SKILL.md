---
name: note-manager
description: >-
  Create properly formatted markdown notes with YAML frontmatter in an Obsidian vault. Use this
  skill whenever the user asks to create a note, write a markdown file with metadata, add
  frontmatter to a document, or save content to their vault. Also trigger when any cogni-x plugin
  needs to produce output files that should be discoverable in Obsidian — the frontmatter standard
  ensures consistent metadata across all plugin outputs.
version: 1.1.0
---

## Purpose

Provide a consistent way to create markdown notes that work well in Obsidian. Every note gets YAML frontmatter with at least a title and date, which makes it searchable, taggable, and visible in Obsidian's graph view. The approach is deliberately minimal — Obsidian handles linking, rendering, and indexing, so the notes just need to be well-structured standard markdown.

## Frontmatter Standard

```yaml
---
title: "Note Title"
date: 2026-03-01
tags:
  - tag1
source: plugin-name
---
```

**Required:** `title` (string) and `date` (YYYY-MM-DD).

**Optional:**
- `tags` (list) — for Obsidian search and graph view
- `source` (string) — which plugin created the note (e.g., "cogni-research", "cogni-narrative")
- `status` (string) — workflow state: draft, review, or final
- `related` (list) — paths to related notes

## Creating Notes

Use the Write tool. Always include frontmatter, even for simple notes.

**Example — user note:**
```markdown
---
title: "Meeting Notes - Q1 Review"
date: 2026-03-01
tags:
  - meetings
  - quarterly
---

# Meeting Notes - Q1 Review

Content goes here...
```

**Example — plugin output:**
```markdown
---
title: "Market Analysis - DACH Region"
date: 2026-03-01
tags:
  - research
  - market-analysis
source: cogni-research
status: final
---

# Market Analysis - DACH Region

Research findings...
```

## File Naming and Placement

Use **kebab-case** filenames: `meeting-notes-q1-review.md`, `market-analysis-dach.md`. For daily notes, prefix with the date: `2026-03-01-daily-standup.md`.

Place files according to vault structure:
- Plugin output goes in the plugin's directory (e.g., `cogni-research/findings/`)
- General notes go in the vault root or a user-specified folder
- Check for existing files before writing to avoid accidental overwrites

## Key Rules

1. **Standard markdown only** — no wikilinks or Obsidian-specific embed syntax; use regular markdown links
2. **Always include frontmatter** — title and date at minimum, tags for discoverability
3. **Respect existing structure** — read the vault layout before placing files
