#!/usr/bin/env python3
"""check-skill-spec.py -- every SKILL.md satisfies the published Agent Skills standard.

WHY THIS EXISTS. The standard a skill is graded against is published in two
places -- the Agent Skills specification (agentskills.io/specification) and
Anthropic's skill-authoring best practices -- and nothing in this repo's CI
read either. `check-skill-names.sh` grades the `name:` field for duplicates and
generic words, `test-skill-trigger-phrases.sh` grades description CONTENT for
collisions, and the `plugin-validator` agent grades structure -- but that agent
is not CI. So a SKILL.md could drift past every published limit while every
guard stayed green, and one audit found exactly that: four bodies over the
500-line ceiling, eight descriptions within thirty characters of the 1024 cap,
a stale README parked inside a skill directory, and two skills whose reference
trees nested two levels deep with most of their files never pointed to from
SKILL.md. Each of those is silent: the host loads the skill, the skill works,
and the cost is paid in context and in files the model previews with `head`
instead of reading.

SIX ARMS, in two classes.

  HARD ARMS -- no baseline, no allowlist, no skip marker. Each is a rule of the
  specification that a single edit satisfies, so there is nothing to ratchet.

  (1) NAME -- 1-64 characters, lowercase letters, digits and single hyphens,
      not starting or ending with one, and EQUAL TO THE DIRECTORY NAME. The
      spec makes all five normative; the host derives the skill's identity
      from the directory, so a `name:` that disagrees is a skill answering to
      two names.

  (2) DESCRIPTION -- present, non-empty, and at most 1024 characters AFTER the
      YAML scalar is resolved. Measuring the raw block would over-count every
      `>-` and `|` description by its indentation, and this repo writes most
      descriptions that way. Claude Code's own cap is 1536, which is why the
      spec's tighter limit is the one to guard: the host masks the breach.

  RATCHET ARMS -- baselined in `scripts/baselines/skill-spec-baseline.json`.
  These are the progressive-disclosure rules, and satisfying them on a skill
  that has grown past them is a restructure, not an edit. A guard that failed
  the tree on day one would be turned off; a guard that admits the measured
  population and refuses any NEW finding is the shape this repo already uses
  (`check-breadcrumbs.py`, and `KNOWN_UNMIRRORED` in
  `cogni-workspace/tests/test-arc-reference-sync.sh`). The baseline key is
  (skill, arm, file) and carries no measurement, so an admitted length finding
  suppresses that SKILL.md at any line count: the ratchet refuses a new
  over-length skill and refuses a stale entry, but does not refuse growth
  inside a skill already admitted. Recording the measured value on length
  entries would close that gap and is deliberately not done at adoption --
  the admitted skills are each tracked as their own restructure, and a
  per-entry number would go stale on every edit to a file the guard is not
  gating yet. The baseline captured
  at adoption admits two populations: the deep reference trees of three
  cogni-workspace skills (narrative, copy-reader, story-to-web), whose
  flattening is tracked as its own restructure; and the length, depth and
  orphan findings in six other
  plugins, each of which is that plugin's own piece of work. No cogni-workspace
  skill is admitted on the length arm.

  (3) LENGTH -- the whole SKILL.md at most 500 lines. The spec says "keep your
      main SKILL.md under 500 lines"; the best-practices page says the same of
      the body. The file count is the stricter reading and the one a `wc -l`
      reproduces, so it is the one asserted. Ratcheted rather than hard
      because the adoption measurement found nine skills across four other
      plugins over the ceiling, and moving a hundred lines of procedure into a
      reference is precisely the restructure a ratchet arm exists to admit.

  (4) STRAY-FILE -- `README.md`, `CHANGELOG.md` or `INSTALLATION.md` at the
      skill root. The spec permits any file, but the authoring guidance is
      explicit that these are not skill payload, and the observed instance was
      a README that had become a second, stale specification contradicting
      SKILL.md on the workflow and the default output path.

  (5) REFERENCE-DEPTH -- a directory nested inside `references/`. The
      best-practices rule is "keep file references one level deep from
      SKILL.md"; the mechanical proxy is the directory tree, because a file
      two directories down is one the model reaches through an intermediate
      listing rather than a direct pointer. A directly linked top-level index
      can make resources discoverable for arm (6), but does not make a nested
      directory satisfy this separate depth rule; flattening is the remedy.

  (6) UNREFERENCED-RESOURCE -- a file under `references/`, `scripts/`,
      `examples/`, `schemas/` or `assets/` whose basename appears nowhere in
      SKILL.md or in a `references/00-index.md` that SKILL.md links directly.
      The standard's stated failure mode is that the model does not know the
      file exists. The single index hop supports deliberate progressive
      disclosure without recursively treating every resource it names as a
      router. Matching resources on basename rather than full path is
      deliberate: this repo cites both `references/x.md` and bare `x.md` in
      resource tables, and the basename is what both forms share.

THE RATCHET CAN ONLY SHRINK. A baseline entry that no longer matches a live
finding is itself a violation (`stale-baseline`): the fix is to delete the
entry, never to leave it, so the baseline cannot silently outlive the drift it
records. A finding on a HARD arm is never baselined -- an entry naming one is
reported as `stale-baseline` too, since nothing can match it.

DISCOVERY is the plugin roots the marketplace pattern defines -- top-level
directories holding `.claude-plugin/plugin.json`, dot-prefixed entries pruned
so `.claude/worktrees/**` never registers -- and then `skills/*/SKILL.md` under
each. Zero discovery is exit 2, not a clean sweep. Frontmatter is read from the
leading `---` block only; a body that quotes `name:` while documenting the
format must not satisfy the requirement.

Stdlib-only. Suite: tests/test_check_skill_spec.sh
"""

