---
name: copywriter
description: Polish, rewrite, or create business documents (memos, briefs, reports, proposals, one-pagers, executive summaries, emails, blog posts, business letters) using professional messaging frameworks (BLUF, McKinsey Pyramid, SCQA, STAR, PSB, FAB) and persuasion techniques (number plays, power words, rhetorical devices). Use this skill when the user asks to polish a document, improve writing, make something more readable, restructure a brief, apply BLUF or Pyramid Principle, rewrite for executives, strengthen messaging, create a proposal, write a one-pager, clean up a report, compress a document to minimum length without losing facts, shorten a synthesis for circulation, tighten a document while keeping every citation and number, or apply any named messaging framework. Handles German documents (Wolf Schneider style), arc-aware narrative polishing (story arcs with arc_id), and IS/DOES/MEANS sales messaging. Simple requests like "make this better" about a markdown file should trigger this skill.
allowed-tools: Read, Write, Edit, Bash, Agent, TodoWrite, Skill
---

<!-- compatibility-delegate: cogni-publishing -->

# Copywriter Compatibility Route

Dispatch `cogni-publishing:copywriter` with the user's request and arguments unchanged. Return its result unchanged; keep no copywriting, translation, or readability logic here.

If `cogni-publishing` is not installed, stop and tell the user to install that plugin. Do not recurse into this workspace route or attempt a reduced local workflow.
