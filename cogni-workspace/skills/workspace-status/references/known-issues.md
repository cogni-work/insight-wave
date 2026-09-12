# Known Issues

Maintained list of diagnosed problems and their fixes. Add new entries as patterns emerge.

---

## Leftover course-progress file

**Symptom**: `.claude/cogni-teacher.local.md` or `.claude/cogni-help.local.md` is present
but nothing reads it.

**Cause**: Both files held progress for the interactive course system, which has been
retired. No surviving skill reads them.

**Fix**: Delete them. There is nothing to migrate to.
```bash
rm -f .claude/cogni-teacher.local.md .claude/cogni-help.local.md
```

---

## Leftover engagement file from a retired consulting plugin

**Symptom**: `diamond-project.json` or `consulting-project.json` is present, but no skill
finds or resumes the engagement.

**Cause**: Both names belong to retired plugins — cogni-diamond, renamed to
cogni-consulting, then retired (source for both remains in git history). No surviving
skill reads either name.

**Fix**: There is nothing to rename to. cogni-consult keeps its engagements at
`cogni-consult/{engagement-slug}/consult-project.json` and has no import path from
either legacy file, so keep the old file as an inert local record and scope a fresh
engagement:
```
/cogni-consult:consult-setup
```

**Note**: renaming a legacy file onto the current name does not migrate it — the
schemas differ (cogni-consult's WBS is action fields, not Double Diamond phases), and
nothing would read the result either.

---

## GitHub not logged in

**Symptom**: The cogni-issues skill fails with an authentication or login error.

**Cause**: GitHub CLI is not authenticated for the current user.

**Fix**: Run `gh auth status`. If authentication is missing, run `gh auth login`,
choose **GitHub.com** and **HTTPS**, and complete the browser or token flow. Then
retry the cogni-issues operation.

---

## Missing COGNI_WORKSPACE_ROOT

**Symptom**: Plugin skills can't find shared resources (themes, env vars).

**Cause**: Workspace not initialized, or `.workspace-env.sh` not sourced by session hook.

**Fix**: Run `/manage-workspace` to set up or update the workspace, or `/workspace-status` to
diagnose what's missing.

---

## PPTX generation produces no .pptx file

**Symptom**: A `presentation-brief.md` is in hand, but no `.pptx` file is produced.

**Cause**: A presentation brief is not a deck — rendering it is a separate step, and the
skill that performs it does not ship from this marketplace. Nothing in this plugin writes
the brief either: the `story-to-slides` producer that once did has retired, so a brief is
hand-authored against `libraries/presentation-brief-template.md` or supplied by a caller.
The render paths are a claude.ai chat with the Anthropic PPTX skill, the in-Claude-Code
`pptx` agent, or an HTML deck via `/render-html-slides`. The `pptx` agent dispatches
`anthropic-skills:pptx` first and `document-skills:pptx` second; when neither resolves in
the session it returns `pptx_skill_unavailable`.

**Fix**: Take the claude.ai route — open a new chat there and attach the
`presentation-brief.md` together with a `theme.md` (resolve one through `manage-themes`
Operation 11 when the brief carries no `theme_path`), then ask for a deck built from the
brief's Rendering Contract. For a no-PowerPoint result, run `/render-html-slides` instead.