import argparse
import json
import os
import re
import sys

MANIFEST = os.path.join(".claude-plugin", "plugin.json")
NAME_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
NAME_MAX = 64
DESCRIPTION_MAX = 1024
LINES_MAX = 500
STRAY_FILES = {"readme.md", "changelog.md", "installation.md"}
RESOURCE_DIRS = ("references", "scripts", "examples", "schemas", "assets")
HARD_ARMS = ("name", "description")
RATCHET_ARMS = ("length", "stray-file", "reference-depth", "unreferenced-resource")

FM_KEY = re.compile(r"""^["']?([A-Za-z][A-Za-z0-9_-]*)["']?[ \t]*:[ \t]*(.*)$""")


def repo_root_default():
    here = os.path.dirname(os.path.abspath(__file__))
    return os.path.dirname(here)


def find_plugin_roots(root):
    out = []
    for name in sorted(os.listdir(root)):
        if name.startswith("."):
            continue
        path = os.path.join(root, name)
        if os.path.isdir(path) and os.path.isfile(os.path.join(path, MANIFEST)):
            out.append(name)
    return out


def frontmatter_block(text):
    """Lines of the leading --- block, or None when there is no such block."""
    text = text.lstrip("﻿")
    lines = text.split("\n")
    if not lines or lines[0].strip() != "---":
        return None
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            return lines[1:i]
    return None


