# Known Issues

Maintained list of diagnosed problems and their fixes. Add new entries as patterns emerge.

---

## Stale progress file after cogni-teacher rename

**Symptom**: Course progress not loading, `/courses` shows all courses as not-started
despite having completed courses.

**Cause**: Progress file still named `.claude/cogni-teacher.local.md` after the plugin
was renamed to cogni-help.

**Fix**: Rename the file:
```bash
mv .claude/cogni-teacher.local.md .claude/cogni-help.local.md
```

---

## Stale project file after cogni-diamond rename

**Symptom**: Consulting engagement data not found when resuming a project.

**Cause**: Project file still named `diamond-project.json` after the plugin was renamed
to cogni-consulting.

**Fix**: Rename the file:
```bash
mv diamond-project.json consulting-project.json
```

---

## GitHub not logged in

**Symptom**: `/issues` fails with authentication or login error.

**Cause**: The user is not logged into GitHub in Chrome.

**Fix**: Run `/issues` with no argument — the cogni-issues skill will detect the
missing login and walk you through signing in via the browser. No CLI tools or
tokens needed.

---

## Missing COGNI_WORKSPACE_ROOT

**Symptom**: Plugin skills can't find shared resources (themes, env vars).

**Cause**: Workspace not initialized, or `.workspace-env.sh` not sourced by session hook.

**Fix**: Run `/init-workspace` to set up the workspace, or `/workspace-status` to
diagnose what's missing.

---

## PPTX generation fails with "pptxgenjs not found"

**Symptom**: `/course-deck` or `/render-slides` fails.

**Cause**: PptxGenJS not installed globally.

**Fix**:
```bash
npm install -g pptxgenjs
```
