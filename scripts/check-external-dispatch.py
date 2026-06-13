#!/usr/bin/env python3
"""check-external-dispatch.py — deterministic external-dispatch guard.

Asserts that **no live-dispatch surface** dispatches the retired engines
`cogni-wiki:` or `cogni-research:` anywhere in the repo. This is the machine
proof behind the FMO archival decision: once cogni-research and cogni-wiki are
archived (source kept, not installable), a live caller dispatching them would
break at runtime. The guard makes that absence objective and regression-proof.

Scope — the surfaces a running session actually dispatches FROM:

  - */skills/*/SKILL.md   (skill bodies + their YAML description)
  - */agents/*.md         (agent prompts)
  - */commands/*.md       (slash-command definitions)
  - */hooks/**            (lifecycle hooks: *.sh / *.py / *.json)

Excluded, by design (NOT live-dispatch surfaces):

  - cogni-knowledge/                its delegation-contract / references
                                    legitimately NAME the retired plugins as
                                    history, and it carries the vendored wiki
                                    engine under scripts/vendor/cogni-wiki/; it
                                    dispatches neither retired plugin (FMO
                                    vendored the engine), and the runtime-path
                                    guard for that lives in its own
                                    test_skill_contracts.
                                    (The cogni-research/ and cogni-wiki/ source
                                    trees were removed from the repo entirely
                                    once archived, so they need no exclude.)
  - */wiki/ , top-level wiki/       generated page dumps (a wiki mirror may
                                    quote a retired dispatch as page content)
  - docs/                           the doc mirror (prose, not a dispatch)

`references/` directories are out of scope on purpose: a reference doc is
loaded on demand as documentation, not the surface a session dispatches from, so
a lineage mention there ("modeled on the cogni-research verify-report skill") is
not a caller.

Unlike the breadcrumb guard, this guard targets a HARD clean-zero — there is no
legitimate live `cogni-wiki:`/`cogni-research:` dispatch after archival, so the
ratchet/baseline model is the wrong tool. The single escape hatch is a per-line
marker for a genuine NON-dispatch prose mention that must keep the literal token
(rare); state the rationale on the same line:

    ... see cogni-research:verify-report for the lineage  # external-dispatch-guard:allow

The fix when the guard trips is to REMOVE the dispatch (cut the caller over to
the vendored cogni-knowledge surface) or, for a true prose mention, reword it
semantically to drop the `plugin:skill` token (drop the colon) — exactly the
discipline the Maintainer-breadcrumb guard uses.

stdlib only; runs under any python3. Exit 0 = clean (zero dispatches),
1 = dispatch(es) found, 2 = script error.
"""

import argparse
import json
import os
import re
import subprocess
import sys

# git ls-files pathspec globs for the live-dispatch surfaces.
DEFAULT_GLOBS = [
    "*/skills/*/SKILL.md",
    "*/agents/*.md",
    "*/commands/*.md",
    "*/hooks/*",
    "*/hooks/*/*",
]

# Path-prefix excludes (own trees + the history-bearing FMO plugin).
EXCLUDE_PREFIXES = ("cogni-knowledge/",)

# Path-segment excludes (generated wiki mirrors + the doc mirror). A surface
# under any of these is content, not a caller.
EXCLUDE_SEGMENTS = ("/wiki/", "/docs/")
EXCLUDE_TOPLEVEL = ("wiki/", "docs/")

# The dispatch-shaped token: `cogni-wiki:` / `cogni-research:` — the `plugin:`
# half of a `plugin:skill` dispatch reference. A bare "cogni-research" (no
# colon) is a plain noun and is NOT matched.
DISPATCH_RE = re.compile(r"\bcogni-(wiki|research):")

# Per-line escape hatch for a genuine non-dispatch prose mention.
ALLOW_MARKER = "external-dispatch-guard:allow"


def discover_files(root):
    """Tracked live-dispatch surfaces, relative to root, via git ls-files."""
    try:
        out = subprocess.check_output(
            ["git", "-C", root, "ls-files", "-z"] + DEFAULT_GLOBS,
            stderr=subprocess.DEVNULL,
        )
    except (subprocess.CalledProcessError, OSError) as exc:
        raise RuntimeError("git ls-files failed: {}".format(exc))
    files = []
    for rel in out.decode("utf-8").split("\x00"):
        if not rel:
            continue
        if rel.startswith(EXCLUDE_PREFIXES):
            continue
        if rel.startswith(EXCLUDE_TOPLEVEL):
            continue
        if any(seg in ("/" + rel) for seg in EXCLUDE_SEGMENTS):
            continue
        files.append(rel)
    return files


def scan_file(abs_path, rel_path):
    """Yield violation dicts for one file."""
    try:
        with open(abs_path, "r", encoding="utf-8") as fh:
            lines = fh.readlines()
    except (OSError, UnicodeDecodeError) as exc:
        raise RuntimeError("cannot read {}: {}".format(rel_path, exc))
    for lineno, raw in enumerate(lines, start=1):
        line = raw.rstrip("\n")
        if ALLOW_MARKER in line:
            continue
        for m in DISPATCH_RE.finditer(line):
            yield {
                "file": rel_path,
                "line": lineno,
                "match": m.group(0),
                "context": line.strip()[:140],
            }


def collect(root, explicit_files):
    occ = []
    if explicit_files:
        pairs = []
        for f in explicit_files:
            abs_path = f if os.path.isabs(f) else os.path.join(root, f)
            rel = os.path.relpath(abs_path, root)
            if rel == os.pardir or rel.startswith(os.pardir + os.sep):
                raise RuntimeError(
                    "file {!r} is outside --root {!r}".format(f, root))
            pairs.append((abs_path, rel))
    else:
        pairs = [(os.path.join(root, rel), rel) for rel in discover_files(root)]
    for abs_path, rel in pairs:
        occ.extend(scan_file(abs_path, rel))
    return occ


def main(argv):
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("files", nargs="*",
                    help="explicit files to scan (default: git ls-files globs)")
    ap.add_argument("--root", default=None,
                    help="repo root for discovery + relative paths "
                         "(default: parent of scripts/)")
    args = ap.parse_args(argv)

    script_dir = os.path.dirname(os.path.abspath(__file__))
    root = os.path.abspath(args.root) if args.root else os.path.dirname(script_dir)

    try:
        violations = collect(root, args.files)
    except RuntimeError as exc:
        print(json.dumps({"success": False, "data": {}, "error": str(exc)}))
        return 2

    by_plugin = {}
    for o in violations:
        plugin = o["file"].split("/", 1)[0]
        by_plugin[plugin] = by_plugin.get(plugin, 0) + 1

    result = {
        "success": not violations,
        "data": {
            "violations": violations,
            "summary": {
                "total": len(violations),
                "by_plugin": by_plugin,
                "files_affected": len(sorted({o["file"] for o in violations})),
            },
        },
        "error": "",
    }
    print(json.dumps(result, indent=2, ensure_ascii=False))

    if violations:
        print("\nFAIL: {} live cogni-wiki:/cogni-research: dispatch(es) found "
              "in live-dispatch surfaces:".format(len(violations)), file=sys.stderr)
        for o in violations:
            print("  {}:{}: {}  ->  {}".format(
                o["file"], o["line"], o["match"], o["context"]), file=sys.stderr)
        print("\nFix: cut the caller over to the vendored cogni-knowledge "
              "surface, OR — for a genuine non-dispatch prose mention — reword "
              "it to drop the `plugin:skill` token (drop the colon), or mark the "
              "line with `# external-dispatch-guard:allow` and a rationale.",
              file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