def resolve_scalar(first, rest):
    """Resolve a YAML scalar value the way a loader would, for measuring.

    `first` is the text after `key:` on the key line; `rest` is the list of
    following frontmatter lines, consumed while they belong to this value.
    Returns (value, lines_consumed). Handles the forms this repo writes --
    block folded (`>`, `>-`), block literal (`|`, `|-`), a double-quoted scalar
    that may span lines, and a plain scalar with indented continuation lines.
    """
    v = first.strip()
    if v in ("|", "|-", "|+", ">", ">-", ">+"):
        body = []
        n = 0
        for line in rest:
            if line.strip() == "" or line.startswith((" ", "\t")):
                body.append(line)
                n += 1
            else:
                break
        indent = min((len(l) - len(l.lstrip(" ")) for l in body if l.strip()), default=0)
        stripped = [l[indent:] if l.strip() else "" for l in body]
        if v.startswith("|"):
            value = "\n".join(stripped)
        else:
            paras, cur = [], []
            for l in stripped:
                if l == "":
                    paras.append(" ".join(cur))
                    cur = []
                else:
                    cur.append(l.strip())
            paras.append(" ".join(cur))
            value = "\n".join(p for p in paras)
        return value.rstrip("\n"), n
    if v.startswith('"'):
        chunks = [v[1:]]
        n = 0
        closed = re.search(r'(?<!\\)"\s*$', v[1:])
        while not closed and n < len(rest):
            chunks.append(rest[n].strip())
            closed = re.search(r'(?<!\\)"\s*$', rest[n])
            n += 1
        joined = " ".join(chunks)
        joined = re.sub(r'(?<!\\)"\s*$', "", joined)
        return joined.replace('\\"', '"').strip(), n
    # plain scalar, possibly continued on indented lines
    chunks = [v]
    n = 0
    for line in rest:
        if line.startswith((" ", "\t")) and line.strip():
            chunks.append(line.strip())
            n += 1
        else:
            break
    return " ".join(c for c in chunks if c).strip(), n


def read_frontmatter(text):
    """{key: resolved value} from the leading --- block; {} when absent."""
    block = frontmatter_block(text)
    if block is None:
        return {}
    out = {}
    i = 0
    while i < len(block):
        m = FM_KEY.match(block[i])
        if not m:
            i += 1
            continue
        key, first = m.group(1), m.group(2)
        value, consumed = resolve_scalar(first, block[i + 1:])
        out.setdefault(key, value)
        i += 1 + consumed
    return out


def finding(skill, arm, file, detail):
    return {"skill": skill, "arm": arm, "file": file, "detail": detail}


def reachable_resource_text(skill_dir, skill_text):
    """SKILL.md plus one directly linked conventional reference index."""
    index_ref = "references/00-index.md"
    if index_ref not in skill_text:
        return skill_text
    index_path = os.path.join(skill_dir, "references", "00-index.md")
    if not os.path.isfile(index_path):
        return skill_text
    with open(index_path, encoding="utf-8", errors="replace") as fh:
        return skill_text + "\n" + fh.read()


