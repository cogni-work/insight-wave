#!/usr/bin/env python3
"""check-breadcrumbs.py — deterministic maintainer-breadcrumb guard.

Greps tracked `*/skills/*/SKILL.md` and `*/agents/*.md` for maintainer
meta-documentation breadcrumbs that should live in git history / CHANGELOG /
references/, not in the prompt the model executes:

  - bare issue/PR refs ........ #344
  - plugin-version tags ....... v0.1.16
  - milestone codes ........... M8
  - slice codes ............... Slice 3
  - finding codes ............. F11

The repo is not breadcrumb-free today, and many matches are legitimate
(hex colors, the cogni-trends `F1` patent formula, emitted candidate IDs,
compatibility-fact version cites). This guard therefore works as a *ratchet*:
every occurrence present at baseline-capture time is recorded in
scripts/baselines/breadcrumb-baseline.json and allowed to pass; the guard fails
only on occurrences that are NOT in the baseline — i.e. newly introduced
breadcrumbs. The baseline can only shrink: as a plugin is cleaned, its entries
are dropped on the next --update-baseline.

The fix when the guard trips is to REMOVE the breadcrumb and state the rationale
semantically — NOT to reconcile mismatched version tags. A genuinely new
load-bearing compatibility fact is admitted by re-running --update-baseline and
justifying the new baseline entry in the PR.

stdlib only; runs under any python3. Exit 0 = clean, 1 = new breadcrumb(s),
2 = script error.
"""

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys

DEFAULT_GLOBS = ["*/skills/*/SKILL.md", "*/agents/*.md"]

# Version/issue/milestone/slice/finding matchers. issue_ref is handled
# specially (hex-color disambiguation); the rest are plain regexes.
VERSION_RE = re.compile(r"\bv[0-9]+\.[0-9]+\.[0-9]+\b")
MILESTONE_RE = re.compile(r"\bM[0-9]+\b")
SLICE_RE = re.compile(r"\bSlice [0-9]+\b")
# 2+ digits: excludes the single-digit cogni-trends `F1` patent formula and the
# archived `F2` fix note, still catches real finding codes (F11, F20, F26).
FINDING_RE = re.compile(r"\bF[0-9]{2,}\b")
# Capture the run after `#` so we can tell an issue ref from a hex color.
ISSUE_RUN_RE = re.compile(r"#([0-9a-fA-F]{2,})\b")


def _issue_refs(line):
    """Yield issue-ref tokens on a line, skipping hex colors.

    A run that is all-digits and not length 6 or 8 is an issue ref (#222, #12,
    #103). A run containing hex letters, or an all-digit run of length 6/8, is a
    color/hash (#000000, #000000B3, #abc123) and is skipped.
    """
    for m in ISSUE_RUN_RE.finditer(line):
        run = m.group(1)
        if not run.isdigit():
            continue  # contains a-f -> color or hash, not an issue ref
        if len(run) in (6, 8):
            continue  # 6/8-digit run -> treat as a hex color
        yield "#" + run


def find_matches(line):
    """Return a list of (pattern_name, matched_token) for one line."""
    out = []
    for token in _issue_refs(line):
        out.append(("issue_ref", token))
    for m in VERSION_RE.finditer(line):
        out.append(("version_tag", m.group(0)))
    for m in MILESTONE_RE.finditer(line):
        out.append(("milestone", m.group(0)))
    for m in SLICE_RE.finditer(line):
        out.append(("slice", m.group(0)))
    for m in FINDING_RE.finditer(line):
        out.append(("finding", m.group(0)))
    return out


def line_sha(line):
    return hashlib.sha1(line.strip().encode("utf-8")).hexdigest()


def occurrence_key(rel_path, token, sha):
    """Position-independent identity for a single breadcrumb occurrence."""
    return "{}\x00{}\x00{}".format(rel_path, token, sha)


def discover_files(root):
    """Tracked SKILL.md + agents/*.md, relative to root, via git ls-files."""
    try:
        out = subprocess.check_output(
            ["git", "-C", root, "ls-files", "-z"] + DEFAULT_GLOBS,
            stderr=subprocess.DEVNULL,
        )
    except (subprocess.CalledProcessError, OSError) as exc:
        raise RuntimeError("git ls-files failed: {}".format(exc))
    return [p for p in out.decode("utf-8").split("\x00") if p]


def scan_file(abs_path, rel_path):
    """Yield occurrence dicts for one file."""
    try:
        with open(abs_path, "r", encoding="utf-8") as fh:
            lines = fh.readlines()
    except (OSError, UnicodeDecodeError) as exc:
        raise RuntimeError("cannot read {}: {}".format(rel_path, exc))
    for lineno, raw in enumerate(lines, start=1):
        line = raw.rstrip("\n")
        for pattern, token in find_matches(line):
            yield {
                "file": rel_path,
                "line": lineno,
                "pattern": pattern,
                "match": token,
                "line_sha": line_sha(line),
                "context": line.strip()[:140],
            }


