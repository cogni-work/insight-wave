#!/usr/bin/env python3
"""check-command-reference-sync.py — binds docs/command-reference.md to the tree.

`docs/command-reference.md` is the hand-maintained one-screen cheatsheet of how
each plugin is invoked: its slash commands and its skills, per plugin. It was
re-homed from the retired doku wiki, where the same page had drifted for months
— it listed five render commands and two skills that no longer existed, because
nothing bound the page to the directories it described. This guard is that
binding. For every plugin the marketplace enumerates it asserts:

  1. SKILLS — the page's `**<plugin>** (N) — ...` line names exactly the
     directories under `<plugin>/skills/` that carry a `SKILL.md`, and N equals
     their count. Both directions: a live skill the page omits and a page skill
     the tree lacks are each a finding.
  2. COMMANDS — the page's slash-command table row for the plugin names exactly
     the `<plugin>/commands/*.md` stems, as `/stem`. A plugin that ships no
     commands directory must sit on the table's "none" row (whose first cell
     lists several plugins), and a plugin on that row must ship none.
  3. PROSE COUNT — the sentence "<N> of the <M> plugins ship **no** commands"
     states the live number of command-less plugins over the live roster, with
     the numbers written as words, the way the page writes them.

Why a page-shaped parser rather than regenerating the page. The page is prose
around two lists; regenerating it would either template the prose (and lose the
naming-pattern section, which is the part worth reading) or replace only the
lists (which is this guard's comparison wearing a writer's hat). A guard keeps
the page hand-written and makes the hand honest: the finding names the plugin
and the stale token, and the remedy is a one-line edit.

Plugins are enumerated ONLY from `plugins[].source` — never a glob. Stale
copies of plugin trees live under `.claude/worktrees/**` and a tree scan would
read those. Names on the page that match no roster plugin are a finding rather
than silently skipped: a retired plugin left on the page is exactly the drift
class this closes.

Absence is never agreement. A plugin with no skills line, or with live commands
and no table row, is its own finding rather than an empty-set comparison that
passes.

Zero discovery is a failure, never a clean zero: a run that enumerated no
plugins or compared no skill list must not report the page as in sync.

Hard clean zero — no baseline file, allowlist, skip marker or per-plugin
exemption.

Usage:
    python3 scripts/check-command-reference-sync.py [--root DIR]

    --root defaults to the repo containing this script.

stdlib only; runs under any python3. Exit 0 = clean, 1 = violation(s) found,
2 = script error.
"""

import argparse
import json
import os
import re
import sys

MARKETPLACE = os.path.join(".claude-plugin", "marketplace.json")
REFERENCE = os.path.join("docs", "command-reference.md")

SKILLS_LINE = re.compile(r"^\*\*([a-z0-9-]+)\*\* \((\d+)\) — (.*)$")
TABLE_ROW = re.compile(r"^\| (.+?) \| (.+?) \|$")
SKILL_TOKEN = re.compile(r"`([a-z0-9-]+)`")
COMMAND_TOKEN = re.compile(r"`/([a-z0-9-]+)`")
PROSE_COUNT = re.compile(
    r"\b([a-z]+) of the ([a-z]+) plugins ship \*\*no\*\* commands", re.IGNORECASE)

NUMBER_WORDS = {
    "zero": 0, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6,
    "seven": 7, "eight": 8, "nine": 9, "ten": 10, "eleven": 11, "twelve": 12,
}


def read_marketplace(root):
    """Return the marketplace plugins[] list. Raises RuntimeError when unusable.

    Duplicated from its siblings rather than imported: no guard in this
    directory imports another, so a manifest-shape change is fixed per copy.
    """
    path = os.path.join(root, MARKETPLACE)
    if not os.path.isfile(path):
        raise RuntimeError("marketplace manifest not found at {}".format(path))
    try:
        with open(path, encoding="utf-8") as fh:
            data = json.load(fh)
    except ValueError as exc:
        raise RuntimeError("marketplace.json does not parse as JSON: {}".format(exc))
    plugins = data.get("plugins")
    if not isinstance(plugins, list):
        raise RuntimeError("marketplace.json has no plugins[] array")
    return plugins


def source_to_dirname(source):
    """Normalise a plugins[].source value to a top-level directory name, or None."""
    if not isinstance(source, str) or not source:
        return None
    cleaned = source.strip()
    if cleaned.startswith("./"):
        cleaned = cleaned[2:]
    cleaned = cleaned.rstrip("/")
    if not cleaned or cleaned.startswith("/") or ":" in cleaned or ".." in cleaned:
        return None
    return cleaned


def live_skills(root, dirname):
    """Skill names: directories under <plugin>/skills/ carrying a SKILL.md."""
    base = os.path.join(root, dirname, "skills")
    if not os.path.isdir(base):
        return []
    found = []
    for entry in sorted(os.listdir(base)):
        if os.path.isfile(os.path.join(base, entry, "SKILL.md")):
            found.append(entry)
    return found