def grade_skill(root, plugin, skill_dir):
    """All findings for one skill directory, before baseline suppression."""
    skill = os.path.basename(skill_dir)
    rel = os.path.relpath(skill_dir, root)
    skill_md = os.path.join(skill_dir, "SKILL.md")
    rel_md = os.path.join(rel, "SKILL.md")
    out = []
    with open(skill_md, encoding="utf-8", errors="replace") as fh:
        text = fh.read()

    fm = read_frontmatter(text)
    name = fm.get("name")
    if name is None or not name:
        out.append(finding(skill, "name", rel_md, "frontmatter has no `name:` -- the spec requires it"))
    else:
        if len(name) > NAME_MAX or not NAME_RE.match(name):
            out.append(finding(skill, "name", rel_md,
                "`name: %s` breaks the spec form (1-64 chars, lowercase letters, digits and single "
                "hyphens, none leading or trailing)" % name))
        if name != skill:
            out.append(finding(skill, "name", rel_md,
                "`name: %s` does not equal the directory name `%s` -- the spec requires "
                "them to match" % (name, skill)))

    desc = fm.get("description")
    if desc is None or not desc.strip():
        out.append(finding(skill, "description", rel_md,
            "frontmatter has no non-empty `description:` -- the spec requires it"))
    elif len(desc) > DESCRIPTION_MAX:
        out.append(finding(skill, "description", rel_md,
            "description is %d characters after YAML folding; the spec caps it at %d "
            "(Claude Code's own 1536 cap masks the breach)" % (len(desc), DESCRIPTION_MAX)))

    line_count = text.count("\n") + (0 if text.endswith("\n") or not text else 1)
    if line_count > LINES_MAX:
        out.append(finding(skill, "length", rel_md,
            "SKILL.md is %d lines; the standard says keep it under %d -- move detail into "
            "references/ and point at it" % (line_count, LINES_MAX)))

    for entry in sorted(os.listdir(skill_dir)):
        if entry.lower() in STRAY_FILES and os.path.isfile(os.path.join(skill_dir, entry)):
            out.append(finding(skill, "stray-file", os.path.join(rel, entry),
                "`%s` is not skill payload -- the authoring guidance keeps README, CHANGELOG "
                "and INSTALLATION files out of the skill directory, and a parallel document "
                "here becomes a second, stale specification" % entry))

    refs = os.path.join(skill_dir, "references")
    if os.path.isdir(refs):
        for dirpath, dirnames, _files in os.walk(refs):
            dirnames[:] = sorted(d for d in dirnames if not d.startswith("."))
            for d in dirnames:
                nested = os.path.relpath(os.path.join(dirpath, d), root)
                out.append(finding(skill, "reference-depth", nested,
                    "a directory nested inside references/ -- the standard keeps file "
                    "references one level deep from SKILL.md; flatten the nested directory "
                    "(an index can expose resources, but does not change the depth rule)"))

    resource_text = reachable_resource_text(skill_dir, text)
    for sub in RESOURCE_DIRS:
        top = os.path.join(skill_dir, sub)
        if not os.path.isdir(top):
            continue
        for dirpath, dirnames, filenames in os.walk(top):
            # __pycache__ is an interpreter artifact, untracked by policy, and
            # would otherwise report a .pyc no SKILL.md could sensibly name.
            dirnames[:] = sorted(d for d in dirnames if not d.startswith(".") and d != "__pycache__")
            for fname in sorted(filenames):
                if fname.startswith(".") or fname.endswith(".pyc"):
                    continue
                if fname not in resource_text:
                    out.append(finding(skill, "unreferenced-resource",
                        os.path.relpath(os.path.join(dirpath, fname), root),
                        "never mentioned in SKILL.md or its directly linked "
                        "references/00-index.md -- the model does not know the file exists; "
                        "name it in a reachable resource table with when to read it"))
    return out


def baseline_key(f):
    return (f["skill"], f["arm"], f["file"])


def load_baseline(path):
    if not os.path.exists(path):
        return []
    with open(path, encoding="utf-8") as fh:
        data = json.load(fh)
    entries = data.get("entries", []) if isinstance(data, dict) else data
    for e in entries:
        for k in ("skill", "arm", "file"):
            if k not in e:
                raise ValueError("baseline entry missing `%s`: %r" % (k, e))
    return entries


def write_baseline(path, findings):
    entries = sorted(
        ({"skill": f["skill"], "arm": f["arm"], "file": f["file"]}
         for f in findings if f["arm"] in RATCHET_ARMS),
        key=lambda e: (e["skill"], e["arm"], e["file"]),
    )
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as fh:
        json.dump({
            "_comment": (
                "Skill-spec ratchet baseline for the four progressive-disclosure arms "
                "(length, stray-file, reference-depth, unreferenced-resource). Each entry "
                "is a finding present when the baseline was captured and therefore allowed "
                "to pass; the hard arms (name, description) are never baselined. The "
                "baseline can only shrink: an entry that no longer matches a live finding "
                "fails the guard as stale-baseline until it is deleted. Regenerate with "
                "`python3 scripts/check-skill-spec.py --update-baseline` and justify any "
                "new entry in the PR."
            ),
            "entries": entries,
        }, fh, indent=2, ensure_ascii=False)
        fh.write("\n")
    return len(entries)


