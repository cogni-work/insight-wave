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
separators, decimal, and a %/currency/unit suffix) in a file's prose, outside
YAML frontmatter and fenced code blocks. For each markdown deliverable the
script walks its commits oldest-to-newest, parses the *full* file content at
each version (so frontmatter and code-fence boundaries are detected exactly,
never guessed from diff fragments), and counts a literal as edited at a commit
whenever its per-file occurrence count differs from the previous version —
added, removed, or multiplicity changed. `edits_per_literal` is the mean edit
count across every distinct (file, literal) pair observed. The full-content
comparison is what keeps the datum honest: a horizontal rule in the body never
masks the literals after it, and a code fence never leaks its numbers, so the
"do numbers move often enough to earn the automation?" decision rests on a
measurement rather than a diff-parsing heuristic.

Output: single-line JSON envelope {"success": bool, "data": {...}, "error": str}.
Stdlib-only (argparse, json, os, re, subprocess, collections). Exit 1 on
failure, mirroring resolve-assumptions.py's fail-loud convention.
"""

import argparse
import datetime
import json
import os
import re
import subprocess
import sys
from collections import Counter, defaultdict

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
    # ensure_ascii=False keeps non-ASCII literals (€4.2bn) and accented file
    # paths readable, consistent with the plugin's other script output.
    print(json.dumps({"success": success, "data": data, "error": error},
                     ensure_ascii=False))
    sys.exit(0 if success else 1)


def _git(args, cwd):
    """Run a git command in cwd, returning stdout text. Raises on non-zero."""
    return subprocess.run(
        ["git", *args], cwd=cwd, check=True,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
    ).stdout


def literals_in_text(text):
    """Count numeric literals in a full markdown document.

    Because it reads the *complete* file content (not diff fragments), YAML
    frontmatter and fenced code blocks are detected reliably: frontmatter is
    only the leading `---`…`---` block, and a code fence's open/close pair is
    always both present. This is what lets the change-frequency measurement
    avoid the diff-hunk ambiguity where a body horizontal rule or a fence whose
    partner is an unchanged context line would silently mask real literals.
    Returns a Counter keyed by literal token so a repeated literal's count
    change registers as an edit.
    """
    counts = Counter()
    lines = text.splitlines()
    in_fence = False
    start = 0
    # YAML frontmatter: only when the very first line is a `---` delimiter.
    if lines and lines[0].strip() == "---":
        for i in range(1, len(lines)):
            if lines[i].strip() == "---":
                start = i + 1
                break
        else:
            start = len(lines)  # unterminated frontmatter → whole file is header
    for line in lines[start:]:
        if FENCE_RE.match(line):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        for m in LITERAL_RE.finditer(line):
            counts[m.group(0).strip()] += 1
    return counts


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

    # (file, literal) -> number of commits that added, removed, or changed the
    # count of that literal in that file. Measured by comparing each commit's
    # full-file literal Counter against the previous version's — no diff-hunk
    # parsing, so frontmatter/fence detection is exact and a line beginning with
    # "--" or "++" is never mistaken for a diff header.
    edit_counts = defaultdict(int)
    commit_instants = []

    for rel in files:
        try:
            log = _git(["log", *since_args, "--reverse", "--format=%H %cI",
                        "--", rel], repo_root)
        except (subprocess.CalledProcessError, OSError) as exc:
            _emit(False, {"failed_check": "git_log_failed", "path": rel},
                  "git log failed for %s: %s" % (rel, exc))

        prev = Counter()
        for entry in log.splitlines():
            if not entry.strip():
                continue
            sha, _, iso = entry.partition(" ")
            try:
                blob = _git(["show", "%s:%s" % (sha, rel)], repo_root)
            except (subprocess.CalledProcessError, OSError) as exc:
                _emit(False, {"failed_check": "git_show_failed", "path": rel},
                      "git show failed for %s at %s: %s" % (rel, sha, exc))
            try:
                commit_instants.append(datetime.datetime.fromisoformat(iso.strip()))
            except ValueError:
                pass  # unparseable date is non-fatal — the edit still counts
            cur = literals_in_text(blob)
            # An edit event for a literal at this commit = its count differs
            # from the previous version (added, removed, or multiplicity change).
            for lit in set(cur) | set(prev):
                if cur[lit] != prev[lit]:
                    edit_counts[(rel, lit)] += 1
            prev = cur

    literals = [
        {"file": os.path.relpath(os.path.join(repo_root, rel), corpus),
         "value": lit, "edit_count": count}
        for (rel, lit), count in sorted(edit_counts.items(),
                                        key=lambda kv: (-kv[1], kv[0][0], kv[0][1]))
    ]
    literals_observed = len(literals)
    total_edits = sum(edit_counts.values())
    edits_per_literal = round(total_edits / literals_observed, 4) if literals_observed else 0.0
    # Compare instants (timezone-aware datetimes), not ISO strings: lexical
    # string order is wrong across differing committer timezone offsets.
    window = {"start": min(commit_instants).isoformat(),
              "end": max(commit_instants).isoformat()} if commit_instants \
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
