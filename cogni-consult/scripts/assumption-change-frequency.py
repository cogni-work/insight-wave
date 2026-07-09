#!/usr/bin/env python3
"""Retrospective change-frequency spike over an engagement's deliverable corpus.

Usage:
  python3 assumption-change-frequency.py <corpus-path> [--since <git-date>]

Mines the git history of the markdown deliverables under <corpus-path> and
measures how often bare numeric literals (market sizes, rates, headcounts,
price points — the class an assumption registry would later capture) changed
over the observed window. This is the sizing datum the assumption-SSOT roadmap
gates its cascade + prose-regen automation on: build the automation only when
numbers actually move often enough to earn it.

Read-only and registry-independent by construction — it reads git history, not
assumptions.json, so it runs retrospectively over corpora that predate any
{{asm:id}} migration. A literal is any number token (with optional thousands
separators, decimal, and a %/currency/unit suffix) appearing on an added or
removed line of a commit diff, outside YAML frontmatter and fenced code blocks.
An "edit" is a commit that added or removed at least one occurrence of that
literal in a file; `edits_per_literal` is the mean edit count across every
distinct (file, literal) pair observed. Measurement is line-granular (git
diffs are line-based): a literal sharing a physical line with a number that
changed is attributed the edit too. That is a deliberate, documented
imprecision for a sizing spike — it over-counts co-located literals slightly
but never under-counts real movement, which is the safe bias for a
"do numbers move often enough to earn the automation?" decision.

Output: single-line JSON envelope {"success": bool, "data": {...}, "error": str}.
Stdlib-only (argparse, json, os, re, subprocess, collections). Exit 1 on
failure, mirroring resolve-assumptions.py's fail-loud convention.
"""

import argparse
import json
import os
import re
import subprocess
import sys
from collections import defaultdict

# A bare numeric literal: an integer/decimal with optional thousands separators
# and an optional trailing unit (%, currency symbol, or a short alpha unit like
# bn/m/k/EUR). A leading currency symbol is captured too. Deliberately broader
# than resolve-assumptions.py's {{asm:id}} PLACEHOLDER_RE — this mines raw prose
# numbers that predate (or never reach) the registry, which the placeholder
# pattern would miss entirely. The trailing-unit group binds to the whole
# number (not one alternation branch), so "4.2bn" stays one token, not "4.2".
LITERAL_RE = re.compile(
    r"(?<![\w.])"                       # not mid-identifier / mid-number
    r"[€$£]?"                           # optional leading currency
    r"\d[\d,]*(?:\.\d+)?"               # digit run (grouping ok) + optional decimal
    r"(?:\s?(?:%|bn|m|k|EUR|USD|GBP|pp|x)\b)?"  # optional trailing unit
)
FENCE_RE = re.compile(r"^\s*(```|~~~)")


def _emit(success, data, error):
    print(json.dumps({"success": success, "data": data, "error": error}))
    sys.exit(0 if success else 1)


def _git(args, cwd):
    """Run a git command in cwd, returning stdout text. Raises on non-zero."""
    return subprocess.run(
        ["git", *args], cwd=cwd, check=True,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
    ).stdout


def _literals_on_line(line):
    """Return the set of normalized numeric literals on one diff content line."""
    return {m.group(0).strip() for m in LITERAL_RE.finditer(line)}