def collect(root):
    plugins = find_plugin_roots(root)
    findings = []
    skills_scanned = 0
    for plugin in plugins:
        skills_dir = os.path.join(root, plugin, "skills")
        if not os.path.isdir(skills_dir):
            continue
        for entry in sorted(os.listdir(skills_dir)):
            if entry.startswith("."):
                continue
            skill_dir = os.path.join(skills_dir, entry)
            if not os.path.isfile(os.path.join(skill_dir, "SKILL.md")):
                continue
            skills_scanned += 1
            findings.extend(grade_skill(root, plugin, skill_dir))
    if not plugins or not skills_scanned:
        raise RuntimeError(
            "zero discovery: found %d plugin roots and %d skills. A sweep that matches "
            "nothing is a broken glob, not a clean tree." % (len(plugins), skills_scanned))
    return findings, plugins, skills_scanned


def main(argv=None):
    ap = argparse.ArgumentParser(description="every SKILL.md satisfies the published Agent Skills standard")
    ap.add_argument("--root", help="repo root to check (default: this script's parent)")
    ap.add_argument("--baseline", default=None,
                    help="ratchet baseline JSON (default: scripts/baselines/skill-spec-baseline.json)")
    ap.add_argument("--update-baseline", action="store_true",
                    help="regenerate the ratchet baseline from the current tree, exit 0")
    args = ap.parse_args(argv)
    root = os.path.abspath(args.root) if args.root else repo_root_default()
    baseline_path = args.baseline or os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "baselines", "skill-spec-baseline.json")

    try:
        raw, plugins, skills_scanned = collect(root)
    except (RuntimeError, OSError) as exc:
        print(json.dumps({"success": False, "data": {}, "error": str(exc)}, indent=2))
        sys.stderr.write("FAIL: %s\n" % exc)
        return 2

    if args.update_baseline:
        n = write_baseline(baseline_path, raw)
        print(json.dumps({"success": True, "data": {"baseline_size": n, "baseline_path": baseline_path},
                          "error": ""}, indent=2))
        return 0

    if args.baseline is not None and not os.path.exists(baseline_path):
        print(json.dumps({"success": False, "data": {},
                          "error": "baseline not found: %s" % baseline_path}, indent=2))
        sys.stderr.write("FAIL: baseline not found: %s\n" % baseline_path)
        return 2
    try:
        baseline = load_baseline(baseline_path)
    except (ValueError, json.JSONDecodeError) as exc:
        print(json.dumps({"success": False, "data": {}, "error": "bad baseline: %s" % exc}, indent=2))
        sys.stderr.write("FAIL: bad baseline: %s\n" % exc)
        return 2

    live = {baseline_key(f) for f in raw if f["arm"] in RATCHET_ARMS}
    admitted = {(e["skill"], e["arm"], e["file"]) for e in baseline}
    findings = [f for f in raw if not (f["arm"] in RATCHET_ARMS and baseline_key(f) in admitted)]
    for key in sorted(admitted - live):
        findings.append(finding(key[0], "stale-baseline", key[2],
            "baseline entry for arm `%s` matches no live finding -- delete it; the ratchet "
            "only shrinks" % key[1]))

    summary = {
        "total": len(findings),
        "plugins_discovered": len(plugins),
        "skills_scanned": skills_scanned,
        "baseline_size": len(baseline),
        "suppressed_by_baseline": len(raw) - len([f for f in findings if f["arm"] != "stale-baseline"]),
    }
    status = 1 if findings else 0
    print(json.dumps({"success": status == 0,
                      "data": {"findings": findings, "summary": summary},
                      "error": ""}, indent=2, ensure_ascii=False))
    if findings:
        for f in findings:
            sys.stderr.write("FAIL: [%s] %s -- %s\n" % (f["arm"], f["file"], f["detail"]))
        sys.stderr.write(
            "\nFix the skill, not the guard: shorten the description, move body detail into "
            "references/, rename or delete the stray file, flatten the reference tree, or "
            "name the resource in SKILL.md. The hard arms (name, description) have no "
            "baseline; a ratchet-arm finding on a skill whose restructure is tracked "
            "elsewhere is admitted only by --update-baseline with the entry justified in "
            "the PR.\n")
    return status


if __name__ == "__main__":
    sys.exit(main())