def live_commands(root, dirname):
    """Command names: <plugin>/commands/*.md stems; [] when no directory."""
    base = os.path.join(root, dirname, "commands")
    if not os.path.isdir(base):
        return []
    return sorted(f[:-3] for f in os.listdir(base)
                  if f.endswith(".md") and os.path.isfile(os.path.join(base, f)))


def parse_reference(text):
    """Return (skills_by_plugin, commands_by_plugin, none_plugins, prose_counts).

    skills_by_plugin: name -> (stated_count, [skill tokens])
    commands_by_plugin: name -> [command stems] for rows carrying `/x` tokens
    none_plugins: names listed on rows carrying no `/x` token
    prose_counts: list of (n, m) integer pairs the prose sentence states, or
                  None entries where a word was not a known number
    """
    skills = {}
    commands = {}
    none_plugins = []
    for line in text.splitlines():
        m = SKILLS_LINE.match(line)
        if m:
            skills[m.group(1)] = (int(m.group(2)), SKILL_TOKEN.findall(m.group(3)))
            continue
        m = TABLE_ROW.match(line)
        if m:
            first, second = m.group(1).strip(), m.group(2).strip()
            if first in ("Plugin",) or set(first) <= set("-"):
                continue  # header or separator row
            names = [n.strip() for n in first.split(",") if n.strip()]
            cmds = COMMAND_TOKEN.findall(second)
            if cmds:
                for n in names:
                    commands[n] = sorted(cmds)
            else:
                none_plugins.extend(names)
    prose = []
    for n_word, m_word in PROSE_COUNT.findall(text):
        prose.append((NUMBER_WORDS.get(n_word.lower()), NUMBER_WORDS.get(m_word.lower())))
    return skills, commands, none_plugins, prose


def collect(root):
    """Return (violations, data) for the command-reference/tree binding."""
    plugins = read_marketplace(root)
    violations = []
    enumerated = 0
    skill_lists_compared = 0
    command_rows_compared = 0

    ref_path = os.path.join(root, REFERENCE)
    if not os.path.isfile(ref_path):
        violations.append({
            "code": "reference-missing",
            "plugin": None,
            "detail": "{} does not exist; the cheatsheet has nothing to bind".format(REFERENCE),
        })
        text = ""
    else:
        with open(ref_path, encoding="utf-8") as fh:
            text = fh.read()

    doc_skills, doc_commands, doc_none, prose = parse_reference(text)
    roster = []

    for entry in plugins:
        if not isinstance(entry, dict):
            violations.append({
                "code": "source-unresolvable", "plugin": None,
                "detail": "plugins[] carries an element that is not an object",
            })
            continue
        enumerated += 1
        source = entry.get("source")
        name = entry.get("name") or (source if isinstance(source, str) else None)
        dirname = source_to_dirname(source)
        if dirname is None:
            violations.append({
                "code": "source-unresolvable", "plugin": name,
                "detail": "source {!r} is not a plain relative path into this repo".format(source),
            })
            continue
        roster.append(name)

        skills = live_skills(root, dirname)
        cmds = live_commands(root, dirname)

        # Arm 1 — skills line.
        if name not in doc_skills:
            violations.append({
                "code": "skills-line-missing", "plugin": name,
                "detail": "no `**{}** (N) — ...` line on the page; the plugin's {} "
                          "live skill(s) are undocumented".format(name, len(skills)),
            })
        else:
            skill_lists_compared += 1
            stated_n, stated = doc_skills[name]
            missing = sorted(set(skills) - set(stated))
            extra = sorted(set(stated) - set(skills))
            if missing:
                violations.append({
                    "code": "skill-missing", "plugin": name,
                    "detail": "live skill(s) absent from the page: {}".format(", ".join(missing)),
                })
            if extra:
                violations.append({
                    "code": "skill-extra", "plugin": name,
                    "detail": "page names skill(s) with no skills/<name>/SKILL.md: "
                              "{}".format(", ".join(extra)),
                })
            if stated_n != len(skills):
                violations.append({
                    "code": "skill-count-desync", "plugin": name,
                    "detail": "page states ({}) skills; the tree has {}".format(
                        stated_n, len(skills)),
                })

        # Arm 2 — commands row.
        if cmds:
            if name in doc_none:
                violations.append({
                    "code": "none-row-desync", "plugin": name,
                    "detail": "listed on the no-commands row but ships {}".format(
                        ", ".join("/" + c for c in cmds)),
                })
            elif name not in doc_commands:
                violations.append({
                    "code": "commands-row-missing", "plugin": name,
                    "detail": "ships {} but has no row in the slash-command table".format(
                        ", ".join("/" + c for c in cmds)),
                })
            else:
                command_rows_compared += 1
                stated = doc_commands[name]
                missing = sorted(set(cmds) - set(stated))
                extra = sorted(set(stated) - set(cmds))
                if missing:
                    violations.append({
                        "code": "command-missing", "plugin": name,
                        "detail": "live command(s) absent from the row: {}".format(
                            ", ".join("/" + c for c in missing)),
                    })
                if extra:
                    violations.append({
                        "code": "command-extra", "plugin": name,
                        "detail": "row names command(s) with no commands/<name>.md: "
                                  "{}".format(", ".join("/" + c for c in extra)),
                    })
        else:
            if name in doc_commands:
                violations.append({
                    "code": "command-extra", "plugin": name,
                    "detail": "row names {} but the plugin ships no commands "
                              "directory".format(", ".join("/" + c for c in doc_commands[name])),
                })
            elif name not in doc_none:
                violations.append({
                    "code": "commands-row-missing", "plugin": name,
                    "detail": "ships no commands but is absent from the table's "
                              "no-commands row",
                })
            else:
                command_rows_compared += 1

    # Names on the page that match no roster plugin: a retired plugin left behind.
    for stale in sorted((set(doc_skills) | set(doc_commands) | set(doc_none)) - set(roster)):
        violations.append({
            "code": "plugin-not-in-roster", "plugin": stale,
            "detail": "the page names a plugin that plugins[] does not list",
        })

    # Arm 3 — the prose count of command-less plugins.
    if text and roster:
        live_none = sum(1 for e in plugins if isinstance(e, dict)
                        and source_to_dirname(e.get("source")) is not None
                        and not live_commands(root, source_to_dirname(e.get("source"))))
        if not prose:
            violations.append({
                "code": "prose-count-missing", "plugin": None,
                "detail": "the sentence '<N> of the <M> plugins ship **no** commands' "
                          "is absent, so the count is un-stated",
            })
        for n, m in prose:
            if n is None or m is None:
                violations.append({
                    "code": "prose-count-desync", "plugin": None,
                    "detail": "the prose count uses a number word this guard does "
                              "not know; write it as a word from zero to twelve",
                })
            elif (n, m) != (live_none, len(roster)):
                violations.append({
                    "code": "prose-count-desync", "plugin": None,
                    "detail": "prose says {} of {} plugins ship no commands; the "
                              "tree has {} of {}".format(n, m, live_none, len(roster)),
                })

    if not enumerated or not skill_lists_compared:
        violations.append({
            "code": "nothing-compared", "plugin": None,
            "detail": "the guard enumerated {} plugin(s) and compared {} skill "
                      "list(s); it examined nothing".format(enumerated, skill_lists_compared),
        })

    data = {
        "plugins_enumerated": enumerated,
        "skill_lists_compared": skill_lists_compared,
        "command_rows_compared": command_rows_compared,
        "violations": violations,
    }
    return violations, data


