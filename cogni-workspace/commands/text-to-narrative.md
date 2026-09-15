---
name: text-to-narrative
description: Turn text into an arc-driven executive narrative and one design brief for Claude Design — slides, document, infographic or web.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
arguments:
  - name: source
    description: Directory of research files, or a finished narrative .md carrying arc_id and word_count frontmatter (then only the brief is built).
    required: true
  - name: target
    description: "Claude Design generator the brief is for: slides (default), document, infographic, web"
    required: false
  - name: arc
    description: Explicit arc id; skips detection and the arc confirmation.
    required: false
  - name: lang
    description: "Output language: en (default) or de"
    required: false
  - name: brief_path
    description: "Where to write the design brief (default: design-brief.md beside the narrative)"
    required: false
  - name: max_units
    description: Upper bound on brief units — slides, infographic blocks or web sections; ignored on document.
    required: false
  - name: theme
    description: Absolute path to a theme.md, recorded in the brief verbatim; never prompted for.
    required: false
  - name: interactive
    description: "Whether the skill may pause for input: true (default) or false"
    required: false
---

Invoke `cogni-publishing:text-to-narrative` and pass `$ARGUMENTS` unchanged. Return its result unchanged.

If `cogni-publishing` is unavailable, stop with an actionable message telling the user to install that plugin. Do not fall back to workspace implementation logic.
