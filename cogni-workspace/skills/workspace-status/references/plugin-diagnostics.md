# Plugin-Level Diagnostics

Procedures for check 7 of `workspace-status` — the plugin-level tier. The SKILL.md
body says *what* each probe establishes and when to reach for it; this file carries
the commands and the lookup tables.

Findings from every probe here are reported in the same Symptom → Cause → Fix shape
the SKILL.md states, using the same field labels `references/known-issues.md` uses,
so a catalogued fix and a fresh diagnosis read identically.

## 7a. Plugin availability

Verify the plugin directory exists and carries a valid `plugin.json`. Start from the
marketplace, which is the roster every other probe is measured against:

```bash
cat .claude-plugin/marketplace.json | python3 -c "
import json, sys
data = json.load(sys.stdin)
for p in data['plugins']:
    print(f\"{p['name']}: {p['source']}\")
"
```

Then verify each `source` directory exists and contains `.claude-plugin/plugin.json`.
A plugin listed in the marketplace whose source is missing is the fault; a directory
present but unlisted is a registration gap, which check 3 (Plugin Registry) owns.

## 7b. Skill-file integrity

For a named plugin, check that every skill directory holds a `SKILL.md` whose YAML
frontmatter parses and carries at minimum `name` and `description`:

```bash
ls -d <plugin-dir>/skills/*/SKILL.md 2>/dev/null
```

Read each one and confirm the frontmatter parses. A skill directory with no
`SKILL.md`, or one whose frontmatter is malformed, will not load — and fails
silently rather than erroring, which is why this is a probe rather than something
the session surfaces on its own.

## 7c. Progress and state-file health

Check `.claude/*.local.md` files for valid YAML frontmatter structure. The recurring
faults are:

- malformed YAML — a missing closing `---`, or bad indentation
- stale project or entity IDs left by a renamed plugin
- corrupted status values

`.claude/cogni-help.local.md` is inert: it held progress for the retired course
system and nothing reads it. Treat it as safe to delete, never as a fault.

## 7d. Cross-plugin dependencies

Many plugins require others to function. Verify each required plugin has a
marketplace entry:

| Plugin | Requires |
|--------|----------|
| cogni-marketing | cogni-trends, cogni-portfolio |
| cogni-sales | cogni-portfolio, cogni-workspace (the `text-to-narrative` skill) |
| cogni-consult | cogni-knowledge (required research spine) |

cogni-consulting was retired and its source remains only in git history. It has no
marketplace entry, so it is absent from the table above rather than listed as a
dependency nothing can satisfy; route new consulting issues to cogni-consult.

## 7e. Stale state from retirements

After a plugin retirement, orphaned files linger with nothing to reap them:

```bash
# Retired cogni-diamond / cogni-consulting engagement state.
# find, not a ** glob: engagement files sit two segments deep
# ({plugin}/{engagement-slug}/), and ** only recurses where globstar is on.
# -maxdepth 3 is that same bound, so the walk skips .git, caches and vaults.
find . -maxdepth 3 -type f \( -name 'diamond-project.json' -o -name 'consulting-project.json' \) 2>/dev/null

# Inert course-progress files (the course system is retired)
ls .claude/cogni-teacher.local.md .claude/cogni-help.local.md 2>/dev/null
```

Route each hit to `references/known-issues.md`, which carries the full remedy:

- Engagement file (`diamond-project.json`, `consulting-project.json`) — "Leftover
  engagement file from a retired consulting plugin". Keep it as an inert local
  record; there is no import path into cogni-consult.
- Course-progress file (`cogni-teacher.local.md`, `cogni-help.local.md`) —
  "Leftover course-progress file". Delete it; nothing reads it any more.

## 7f. Common misconfigurations

Recognition patterns rather than probes — name the symptom, then route to the
remedy. Each has a `references/known-issues.md` entry that carries the fix.

- **Missing `COGNI_WORKSPACE_ROOT`** — a plugin reports that shared resources
  (themes, env vars) are unavailable, typically because the workspace was never
  initialized or `.workspace-env.sh` is not sourced by the session hook. Check 2
  (Environment) confirms it directly; `/manage-workspace` repairs it. See the
  entry "Missing COGNI_WORKSPACE_ROOT".
- **GitHub CLI not authenticated** — the `cogni-issues` skill fails with an
  authentication or login error. `gh` is not among the tools check 5 (Dependencies)
  probes, so `references/known-issues.md` stays its documented owner — see
  "GitHub not logged in".
- **PPTX rendering skill unavailable** — the skill that renders a
  presentation brief into a `.pptx` does not ship from this marketplace; the
  `pptx` agent tries `anthropic-skills:pptx` then `document-skills:pptx` and
  returns `pptx_skill_unavailable` when neither resolves. Take the claude.ai
  attachment path or the HTML deck (`/render-html-slides`) instead: neither
  needs anything installed here.