def main(argv):
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--root", help="repo root to check (default: this script's parent)")
    args = ap.parse_args(argv)

    script_dir = os.path.dirname(os.path.abspath(__file__))
    root = os.path.abspath(args.root) if args.root else os.path.dirname(script_dir)

    try:
        violations, data = collect(root)
    except (RuntimeError, OSError) as exc:
        print(json.dumps({"success": False, "data": {}, "error": str(exc)}))
        return 2

    by_code = {}
    for v in violations:
        by_code[v["code"]] = by_code.get(v["code"], 0) + 1
    data["summary"] = {"total": len(violations), "by_code": by_code}

    print(json.dumps({"success": not violations, "data": data, "error": ""},
                     indent=2, ensure_ascii=False))

    if violations:
        print("\nFAIL: {} command-reference sync violation(s):".format(len(violations)),
              file=sys.stderr)
        for v in violations:
            print("  [{}] {}  ({})".format(v["code"], v["plugin"] or "-", v["detail"]),
                  file=sys.stderr)
        print("\nFix: docs/command-reference.md is hand-maintained and this guard is "
              "the only thing binding it to the tree. Edit the page, never the tree, "
              "unless the tree is what is wrong. `skill-missing` / `skill-extra` / "
              "`skill-count-desync`: correct the plugin's `**name** (N) — ...` line so "
              "it names exactly the skills/<name>/SKILL.md directories and N is their "
              "count. `command-missing` / `command-extra`: correct the plugin's row in "
              "the slash-command table to the commands/<name>.md stems. "
              "`commands-row-missing` / `none-row-desync`: a plugin with no commands "
              "directory belongs on the table's no-commands row and nowhere else; one "
              "that ships commands needs its own row. `plugin-not-in-roster`: the page "
              "names a plugin plugins[] no longer lists — remove it. "
              "`prose-count-desync` / `prose-count-missing`: restate the '<N> of the "
              "<M> plugins ship **no** commands' sentence with the live numbers as "
              "words. `reference-missing` and `nothing-compared` mean the guard had "
              "nothing to bind, which is never a clean result.",
              file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
