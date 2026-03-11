# Copywriting Plugin

A copywriting plugin for Claude Code. Polish documents for executive readability, get multi-stakeholder feedback, and strengthen story arc narratives — in English or German. Applies messaging frameworks, readability standards, and impact techniques so your writing lands.

## Installation

```bash
claude plugins add cogni-copywriting
```

## Commands

| Command | Description |
|---------|-------------|
| `/copywrite` | Polish a document for executive readability — apply messaging frameworks (BLUF, Pyramid, SCQA, STAR, PSB, FAB), optimize readability, and add visual hierarchy |
| `/review-doc` | Run parallel stakeholder personas (executive, technical, legal, marketing, end-user), synthesize feedback, and auto-apply improvements |

## Skills

Domain knowledge Claude uses automatically when relevant:

| Skill | Description |
|-------|-------------|
| `copywriter` | Executive document polishing — 7 messaging frameworks, 9 deliverable types, readability scoring (Flesch/Amstad), Wolf Schneider German style rules, arc-aware narrative mode, and sales enhancement |
| `reader` | Multi-stakeholder review — 5 parallel personas with cross-persona synthesis, blind spot detection, and automatic improvement with backup |

## Example Workflows

### Polish, Then Review

The recommended sequence: polish first to get the document into shape, then review to validate and catch blind spots.

```
/copywrite quarterly-report.md
```

Reads the document, detects it's a report, applies Pyramid Principle structure, transforms academic language to executive tone, adds visual hierarchy. Validates with Flesch score, active voice percentage, and visual element count.

```
/review-doc quarterly-report.md
```

Creates a backup, runs 5 personas in parallel, synthesizes critical and high-priority improvements, auto-applies them. Reports overall score and improvement count.

### Scoped Polishing

Focus on one dimension — skip the rest:

```
/copywrite research-paper.md --scope=tone
```

Transforms passive academic voice to direct executive language. Structure and formatting stay untouched. Also supports `--scope=structure` (McKinsey Pyramid only) and `--scope=formatting` (visual hierarchy only).

### Feedback Only

```
/review-doc proposal.md --no-improve
```

Runs all 5 personas but does not modify the document. Returns structured feedback per persona with scores — you decide what to apply. Also supports `--personas=executive,legal` to run specific personas only.

### Story Arc Polishing

When paired with `cogni-narrative`, detects story arcs and applies element-specific techniques without breaking arc structure:

```
/copywrite why-change-narrative.md
```

Detects `arc_id` in frontmatter, loads arc-technique-map, and applies techniques tuned to each arc element — ratio framing for Why Change, forcing functions for Why Now, compound impact for Why Pay.

### German Documents

```
/copywrite vorstandsbericht.md
```

Detects German language automatically, loads Wolf Schneider style rules — breaks Satzklammer, shortens Mittelfeld, eliminates Floskeln, chains Hauptsatze for rhythm. Validates with Amstad readability score. Preserves all German characters and citations.

## Language Support

| Language | Readability | Style Rules | Metric |
|----------|-------------|-------------|--------|
| English | Flesch Reading Ease | Messaging frameworks, active voice, visual hierarchy | Target: 50-60 |
| German | Amstad | Wolf Schneider (7 rules: Satzklammer, Mittelfeld, Floskeln, Rhythmus, etc.) | Target: 30-50 |

## Prerequisites

- Python 3 (for readability calculations)
- Claude Code with plugin support

## Architecture

```
cogni-copywriting/
├── .claude-plugin/plugin.json    Plugin manifest
├── skills/                       2 copywriting skills
│   ├── copywriter/
│   └── reader/
├── agents/                       2 delegation agents
│   ├── copywriter.md
│   └── reader.md
└── commands/                     2 slash commands
    ├── copywrite.md
    └── review-doc.md
```

## License

[AGPL-3.0](LICENSE)
