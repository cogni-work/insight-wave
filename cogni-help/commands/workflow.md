---
name: workflow
description: Show cross-plugin workflow templates for common multi-plugin pipelines
argument-hint: "[workflow-name]"
allowed-tools:
  - Read
  - Glob
---

Show step-by-step workflow templates for chaining insight-wave plugins.

Accept either:
- A user-facing workflow name (research-to-report, trends-to-solutions,
  portfolio-to-pitch, consulting-engagement) — show that specific workflow
- An operational ID (docs-pipeline, full-onboarding) — show the
  internal/operational template with its framing banner
- No argument — list user-facing workflows only

Steps:
1. Load the workflow skill for template structure and presentation rules
2. If a workflow name is provided, load the matching template from
   references/workflows/ (user-facing IDs) or references/internal-workflows/
   (operational IDs like docs-pipeline, full-onboarding)
3. Present the pipeline diagram and walk through each step
4. If no argument, present the user-facing workflow summary table
