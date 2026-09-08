#!/usr/bin/env python3
"""Bind recorded mutation recipes to the stable managed-service harness path.

Every invocation-shaped mutation recipe in ``tests/*.sh`` and ``*/tests/*.sh``
must name the unversioned managed-service marketplace installation. Versioned
cache paths are rejected because every cogni-service patch bump strands them;
the two different pinned versions found when this guard was introduced showed
that drift already occurring. Repo-root, placeholder, checkout-local, and
pathless spellings are rejected for the same reason: they do not identify the
shared argument-taking harness in a fresh insight-wave clone.

CI checks spelling rather than filesystem resolvability. Its runner does not
install the cogni-service plugin, so an existence check would either fail every
run or need to be disabled precisely where the invariant matters. Local users
may separately replay a recipe to prove the installed path resolves.

Detection keys on an invocation-shaped comment: an optional ``bash`` token, a
harness token ending in ``mutation-check.sh``, and at least one recipe flag on
that line or its backslash-continued comment block. This excludes prose about
the legitimate plugin-local harnesses and the repository's general ``--case``
convention without an allowlist. Heredoc bodies are skipped because the suite
for this guard contains deliberately broken fixture recipes.

The invariant is hard clean zero: no baseline, allowlist, skip marker, or
per-file exemption. Zero suite discovery and zero invocation discovery are
errors, since either means the guard stopped observing its intended population.

Python stdlib only. Exit 0 = clean, 1 = violation(s), 2 = script error.
"""

import argparse
import glob
import json
import os
import re
import sys


APPROVED_HARNESSES = {
    "~/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh",
    "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh",
}

HARNESS_RE = re.compile(
    r"^\s*#\s+(?:bash\s+)?(?P<path>"
    r"(?:[\"']?(?:\$HOME|~)[^\s\"']*mutation-check\.sh[\"']?)|"
    r"(?:[^\s`\"']*/mutation-check\.sh)|mutation-check\.sh)"
    r"(?=\s|$)"
)
FLAG_RE = re.compile(r"(?:^|\s)--(?:root|file|expr|test|case)(?=\s|=|$)")
STRONG_FLAG_RE = re.compile(r"(?:^|\s)--(?:root|file|expr|test)(?=\s|=|$)")
HEREDOC_RE = re.compile(r"<<-?\s*['\"]?([A-Za-z_][A-Za-z0-9_]*)['\"]?")
CONTEXT_LIMIT = 180


def repo_root_default():
    return os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))


def discover(root):
    found = set()
    for pattern in (os.path.join(root, "tests", "*.sh"),
                    os.path.join(root, "*", "tests", "*.sh")):
        for path in glob.glob(pattern):
            if os.path.isfile(path):
                found.add(os.path.relpath(path, root))
    return sorted(found)


def source_lines(lines):
    """Yield non-heredoc source lines as (one-based-number, text)."""
    terminator = None
    for number, line in enumerate(lines, 1):
        if terminator is not None:
            if line.lstrip("\t") == terminator:
                terminator = None
            continue
        yield number, line
        match = HEREDOC_RE.search(line)
        if match:
            terminator = match.group(1)


def scan_file(root, rel_path, counters):
    try:
        with open(os.path.join(root, rel_path), "r", encoding="utf-8", errors="replace") as handle:
            lines = handle.read().splitlines()
    except OSError as exc:
        raise RuntimeError("could not read %s: %s" % (rel_path, exc))

    counters["files_scanned"] += 1
    visible = list(source_lines(lines))
    findings = []
    index = 0
    while index < len(visible):
        number, line = visible[index]
        match = HARNESS_RE.match(line)
        if not match:
            index += 1
            continue

        block = line
        cursor = index
        while block.rstrip().endswith("\\") and cursor + 1 < len(visible):
            next_number, next_line = visible[cursor + 1]
            if next_number != visible[cursor][0] + 1:
                break
            block += "\n" + next_line
            cursor += 1

        if not FLAG_RE.search(block):
            index += 1
            continue

        harness = match.group("path").strip("\"'")
        # A pathless `mutation-check.sh --case ...` sentence is the repository's
        # convention prose, not a runnable invocation. A pathless token becomes
        # invocation-shaped only when it also carries an operand-bearing flag.
        if harness == "mutation-check.sh" and not STRONG_FLAG_RE.search(block):
            index += 1
            continue

        counters["invocations_inspected"] += 1
        if harness not in APPROVED_HARNESSES:
            findings.append({
                "file": rel_path,
                "line": number,
                "arm": "unapproved_harness",
                "harness": harness,
                "context": line.strip()[:CONTEXT_LIMIT],
            })
        index = cursor + 1
    return findings


def collect(root):
    suites = discover(root)
    if not suites:
        raise RuntimeError(
            "no test suites discovered under %s; the two test globs stopped matching" % root
        )
    counters = {"files_scanned": 0, "invocations_inspected": 0}
    findings = []
    for rel_path in suites:
        findings.extend(scan_file(root, rel_path, counters))
    if counters["invocations_inspected"] == 0:
        raise RuntimeError(
            "no mutation-recipe invocations discovered under %s; the predicate stopped matching" % root
        )
    return suites, findings, counters


def main(argv):
    parser = argparse.ArgumentParser(description="mutation-recipe harness path guard")
    parser.add_argument("--root", default=None,
                        help="tree to scan; paths in findings are relative to it")
    args = parser.parse_args(argv)
    root = os.path.abspath(args.root) if args.root else repo_root_default()

    try:
        suites, findings, counters = collect(root)
    except RuntimeError as exc:
        print(json.dumps({"success": False, "data": {}, "error": str(exc)},
                         indent=2, ensure_ascii=False))
        return 2

    result = {
        "success": not findings,
        "data": {
            "root": root,
            "violations": findings,
            "summary": {
                "total": len(findings),
                "by_arm": ({"unapproved_harness": len(findings)} if findings else {}),
                "files_affected": len({item["file"] for item in findings}),
                "files_discovered": len(suites),
                "files_scanned": counters["files_scanned"],
                "invocations_inspected": counters["invocations_inspected"],
            },
        },
        "error": "",
    }
    print(json.dumps(result, indent=2, ensure_ascii=False))
    if findings:
        for item in findings:
            print("FAIL: %s:%d [%s] %s" % (
                item["file"], item["line"], item["arm"], item["harness"]
            ), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