def collect(root, explicit_files):
    """Collect every occurrence across the scanned files."""
    occ = []
    if explicit_files:
        pairs = []
        for f in explicit_files:
            abs_path = f if os.path.isabs(f) else os.path.join(root, f)
            rel = os.path.relpath(abs_path, root)
            pairs.append((abs_path, rel))
    else:
        pairs = [(os.path.join(root, rel), rel) for rel in discover_files(root)]
    for abs_path, rel in pairs:
        occ.extend(scan_file(abs_path, rel))
    return occ


def load_baseline(path):
    if not path or not os.path.exists(path):
        return set()
    with open(path, "r", encoding="utf-8") as fh:
        data = json.load(fh)
    entries = data.get("entries", []) if isinstance(data, dict) else data
    return {occurrence_key(e["file"], e["match"], e["line_sha"]) for e in entries}


def write_baseline(path, occ):
    entries = sorted(
        ({"file": o["file"], "match": o["match"], "line_sha": o["line_sha"]}
         for o in occ),
        key=lambda e: (e["file"], e["match"], e["line_sha"]),
    )
    # De-duplicate identical (file, match, sha) tuples.
    deduped = []
    seen = set()
    for e in entries:
        k = occurrence_key(e["file"], e["match"], e["line_sha"])
        if k not in seen:
            seen.add(k)
            deduped.append(e)
    payload = {
        "_comment": (
            "Breadcrumb-guard ratchet baseline. Each entry is a breadcrumb "
            "occurrence present when the baseline was captured and therefore "
            "allowed to pass. Regenerate with "
            "`python3 scripts/check-breadcrumbs.py --update-baseline`. The fix "
            "for a NEW breadcrumb is to remove it and state the rationale "
            "semantically — not to add it here."
        ),
        "entries": deduped,
    }
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(payload, fh, indent=2, ensure_ascii=False)
        fh.write("\n")
    return len(deduped)


def main(argv):
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("files", nargs="*",
                    help="explicit files to scan (default: git ls-files globs)")
    ap.add_argument("--root", default=None,
                    help="repo root for discovery + relative paths "
                         "(default: parent of scripts/)")
    ap.add_argument("--baseline", default=None,
                    help="baseline JSON path "
                         "(default: scripts/baselines/breadcrumb-baseline.json)")
    ap.add_argument("--update-baseline", action="store_true",
                    help="regenerate the baseline from the current tree, exit 0")
    args = ap.parse_args(argv)

    script_dir = os.path.dirname(os.path.abspath(__file__))
    root = os.path.abspath(args.root) if args.root else os.path.dirname(script_dir)
    baseline_path = args.baseline or os.path.join(
        script_dir, "baselines", "breadcrumb-baseline.json")

    try:
        occ = collect(root, args.files)
    except RuntimeError as exc:
        print(json.dumps({"success": False, "data": {}, "error": str(exc)}))
        return 2

    if args.update_baseline:
        n = write_baseline(baseline_path, occ)
        print(json.dumps({
            "success": True,
            "data": {"baseline_size": n, "baseline_path": baseline_path},
            "error": "",
        }))
        return 0

    try:
        baseline = load_baseline(baseline_path)
    except (OSError, ValueError, KeyError) as exc:
        print(json.dumps({"success": False, "data": {},
                          "error": "bad baseline: {}".format(exc)}))
        return 2

    violations = [
        o for o in occ
        if occurrence_key(o["file"], o["match"], o["line_sha"]) not in baseline
    ]

    by_pattern = {}
    for o in violations:
        by_pattern[o["pattern"]] = by_pattern.get(o["pattern"], 0) + 1

    result = {
        "success": not violations,
        "data": {
            "violations": violations,
            "summary": {
                "total": len(violations),
                "by_pattern": by_pattern,
                "files_affected": len(sorted({o["file"] for o in violations})),
                "baseline_size": len(baseline),
                "scanned_occurrences": len(occ),
            },
        },
        "error": "",
    }
    print(json.dumps(result, indent=2, ensure_ascii=False))

    if violations:
        print("\nFAIL: {} new maintainer breadcrumb(s) found "
              "(not in baseline):".format(len(violations)), file=sys.stderr)
        for o in violations:
            print("  {}:{}: [{}] {}  ->  {}".format(
                o["file"], o["line"], o["pattern"], o["match"], o["context"]),
                file=sys.stderr)
        print("\nFix: remove the breadcrumb and state the rationale "
              "semantically (do NOT reconcile version tags). A genuine new "
              "compatibility fact is admitted via "
              "`python3 scripts/check-breadcrumbs.py --update-baseline` with a "
              "PR justification.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