def cmd_frequency(args):
    # realpath both sides so file paths stay clean across symlinked temp roots
    # (e.g. macOS /var -> /private/var) — git rev-parse returns the real path.
    corpus = os.path.realpath(args.corpus_path)
    if not os.path.isdir(corpus):
        _emit(False, {"failed_check": "corpus_missing", "path": corpus},
              "corpus path is not a directory: %s" % corpus)

    # Locate the git work tree that owns the corpus. `git -C <corpus>` resolves
    # the enclosing repo, so a subdirectory of a repo works too.
    try:
        repo_root = os.path.realpath(
            _git(["rev-parse", "--show-toplevel"], corpus).strip())
    except (subprocess.CalledProcessError, OSError) as exc:
        _emit(False, {"failed_check": "not_a_git_repo", "path": corpus},
              "corpus path is not inside a git repository: %s" % exc)

    since_args = ["--since", args.since] if args.since else []

    # List the markdown deliverables tracked under the corpus path. A plain
    # pathspec (not a `*.md` glob, which git's wildmatch would not recurse
    # through subdirectories) lists every tracked file under the corpus; filter
    # to markdown in Python so nested action-fields/<field>/<deliverable>.md are
    # all included.
    try:
        listing = _git(["ls-files", "--", corpus], repo_root)
    except (subprocess.CalledProcessError, OSError) as exc:
        _emit(False, {"failed_check": "git_ls_failed", "path": corpus},
              "could not list tracked markdown under the corpus: %s" % exc)
    files = [f for f in listing.splitlines() if f.strip().endswith(".md")]
    if not files:
        _emit(True, {"corpus_path": corpus, "window": {"start": None, "end": None},
                     "files_observed": 0, "literals_observed": 0,
                     "literals": [], "edits_per_literal": 0.0}, "")

    # (file, literal) -> count of commits that changed that literal in that file.
    edit_counts = defaultdict(int)
    commit_dates = []

    def flush(rel, date, touched_set):
        # Record one edit event per literal touched by a single commit of rel.
        if date is None:
            return
        commit_dates.append(date)
        for lit in touched_set:
            edit_counts[(rel, lit)] += 1

    for rel in files:
        try:
            log = _git(["log", *since_args, "--follow", "--format=%x01%cI",
                        "-p", "--", rel], repo_root)
        except (subprocess.CalledProcessError, OSError) as exc:
            _emit(False, {"failed_check": "git_log_failed", "path": rel},
                  "git log failed for %s: %s" % (rel, exc))

        commit_date = None
        in_fence = False
        in_frontmatter = False
        # Per-commit set of literals touched, so N occurrences on one commit
        # count as a single edit event for that literal.
        touched = set()

        for line in log.splitlines():
            if line.startswith("\x01"):
                # New commit boundary — flush the previous commit's touches.
                flush(rel, commit_date, touched)
                commit_date = line[1:].strip() or None
                touched = set()
                in_fence = False
                in_frontmatter = False
                continue
            if not line or line[0] not in "+-":
                continue
            content = line[1:]
            # Skip diff headers (+++/---).
            if content.startswith(("++ ", "-- ")) or content in ("++", "--"):
                continue
            stripped = content.strip()
            # Track YAML frontmatter fences (--- on its own line) and code fences
            # so numbers inside them are not counted as prose literals.
            if stripped == "---":
                in_frontmatter = not in_frontmatter
                continue
            if FENCE_RE.match(content):
                in_fence = not in_fence
                continue
            if in_fence or in_frontmatter:
                continue
            touched |= _literals_on_line(content)
        flush(rel, commit_date, touched)

    literals = [
        {"file": os.path.relpath(os.path.join(repo_root, rel), corpus),
         "value": lit, "edit_count": count}
        for (rel, lit), count in sorted(edit_counts.items(),
                                        key=lambda kv: (-kv[1], kv[0][0], kv[0][1]))
    ]
    literals_observed = len(literals)
    total_edits = sum(edit_counts.values())
    edits_per_literal = round(total_edits / literals_observed, 4) if literals_observed else 0.0
    window = {"start": min(commit_dates), "end": max(commit_dates)} if commit_dates \
        else {"start": None, "end": None}

    _emit(True, {
        "corpus_path": corpus,
        "window": window,
        "files_observed": len(files),
        "literals_observed": literals_observed,
        "literals": literals,
        "edits_per_literal": edits_per_literal,
    }, "")


def main():
    parser = argparse.ArgumentParser(
        description="Measure git-history change frequency of numeric literals "
                    "in an engagement's deliverable corpus")
    parser.add_argument("corpus_path",
                        help="directory of deliverable markdown (an engagement "
                             "root or its action-fields/ tree)")
    parser.add_argument("--since", default=None,
                        help="only mine commits since this git date (e.g. "
                             "'2026-01-01' or '6 months ago')")
    parser.set_defaults(func=cmd_frequency)
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
